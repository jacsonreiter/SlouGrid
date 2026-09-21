import SwiftUI
import UIKit

struct TelaDeCombate: View {
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    let zona: Zona
    let contraChefe: Bool
    let elite: Bool
    // Guardado (não só usado no init) porque "Continuar Explorando" gera
    // um novo inimigo sem sair da tela — precisa do nível de novo.
    let nivelHeroi: Int
    // Idem: "Continuar Explorando" precisa regerar inimigos com o mesmo
    // multiplicador de New Game+ do resto do combate (ver `Zona.
    // multiplicadorDeCiclo`).
    let cicloNewGamePlus: Int

    // Sempre um array, mesmo contra chefe/elite (grupo de 1) — um único
    // caminho de código pra combate solo ou em grupo, em vez de duplicar
    // toda a lógica. Ver `Zona.gerarGrupoComum`.
    @State private var inimigos: [Inimigo]
    @State private var indiceAlvo: Int = 0
    @State private var log: [String] = []
    @State private var combateEncerrado = false
    @State private var vitoria = false
    @State private var mostrandoItens = false
    @State private var mostrandoMagias = false

    // Efeitos ativos nos inimigos (só duram durante este combate), um por
    // índice do array — permite vários inimigos envenenados/atordoados ao
    // mesmo tempo num grupo.
    @State private var venenoPorAlvo: [Int: (dano: Int, turnos: Int)] = [:]
    @State private var atordoadoPorAlvo: Set<Int> = []

    // Golpe carregado do chefe (estilo "telegraph" de RPG por turnos, ver
    // `aplicarAtaqueDoChefe`) — só chefes fazem isso, e só existe um chefe
    // por combate (array de 1), então continuam sendo estado escalar.
    @State private var turnosAteGolpeDoChefe = 3
    @State private var chefePrestesAGolpear = false
    // Depois de atordoado, o chefe fica 2 turnos imune a um novo
    // atordoamento — sem isso, uma magia atordoante recastada todo turno
    // travava o chefe pra sempre, sem ele nunca conseguir agir. Elite é
    // sempre imune (ver `lancarMagia`), forte demais pra ser controlado assim.
    @State private var turnosDeImunidadeAAtordoamento = 0

    // Fortalecimentos ativos no herói (só duram durante este combate,
    // nunca alteram os atributos salvos do personagem).
    @State private var bonusForcaTemporario = 0
    @State private var turnosDeBonusForca = 0
    @State private var bonusDefesaTemporaria = 0
    @State private var turnosDeBonusDefesa = 0
    @State private var bonusInteligenciaTemporaria = 0
    @State private var turnosDeBonusInteligencia = 0
    @State private var bonusAgilidadeTemporaria = 0
    @State private var turnosDeBonusAgilidade = 0

    init(zona: Zona, contraChefe: Bool, nivelHeroi: Int, elite: Bool = false, cicloNewGamePlus: Int = 0) {
        self.zona = zona
        self.contraChefe = contraChefe
        self.elite = elite
        self.nivelHeroi = nivelHeroi
        self.cicloNewGamePlus = cicloNewGamePlus
        _inimigos = State(initialValue: contraChefe
            ? [zona.gerarChefe(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)]
            : (elite ? [zona.gerarInimigoDeElite(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)] : zona.gerarGrupoComum(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inimigosCard
                heroiCard
                logDeCombate

                if combateEncerrado {
                    resultadoBox
                } else {
                    acoesDeCombate
                }
            }
            .padding()
        }
        .navigationTitle(zona.nome)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: iniciarSeNecessario)
        .sheet(isPresented: $mostrandoItens) {
            listaDeItens
        }
        .sheet(isPresented: $mostrandoMagias) {
            listaDeMagias
        }
    }

    // MARK: - Cartões de status

    var inimigosCard: some View {
        VStack(spacing: 10) {
            if inimigos.count > 1 {
                Text("Toque em um inimigo para focar seus ataques nele.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            ForEach(Array(inimigos.enumerated()), id: \.offset) { indice, inimigoDaLista in
                cartaoDeInimigo(indice: indice, inimigoDaLista: inimigoDaLista)
            }
        }
    }

    func cartaoDeInimigo(indice: Int, inimigoDaLista: Inimigo) -> some View {
        let emFoco = indice == indiceAlvo && inimigoDaLista.estaVivo
        let corBase: Color = inimigoDaLista.chefe ? .red : (inimigoDaLista.elite ? .orange : .primary)
        let corFundo: Color = inimigoDaLista.chefe ? .red : (inimigoDaLista.elite ? .orange : .gray)

        return Button {
            selecionarAlvo(indice)
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: inimigoDaLista.icone)
                        .font(.system(size: 34))
                        .foregroundColor(corBase)
                    VStack(alignment: .leading) {
                        Text(inimigoDaLista.nome).font(.subheadline).fontWeight(.bold)
                        Text("Nível \(inimigoDaLista.nivel)\(inimigoDaLista.chefe ? " · Chefe" : (inimigoDaLista.elite ? " · Elite" : ""))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if venenoPorAlvo[indice] != nil {
                            Label("Envenenado", systemImage: "drop.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        if atordoadoPorAlvo.contains(indice) {
                            Label("Atordoado", systemImage: "zzz")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        if inimigoDaLista.chefe && chefePrestesAGolpear {
                            Label("Carregando golpe!", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
                if inimigoDaLista.estaVivo {
                    ProgressView(value: Double(inimigoDaLista.vidaAtual), total: Double(inimigoDaLista.vidaMaxima))
                        .tint(.red)
                    Text("\(inimigoDaLista.vidaAtual) / \(inimigoDaLista.vidaMaxima) vida")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Derrotado")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(corFundo.opacity(inimigoDaLista.estaVivo ? (emFoco ? 0.22 : 0.1) : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(emFoco ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .disabled(!inimigoDaLista.estaVivo || combateEncerrado)
        .opacity(inimigoDaLista.estaVivo ? 1 : 0.6)
    }

    var heroiCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: vm.heroi.classe.icone)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(vm.heroi.nome).font(.headline)
                    Text("Nível \(vm.heroi.nivel)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            ProgressView(value: Double(vm.heroi.vidaAtual), total: Double(vm.heroi.vidaMaxima))
                .tint(.green)
            Text("\(vm.heroi.vidaAtual) / \(vm.heroi.vidaMaxima) vida")
                .font(.caption2)
                .foregroundColor(.secondary)
            ProgressView(value: Double(vm.heroi.energiaAtual), total: Double(vm.heroi.energiaMaximaTotal))
                .tint(.blue)
            Text("\(vm.heroi.energiaAtual) / \(vm.heroi.energiaMaximaTotal) \(vm.heroi.classe.nomeDoRecurso.lowercased())")
                .font(.caption2)
                .foregroundColor(.secondary)

            if bonusForcaTemporario > 0 || bonusDefesaTemporaria > 0 || bonusInteligenciaTemporaria > 0 || bonusAgilidadeTemporaria > 0 {
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        if bonusForcaTemporario > 0 {
                            Label("+\(bonusForcaTemporario) Força (\(turnosDeBonusForca)t)", systemImage: "arrow.up.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if bonusDefesaTemporaria > 0 {
                            Label("+\(bonusDefesaTemporaria) Defesa (\(turnosDeBonusDefesa)t)", systemImage: "shield.fill")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        }
                    }
                    HStack(spacing: 12) {
                        if bonusInteligenciaTemporaria > 0 {
                            Label("+\(bonusInteligenciaTemporaria) Intel. (\(turnosDeBonusInteligencia)t)", systemImage: "brain.head.profile")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if bonusAgilidadeTemporaria > 0 {
                            Label("+\(bonusAgilidadeTemporaria) Agilidade (\(turnosDeBonusAgilidade)t)", systemImage: "hare.fill")
                                .font(.caption2)
                                .foregroundColor(.mint)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }

    // Tamanho fixo com rolagem própria — antes crescia sem parar conforme o
    // combate avançava, empurrando os botões de ação cada vez mais pra
    // baixo da tela. Ordem cronológica (mais antiga no topo) com auto-scroll
    // pra última linha a cada evento novo, como um log de chat de verdade.
    var logDeCombate: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(log.enumerated()), id: \.offset) { indice, linha in
                        Text(linha).font(.caption).id(indice)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color.gray.opacity(0.06))
            .cornerRadius(10)
            .frame(height: 140)
            .onChange(of: log.count) { _ in
                guard let ultimoIndice = log.indices.last else { return }
                withAnimation {
                    proxy.scrollTo(ultimoIndice, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Ações

    var acoesDeCombate: some View {
        VStack(spacing: 10) {
            Button { atacar() } label: {
                Label("Atacar", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let habilidade = vm.heroi.armaEquipada?.habilidadeDeArma {
                botaoDeGolpeDeArma(habilidade)
            }

            HStack(spacing: 8) {
                ForEach(0..<Personagem.numeroDeSlotsDeMagia, id: \.self) { indice in
                    botaoDeSlotDeMagia(indice)
                }
            }

            if vm.heroi.cargasDeFrascoTotal > 0 {
                HStack(spacing: 8) {
                    botaoDeFrasco(titulo: "Frasco de Vida", icone: "drop.fill", cor: .pink,
                                  atuais: vm.heroi.frascosDeVidaAtuais, alocados: vm.heroi.frascosDeVidaAlocados,
                                  acao: usarFrascoDeVida)
                    botaoDeFrasco(titulo: "Frasco de \(vm.heroi.classe.nomeDoRecurso)", icone: "flask.fill", cor: .teal,
                                  atuais: vm.heroi.frascosDeEnergiaAtuais, alocados: vm.heroi.frascosDeEnergiaAlocados,
                                  acao: usarFrascoDeEnergia)
                }
            }

            HStack {
                Button { mostrandoItens = true } label: {
                    Label("Itens", systemImage: "bag.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button { mostrandoMagias = true } label: {
                    Label("Grimório", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button { fugir() } label: {
                    Label("Fugir", systemImage: "figure.run")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    // Slot de ataque rápido: um toque só, sem precisar abrir o grimório.
    func botaoDeSlotDeMagia(_ indice: Int) -> some View {
        let magia = vm.heroi.magiaNoSlot(indice)
        let energiaSuficiente = magia != nil && vm.heroi.energiaAtual >= magia!.custoEnergia

        return Button {
            if let magia = magia {
                lancarMagia(magia)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: magia?.icone ?? "minus.circle")
                    .font(.title3)
                Text(magia?.nome ?? "Vazio")
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let magia = magia {
                    Text("\(magia.custoEnergia) EN")
                        .font(.system(size: 9))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.vertical, 6)
            .background(magia == nil ? Color.gray.opacity(0.35) : (energiaSuficiente ? Color.purple : Color.gray))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(magia == nil || !energiaSuficiente)
    }

    // "Golpe de Arma" (estilo Ash of War): a habilidade especial da arma
    // equipada. Reaproveita `lancarMagia` — mesmo motor de dano/efeito do
    // grimório — já que a habilidade nada mais é que uma `Magia` carregada
    // pelo item em vez de escolhida pelo jogador em um slot.
    func botaoDeGolpeDeArma(_ habilidade: Magia) -> some View {
        let energiaSuficiente = vm.heroi.energiaAtual >= habilidade.custoEnergia
        return Button { lancarMagia(habilidade) } label: {
            Label("\(habilidade.nome) (\(habilidade.custoEnergia) EN)", systemImage: habilidade.icone)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(energiaSuficiente ? Color.indigo : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(!energiaSuficiente || combateEncerrado)
    }

    // Frasco Sagrado: cura/energia gratuita com cargas limitadas, recarrega
    // só ao descansar (ver `Personagem.descansar`).
    func botaoDeFrasco(titulo: String, icone: String, cor: Color, atuais: Int, alocados: Int, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            VStack(spacing: 2) {
                Image(systemName: icone).font(.title3)
                Text(titulo).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                Text("\(atuais)/\(alocados)").font(.system(size: 9))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.vertical, 6)
            .background(atuais > 0 ? cor : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(atuais <= 0 || combateEncerrado)
    }

    // Depois de uma vitória (ou descoberta), o jogador escolhe: sair da
    // masmorra com o que já ganhou, ou continuar explorando ali mesmo, sem
    // voltar pro menu — encadeando encontros dentro da mesma visita, como
    // um "delve" de roguelike. Só derrota não oferece continuar (a vida
    // zerada não dá pra seguir; volte e descanse).
    var resultadoBox: some View {
        VStack(spacing: 12) {
            Image(systemName: vitoria ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(vitoria ? .green : .red)
            Text(vitoria ? "Vitória!" : "Derrota")
                .font(.title)
                .fontWeight(.bold)

            if vitoria {
                HStack(spacing: 12) {
                    Button("Sair da Masmorra") { dismiss() }
                        .font(.subheadline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)

                    Button("Continuar Explorando") { continuarExplorando() }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                Button("Voltar") { dismiss() }
                    .font(.title3)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    var listaDeItens: some View {
        NavigationStack {
            List {
                let pocoes = vm.heroi.inventario.filter { $0.item.tipo == .pocao }
                if pocoes.isEmpty {
                    Text("Você não tem poções.").foregroundColor(.secondary)
                } else {
                    ForEach(pocoes) { pilha in
                        Button {
                            usarItem(pilha)
                        } label: {
                            HStack {
                                Text("\(pilha.item.nome) x\(pilha.quantidade)")
                                Spacer()
                                Text(pilha.item.descricao).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Usar Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { mostrandoItens = false }
                }
            }
        }
    }

    var listaDeMagias: some View {
        NavigationStack {
            List {
                let magias = vm.heroi.classe.grimorio
                    .filter { $0.nivelNecessario <= vm.heroi.nivel }
                    .sorted { $0.nivelNecessario < $1.nivelNecessario }
                ForEach(magias) { magia in
                    Button {
                        lancarMagia(magia)
                    } label: {
                        HStack {
                            Image(systemName: magia.icone)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(magia.nome).font(.headline)
                                Text(magia.descricao)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(magia.custoEnergia) EN")
                                .font(.caption)
                                .foregroundColor(vm.heroi.energiaAtual >= magia.custoEnergia ? .blue : .red)
                        }
                    }
                    .disabled(vm.heroi.energiaAtual < magia.custoEnergia)
                }
            }
            .navigationTitle("Magias")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { mostrandoMagias = false }
                }
            }
        }
    }

    // MARK: - Lógica de combate

    private func iniciarSeNecessario() {
        guard log.isEmpty else { return }
        anunciarInimigo()
    }

    private func anunciarInimigo() {
        if inimigos.count > 1 {
            log.append("Um grupo de \(inimigos.count) inimigos apareceu: \(inimigos.map { $0.nome }.joined(separator: ", "))!")
        } else if let unico = inimigos.first {
            if unico.chefe {
                log.append("O chefe \(unico.nome) apareceu!")
            } else if unico.elite {
                log.append("Um inimigo de elite, \(unico.nome), apareceu! Ele é mais forte que o normal da zona — cuidado.")
            } else {
                log.append("\(unico.nome) apareceu!")
            }
        }
    }

    // "Continuar Explorando" (ver `resultadoBox`): sorteia o próximo
    // encontro dentro da MESMA zona, sem sair da tela — reaproveita
    // `Zona.sortearEncontro()`, a mesma variedade do botão "Explorar" das
    // Masmorras. Depois de um chefe, o próximo encontro é sempre um
    // encontro comum de exploração (nunca outro chefe).
    private func continuarExplorando() {
        switch zona.sortearEncontro() {
        case .comum:
            inimigos = zona.gerarGrupoComum(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)
            iniciarNovoEncontro()
        case .eliteDeCampo:
            inimigos = [zona.gerarInimigoDeElite(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)]
            iniciarNovoEncontro()
        case .descoberta:
            let recompensa = vm.heroi.receberDescoberta(zonaNome: zona.nome, nivelZona: zona.nivelBaseInimigos)
            var texto = "Você encontrou \(recompensa.runas) Runas explorando mais fundo, sem cruzar com nenhum inimigo."
            if let item = recompensa.item {
                texto += " Também achou: \(item.nome)!"
            }
            log.append(texto)
            // Continua em "resultado" (combateEncerrado/vitoria já true) —
            // o resultadoBox some de novo com Sair/Continuar.
        }
    }

    // Reseta todo o estado de UM combate (efeitos, fortalecimentos, golpe
    // de chefe) sem tocar no herói (vida/energia continuam de onde
    // pararam) — é o que faz "Continuar Explorando" sentir como seguir
    // fundo na masmorra, não um combate isolado novo.
    private func iniciarNovoEncontro() {
        combateEncerrado = false
        vitoria = false
        indiceAlvo = 0
        venenoPorAlvo = [:]
        atordoadoPorAlvo = []
        turnosAteGolpeDoChefe = 3
        chefePrestesAGolpear = false
        turnosDeImunidadeAAtordoamento = 0
        bonusForcaTemporario = 0
        turnosDeBonusForca = 0
        bonusDefesaTemporaria = 0
        turnosDeBonusDefesa = 0
        bonusInteligenciaTemporaria = 0
        turnosDeBonusInteligencia = 0
        bonusAgilidadeTemporaria = 0
        turnosDeBonusAgilidade = 0
        anunciarInimigo()
    }

    // Destreza rege a chance de acerto — usada tanto pelo ataque básico
    // quanto pelas magias ofensivas (ver `lancarMagia`).
    private func rolarAcerto() -> Bool {
        Int.random(in: 1...100) <= vm.heroi.chanceDeAcerto
    }

    private var inimigoAlvo: Inimigo? {
        guard indiceAlvo >= 0, indiceAlvo < inimigos.count, inimigos[indiceAlvo].estaVivo else { return nil }
        return inimigos[indiceAlvo]
    }

    private var algumInimigoVivo: Bool {
        inimigos.contains(where: { $0.estaVivo })
    }

    // Se o alvo focado morreu (ou nunca foi válido), foca automaticamente
    // no próximo inimigo vivo — o jogador sempre pode trocar de novo
    // tocando em outro cartão.
    private func avancarAlvoSeNecessario() {
        if indiceAlvo >= inimigos.count || !inimigos[indiceAlvo].estaVivo {
            if let proximo = inimigos.firstIndex(where: { $0.estaVivo }) {
                indiceAlvo = proximo
            }
        }
    }

    private func selecionarAlvo(_ indice: Int) {
        guard indice >= 0, indice < inimigos.count, inimigos[indice].estaVivo else { return }
        indiceAlvo = indice
    }

    private func atacar() {
        guard !combateEncerrado, inimigoAlvo != nil else { return }
        guard rolarAcerto() else {
            log.append("Você errou o ataque!")
            turnoDosInimigos()
            return
        }
        let resultado = vm.heroi.calcularDanoBasico(bonusForca: bonusForcaTemporario)
        aplicarDanoBasicoAoAlvo(resultado.dano, critico: resultado.critico)
    }

    // A Defesa do inimigo (ver `Zona.swift`) mitiga o golpe, espelhando
    // como a Defesa do herói já funciona em `Personagem.sofrerDano`.
    private func aplicarDanoBasicoAoAlvo(_ danoBruto: Int, critico: Bool) {
        let indice = indiceAlvo
        let danoFinal = max(1, danoBruto - inimigos[indice].defesa)
        inimigos[indice].vidaAtual = max(0, inimigos[indice].vidaAtual - danoFinal)
        let nomeAlvo = inimigos[indice].nome
        log.append(critico
            ? "Você acertou um golpe crítico! -\(danoFinal) de vida no \(nomeAlvo)."
            : "Você atacou o \(nomeAlvo) causando \(danoFinal) de dano.")
        UIImpactFeedbackGenerator(style: critico ? .heavy : .medium).impactOccurred()

        if !inimigos[indice].estaVivo {
            log.append("\(nomeAlvo) foi derrotado!")
            venenoPorAlvo[indice] = nil
            atordoadoPorAlvo.remove(indice)
            avancarAlvoSeNecessario()
        }

        if algumInimigoVivo {
            turnoDosInimigos()
        } else {
            finalizarCombate(vitoria: true)
        }
    }

    private func lancarMagia(_ magia: Magia) {
        guard !combateEncerrado else { return }
        guard vm.heroi.energiaAtual >= magia.custoEnergia else {
            log.append("Energia insuficiente para \(magia.nome)!")
            return
        }
        vm.heroi.energiaAtual -= magia.custoEnergia
        mostrandoMagias = false

        if magia.tipo == .cura {
            vm.heroi.vidaAtual = min(vm.heroi.vidaMaxima, vm.heroi.vidaAtual + magia.valorCura)
            log.append("Você usou \(magia.nome) e recuperou \(magia.valorCura) de vida!")
            turnoDosInimigos()
            return
        }

        if magia.tipo == .fortalecimento {
            let partes = aplicarFortalecimento(magia)
            log.append("Você usou \(magia.nome)! \(partes) por \(magia.duracaoEmTurnos) turnos.")
            turnoDosInimigos()
            return
        }

        guard inimigoAlvo != nil else { return }

        // Magias ofensivas (dano, veneno, atordoante) também dependem de
        // Destreza para acertar — exceto as marcadas como certeiras.
        if !magia.sempreAcerta && !rolarAcerto() {
            log.append("Sua magia \(magia.nome) falhou!")
            turnoDosInimigos()
            return
        }

        // O atributo que escala a magia depende da classe/magia (Força,
        // Inteligência ou Agilidade), incluindo fortalecimentos ativos —
        // mesmo soft cap de efetividade do ataque básico (ver
        // `Personagem.valorEfetivoDeDano`).
        let atributoBruto: Int
        switch magia.atributoDeEscala {
        case .forca: atributoBruto = vm.heroi.forcaTotal + bonusForcaTemporario
        case .inteligencia: atributoBruto = vm.heroi.inteligenciaTotal + bonusInteligenciaTemporaria
        case .agilidade: atributoBruto = vm.heroi.agilidadeTotal + bonusAgilidadeTemporaria
        }
        let atributoBase = Int(Personagem.valorEfetivoDeDano(atributoBruto))
        let danoBruto = max(1, Int(Double(atributoBase) * magia.multiplicadorDano))

        let indice = indiceAlvo
        // Mesma mitigação de Defesa do ataque básico (ver
        // `aplicarDanoBasicoAoAlvo`) — o veneno/dano por turno logo abaixo
        // fica de fora de propósito, como o sangramento/veneno de Elden
        // Ring, que ignora a armadura.
        let danoFinal = max(1, danoBruto - inimigos[indice].defesa)
        inimigos[indice].vidaAtual = max(0, inimigos[indice].vidaAtual - danoFinal)
        let nomeAlvo = inimigos[indice].nome
        var texto = "Você usou \(magia.nome) e causou \(danoFinal) de dano em \(nomeAlvo)!"

        let alvoAindaVivo = inimigos[indice].estaVivo
        if alvoAindaVivo && magia.tipo == .danoComEfeito {
            let danoPorTurno = max(1, Int(Double(atributoBase) * magia.multiplicadorDanoPorTurno))
            venenoPorAlvo[indice] = (dano: danoPorTurno, turnos: magia.duracaoEmTurnos)
            texto += " \(nomeAlvo) está envenenado."
        } else if alvoAindaVivo && magia.tipo == .atordoante {
            if inimigos[indice].elite {
                // Elite é grande e resistente demais pra ser controlado por
                // atordoamento — só dano puro funciona nele.
                texto += " Mas \(nomeAlvo) resiste ao atordoamento — é forte demais!"
            } else if inimigos[indice].chefe && turnosDeImunidadeAAtordoamento > 0 {
                texto += " Mas \(nomeAlvo) ainda resiste, se recuperando do último atordoamento!"
            } else {
                atordoadoPorAlvo.insert(indice)
                texto += " \(nomeAlvo) ficou atordoado!"
            }
        }

        if magia.valorCura > 0 {
            vm.heroi.vidaAtual = min(vm.heroi.vidaMaxima, vm.heroi.vidaAtual + magia.valorCura)
            texto += " Você recuperou \(magia.valorCura) de vida."
        }

        log.append(texto)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        if !alvoAindaVivo {
            log.append("\(nomeAlvo) foi derrotado!")
            venenoPorAlvo[indice] = nil
            atordoadoPorAlvo.remove(indice)
            avancarAlvoSeNecessario()
        }

        if algumInimigoVivo {
            turnoDosInimigos()
        } else {
            finalizarCombate(vitoria: true)
        }
    }

    // Aplica um bônus temporário de combate (Força/Defesa/Inteligência/
    // Agilidade) e devolve uma descrição textual — usado tanto por magias
    // de fortalecimento do grimório (`lancarMagia`) quanto por poções de
    // fortalecimento (`usarItem`, logo abaixo), já que as duas reaproveitam
    // o mesmo `Magia.tipo == .fortalecimento`.
    @discardableResult
    private func aplicarFortalecimento(_ magia: Magia) -> String {
        var partes: [String] = []
        if magia.bonusForca > 0 {
            bonusForcaTemporario = magia.bonusForca
            turnosDeBonusForca = magia.duracaoEmTurnos
            partes.append("+\(magia.bonusForca) força")
        }
        if magia.bonusDefesa > 0 {
            bonusDefesaTemporaria = magia.bonusDefesa
            turnosDeBonusDefesa = magia.duracaoEmTurnos
            partes.append("+\(magia.bonusDefesa) defesa")
        }
        if magia.bonusInteligencia > 0 {
            bonusInteligenciaTemporaria = magia.bonusInteligencia
            turnosDeBonusInteligencia = magia.duracaoEmTurnos
            partes.append("+\(magia.bonusInteligencia) inteligência")
        }
        if magia.bonusAgilidade > 0 {
            bonusAgilidadeTemporaria = magia.bonusAgilidade
            turnosDeBonusAgilidade = magia.duracaoEmTurnos
            partes.append("+\(magia.bonusAgilidade) agilidade")
        }
        return partes.joined(separator: " e ")
    }

    private func usarFrascoDeVida() {
        guard !combateEncerrado else { return }
        log.append(vm.heroi.usarFrascoDeVida())
        turnoDosInimigos()
    }

    private func usarFrascoDeEnergia() {
        guard !combateEncerrado else { return }
        log.append(vm.heroi.usarFrascoDeEnergia())
        turnoDosInimigos()
    }

    private func usarItem(_ pilha: PilhaDeItens) {
        guard !combateEncerrado else { return }
        let efeito = pilha.item.efeitoDePocao
        let buff = pilha.item.efeitoDeBuffTemporario
        log.append(vm.heroi.usarItem(pilha))
        if efeito == .antidoto { venenoPorAlvo = [:] }
        if efeito == .fortalecimento, let buff = buff {
            let partes = aplicarFortalecimento(buff)
            log.append("Efeito: \(partes) por \(buff.duracaoEmTurnos) turnos.")
        }
        mostrandoItens = false
        turnoDosInimigos()
    }

    private func fugir() {
        guard !combateEncerrado else { return }
        if Int.random(in: 1...100) <= 50 {
            log.append("Você fugiu do combate!")
            combateEncerrado = true
            vitoria = false
        } else {
            log.append("Você tentou fugir, mas não conseguiu!")
            turnoDosInimigos()
        }
    }

    // Turno de TODOS os inimigos vivos: cada um age na sua vez — atordoado
    // perde a vez, o chefe usa seu golpe telegrafado, os demais atacam
    // normalmente. É isso que torna um grupo mais perigoso que um inimigo
    // só: o dano recebido no turno soma o de todos que ainda estão de pé,
    // então ignorar um deles pra focar outro tem custo real.
    private func turnoDosInimigos() {
        guard algumInimigoVivo else { return }

        aplicarRegenPassivaDeTalisma()

        if turnosDeBonusForca > 0 {
            turnosDeBonusForca -= 1
            if turnosDeBonusForca == 0 {
                bonusForcaTemporario = 0
                log.append("O efeito de força aumentada acabou.")
            }
        }
        if turnosDeBonusDefesa > 0 {
            turnosDeBonusDefesa -= 1
            if turnosDeBonusDefesa == 0 {
                bonusDefesaTemporaria = 0
                log.append("O efeito de defesa aumentada acabou.")
            }
        }
        if turnosDeBonusInteligencia > 0 {
            turnosDeBonusInteligencia -= 1
            if turnosDeBonusInteligencia == 0 {
                bonusInteligenciaTemporaria = 0
                log.append("O efeito de inteligência aumentada acabou.")
            }
        }
        if turnosDeBonusAgilidade > 0 {
            turnosDeBonusAgilidade -= 1
            if turnosDeBonusAgilidade == 0 {
                bonusAgilidadeTemporaria = 0
                log.append("O efeito de agilidade aumentada acabou.")
            }
        }
        if turnosDeImunidadeAAtordoamento > 0 {
            turnosDeImunidadeAAtordoamento -= 1
        }

        for indice in venenoPorAlvo.keys.sorted() {
            guard indice < inimigos.count, inimigos[indice].estaVivo, let ativo = venenoPorAlvo[indice] else {
                venenoPorAlvo[indice] = nil
                continue
            }
            inimigos[indice].vidaAtual = max(0, inimigos[indice].vidaAtual - ativo.dano)
            log.append("O veneno causa \(ativo.dano) de dano em \(inimigos[indice].nome).")
            if !inimigos[indice].estaVivo {
                log.append("\(inimigos[indice].nome) sucumbiu ao veneno!")
                venenoPorAlvo[indice] = nil
                atordoadoPorAlvo.remove(indice)
            } else {
                venenoPorAlvo[indice] = ativo.turnos <= 1 ? nil : (dano: ativo.dano, turnos: ativo.turnos - 1)
            }
        }

        guard algumInimigoVivo else {
            finalizarCombate(vitoria: true)
            return
        }
        avancarAlvoSeNecessario()

        for indice in inimigos.indices where inimigos[indice].estaVivo {
            if atordoadoPorAlvo.contains(indice) {
                log.append("\(inimigos[indice].nome) está atordoado e perde o turno!")
                atordoadoPorAlvo.remove(indice)
                if inimigos[indice].chefe {
                    turnosDeImunidadeAAtordoamento = 2
                }
                continue
            }
            if inimigos[indice].chefe {
                aplicarAtaqueDoChefe(indice: indice)
            } else {
                let resultado = vm.heroi.sofrerDano(deInimigo: inimigos[indice].forca, bonusDefesa: bonusDefesaTemporaria)
                if resultado.esquivou {
                    log.append("Você esquivou do ataque de \(inimigos[indice].nome)!")
                } else {
                    log.append("\(inimigos[indice].nome) atacou você causando \(resultado.dano) de dano.")
                }
            }
            if !vm.heroi.estaVivo { break }
        }

        vm.heroi.regenerarEnergia(5 + vm.heroi.regenEnergiaPorTurno)

        if !vm.heroi.estaVivo {
            finalizarCombate(vitoria: false)
        }
    }

    // O que diferencia um chefe de um inimigo comum, além dos números: a
    // cada poucos turnos, em vez de atacar, ele avisa que está carregando um
    // golpe pesado — o jogador ganha o turno seguinte pra reagir (curar,
    // fortalecer a defesa, beber o Frasco) antes do golpe vir com força
    // total. Estilo o "telegraph" clássico de RPG por turnos: dá pra
    // aprender o padrão e se preparar, não é um dano surpresa injusto.
    // Abaixo de 40% de vida o chefe "enfurece" (estilo fase 2 dos chefes de
    // Elden Ring): carrega mais rápido e bate mais forte — a luta fica mais
    // tensa perto do fim, não mais fácil.
    private func aplicarAtaqueDoChefe(indice: Int) {
        let vidaPercentual = Double(inimigos[indice].vidaAtual) / Double(max(1, inimigos[indice].vidaMaxima))
        let enfurecido = vidaPercentual <= 0.4
        let turnosDeCarga = enfurecido ? 2 : 3
        let multiplicadorDoGolpe = enfurecido ? 2.6 : 2.2

        if chefePrestesAGolpear {
            let forcaDoGolpe = Int(Double(inimigos[indice].forca) * multiplicadorDoGolpe)
            let resultado = vm.heroi.sofrerDano(deInimigo: forcaDoGolpe, bonusDefesa: bonusDefesaTemporaria)
            if resultado.esquivou {
                log.append("Você esquivou do golpe carregado de \(inimigos[indice].nome)!")
            } else {
                log.append("O golpe carregado de \(inimigos[indice].nome) atinge em cheio, causando \(resultado.dano) de dano!")
            }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            chefePrestesAGolpear = false
            turnosAteGolpeDoChefe = turnosDeCarga
            return
        }

        turnosAteGolpeDoChefe -= 1
        if turnosAteGolpeDoChefe <= 0 {
            chefePrestesAGolpear = true
            log.append(enfurecido
                ? "\(inimigos[indice].nome) entra em fúria e começa a carregar um golpe ainda mais devastador!"
                : "\(inimigos[indice].nome) começa a carregar um golpe devastador! Prepare-se para o próximo turno.")
            return
        }

        let resultado = vm.heroi.sofrerDano(deInimigo: inimigos[indice].forca, bonusDefesa: bonusDefesaTemporaria)
        if resultado.esquivou {
            log.append("Você esquivou do ataque de \(inimigos[indice].nome)!")
        } else {
            log.append("\(inimigos[indice].nome) atacou você causando \(resultado.dano) de dano.")
        }
    }

    // Talismãs de regen (Amuleto da Regeneração, Coração da Fênix, etc.)
    // curam uma quantidade fixa por turno, além da recuperação normal de
    // energia — passivo, então roda todo turno, atordoado ou não.
    private func aplicarRegenPassivaDeTalisma() {
        let regenVida = vm.heroi.regenVidaPorTurno
        guard regenVida > 0, vm.heroi.vidaAtual < vm.heroi.vidaMaxima else { return }
        vm.heroi.regenerarVida(regenVida)
        log.append("Seu talismã restaura \(regenVida) de vida.")
    }

    private func finalizarCombate(vitoria: Bool) {
        combateEncerrado = true
        self.vitoria = vitoria

        if vitoria {
            var totalRunas = 0
            var itensGanhos: [String] = []
            var novaRunicaGanha: String? = nil
            for inimigoDerrotado in inimigos {
                let recompensa = vm.heroi.receberRecompensa(deInimigo: inimigoDerrotado)
                totalRunas += recompensa.runas
                if let item = recompensa.item { itensGanhos.append(item.nome) }
                if let zonaDaRunica = recompensa.novaRunica { novaRunicaGanha = zonaDaRunica }
            }
            var texto = "Vitória! +\(totalRunas) Runas."
            if !itensGanhos.isEmpty {
                texto += " Encontrou: \(itensGanhos.joined(separator: ", "))!"
            }
            log.append(texto)
            if let zonaDaRunica = novaRunicaGanha {
                log.append("Você conquistou a Grande Rúnica de \(zonaDaRunica)! Selecione-a na tela de Equipamento e descanse para ativá-la.")
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            // Derrota zera a sequência de exploração (ver
            // `Personagem.descansar`/`bonusDeSequenciaPercentual`) — o risco
            // real de continuar empurrando a sorte em vez de descansar.
            vm.heroi.sequenciaDeExploracao = 0
            log.append("Você foi derrotado! Volte para descansar.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

struct TelaDeCombate_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDeCombate(zona: zonasDoJogo[0], contraChefe: false, nivelHeroi: 1)
                .environmentObject(GameViewModel())
        }
    }
}
