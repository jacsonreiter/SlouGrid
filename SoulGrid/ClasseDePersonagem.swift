import Foundation

enum ClasseDePersonagem: String, Codable, CaseIterable, Identifiable {
    case guerreiro = "Guerreiro"
    case mago = "Mago"
    case ladino = "Ladino"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .guerreiro: return "shield.lefthalf.filled"
        case .mago: return "wand.and.stars"
        case .ladino: return "theatermasks.fill"
        }
    }

    var descricao: String {
        switch self {
        case .guerreiro: return "Força e resistência acima de tudo. Vida alta e dano físico brutal com armas pesadas."
        case .mago: return "Inteligência e Mana movem sua magia. Frágil de perto, devastador à distância."
        case .ladino: return "Agilidade, Destreza e Sorte combinadas. Crítico, esquiva e golpes certeiros."
        }
    }

    // Nome de exibição do recurso gasto para atacar/lançar magias — cada
    // classe sente esse recurso de um jeito diferente (fôlego físico do
    // guerreiro, mana arcana do mago, foco silencioso do ladino).
    var nomeDoRecurso: String {
        switch self {
        case .guerreiro: return "Fôlego"
        case .mago: return "Mana"
        case .ladino: return "Foco"
        }
    }

    // Frase curta que resume a identidade mecânica da classe, mostrada na
    // criação do herói para deixar claro por que jogar de um jeito ou de
    // outro muda a experiência de combate — e o que os pontos de atributo
    // realmente fazem por ela.
    var tracoPassivo: String {
        switch self {
        case .guerreiro: return "Pele de Aço: reduz em 15% todo o dano recebido. Vitalidade também aumenta sua Vida máxima, Defesa e Fôlego."
        case .mago: return "Fluxo Arcano: o dano das suas magias escala com Inteligência, que também aumenta sua Mana máxima."
        case .ladino: return "Reflexos Felinos: Agilidade e Sorte aumentam crítico e esquiva; Destreza garante que seus golpes não errem."
        }
    }

    // MARK: - Atributos base (nível 1)
    //
    // Seis atributos, inspirados no clássico STR/AGI/VIT/INT/DEX/LUK: cada
    // um com um papel único (ver `Personagem`), para que investir em
    // qualquer um deles sempre valha a pena, não só "número maior".

    var vidaBase: Int {
        switch self {
        case .guerreiro: return 80
        case .mago: return 42
        case .ladino: return 58
        }
    }

    var forcaBase: Int {
        switch self {
        case .guerreiro: return 14
        case .mago: return 4
        case .ladino: return 7
        }
    }

    var vitalidadeBase: Int {
        switch self {
        case .guerreiro: return 13
        case .mago: return 4
        case .ladino: return 6
        }
    }

    var inteligenciaBase: Int {
        switch self {
        case .guerreiro: return 2
        case .mago: return 18
        case .ladino: return 4
        }
    }

    var destrezaBase: Int {
        switch self {
        case .guerreiro: return 6
        case .mago: return 7
        case .ladino: return 10
        }
    }

    var agilidadeBase: Int {
        switch self {
        case .guerreiro: return 6
        case .mago: return 6
        case .ladino: return 13
        }
    }

    var sorteBase: Int {
        switch self {
        case .guerreiro: return 3
        case .mago: return 5
        case .ladino: return 4
        }
    }

    var energiaBase: Int {
        switch self {
        case .guerreiro: return 45
        case .mago: return 75
        case .ladino: return 55
        }
    }

    // MARK: - Crescimento por nível

    // Nenhum dos seis atributos cresce sozinho — todos vêm de pontos
    // comprados diretamente com Runas (ver `Personagem.comprarPonto`), cada
    // um subindo o nível em 1. O que cresce automaticamente é só a base "de
    // nível" de Vida e do recurso da classe (equivalente ao Base Level do
    // Ragnarok); o resto vem do investimento em Vitalidade/Inteligência.
    var vidaBasePorNivel: Int {
        switch self {
        case .guerreiro: return 8
        case .mago: return 4
        case .ladino: return 5
        }
    }

    var energiaBasePorNivel: Int {
        switch self {
        case .guerreiro: return 2
        case .mago: return 4
        case .ladino: return 3
        }
    }

    // Redução percentual de todo dano recebido — a resistência natural do
    // guerreiro, que nenhuma outra classe tem.
    var reducaoDeDanoPercentual: Double {
        switch self {
        case .guerreiro: return 0.15
        case .mago: return 0
        case .ladino: return 0
        }
    }
}
