import SwiftUI

// Categoria de item mostrada em cada aba do mercado — separa Acessórios
// (bônus de atributo puro) de Talismãs (efeitos passivos, ver
// `Item.ehTalisma`), embora os dois usem `TipoDeItem.acessorio` por baixo.
enum AbaDoMercado: String, CaseIterable, Identifiable {
    case pocoes = "Poções"
    case armas = "Armas"
    case armaduras = "Armaduras"
    case acessorios = "Acessórios"
    case talismas = "Talismãs"

    var id: String { rawValue }
}

struct TelaDoMercado: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var mensagem = ""
    @State private var abaSelecionada: AbaDoMercado = .pocoes

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Mercado")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Suas Runas: \(vm.heroi.ouro)")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text("Mostrando itens para \(vm.heroi.classe.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Categoria", selection: $abaSelecionada) {
                    ForEach(AbaDoMercado.allCases) { aba in
                        Text(aba.rawValue).tag(aba)
                    }
                }
                .pickerStyle(.segmented)

                if !mensagem.isEmpty {
                    Text(mensagem)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach(itensDaAba) { item in
                    linhaDoItem(item)
                }
            }
            .padding()
        }
        .navigationTitle("Mercado")
    }

    // Itens da classe atual, filtrados pela aba selecionada e ordenados por
    // nível mínimo — pra sempre mostrar o mais acessível primeiro.
    var itensDaAba: [Item] {
        let doCatalogo = Item.catalogoParaClasse(vm.heroi.classe)
        let filtrados: [Item]
        switch abaSelecionada {
        case .pocoes: filtrados = doCatalogo.filter { $0.tipo == .pocao }
        case .armas: filtrados = doCatalogo.filter { $0.tipo == .arma }
        case .armaduras: filtrados = doCatalogo.filter { $0.tipo == .armadura }
        case .acessorios: filtrados = doCatalogo.filter { $0.tipo == .acessorio && !$0.ehTalisma }
        case .talismas: filtrados = doCatalogo.filter { $0.tipo == .acessorio && $0.ehTalisma }
        }
        return filtrados.sorted { $0.nivelMinimo < $1.nivelMinimo }
    }

    func linhaDoItem(_ item: Item) -> some View {
        let bloqueado = vm.heroi.nivel < item.nivelMinimo

        return HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(item.nome)
                        .font(.headline)
                    Text(item.raridade.nome)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.raridade.cor.opacity(0.2))
                        .foregroundColor(item.raridade.cor)
                        .cornerRadius(6)
                }
                Text(item.descricao)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if bloqueado {
                    Label("Requer nível \(item.nivelMinimo)", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.preco) Runas")
                    .font(.subheadline)
                Button("Comprar") {
                    mensagem = vm.heroi.comprar(item)
                }
                .foregroundColor(vm.heroi.ouro >= item.preco && !bloqueado ? .green : .gray)
                .disabled(vm.heroi.ouro < item.preco || bloqueado)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .opacity(bloqueado ? 0.6 : 1)
    }
}

struct TelaDoMercado_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDoMercado().environmentObject(GameViewModel())
        }
    }
}
