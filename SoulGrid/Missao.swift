import Foundation

// O tipo de objetivo de uma missão — cada um sabe checar seu próprio
// progresso reaproveitando dados que o herói já guarda, sem precisar de
// nenhum contador novo e persistido (ver `Personagem.statusDaMissao`).
enum TipoDeMissao: String, Codable {
    case cacar           // N vitórias numa zona (reaproveita `progressoZonas`)
    case derrotarChefe   // o chefe de uma zona (reaproveita `runicasConquistadas`)
    case alcancarNivel   // alcançar um nível de personagem
    case coletar         // entregar N de um material específico (ver `Item.materiaisDeZona`)
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
    var quantidadeAlvo: Int = 1    // nº de vitórias/itens, ou o nível-alvo em .alcancarNivel
    var nivelMinimo: Int = 1       // nível do herói pra missão aparecer disponível
    var recompensaRunas: Int
    var recompensaItem: Item? = nil
    var pnjID: String
    var itemAlvo: String? = nil        // nome do item, só relevante para .coletar
    // Texto de ambientação mostrado ao entregar — reservado pras missões
    // da trama principal (marcos de nível, ver o catálogo abaixo), que
    // formam o fio narrativo do jogo ("O Selo Rompido"). Missões de zona
    // não têm: são conteúdo paralelo, não avançam a história central.
    var loreAoEntregar: String? = nil
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
        Missao(id: "coletar_floresta_sombria", titulo: "Peles para o Curtidor",
               descricao: "Colete 5 unidades de Pelo de Lobo Selvagem.",
               tipo: .coletar, quantidadeAlvo: 5, nivelMinimo: 1,
               recompensaRunas: 100, pnjID: "milo", itemAlvo: "Pelo de Lobo Selvagem"),
        Missao(id: "coletar_pantano_nebuloso", titulo: "Toxinas Raras",
               descricao: "Colete 5 unidades de Glândula de Sapo Venenoso.",
               tipo: .coletar, quantidadeAlvo: 5, nivelMinimo: 1,
               recompensaRunas: 100, pnjID: "milo", itemAlvo: "Glândula de Sapo Venenoso"),

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
        Missao(id: "coletar_cavernas_de_pedra", titulo: "Cristais Brutos",
               descricao: "Colete 6 unidades de Fragmento de Cristal Bruto.",
               tipo: .coletar, quantidadeAlvo: 6, nivelMinimo: 4,
               recompensaRunas: 170, pnjID: "yara", itemAlvo: "Fragmento de Cristal Bruto"),
        Missao(id: "coletar_necropole_congelada", titulo: "Ossos Amaldiçoados",
               descricao: "Colete 6 unidades de Osso Gélido Amaldiçoado.",
               tipo: .coletar, quantidadeAlvo: 6, nivelMinimo: 4,
               recompensaRunas: 170, pnjID: "yara", itemAlvo: "Osso Gélido Amaldiçoado"),

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
        Missao(id: "coletar_ruinas_antigas", titulo: "Fragmentos do Passado",
               descricao: "Colete 7 unidades de Fragmento de Runa Antiga.",
               tipo: .coletar, quantidadeAlvo: 7, nivelMinimo: 8,
               recompensaRunas: 270, pnjID: "bruno", itemAlvo: "Fragmento de Runa Antiga"),
        Missao(id: "coletar_fortaleza_abandonada", titulo: "Emblemas Renegados",
               descricao: "Colete 7 unidades de Emblema do Renegado.",
               tipo: .coletar, quantidadeAlvo: 7, nivelMinimo: 8,
               recompensaRunas: 270, pnjID: "bruno", itemAlvo: "Emblema do Renegado"),

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
        Missao(id: "coletar_torre_do_feiticeiro", titulo: "Pó Instável",
               descricao: "Colete 8 unidades de Pó Arcano Instável.",
               tipo: .coletar, quantidadeAlvo: 8, nivelMinimo: 13,
               recompensaRunas: 440, pnjID: "seraphine", itemAlvo: "Pó Arcano Instável"),
        Missao(id: "coletar_abismo_estelar", titulo: "Ecos do Vazio",
               descricao: "Colete 8 unidades de Fragmento do Vazio.",
               tipo: .coletar, quantidadeAlvo: 8, nivelMinimo: 13,
               recompensaRunas: 440, pnjID: "seraphine", itemAlvo: "Fragmento do Vazio"),

        // MARK: - A trama principal: "O Selo Rompido"
        //
        // Há gerações, uma ordem de guardiões (a de Toren) selou algo
        // adormecido no Abismo Estelar. O selo está se rompendo, e a
        // corrupção do Vazio vem se espalhando por todas as zonas — é por
        // isso que tantos inimigos do jogo já eram "Corrompidos" ou
        // "Amaldiçoados" antes mesmo dessa trama existir. Cada marco de
        // nível revela mais um pedaço da história através do `loreAoEntregar`,
        // culminando na derrota do Devorador de Mundos e no fechamento do
        // arco no nível 40.
        Missao(id: "marco_nivel_5", titulo: "Prove seu Valor",
               descricao: "Alcance o nível 5.",
               tipo: .alcancarNivel, quantidadeAlvo: 5, nivelMinimo: 1,
               recompensaRunas: 200,
               recompensaItem: Item(nome: "Broche do Aventureiro", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .incomum, nivelMinimo: 5,
                                     bonus: BonusDeAtributos(vitalidade: 3, destreza: 3, sorte: 3)),
               pnjID: "toren",
               loreAoEntregar: "Ancião Toren observa você com um leve aceno. \"Você já não é mais um novato. Sinta-se em casa na Vila — mas não descanse por muito tempo. Há sinais de que algo desperta longe daqui, no Abismo Estelar. Continue forte.\""),

        // Nível 10 — Capitã Oriana, ligada à Fortaleza Abandonada.
        Missao(id: "marco_nivel_10", titulo: "O Chamado às Armas",
               descricao: "Alcance o nível 10.",
               tipo: .alcancarNivel, quantidadeAlvo: 10, nivelMinimo: 1,
               recompensaRunas: 320,
               recompensaItem: Item(nome: "Emblema da Milícia", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .raro, nivelMinimo: 10,
                                     bonus: BonusDeAtributos(forca: 5, vitalidade: 5, destreza: 5)),
               pnjID: "oriana",
               loreAoEntregar: "Capitã Oriana observa você com aprovação. \"As criaturas ao redor da Fortaleza mudaram... estão mais ferozes, mais erradas. Algo as está corrompendo. Continue forte — vamos precisar de você.\""),
        Missao(id: "oriana_fragmentos", titulo: "Selos de Contenção",
               descricao: "Colete 8 unidades de Fragmento de Runa Antiga para reforçar as wards da Fortaleza.",
               tipo: .coletar, quantidadeAlvo: 8, nivelMinimo: 10,
               recompensaRunas: 350,
               recompensaItem: Item(nome: "Amuleto dos Selos Antigos", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .raro, nivelMinimo: 10,
                                     bonus: BonusDeAtributos(defesa: 6, regenVidaPorTurno: 3)),
               pnjID: "oriana", itemAlvo: "Fragmento de Runa Antiga"),

        // Nível 20 — Kael, o Ferreiro, ligado à Torre do Feiticeiro.
        Missao(id: "marco_nivel_20", titulo: "O Forjador de Lendas",
               descricao: "Alcance o nível 20.",
               tipo: .alcancarNivel, quantidadeAlvo: 20, nivelMinimo: 1,
               recompensaRunas: 500,
               recompensaItem: Item(nome: "Coração de Forja", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .epico, nivelMinimo: 20,
                                     bonus: BonusDeAtributos(forca: 6, inteligencia: 6, agilidade: 6, energia: 20)),
               pnjID: "kael",
               loreAoEntregar: "Kael limpa as mãos enfuligentas e sorri. \"Vinte anos forjando, e nunca vi minério reagir ao Vazio como esses fragmentos reagem. A corrupção está mudando até o metal. Tome — forjei isso pensando em você.\""),
        Missao(id: "kael_po_arcano", titulo: "Pó para a Forja",
               descricao: "Colete 10 unidades de Pó Arcano Instável para a forja de Kael.",
               tipo: .coletar, quantidadeAlvo: 10, nivelMinimo: 20,
               recompensaRunas: 400,
               recompensaItem: Item(nome: "Anel do Fluxo Arcano", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .raro, nivelMinimo: 20,
                                     bonus: BonusDeAtributos(inteligencia: 10, energia: 15)),
               pnjID: "kael", itemAlvo: "Pó Arcano Instável"),
        Missao(id: "kael_fragmento_vazio", titulo: "Metal Tocado pelo Vazio",
               descricao: "Colete 8 unidades de Fragmento do Vazio — o material mais raro que Kael já pediu.",
               tipo: .coletar, quantidadeAlvo: 8, nivelMinimo: 20,
               recompensaRunas: 550,
               recompensaItem: Item(nome: "Talismã da Forja Vazia", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .epico, nivelMinimo: 20,
                                     bonus: BonusDeAtributos(bonusOuroPercentual: 25, bonusChanceDeItemPercentual: 15)),
               pnjID: "kael", itemAlvo: "Fragmento do Vazio"),

        // Nível 30 — Ithra, a Vidente, ligada ao Abismo Estelar.
        Missao(id: "marco_nivel_30", titulo: "A Vidente do Vazio",
               descricao: "Alcance o nível 30.",
               tipo: .alcancarNivel, quantidadeAlvo: 30, nivelMinimo: 1,
               recompensaRunas: 700,
               recompensaItem: Item(nome: "Olho da Videncia", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .epico, nivelMinimo: 30,
                                     bonus: BonusDeAtributos(destreza: 8, sorte: 12, bonusRaridadeDeItem: 1)),
               pnjID: "ithra",
               loreAoEntregar: "Os olhos de Ithra ficam brancos por um instante. \"Eu vi... um Devorador, adormecido sob estrelas erradas, prestes a acordar. O selo que o prende está quase rompido. Você é a última esperança que enxerguei nessa visão.\""),
        Missao(id: "ithra_dominio", titulo: "Domínio sobre o Abismo",
               descricao: "Prove seu domínio: acumule 15 vitórias no Abismo Estelar.",
               tipo: .cacar, zonaAlvo: "Abismo Estelar", quantidadeAlvo: 15, nivelMinimo: 30,
               recompensaRunas: 650,
               recompensaItem: Item(nome: "Manto do Domínio Estelar", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .epico, nivelMinimo: 30,
                                     bonus: BonusDeAtributos(vitalidade: 15, defesa: 8, regenVidaPorTurno: 5)),
               pnjID: "ithra"),

        // Nível 40 — Ancião Toren retorna para o desfecho da trama.
        Missao(id: "marco_nivel_40", titulo: "O Selo Final",
               descricao: "Alcance o nível 40.",
               tipo: .alcancarNivel, quantidadeAlvo: 40, nivelMinimo: 1,
               recompensaRunas: 1200,
               recompensaItem: Item(nome: "Selo do Vazio Contido", tipo: .acessorio, valor: 0, preco: 0,
                                     raridade: .epico, nivelMinimo: 40,
                                     bonus: BonusDeAtributos(forca: 10, vitalidade: 10, inteligencia: 10, destreza: 10,
                                                              agilidade: 10, sorte: 10, regenVidaPorTurno: 8, regenEnergiaPorTurno: 8)),
               pnjID: "toren",
               loreAoEntregar: "Ancião Toren se ajoelha, algo que ninguém jamais o viu fazer. \"O Devorador de Mundos... você o deteve. O selo que minha ordem jurou proteger, há gerações, finalmente pode descansar em paz — porque você o restaurou. A Vila, e este mundo, devem tudo a você.\""),

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
               pnjID: "toren",
               loreAoEntregar: "Ancião Toren entrega a arma com reverência. \"Isso pertenceu a um guardião caído, há muito tempo. Ele lutou para conter o que dorme no Abismo Estelar... e falhou. Não cometa o mesmo erro.\""),
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
               pnjID: "toren",
               loreAoEntregar: "Ancião Toren entrega a arma com reverência. \"Isso pertenceu a um guardião caído, há muito tempo. Ele lutou para conter o que dorme no Abismo Estelar... e falhou. Não cometa o mesmo erro.\""),
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
               pnjID: "toren",
               loreAoEntregar: "Ancião Toren entrega a arma com reverência. \"Isso pertenceu a um guardião caído, há muito tempo. Ele lutou para conter o que dorme no Abismo Estelar... e falhou. Não cometa o mesmo erro.\"")
    ]
}
