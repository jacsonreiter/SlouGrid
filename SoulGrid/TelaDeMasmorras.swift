import SwiftUI

struct TelaDeMasmorras: View {
    @EnvironmentObject var vm: GameViewModel
    // O que "Explorar" rendeu — decidido antes de navegar, pois um dos
    // resultados (descoberta) nem entra na tela de combate. Usa o padrão
    // de NavigationLink oculto + `isActive` (em vez de
    // `navigationDestination(item:)`, que só existe a partir do iOS 17 —
    // este projeto mira iOS 16.2).
    @State private var zonaParaExplorar: Zona?
    @State private var eliteParaExplorar = false
    @State private var navegandoParaExploracao = false
    @State private var mensagemDeDescoberta: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Masmorras")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Escolha uma zona para explorar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if vm.heroi.sequenciaDeExploracao > 0 {
                    sequenciaBox
                }

                if !vm.heroi.estaVivo {
                    VStack(spacing: 12) {
                        Image(systemName: "bed.double.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Você precisa descansar antes de explorar novamente.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(faixasDeNivel, id: \.self) { nivelMinimo in
                        faixaBox(nivelMinimo)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Masmorras")
        .background(
            Group {
                if let zona = zonaParaExplorar {
                    NavigationLink(
                        destination: TelaDeCombate(zona: zona, contraChefe: false, nivelHeroi: vm.heroi.nivel, elite: eliteParaExplorar, cicloNewGamePlus: vm.heroi.cicloNewGamePlus),
                        isActive: $navegandoParaExploracao
                    ) { EmptyView() }
                }
            }
        )
        .alert("Descoberta!", isPresented: Binding(
            get: { mensagemDeDescoberta != nil },
            set: { mostrando in if !mostrando { mensagemDeDescoberta = nil } }
        )) {
            Button("OK") { mensagemDeDescoberta = nil }
        } message: {
            Text(mensagemDeDescoberta ?? "")
        }
    }

    // Mostra a sequência de exploração e o bônus de Runas que ela já dá —
    // lembra o jogador da decisão em aberto: continuar empurrando a sorte
    // por mais recompensa, ou voltar pra "Descansar" e zerar com segurança.
    var sequenciaBox: some View {
        HStack {
            Label("Sequência de Exploração: \(vm.heroi.sequenciaDeExploracao)", systemImage: "flame.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text("+\(vm.heroi.bonusDeSequenciaPercentual)% Runas")
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .foregroundColor(.orange)
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(10)
    }

    // Como no mapa aberto de Elden Ring: a maior parte das explorações leva
    // a um combate comum, mas às vezes rende um inimigo de elite (mais
    // forte, mais recompensa) ou uma descoberta pacífica (sem combate).
    // Rolado aqui, antes de navegar, porque uma descoberta nem abre a tela
    // de combate.
    func iniciarExploracao(_ zona: Zona) {
        switch zona.sortearEncontro() {
        case .comum:
            zonaParaExplorar = zona
            eliteParaExplorar = false
            navegandoParaExploracao = true
        case .eliteDeCampo:
            zonaParaExplorar = zona
            eliteParaExplorar = true
            navegandoParaExploracao = true
        case .descoberta:
            let recompensa = vm.heroi.receberDescoberta(zonaNome: zona.nome, nivelZona: zona.nivelBaseInimigos)
            var texto = "Você encontrou \(recompensa.runas) Runas explorando \(zona.nome), sem cruzar com nenhum inimigo."
            if let item = recompensa.item {
                texto += " Também achou: \(item.nome)!"
            }
            mensagemDeDescoberta = texto
        }
    }

    // MARK: - Faixas de nível

    // Os `nivelMinimo` distintos das zonas, em ordem — cada um é uma faixa
    // de progressão (ver `Zona.swift`), com 2 lugares para explorar.
    var faixasDeNivel: [Int] {
        Array(Set(zonasDoJogo.map { $0.nivelMinimo })).sorted()
    }

    // Rótulo da faixa: do seu nível mínimo até o nível mínimo da próxima
    // faixa (exclusive), ou "N+" se for a última.
    func rotuloDaFaixa(_ nivelMinimo: Int) -> String {
        let faixas = faixasDeNivel
        guard let indice = faixas.firstIndex(of: nivelMinimo) else { return "Nível \(nivelMinimo)+" }
        if indice + 1 < faixas.count {
            return "Nível \(nivelMinimo)–\(faixas[indice + 1] - 1)"
        }
        return "Nível \(nivelMinimo)+"
    }

    func faixaBox(_ nivelMinimo: Int) -> some View {
        let zonas = zonasDoJogo.filter { $0.nivelMinimo == nivelMinimo }
        return VStack(alignment: .leading, spacing: 10) {
            Text(rotuloDaFaixa(nivelMinimo))
                .font(.headline)
                .foregroundColor(.secondary)
            ForEach(zonas) { zona in
                zonaCard(zona)
            }
        }
    }

    func zonaCard(_ zona: Zona) -> some View {
        let desbloqueada = vm.heroi.nivel >= zona.nivelMinimo
        let vitorias = vm.heroi.vitoriasNaZona(zona.nome)
        let chefeDisponivel = vitorias >= zona.vitoriasParaChefe

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: zona.icone)
                    .font(.title2)
                    .foregroundColor(desbloqueada ? .blue : .gray)
                VStack(alignment: .leading) {
                    Text(zona.nome).font(.headline)
                    Text(zona.descricao).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }

            if desbloqueada {
                Text("Vitórias nesta zona: \(vitorias)/\(zona.vitoriasParaChefe)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button {
                        iniciarExploracao(zona)
                    } label: {
                        Text("Explorar")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    NavigationLink(destination: TelaDeCombate(zona: zona, contraChefe: true, nivelHeroi: vm.heroi.nivel, cicloNewGamePlus: vm.heroi.cicloNewGamePlus)) {
                        Text("Desafiar Chefe")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(chefeDisponivel ? Color.red : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!chefeDisponivel)
                }
            } else {
                Label("Requer nível \(zona.nivelMinimo)", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
        .opacity(desbloqueada ? 1 : 0.6)
    }
}

struct TelaDeMasmorras_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDeMasmorras().environmentObject(GameViewModel())
        }
    }
}
