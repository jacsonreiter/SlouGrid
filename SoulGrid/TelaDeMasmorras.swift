import SwiftUI

struct TelaDeMasmorras: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Masmorras")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Escolha uma zona para explorar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

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
                    NavigationLink(destination: TelaDeCombate(zona: zona, contraChefe: false, nivelHeroi: vm.heroi.nivel)) {
                        Text("Explorar")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    NavigationLink(destination: TelaDeCombate(zona: zona, contraChefe: true, nivelHeroi: vm.heroi.nivel)) {
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
