import SwiftUI

struct TelaDoMercado: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var mensagem = ""

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

                if !mensagem.isEmpty {
                    Text(mensagem)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach(Item.catalogoParaClasse(vm.heroi.classe)) { item in
                    linhaDoItem(item)
                }
            }
            .padding()
        }
        .navigationTitle("Mercado")
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
