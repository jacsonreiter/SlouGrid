import Foundation

enum TipoDeMagia: String, Codable {
    case dano             // dano direto
    case danoComEfeito    // dano + veneno (dano extra por N turnos)
    case atordoante        // dano + inimigo perde o próximo turno
    case cura             // cura o próprio herói, sem afetar o inimigo
    case fortalecimento    // buff temporário de atributos no herói
    // Sangramento (estilo Bleed de Elden Ring): dano + acúmulo de status no
    // alvo (`acumuloDeStatus`); ao cruzar o limiar, explode em dano extra
    // proporcional à vida máxima do alvo. Base da build de sangramento do
    // Guerreiro/Ladino.
    case sangramento
    // Calafrio (estilo Frostbite): dano + acúmulo; ao cruzar o limiar,
    // atordoa o alvo. Base da build de gelo do Mago/Ladino.
    case calafrio
    // Queimadura: dano + dano por turno (como danoComEfeito), mas também
    // reduz a Defesa do alvo (`reduzDeDefesaPercentual`) enquanto ativa.
    // Base da build de fogo do Mago.
    case queimadura
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

// O "tipo de dano" de Elden Ring (Físico/Mágico/Fogo/Relâmpago/Sagrado),
// adaptado pro jogo: cada zona tem um perfil de resistência/fraqueza (ver
// `Zona.resistenciasDaZona`), então a MESMA build bate diferente dependendo
// de onde é usada — escolher a build certa pra cada masmorra vira uma
// decisão tática de verdade, não só estética. Derivado direto do `tipo`/
// `atributoDeEscala` da magia (nunca um campo salvo) — não muda a forma
// como `Magia` é persistida dentro de `Item.habilidadeDeArma`.
enum ElementoDeDano: String {
    case fisico
    case fogo
    case gelo
    case veneno
    case arcano
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
    // Os dois campos abaixo são `Optional`, não defasados com um valor
    // padrão comum — de propósito. `Magia` não tem `init(from:)` próprio
    // (usa a síntese padrão do Codable), e uma `Magia` pode estar salva
    // dentro do save de um jogador (`Item.habilidadeDeArma`). Um campo
    // `Optional` ganha `decodeIfPresent` automático na síntese e cai em
    // `nil` se a chave não existir num save antigo; um campo não-opcional
    // com valor padrão NÃO tem esse fallback — a síntese chamaria
    // `decode` direto e quebraria o save de qualquer jogador cujo item
    // salvo não tivesse esse campo ainda.
    var acumuloDeStatus: Int? = nil              // Sangramento/Calafrio: quanto esse golpe soma ao acúmulo
    var reducaoDeDefesaPercentual: Int? = nil    // Queimadura: % de Defesa a menos no alvo enquanto ativa

    // Elemento pra fins de resistência/fraqueza (ver `ElementoDeDano`):
    // sempre derivado de `tipo`/`atributoDeEscala`, nunca guardado — cada
    // status novo já "nasce" com elemento certo sem precisar migrar nada.
    var elemento: ElementoDeDano {
        switch tipo {
        case .queimadura: return .fogo
        case .calafrio: return .gelo
        case .danoComEfeito: return .veneno
        case .sangramento: return .fisico
        case .dano, .atordoante:
            return atributoDeEscala == .inteligencia ? .arcano : .fisico
        case .cura, .fortalecimento: return .fisico
        }
    }
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
                      tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 4.0),
                // Build de Sangramento: golpes que acumulam corte profundo
                // até o alvo sangrar de verdade (ver `TipoDeMagia.sangramento`).
                Magia(nome: "Corte Sangrento",
                      descricao: "Um talho profundo que acumula sangramento no alvo.",
                      icone: "drop.triangle.fill", custoEnergia: 30, nivelNecessario: 6,
                      tipo: .sangramento, atributoDeEscala: .forca, multiplicadorDano: 1.6, acumuloDeStatus: 35),
                // Build de Lança: golpes certeiros de longo alcance, foco em
                // precisão em vez de força bruta.
                Magia(nome: "Investida da Lança",
                      descricao: "Uma estocada de longo alcance que encontra qualquer brecha na guarda.",
                      icone: "scope", custoEnergia: 35, nivelNecessario: 11,
                      tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 1.7, sempreAcerta: true)
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
                      tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 4.5),
                // Build de Fogo: dano + queimadura, que corrói a Defesa do
                // alvo enquanto ativa (ver `TipoDeMagia.queimadura`).
                Magia(nome: "Chama Ardente",
                      descricao: "Fogo que gruda no alvo, queimando e corroendo sua defesa.",
                      icone: "flame.fill", custoEnergia: 32, nivelNecessario: 7,
                      tipo: .queimadura, atributoDeEscala: .inteligencia,
                      multiplicadorDano: 1.1, multiplicadorDanoPorTurno: 0.5, duracaoEmTurnos: 3, reducaoDeDefesaPercentual: 20),
                Magia(nome: "Explosão Flamejante",
                      descricao: "Uma explosão de fogo arcano que deixa o alvo queimando por muito mais tempo.",
                      icone: "flame.fill", custoEnergia: 55, nivelNecessario: 13,
                      tipo: .queimadura, atributoDeEscala: .inteligencia,
                      multiplicadorDano: 2.0, multiplicadorDanoPorTurno: 0.6, duracaoEmTurnos: 4, reducaoDeDefesaPercentual: 25),
                // Build de Gelo: dano + acúmulo de calafrio, que atordoa o
                // alvo ao explodir (ver `TipoDeMagia.calafrio`).
                Magia(nome: "Lança de Gelo",
                      descricao: "Uma lança de gelo puro que acumula calafrio no alvo.",
                      icone: "snowflake", custoEnergia: 34, nivelNecessario: 10,
                      tipo: .calafrio, atributoDeEscala: .inteligencia, multiplicadorDano: 1.5, acumuloDeStatus: 40),
                Magia(nome: "Nova Glacial",
                      descricao: "Uma explosão de gelo que quase sempre já atordoa o alvo na hora.",
                      icone: "snowflake", custoEnergia: 60, nivelNecessario: 16,
                      tipo: .calafrio, atributoDeEscala: .inteligencia, multiplicadorDano: 2.2, acumuloDeStatus: 55)
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
                      tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 4.2),
                // Segunda build ofensiva do ladino, ao lado do veneno:
                // sangramento rápido, escalando com a mesma Agilidade dos
                // golpes diretos.
                Magia(nome: "Corte Retalhante",
                      descricao: "Uma sequência de cortes rasos que acumulam sangramento.",
                      icone: "drop.triangle.fill", custoEnergia: 28, nivelNecessario: 6,
                      tipo: .sangramento, atributoDeEscala: .agilidade, multiplicadorDano: 1.4, acumuloDeStatus: 30),
                Magia(nome: "Lâmina Congelante",
                      descricao: "Uma lâmina gelada que acumula calafrio a cada corte.",
                      icone: "snowflake", custoEnergia: 32, nivelNecessario: 11,
                      tipo: .calafrio, atributoDeEscala: .agilidade, multiplicadorDano: 1.3, acumuloDeStatus: 30)
            ]
        }
    }
}
