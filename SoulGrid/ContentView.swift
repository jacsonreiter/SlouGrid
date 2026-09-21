import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        Group {
            // Cada estágio tem sua própria NavigationStack: ao criar o perfil,
            // trocar de herói ou entrar em um herói, a pilha de navegação
            // inteira é recriada do zero, em vez de trocar a raiz de uma pilha
            // com uma navegação em andamento (o que perdia o environmentObject
            // e derrubava o app).
            if vm.perfil == nil {
                NavigationStack {
                    TelaDeCadastro()
                }
            } else if vm.heroiSelecionadoID == nil {
                NavigationStack {
                    TelaDeHerois()
                }
            } else {
                NavigationStack {
                    TelaDoPersonagem()
                }
            }
        }
        .environmentObject(vm)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
