import SwiftUI

struct TelaDeCadastro: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var nome = ""

    var body: some View {
        VStack(spacing: 24) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)

            Text("Como podemos te chamar?")
                .font(.headline)
                .foregroundColor(.secondary)

            TextField("Seu nome", text: $nome)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button {
                let nomeFinal = nome.trimmingCharacters(in: .whitespaces)
                vm.criarPerfil(nome: nomeFinal.isEmpty ? "Jogador" : nomeFinal)
            } label: {
                Text("Continuar")
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
}

struct TelaDeCadastro_Previews: PreviewProvider {
    static var previews: some View {
        TelaDeCadastro().environmentObject(GameViewModel())
    }
}
