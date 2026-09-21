import SwiftUI

// A Vila: hub social do jogo, sem combate — estilo os NPCs espalhados por
// Roundtable Hold em Elden Ring. Cada morador oferece missões (ver
// `PNJ`/`Missao`), quase sempre "derrote isso na zona X", cujo progresso
// já é calculado a partir de dados que o herói guarda de qualquer forma
// (ver `Personagem.statusDaMissao`) — visitar a Vila só mostra o que já
// foi conquistado e permite resgatar a recompensa.
struct TelaDaVila: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var mensagem: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Vila")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Converse com os moradores e entregue as missões concluídas.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if vm.heroi.elegivelParaNewGamePlus {
                    novoCicloBox
                }

                ForEach(pnjsVisiveis) { pnj in
                    pnjBox(pnj)
                }
            }
            .padding()
        }
        .navigationTitle("Vila")
        .alert("Vila", isPresented: Binding(
            get: { mensagem != nil },
            set: { mostrando in if !mostrando { mensagem = nil } }
        )) {
            Button("OK") { mensagem = nil }
        } message: {
            Text(mensagem ?? "")
        }
    }

    // Só os moradores já desbloqueados pelo nível atual do herói — é isso
    // que faz "a cada 10 níveis aparecem NPCs novos" (Oriana/Kael/Ithra,
    // ver `PNJ.nivelMinimoParaAparecer`) valer de verdade, em vez de só
    // mostrar as missões deles como "Bloqueada".
    var pnjsVisiveis: [PNJ] {
        PNJ.catalogo.filter { vm.heroi.nivel >= $0.nivelMinimoParaAparecer }
    }

    // Missões que fazem sentido mostrar desse PNJ para o herói atual — só
    // filtra as de recompensa exclusiva de classe (`marco_nivel_16_*`,
    // ver `Missao.catalogo`) que não combinam com a classe do herói, pra
    // não listar 3 versões da mesma missão lado a lado.
    func missoesVisiveis(_ pnj: PNJ) -> [Missao] {
        pnj.missoes.filter { missao in
            guard let restrita = missao.recompensaItem?.classeRestrita else { return true }
            return restrita == vm.heroi.classe
        }
    }

    // New Game+ (ver `Personagem.cicloNewGamePlus`): só aparece depois de
    // completar "O Selo Final" (nível 40). Iniciar um ciclo não reseta nem
    // apaga nada do herói — só deixa o mundo inteiro mais perigoso e mais
    // generoso em recompensa (ver `Zona.multiplicadorDeCiclo`).
    var novoCicloBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 32)
                VStack(alignment: .leading) {
                    Text("Novo Ciclo").font(.headline)
                    Text(vm.heroi.cicloNewGamePlus > 0 ? "Ciclo atual: \(vm.heroi.cicloNewGamePlus)" : "Ainda não iniciado")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            Text("O selo sempre se rompe de novo. Inicie um novo ciclo e o mundo inteiro fica mais perigoso — e mais generoso em Runas — sem que você perca nada do que já conquistou.")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Iniciar Novo Ciclo") {
                mensagem = vm.heroi.iniciarNovoCicloNewGamePlus()
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .cornerRadius(12)
    }

    func pnjBox(_ pnj: PNJ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: pnj.icone)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)
                VStack(alignment: .leading) {
                    Text(pnj.nome).font(.headline)
                    Text(pnj.titulo).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            Text("\"\(pnj.fala)\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()

            ForEach(missoesVisiveis(pnj)) { missao in
                missaoLinha(missao)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    func missaoLinha(_ missao: Missao) -> some View {
        let status = vm.heroi.statusDaMissao(missao)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(missao.titulo).font(.subheadline).fontWeight(.semibold)
                    Text(missao.descricao).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                selo(status)
            }

            HStack(spacing: 10) {
                Label("\(missao.recompensaRunas) Runas", systemImage: "circle.hexagongrid.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                if let item = missao.recompensaItem {
                    Label(item.nome, systemImage: "gift.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
                Spacer()
                if status == .prontaParaEntrega {
                    Button("Entregar") {
                        mensagem = vm.heroi.entregarMissao(missao)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
    }

    func selo(_ status: Personagem.StatusDeMissao) -> some View {
        Group {
            switch status {
            case .bloqueada:
                Text("Bloqueada").foregroundColor(.secondary)
            case .emAndamento(let atual, let alvo):
                Text("\(atual)/\(alvo)").foregroundColor(.blue)
            case .prontaParaEntrega:
                Text("Concluída!").foregroundColor(.green).fontWeight(.bold)
            case .entregue:
                Text("Entregue").foregroundColor(.secondary)
            }
        }
        .font(.caption2)
    }
}

struct TelaDaVila_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDaVila().environmentObject(GameViewModel())
        }
    }
}
