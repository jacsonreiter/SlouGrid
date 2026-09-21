import Foundation

enum TipoDeMagia: String, Codable {
    case dano             // dano direto
    case danoComEfeito    // dano + veneno (dano extra por N turnos)
    case atordoante        // dano + inimigo perde o próximo turno
    case cura             // cura o próprio herói, sem afetar o inimigo
    case fortalecimento    // buff temporário de atributos no herói
}

// De qual atributo do herói o dano/efeito da magia escala. É isso que faz
// cada classe sentir sua identidade em combate: o guerreiro bate com Força,
// o mago com Inteligência, e o ladino mistura Agilidade (golpes) com
// Inteligência (venenos).
enum AtributoDeEscala: String, Codable {
    case forca
    case inteligencia
    case agilidade
}

// `Codable` porque, além do grimório da classe (nunca persistido, sempre
// recriado em código), uma `Magia` agora também pode viver dentro de um
// `Item` como o "Golpe de Arma" da arma (ver `Item.habilidadeDeArma`) — e
// esse `Item` é salvo no inventário/equipamento do herói.
struct Magia: Identifiable, Codable {
    var id = UUID()
    var nome: String
    var descricao: String
    var icone: String
    var custoEnergia: Int
    var nivelNecessario: Int
    var tipo: TipoDeMagia
    var atributoDeEscala: AtributoDeEscala = .forca
    var multiplicadorDano: Double = 0
    var multiplicadorDanoPorTurno: Double = 0
    var duracaoEmTurnos: Int = 0
    var valorCura: Int = 0
    var bonusForca: Int = 0
    var bonusDefesa: Int = 0
    var bonusInteligencia: Int = 0
    var bonusAgilidade: Int = 0
    var sempreAcerta: Bool = false   // ignora a chance de acerto (Destreza) — um golpe "certeiro" de assinatura
}

extension ClasseDePersonagem {
    // O grimório/repertório de magias e golpes especiais da classe,
    // desbloqueado progressivamente pelo nível do herói, até magias de
    // assinatura em nível alto — sempre há uma próxima magia esperando.
    var grimorio: [Magia] {
        switch self {
        case .guerreiro:
            // Guerreiro: tudo escala com Força. Sem cura mágica — a
            // sobrevivência dele vem da resistência natural da classe.
            return [
                Magia(nome: "Golpe Poderoso",
                      descricao: "Um golpe brutal com sua arma.",
                      icone: "bolt.fill", custoEnergia: 30, nivelNecessario: 1,
                      tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 2.2),
                Magia(nome: "Golpe Certeiro",
                      descricao: "Um golpe calculado que nunca erra o alvo.",
                      icone: "scope", custoEnergia: 20, nivelNecessario: 2,
                      tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 1.5, sempreAcerta: true),
                Magia(nome: "Grito de Guerra",
                      descricao: "Um brado que aumenta sua força por 3 turnos.",
                      icone: "megaphone.fill", custoEnergia: 25, nivelNecessario: 4,
                      tipo: .fortalecimento, duracaoEmTurnos: 3, bonusForca: 6),
                Magia(nome: "Postura Defensiva",
                      descricao: "Fecha a guarda, aumentando sua defesa por 3 turnos.",
                      icone: "shield.lefthalf.filled", custoEnergia: 25, nivelNecessario: 7,
                      tipo: .fortalecimento, duracaoEmTurnos: 3, bonusDefesa: 6),
                Magia(nome: "Investida Atordoante",
                      descricao: "Acerta e atordoa o inimigo, que perde o próximo turno.",
                      icone: "hand.raised.fill", custoEnergia: 40, nivelNecessario: 10,
                      tipo: .atordoante, atributoDeEscala: .forca, multiplicadorDano: 1.4),
                Magia(nome: "Fúria Sangrenta",
                      descricao: "Dano altíssimo e recupera um pouco da sua vida.",
                      icone: "flame.fill", custoEnergia: 55, nivelNecessario: 13,
                      tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 2.8, valorCura: 20),
                Magia(nome: "Brado do Campeão",
                      descricao: "Um brado ancestral que fortalece força e defesa por 4 turnos.",
                      icone: "flag.fill", custoEnergia: 60, nivelNecessario: 16,
                      tipo: .fortalecimento, duracaoEmTurnos: 4, bonusForca: 10, bonusDefesa: 4),
                Magia(nome: "Golpe Devastador",
                      descricao: "O golpe final: um ataque capaz de decidir a batalha sozinho.",
                      icone: "burst.fill", custoEnergia: 70, nivelNecessario: 18,
                      tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 4.0)
            ]
        case .mago:
            // Mago: dano, controle e cura escalam com Inteligência. Os
            // fortalecimentos reforçam Inteligência, nunca Força.
            return [
                Magia(nome: "Bola de Fogo",
                      descricao: "Uma explosão de fogo arcano.",
                      icone: "flame.fill", custoEnergia: 35, nivelNecessario: 1,
                      tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 2.0),
                Magia(nome: "Mísseis Arcanos",
                      descricao: "Projéteis mágicos guiados que nunca erram o alvo.",
                      icone: "scope", custoEnergia: 25, nivelNecessario: 2,
                      tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 1.4, sempreAcerta: true),
                Magia(nome: "Cura Menor",
                      descricao: "Recupera parte da sua vida.",
                      icone: "cross.case.fill", custoEnergia: 25, nivelNecessario: 3,
                      tipo: .cura, valorCura: 40),
                Magia(nome: "Toque Venenoso",
                      descricao: "Envenena o alvo, causando dano por 3 turnos.",
                      icone: "drop.fill", custoEnergia: 30, nivelNecessario: 4,
                      tipo: .danoComEfeito, atributoDeEscala: .inteligencia,
                      multiplicadorDano: 1.0, multiplicadorDanoPorTurno: 0.5, duracaoEmTurnos: 3),
                Magia(nome: "Escudo Arcano",
                      descricao: "Um escudo de energia aumenta sua defesa por 3 turnos.",
                      icone: "shield.fill", custoEnergia: 25, nivelNecessario: 5,
                      tipo: .fortalecimento, duracaoEmTurnos: 3, bonusDefesa: 5),
                Magia(nome: "Concentração Arcana",
                      descricao: "Foca sua mente, aumentando seu poder mágico por 3 turnos.",
                      icone: "wand.and.stars", custoEnergia: 25, nivelNecessario: 6,
                      tipo: .fortalecimento, duracaoEmTurnos: 3, bonusInteligencia: 6),
                Magia(nome: "Anel de Congelamento",
                      descricao: "Um anel de gelo atinge e atordoa o inimigo.",
                      icone: "snowflake", custoEnergia: 40, nivelNecessario: 8,
                      tipo: .atordoante, atributoDeEscala: .inteligencia, multiplicadorDano: 1.2),
                Magia(nome: "Meteoro",
                      descricao: "Dano devastador vindo do céu.",
                      icone: "sparkles", custoEnergia: 70, nivelNecessario: 9,
                      tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 3.5),
                Magia(nome: "Explosão Arcana",
                      descricao: "Uma onda de energia arcana pura.",
                      icone: "sun.max.fill", custoEnergia: 60, nivelNecessario: 12,
                      tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 3.0),
                Magia(nome: "Cura Maior",
                      descricao: "Uma cura poderosa, para sustentar batalhas longas.",
                      icone: "cross.case.fill", custoEnergia: 45, nivelNecessario: 14,
                      tipo: .cura, valorCura: 90),
                Magia(nome: "Cataclismo",
                      descricao: "A magia mais destrutiva do grimório arcano.",
                      icone: "tornado", custoEnergia: 85, nivelNecessario: 17,
                      tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 4.5)
            ]
        case .ladino:
            // Ladino: golpes diretos escalam com Agilidade, venenos (mais
            // sutis, exigem técnica) escalam com Inteligência.
            return [
                Magia(nome: "Ataque Furtivo",
                      descricao: "Um golpe rápido e certeiro.",
                      icone: "eye.slash.fill", custoEnergia: 25, nivelNecessario: 1,
                      tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 1.6),
                Magia(nome: "Investida Precisa",
                      descricao: "Um golpe estudado que encontra a brecha na guarda do alvo.",
                      icone: "scope", custoEnergia: 20, nivelNecessario: 2,
                      tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 1.3, sempreAcerta: true),
                Magia(nome: "Lâmina Envenenada",
                      descricao: "Corta o inimigo e o envenena por 3 turnos.",
                      icone: "drop.fill", custoEnergia: 30, nivelNecessario: 4,
                      tipo: .danoComEfeito, atributoDeEscala: .inteligencia,
                      multiplicadorDano: 0.9, multiplicadorDanoPorTurno: 0.6, duracaoEmTurnos: 3),
                Magia(nome: "Passo Sombrio",
                      descricao: "Desliza pelas sombras, aumentando sua agilidade por 3 turnos.",
                      icone: "figure.walk", custoEnergia: 25, nivelNecessario: 7,
                      tipo: .fortalecimento, duracaoEmTurnos: 3, bonusAgilidade: 6),
                Magia(nome: "Marca da Presa",
                      descricao: "Um golpe certeiro que atordoa o alvo.",
                      icone: "hand.raised.fill", custoEnergia: 35, nivelNecessario: 9,
                      tipo: .atordoante, atributoDeEscala: .agilidade, multiplicadorDano: 1.3),
                Magia(nome: "Golpe Fatal",
                      descricao: "Um ataque final e brutal.",
                      icone: "target", custoEnergia: 50, nivelNecessario: 10,
                      tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 3.2),
                Magia(nome: "Toxina Mortal",
                      descricao: "Um veneno raro, muito mais potente que o comum.",
                      icone: "drop.fill", custoEnergia: 45, nivelNecessario: 12,
                      tipo: .danoComEfeito, atributoDeEscala: .inteligencia,
                      multiplicadorDano: 1.1, multiplicadorDanoPorTurno: 0.8, duracaoEmTurnos: 4),
                Magia(nome: "Dança das Sombras",
                      descricao: "Torna-se quase invisível, elevando agilidade e inteligência por 4 turnos.",
                      icone: "moon.stars.fill", custoEnergia: 55, nivelNecessario: 15,
                      tipo: .fortalecimento, duracaoEmTurnos: 4, bonusInteligencia: 5, bonusAgilidade: 10),
                Magia(nome: "Execução",
                      descricao: "O golpe mais rápido e letal do repertório do ladino.",
                      icone: "bolt.trianglebadge.exclamationmark.fill", custoEnergia: 75, nivelNecessario: 17,
                      tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 4.2)
            ]
        }
    }
}
