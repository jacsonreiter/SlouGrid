import SwiftUI

struct TelaDoPersonagem: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var mensagem = "Bem-vindo(a) de volta, aventureiro(a)!"
    @State private var slotSelecionado: Int? = nil
    @State private var abaMochila: AbaDaMochila = .pocoes

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cabecalho
                statusBox
                equipadoBox
                magiasEquipadasBox
                mensagemBox
                botoesDeAcao
                mochilaBox
                botaoTrocarHeroi
            }
            .padding()
        }
        .navigationTitle("Soul Grid")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { slotSelecionado != nil },
            set: { mostrando in if !mostrando { slotSelecionado = nil } }
        )) {
            if let indice = slotSelecionado {
                editorDeMagia(indice)
            }
        }
    }

    // MARK: - Pedaços da tela

    var cabecalho: some View {
        VStack(spacing: 8) {
            Image(systemName: vm.heroi.classe.icone)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(vm.heroi.estaVivo ? .blue : .gray)
                .padding(18)
                .background(Circle().fill(Color.blue.opacity(0.1)))

            Text(vm.heroi.nome)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(vm.heroi.classe.rawValue) · Nível \(vm.heroi.nivel)")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    var statusBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            barraDeStatus(titulo: "Vida", atual: vm.heroi.vidaAtual, maximo: vm.heroi.vidaMaxima, cor: .red)
            barraDeStatus(titulo: vm.heroi.classe.nomeDoRecurso, atual: vm.heroi.energiaAtual, maximo: vm.heroi.energiaMaximaTotal, cor: .blue)

            HStack {
                Label("\(vm.heroi.forcaTotal)", systemImage: "bolt.fill")
                Spacer()
                Label("\(vm.heroi.inteligenciaTotal)", systemImage: "brain.head.profile")
                Spacer()
                Label("\(vm.heroi.agilidadeTotal)", systemImage: "hare.fill")
                Spacer()
                Label("\(vm.heroi.defesaTotal)", systemImage: "shield.fill")
            }
            .font(.caption)
            .padding(.top, 4)

            HStack {
                Spacer()
                Label("\(vm.heroi.ouro) Runas", systemImage: "circle.hexagongrid.fill")
                    .foregroundColor(.orange)
            }
            .font(.subheadline)

            if vm.heroi.sequenciaDeExploracao > 0 {
                HStack {
                    Spacer()
                    Label("Sequência \(vm.heroi.sequenciaDeExploracao) (+\(vm.heroi.bonusDeSequenciaPercentual)% Runas)", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }

    func barraDeStatus(titulo: String, atual: Int, maximo: Int, cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titulo).font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("\(atual) / \(maximo)").font(.caption).foregroundColor(.secondary)
            }
            ProgressView(value: Double(atual), total: Double(max(maximo, 1)))
                .tint(cor)
        }
    }

    var equipadoBox: some View {
        NavigationLink(destination: TelaDeEquipamento()) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Equipamento")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                Text("Arma: \(vm.heroi.armaEquipada?.nome ?? "nenhuma")")
                Text("Armadura: \(vm.heroi.armaduraEquipada?.nome ?? "nenhuma")")
                Text("Talismãs: \(nomesDosTalismasEquipados)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.blue.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }

    var nomesDosTalismasEquipados: String {
        let nomes = vm.heroi.acessoriosEquipados.compactMap { $0?.nome }
        return nomes.isEmpty ? "nenhum" : nomes.joined(separator: ", ")
    }

    var magiasEquipadasBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Magias Equipadas")
                .font(.title2)
                .fontWeight(.bold)
            Text("Toque em um slot para escolher a magia dele. Elas aparecem como atalhos rápidos na batalha.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(0..<Personagem.numeroDeSlotsDeMagia, id: \.self) { indice in
                slotDeMagia(indice)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.purple.opacity(0.08))
        .cornerRadius(12)
    }

    func slotDeMagia(_ indice: Int) -> some View {
        let magia = vm.heroi.magiaNoSlot(indice)
        return Button {
            slotSelecionado = indice
        } label: {
            HStack {
                Image(systemName: magia?.icone ?? "questionmark.circle")
                    .frame(width: 28)
                    .foregroundColor(magia == nil ? .secondary : .purple)
                if let magia = magia {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(magia.nome).font(.subheadline).fontWeight(.semibold)
                        Text("\(magia.custoEnergia) energia").font(.caption2).foregroundColor(.secondary)
                    }
                } else {
                    Text("Slot vazio — toque para equipar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }

    func editorDeMagia(_ indice: Int) -> some View {
        NavigationStack {
            List {
                if vm.heroi.magiaNoSlot(indice) != nil {
                    Button(role: .destructive) {
                        vm.heroi.removerMagia(doSlot: indice)
                        slotSelecionado = nil
                    } label: {
                        Label("Remover do slot", systemImage: "xmark.circle")
                    }
                }

                let magias = vm.heroi.classe.grimorio
                    .filter { $0.nivelNecessario <= vm.heroi.nivel }
                    .sorted { $0.nivelNecessario < $1.nivelNecessario }

                ForEach(magias) { magia in
                    Button {
                        vm.heroi.equiparMagia(magia, noSlot: indice)
                        slotSelecionado = nil
                    } label: {
                        HStack {
                            Image(systemName: magia.icone).frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(magia.nome).font(.headline)
                                Text(magia.descricao).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(magia.custoEnergia) EN").font(.caption).foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Escolher Magia")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { slotSelecionado = nil }
                }
            }
        }
    }

    var mensagemBox: some View {
        Text(mensagem)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    var botoesDeAcao: some View {
        VStack(spacing: 12) {
            if vm.heroi.estaVivo {
                NavigationLink(destination: TelaDeMasmorras()) {
                    botao("Ir para as Masmorras", cor: .red, icone: "map.fill")
                }
                NavigationLink(destination: TelaDoMercado()) {
                    botao("Ir ao Mercado", cor: .purple, icone: "cart.fill")
                }
                NavigationLink(destination: TelaDaVila()) {
                    botao("Ir à Vila", cor: .green, icone: "house.fill")
                }
                Button {
                    mensagem = descansarEDescrever()
                } label: {
                    botao("Descansar", cor: .orange, icone: "bed.double.fill")
                }
            } else {
                Button {
                    mensagem = descansarEDescrever()
                } label: {
                    botao("Descansar", cor: .orange, icone: "bed.double.fill")
                }
            }
        }
    }

    // Descansar (o "Site of Grace" do SoulGrid) recupera vida/energia,
    // recarrega o Frasco Sagrado e ativa a Grande Rúnica selecionada — por
    // isso a mensagem muda quando uma nova rúnica acabou de entrar em vigor.
    func descansarEDescrever() -> String {
        let runicaAntes = vm.heroi.runicaEquipadaAtiva
        vm.heroi.descansar()
        if vm.heroi.runicaEquipadaAtiva != runicaAntes, let ativa = vm.heroi.runicaEquipadaAtiva {
            return "Você descansou! Vida, energia e Frasco Sagrado recarregados. A Grande Rúnica de \(ativa) está ativa."
        }
        return "Você descansou e recuperou toda a vida, energia e o Frasco Sagrado!"
    }

    func botao(_ titulo: String, cor: Color, icone: String) -> some View {
        Label(titulo, systemImage: icone)
            .font(.title3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(cor)
            .foregroundColor(.white)
            .cornerRadius(12)
    }

    // Abas por tipo — antes a mochila listava tudo junto numa lista só,
    // que ficava enorme depois de algumas horas de jogo. Mesmo padrão de
    // `TelaDoMercado.AbaDoMercado`.
    enum AbaDaMochila: String, CaseIterable {
        case pocoes = "Poções"
        case armas = "Armas"
        case armaduras = "Armaduras"
        case acessorios = "Acessórios"
        case materiais = "Materiais"
    }

    var itensDaAbaMochila: [PilhaDeItens] {
        vm.heroi.inventario.filter { pilha in
            switch abaMochila {
            case .pocoes: return pilha.item.tipo == .pocao
            case .armas: return pilha.item.tipo == .arma
            case .armaduras: return pilha.item.tipo == .armadura
            case .acessorios: return pilha.item.tipo == .acessorio
            case .materiais: return pilha.item.tipo == .material
            }
        }
    }

    var mochilaBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mochila")
                .font(.title2)
                .fontWeight(.bold)

            Picker("Aba", selection: $abaMochila) {
                ForEach(AbaDaMochila.allCases, id: \.self) { aba in
                    Text(aba.rawValue).tag(aba)
                }
            }
            .pickerStyle(.segmented)

            if vm.heroi.inventario.isEmpty {
                Text("Vazia")
                    .foregroundColor(.secondary)
            } else if itensDaAbaMochila.isEmpty {
                Text("Nada nessa aba ainda.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(itensDaAbaMochila) { pilha in
                    linhaDaMochila(pilha)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    func linhaDaMochila(_ pilha: PilhaDeItens) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(pilha.item.nome)
                    if pilha.quantidade > 1 {
                        Text("x\(pilha.quantidade)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(pilha.item.raridade.nome)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(pilha.item.raridade.cor.opacity(0.2))
                        .foregroundColor(pilha.item.raridade.cor)
                        .cornerRadius(6)
                }
                Text(pilha.item.descricao)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if pilha.item.tipo == .pocao {
                if pilha.item.efeitoDePocao == .fortalecimento {
                    // Poção de buff: só tem efeito em combate (mexe no
                    // estado temporário de `TelaDeCombate`), então não
                    // oferece "Usar" aqui pra não desperdiçar o item à toa.
                    Text("Use em combate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Button("Usar") {
                        mensagem = vm.heroi.usarItem(pilha)
                    }
                    .foregroundColor(.green)
                }
            } else if pilha.item.tipo == .material {
                // Material de missão/comércio: não equipa nem se "usa",
                // só entrega em missões (na Vila) ou vende aqui.
                Text("Missão ou venda")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Button("Equipar") {
                    mensagem = vm.heroi.equiparItem(pilha)
                }
                .foregroundColor(.blue)
            }

            Button("Vender") {
                mensagem = vm.heroi.vender(pilha)
            }
            .foregroundColor(.red)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    var botaoTrocarHeroi: some View {
        Button("Trocar de Herói") {
            vm.voltarParaListaDeHerois()
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }

}

struct TelaDoPersonagem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDoPersonagem().environmentObject(GameViewModel())
        }
    }
}
