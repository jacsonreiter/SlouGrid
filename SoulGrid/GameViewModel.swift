import Foundation
import Combine

// Fonte única de verdade do jogo: o perfil local do jogador e a lista de
// heróis dele. Qualquer mutação em `herois` é salva automaticamente
// (didSet), então nenhuma tela precisa lembrar de salvar.
final class GameViewModel: ObservableObject {
    @Published private(set) var perfil: PerfilDoJogador?
    @Published private(set) var herois: [Personagem] = [] {
        didSet { salvarHerois() }
    }
    @Published private(set) var heroiSelecionadoID: UUID?

    private let chavePerfil = "perfilDoJogadorV1"
    private let chaveHerois = "listaDeHeroisV1"

    init() {
        if let dados = UserDefaults.standard.data(forKey: chavePerfil),
           let perfilSalvo = try? JSONDecoder().decode(PerfilDoJogador.self, from: dados) {
            perfil = perfilSalvo
        }
        if let dados = UserDefaults.standard.data(forKey: chaveHerois),
           let listaSalva = try? JSONDecoder().decode([Personagem].self, from: dados) {
            herois = listaSalva
        }
    }

    // MARK: - Perfil local

    func criarPerfil(nome: String) {
        perfil = PerfilDoJogador(nomeDoJogador: nome)
        salvarPerfil()
    }

    private func salvarPerfil() {
        guard let perfil, let dados = try? JSONEncoder().encode(perfil) else { return }
        UserDefaults.standard.set(dados, forKey: chavePerfil)
    }

    // MARK: - Heróis

    // Acesso ao herói selecionado no momento. As telas de jogo usam
    // `vm.heroi.algumMetodo()`, que lê e regrava o herói certo dentro
    // de `herois` — e como `herois` já salva sozinho, tudo continua
    // persistindo automaticamente sem nenhum código extra nas telas.
    var heroi: Personagem {
        get {
            herois.first(where: { $0.id == heroiSelecionadoID }) ?? Personagem(nome: "", classe: .guerreiro)
        }
        set {
            guard let indice = herois.firstIndex(where: { $0.id == newValue.id }) else { return }
            herois[indice] = newValue
        }
    }

    func criarHeroi(nome: String, classe: ClasseDePersonagem) {
        let novo = Personagem(nome: nome, classe: classe)
        herois.append(novo)
        heroiSelecionadoID = novo.id
    }

    func selecionarHeroi(_ id: UUID) {
        heroiSelecionadoID = id
    }

    func voltarParaListaDeHerois() {
        heroiSelecionadoID = nil
    }

    func excluirHeroi(_ id: UUID) {
        herois.removeAll { $0.id == id }
        if heroiSelecionadoID == id {
            heroiSelecionadoID = nil
        }
    }

    private func salvarHerois() {
        guard let dados = try? JSONEncoder().encode(herois) else { return }
        UserDefaults.standard.set(dados, forKey: chaveHerois)
    }
}
