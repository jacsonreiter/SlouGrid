import SwiftUI

struct TelaDeHerois: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var heroiParaExcluir: Personagem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Olá, \(vm.perfil?.nomeDoJogador ?? "Jogador")!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Seus Heróis")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if vm.herois.isEmpty {
                    Text("Você ainda não criou nenhum herói.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(vm.herois, id: \.id) { heroi in
                        linhaDoHeroi(heroi)
                    }
                }

                NavigationLink(destination: TelaCriacaoDePersonagem()) {
                    Label("Criar Novo Herói", systemImage: "plus.circle.fill")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Meus Heróis")
        .confirmationDialog(
            "Excluir \(heroiParaExcluir?.nome ?? "herói")? Essa ação não pode ser desfeita.",
            isPresented: Binding(
                get: { heroiParaExcluir != nil },
                set: { mostrando in if !mostrando { heroiParaExcluir = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                if let heroi = heroiParaExcluir {
                    vm.excluirHeroi(heroi.id)
                }
                heroiParaExcluir = nil
            }
            Button("Cancelar", role: .cancel) {
                heroiParaExcluir = nil
            }
        }
    }

    func linhaDoHeroi(_ heroi: Personagem) -> some View {
        Button {
            vm.selecionarHeroi(heroi.id)
        } label: {
            HStack {
                Image(systemName: heroi.classe.icone)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 36)
                VStack(alignment: .leading) {
                    Text(heroi.nome).font(.headline)
                    Text("\(heroi.classe.rawValue) · Nível \(heroi.nivel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .contextMenu {
            Button(role: .destructive) {
                heroiParaExcluir = heroi
            } label: {
                Label("Excluir Herói", systemImage: "trash")
            }
        }
    }
}

struct TelaDeHerois_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDeHerois().environmentObject(GameViewModel())
        }
    }
}
