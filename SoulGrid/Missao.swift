import Foundation

// O tipo de objetivo de uma missão — cada um sabe checar seu próprio
// progresso reaproveitando dados que o herói já guarda, sem precisar de
// nenhum contador novo e persistido (ver `Personagem.statusDaMissao`).
enum TipoDeMissao: String, Codable {
    case cacar           // N vitórias numa zona (reaproveita `progressoZonas`)
    case derrotarChefe   // o chefe de uma zona (reaproveita `runicasConquistadas`)
    case alcancarNivel   // alcançar um nível de personagem
}

// Uma missão de bounty board, estilo os pedidos de NPC de Elden Ring
// (Irina, White Mask Varré, D) — objetivo simples, entregue de volta a um
// NPC na Vila por uma recompensa. `id` é uma string estável (não UUID)
// porque também é a chave salva em `Personagem.missoesEntregues`; nunca
// renomear o id de uma missão já publicada, ou saves antigos vão oferecer
// a "mesma" missão de novo com um id diferente.
struct Missao: Identifiable {
    var id: String
    var titulo: String
    var descricao: String
    var tipo: TipoDeMissao
    var zonaAlvo: String? = nil    // relevante para .cacar/.derrotarChefe
    var quantidadeAlvo: Int = 1    // nº de vitórias, ou o nível-alvo em .alcancarNivel
    var nivelMinimo: Int = 1       // nível do herói pra missão aparecer disponível
    var recompensaRunas: Int
    var recompensaItem: Item? = nil
    var pnjID: String
}

extension Missao {
    // Catálogo único de todas as missões do jogo — 2 por zona (caçada +
    // chefe) mais 2 marcos de progressão com recompensa exclusiva de item,
    // nunca vendida no mercado (ver `TelaDaVila`/`PNJ`).
    static let catalogo: [Missao] = [
        // Faixa 1 — Milo, o Batedor
        Missao(id: "caca_floresta_sombria", titulo: "Pragas da Floresta",
               descricao: "Derrote 5 criaturas na Floresta Sombria.",
               tipo: .cacar, zonaAlvo: "Floresta Sombria", quantidadeAlvo: 5, nivelMinimo: 1,
               recompensaRunas: 90, pnjID: "milo"),
        Missao(id: "chefe_floresta_sombria", titulo: "A Raiz Podre",
               descricao: "Derrote o Ent Corrompido, chefe da Floresta Sombria.",
               tipo: .derrotarChefe, zonaAlvo: "Floresta Sombria", nivelMinimo: 1,
               recompensaRunas: 180, pnjID: "milo"),
        Missao(id: "caca_pantano_nebuloso", titulo: "Névoa Infestada",
               descricao: "Derrote 5 criaturas no Pântano Nebuloso.",
               tipo: .cacar, zonaAlvo: "Pântano Nebuloso", quantidadeAlvo: 5, nivelMinimo: 1,
               recompensaRunas: 90, pnjID: "milo"),
        Missao(id: "chefe_pantano_nebuloso", titulo: "O Verme Ancestral",
               descricao: "Derrote o Verme das Profundezas, chefe do Pântano Nebuloso.",
               tipo: .derrotarChefe, zonaAlvo: "Pântano Nebuloso", nivelMinimo: 1,
               recompensaRunas: 180, pnjID: "milo"),

        // Faixa 2 — Yara, a Exploradora
        Missao(id: "caca_cavernas_de_pedra", titulo: "Ecos nas Cavernas",
               descricao: "Derrote 6 criaturas nas Cavernas de Pedra.",
               tipo: .cacar, zonaAlvo: "Cavernas de Pedra", quantidadeAlvo: 6, nivelMinimo: 4,
               recompensaRunas: 160, pnjID: "yara"),
        Missao(id: "chefe_cavernas_de_pedra", titulo: "O Gigante Adormecido",
               descricao: "Derrote o Golem de Pedra, chefe das Cavernas de Pedra.",
               tipo: .derrotarChefe, zonaAlvo: "Cavernas de Pedra", nivelMinimo: 4,
               recompensaRunas: 320, pnjID: "yara"),
        Missao(id: "caca_necropole_congelada", titulo: "Os Mortos Inquietos",
               descricao: "Derrote 6 criaturas na Necrópole Congelada.",
               tipo: .cacar, zonaAlvo: "Necrópole Congelada", quantidadeAlvo: 6, nivelMinimo: 4,
               recompensaRunas: 160, pnjID: "yara"),
        Missao(id: "chefe_necropole_congelada", titulo: "O Frio Eterno",
               descricao: "Derrote o Cavaleiro Gélido, chefe da Necrópole Congelada.",
               tipo: .derrotarChefe, zonaAlvo: "Necrópole Congelada", nivelMinimo: 4,
               recompensaRunas: 320, pnjID: "yara"),

        // Faixa 3 — Bruno, o Veterano
        Missao(id: "caca_ruinas_antigas", titulo: "Guardiões Esquecidos",
               descricao: "Derrote 7 criaturas nas Ruínas Antigas.",
               tipo: .cacar, zonaAlvo: "Ruínas Antigas", quantidadeAlvo: 7, nivelMinimo: 8,
               recompensaRunas: 260, pnjID: "bruno"),
        Missao(id: "chefe_ruinas_antigas", titulo: "O Lich Ancestral",
               descricao: "Derrote o Lich Ancestral, chefe das Ruínas Antigas.",
               tipo: .derrotarChefe, zonaAlvo: "Ruínas Antigas", nivelMinimo: 8,
               recompensaRunas: 520, pnjID: "bruno"),
        Missao(id: "caca_fortaleza_abandonada", titulo: "Renegados em Armas",
               descricao: "Derrote 7 criaturas na Fortaleza Abandonada.",
               tipo: .cacar, zonaAlvo: "Fortaleza Abandonada", quantidadeAlvo: 7, nivelMinimo: 8,
               recompensaRunas: 260, pnjID: "bruno"),
        Missao(id: "chefe_fortaleza_abandonada", titulo: "O Último General",
               descricao: "Derrote o General Caído, chefe da Fortaleza Abandonada.",
               tipo: .derrotarChefe, zonaAlvo: "Fortaleza Abandonada", nivelMinimo: 8,
               recompensaRunas: 520, pnjID: "bruno"),

        // Faixa 4 — Seraphine, a Guardiã
        Missao(id: "caca_torre_do_feiticeiro", titulo: "Ecos Arcanos",
               descricao: "Derrote 8 criaturas na Torre do Feiticeiro.",
               tipo: .cacar, zonaAlvo: "Torre do Feiticeiro", quantidadeAlvo: 8, nivelMinimo: 13,
               recompensaRunas: 420, pnjID: "seraphine"),
        Missao(id: "chefe_torre_do_feiticeiro", titulo: "A Queda do Arquimago",
               descricao: "Derrote o Arquimago Caído, chefe da Torre do Feiticeiro.",
               tipo: .derrotarChefe, zonaAlvo: "Torre do Feiticeiro", nivelMinimo: 13,
               recompensaRunas: 850, pnjID: "seraphine"),
        Missao(id: "caca_abismo_estelar", titulo: "Sussurros do Vazio",
               descricao: "Derrote 8 criaturas no Abismo Estelar.",
               tipo: .cacar, zonaAlvo: "Abismo Estelar", quantidadeAlvo: 8, nivelMinimo: 13,
               recompensaRunas: 420, pnjID: "seraphine"),
        Missao(id: "chefe_abismo_estelar", titulo: "O Devorador de Mundos",
               descricao: "Derrote o Devorador de Mundos, chefe do Abismo Estelar.",
               tipo: .derrotarChefe, zonaAlvo: "Abismo Estelar", nivelMinimo: 13,
               recompensaRunas: 850, pnjID: "seraphine"),

        // Marcos de progressão — Ancião Toren, na Vila
        Missao(id: "marco_nivel_5", titulo: "Prove seu Valor",
               descricao: "Alcance o nível 5.",
               tipo: .alcancarNivel, quantidadeAlvo: 5, nivelMinimo: 1,
               recompensaRunas: 200,
               recompensaItem: Item(nome: "Broche do Aventureiro", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .incomum, nivelMinimo: 5,
                                     bonus: BonusDeAtributos(vitalidade: 3, destreza: 3, sorte: 3)),
               pnjID: "toren"),

        // Nível 16, com recompensa exclusiva por classe — só a que combina
        // com o herói atual aparece na Vila (ver `TelaDaVila.missoesVisiveis`).
        Missao(id: "marco_nivel_16_guerreiro", titulo: "O Peso da Lenda",
               descricao: "Alcance o nível 16.",
               tipo: .alcancarNivel, quantidadeAlvo: 16, nivelMinimo: 1,
               recompensaRunas: 600,
               recompensaItem: Item(nome: "Fúria do Ancião", tipo: .arma, valor: 0, preco: 0,
                                     raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 16,
                                     bonus: BonusDeAtributos(forca: 28, vitalidade: 8, destreza: 4),
                                     habilidadeDeArma: Magia(nome: "Golpe do Ancião",
                                                              descricao: "Um golpe ancestral que atordoa e fere fundo.",
                                                              icone: "burst.fill", custoEnergia: 45, nivelNecessario: 1,
                                                              tipo: .atordoante, atributoDeEscala: .forca, multiplicadorDano: 2.0)),
               pnjID: "toren"),
        Missao(id: "marco_nivel_16_mago", titulo: "O Peso da Lenda",
               descricao: "Alcance o nível 16.",
               tipo: .alcancarNivel, quantidadeAlvo: 16, nivelMinimo: 1,
               recompensaRunas: 600,
               recompensaItem: Item(nome: "Cajado do Vazio Sussurrante", tipo: .arma, valor: 0, preco: 0,
                                     raridade: .epico, classeRestrita: .mago, nivelMinimo: 16,
                                     bonus: BonusDeAtributos(inteligencia: 28, energia: 18),
                                     habilidadeDeArma: Magia(nome: "Sussurro do Vazio",
                                                              descricao: "Uma explosão arcana que corrói o alvo aos poucos.",
                                                              icone: "sparkles", custoEnergia: 48, nivelNecessario: 1,
                                                              tipo: .danoComEfeito, atributoDeEscala: .inteligencia,
                                                              multiplicadorDano: 1.4, multiplicadorDanoPorTurno: 0.7, duracaoEmTurnos: 3)),
               pnjID: "toren"),
        Missao(id: "marco_nivel_16_ladino", titulo: "O Peso da Lenda",
               descricao: "Alcance o nível 16.",
               tipo: .alcancarNivel, quantidadeAlvo: 16, nivelMinimo: 1,
               recompensaRunas: 600,
               recompensaItem: Item(nome: "Garras da Vila Esquecida", tipo: .arma, valor: 0, preco: 0,
                                     raridade: .epico, classeRestrita: .ladino, nivelMinimo: 16,
                                     bonus: BonusDeAtributos(destreza: 10, agilidade: 26),
                                     habilidadeDeArma: Magia(nome: "Zarpada Esquecida",
                                                              descricao: "Um golpe certeiro vindo de todos os ângulos.",
                                                              icone: "wind", custoEnergia: 44, nivelNecessario: 1,
                                                              tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 2.6, sempreAcerta: true)),
               pnjID: "toren")
    ]
}
