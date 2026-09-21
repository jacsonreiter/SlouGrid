import SwiftUI
import UIKit

struct TelaDeCombate: View {
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    let zona: Zona
    let contraChefe: Bool
    let elite: Bool

    @State private var inimigo: Inimigo
    @State private var log: [String] = []
    @State private var combateEncerrado = false
    @State private var vitoria = false
    @State private var mostrandoItens = false
    @State private var mostrandoMagias = false

    // Efeitos ativos no inimigo (só duram durante este combate).
    @State private var veneno: (dano: Int, turnos: Int)? = nil
    @State private var inimigoAtordoado = false

    // Golpe carregado do chefe (estilo "telegraph" de RPG por turnos, ver
    // `aplicarAtaqueDoChefe`) — só chefes fazem isso, inimigo comum nunca.
    @State private var turnosAteGolpeDoChefe = 3
    @State private var chefePrestesAGolpear = false

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

    init(zona: Zona, contraChefe: Bool, nivelHeroi: Int, elite: Bool = false) {
        self.zona = zona
        self.contraChefe = contraChefe
        self.elite = elite
        _inimigo = State(initialValue: contraChefe
            ? zona.gerarChefe(nivelHeroi: nivelHeroi)
            : (elite ? zona.gerarInimigoDeElite(nivelHeroi: nivelHeroi) : zona.gerarInimigoComum(nivelHeroi: nivelHeroi)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inimigoCard
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

    var inimigoCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: inimigo.icone)
                    .font(.system(size: 40))
                    .foregroundColor(inimigo.chefe ? .red : (inimigo.elite ? .orange : .primary))
                VStack(alignment: .leading) {
                    Text(inimigo.nome).font(.title3).fontWeight(.bold)
                    Text("Nível \(inimigo.nivel)\(inimigo.chefe ? " · Chefe" : (inimigo.elite ? " · Elite" : ""))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if veneno != nil {
                        Label("Envenenado", systemImage: "drop.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    if inimigoAtordoado {
                        Label("Atordoado", systemImage: "zzz")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    if chefePrestesAGolpear {
                        Label("Carregando golpe!", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            ProgressView(value: Double(inimigo.vidaAtual), total: Double(inimigo.vidaMaxima))
                .tint(.red)
            Text("\(inimigo.vidaAtual) / \(inimigo.vidaMaxima) vida")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(inimigo.chefe ? Color.red.opacity(0.1) : (inimigo.elite ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1)))
        .cornerRadius(12)
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

    var logDeCombate: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(log.enumerated().reversed()), id: \.offset) { _, linha in
                Text(linha).font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
        .frame(minHeight: 80)
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

    var resultadoBox: some View {
        VStack(spacing: 12) {
            Image(systemName: vitoria ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(vitoria ? .green : .red)
            Text(vitoria ? "Vitória!" : "Derrota")
                .font(.title)
                .fontWeight(.bold)
            Button("Continuar") { dismiss() }
                .font(.title3)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
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
        if inimigo.chefe {
            log.append("O chefe \(inimigo.nome) apareceu!")
        } else if inimigo.elite {
            log.append("Um inimigo de elite, \(inimigo.nome), apareceu! Ele é mais forte que o normal da zona — cuidado.")
        } else {
            log.append("\(inimigo.nome) apareceu!")
        }
    }

    // Destreza rege a chance de acerto — usada tanto pelo ataque básico
    // quanto pelas magias ofensivas (ver `lancarMagia`).
    private func rolarAcerto() -> Bool {
        Int.random(in: 1...100) <= vm.heroi.chanceDeAcerto
    }

    private func atacar() {
        guard !combateEncerrado else { return }
        guard rolarAcerto() else {
            log.append("Você errou o ataque!")
            turnoDoInimigo()
            return
        }
        let resultado = vm.heroi.calcularDanoBasico(bonusForca: bonusForcaTemporario)
        // A Defesa do inimigo (ver `Zona.swift`) mitiga o golpe, espelhando
        // como a Defesa do herói já funciona em `Personagem.sofrerDano`.
        let danoFinal = max(1, resultado.dano - inimigo.defesa)
        inimigo.vidaAtual = max(0, inimigo.vidaAtual - danoFinal)
        log.append(resultado.critico
            ? "Você acertou um golpe crítico! -\(danoFinal) de vida no \(inimigo.nome)."
            : "Você atacou o \(inimigo.nome) causando \(danoFinal) de dano.")
        UIImpactFeedbackGenerator(style: resultado.critico ? .heavy : .medium).impactOccurred()

        if !inimigo.estaVivo {
            finalizarCombate(vitoria: true)
        } else {
            turnoDoInimigo()
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
            turnoDoInimigo()
            return
        }

        if magia.tipo == .fortalecimento {
            let partes = aplicarFortalecimento(magia)
            log.append("Você usou \(magia.nome)! \(partes) por \(magia.duracaoEmTurnos) turnos.")
            turnoDoInimigo()
            return
        }

        // Magias ofensivas (dano, veneno, atordoante) também dependem de
        // Destreza para acertar — exceto as marcadas como certeiras.
        if !magia.sempreAcerta && !rolarAcerto() {
            log.append("Sua magia \(magia.nome) falhou!")
            turnoDoInimigo()
            return
        }

        // O atributo que escala a magia depende da classe/magia (Força,
        // Inteligência ou Agilidade), incluindo fortalecimentos ativos.
        let atributoBase: Int
        switch magia.atributoDeEscala {
        case .forca: atributoBase = vm.heroi.forcaTotal + bonusForcaTemporario
        case .inteligencia: atributoBase = vm.heroi.inteligenciaTotal + bonusInteligenciaTemporaria
        case .agilidade: atributoBase = vm.heroi.agilidadeTotal + bonusAgilidadeTemporaria
        }

        let danoBruto = max(1, Int(Double(atributoBase) * magia.multiplicadorDano))
        // Mesma mitigação de Defesa do ataque básico (ver `atacar()`) — o
        // veneno/dano por turno logo abaixo fica de fora de propósito,
        // como o sangramento/veneno de Elden Ring, que ignora a armadura.
        let dano = max(1, danoBruto - inimigo.defesa)
        inimigo.vidaAtual = max(0, inimigo.vidaAtual - dano)
        var texto = "Você usou \(magia.nome) e causou \(dano) de dano!"

        if magia.tipo == .danoComEfeito {
            let danoPorTurno = max(1, Int(Double(atributoBase) * magia.multiplicadorDanoPorTurno))
            veneno = (dano: danoPorTurno, turnos: magia.duracaoEmTurnos)
            texto += " O inimigo está envenenado."
        } else if magia.tipo == .atordoante {
            inimigoAtordoado = true
            texto += " O inimigo ficou atordoado!"
        }

        if magia.valorCura > 0 {
            vm.heroi.vidaAtual = min(vm.heroi.vidaMaxima, vm.heroi.vidaAtual + magia.valorCura)
            texto += " Você recuperou \(magia.valorCura) de vida."
        }

        log.append(texto)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        if !inimigo.estaVivo {
            finalizarCombate(vitoria: true)
        } else {
            turnoDoInimigo()
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
        turnoDoInimigo()
    }

    private func usarFrascoDeEnergia() {
        guard !combateEncerrado else { return }
        log.append(vm.heroi.usarFrascoDeEnergia())
        turnoDoInimigo()
    }

    private func usarItem(_ pilha: PilhaDeItens) {
        guard !combateEncerrado else { return }
        let efeito = pilha.item.efeitoDePocao
        let buff = pilha.item.efeitoDeBuffTemporario
        log.append(vm.heroi.usarItem(pilha))
        if efeito == .antidoto { veneno = nil }
        if efeito == .fortalecimento, let buff = buff {
            let partes = aplicarFortalecimento(buff)
            log.append("Efeito: \(partes) por \(buff.duracaoEmTurnos) turnos.")
        }
        mostrandoItens = false
        turnoDoInimigo()
    }

    private func fugir() {
        guard !combateEncerrado else { return }
        if Int.random(in: 1...100) <= 50 {
            log.append("Você fugiu do combate!")
            combateEncerrado = true
            vitoria = false
        } else {
            log.append("Você tentou fugir, mas não conseguiu!")
            turnoDoInimigo()
        }
    }

    private func turnoDoInimigo() {
        guard inimigo.estaVivo else { return }

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

        if let venenoAtivo = veneno {
            inimigo.vidaAtual = max(0, inimigo.vidaAtual - venenoAtivo.dano)
            log.append("O veneno causa \(venenoAtivo.dano) de dano em \(inimigo.nome).")
            veneno = venenoAtivo.turnos <= 1 ? nil : (dano: venenoAtivo.dano, turnos: venenoAtivo.turnos - 1)

            if !inimigo.estaVivo {
                finalizarCombate(vitoria: true)
                return
            }
        }

        if inimigoAtordoado {
            log.append("\(inimigo.nome) está atordoado e perde o turno!")
            inimigoAtordoado = false
            vm.heroi.regenerarEnergia(5 + vm.heroi.regenEnergiaPorTurno)
            return
        }

        if inimigo.chefe {
            aplicarAtaqueDoChefe()
        } else {
            let resultado = vm.heroi.sofrerDano(deInimigo: inimigo.forca, bonusDefesa: bonusDefesaTemporaria)
            if resultado.esquivou {
                log.append("Você esquivou do ataque de \(inimigo.nome)!")
            } else {
                log.append("\(inimigo.nome) atacou você causando \(resultado.dano) de dano.")
            }
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
    private func aplicarAtaqueDoChefe() {
        if chefePrestesAGolpear {
            let forcaDoGolpe = Int(Double(inimigo.forca) * 2.2)
            let resultado = vm.heroi.sofrerDano(deInimigo: forcaDoGolpe, bonusDefesa: bonusDefesaTemporaria)
            if resultado.esquivou {
                log.append("Você esquivou do golpe carregado de \(inimigo.nome)!")
            } else {
                log.append("O golpe carregado de \(inimigo.nome) atinge em cheio, causando \(resultado.dano) de dano!")
            }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            chefePrestesAGolpear = false
            turnosAteGolpeDoChefe = 3
            return
        }

        turnosAteGolpeDoChefe -= 1
        if turnosAteGolpeDoChefe <= 0 {
            chefePrestesAGolpear = true
            log.append("\(inimigo.nome) começa a carregar um golpe devastador! Prepare-se para o próximo turno.")
            return
        }

        let resultado = vm.heroi.sofrerDano(deInimigo: inimigo.forca, bonusDefesa: bonusDefesaTemporaria)
        if resultado.esquivou {
            log.append("Você esquivou do ataque de \(inimigo.nome)!")
        } else {
            log.append("\(inimigo.nome) atacou você causando \(resultado.dano) de dano.")
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
            let recompensa = vm.heroi.receberRecompensa(deInimigo: inimigo)
            var texto = "Vitória! +\(recompensa.runas) Runas."
            if let item = recompensa.item {
                texto += " Encontrou: \(item.nome)!"
            }
            log.append(texto)
            if let zonaDaRunica = recompensa.novaRunica {
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
