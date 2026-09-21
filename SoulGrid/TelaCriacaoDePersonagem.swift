import SwiftUI

struct TelaCriacaoDePersonagem: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var nome: String = ""
    @State private var classeSelecionada: ClasseDePersonagem = .guerreiro

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Crie seu Herói")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Nome do herói", text: $nome)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(ClasseDePersonagem.allCases) { classe in
                        Button {
                            classeSelecionada = classe
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: classe.icone)
                                    .font(.title2)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(classe.rawValue)
                                        .font(.headline)
                                    Text(classe.descricao)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                if classeSelecionada == classe {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(classeSelecionada == classe ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)

                tracoDaClasseSelecionadaBox
                    .padding(.horizontal)

                Button {
                    let nomeFinal = nome.trimmingCharacters(in: .whitespaces)
                    vm.criarHeroi(nome: nomeFinal.isEmpty ? "Herói" : nomeFinal, classe: classeSelecionada)
                } label: {
                    Text("Começar Aventura")
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Novo Herói")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Mostra o traço passivo da classe escolhida, para o jogador decidir com
    // base em como ela realmente joga — não só na descrição de sabor.
    var tracoDaClasseSelecionadaBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Traço de \(classeSelecionada.rawValue)", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(.orange)
            Text(classeSelecionada.tracoPassivo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TelaCriacaoDePersonagem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaCriacaoDePersonagem().environmentObject(GameViewModel())
        }
    }
}
