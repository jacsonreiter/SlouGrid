import Foundation

// Um morador da Vila que oferece missões — estilo os NPCs de bounty/quest
// de Elden Ring, sem diálogo ramificado nenhum, só uma fala de ambientação
// e a lista de missões que carrega (ver `Missao.catalogo`).
struct PNJ: Identifiable {
    var id: String
    var nome: String
    var titulo: String
    var icone: String
    var fala: String
    // Nível do herói pra esse morador aparecer na Vila — Oriana/Ithra e o
    // retorno de Toren no fim só se mostram a cada marco de 10 níveis,
    // como pedido: "a cada 10 níveis aparecem NPCs novos". Os guias de
    // zona aparecem no mesmo nível em que a zona deles desbloqueia (ver
    // `Zona.nivelMinimo`). Kael é a exceção: fica sempre visível desde o
    // nível 1, porque a Forja não pode ficar trancada (ver o card dele,
    // logo abaixo) — só as missões dele continuam presas ao nível 20.
    var nivelMinimoParaAparecer: Int = 1

    var missoes: [Missao] {
        Missao.catalogo.filter { $0.pnjID == id }
    }
}

extension PNJ {
    static let catalogo: [PNJ] = [
        PNJ(id: "milo", nome: "Milo, o Batedor", titulo: "Guia da Floresta e do Pântano",
            icone: "leaf.fill",
            fala: "Essas terras próximas escondem mais perigo do que parecem. Ajude a limpar o caminho, e não vai faltar recompensa.",
            nivelMinimoParaAparecer: 1),
        PNJ(id: "yara", nome: "Yara, a Exploradora", titulo: "Guia das Cavernas e da Necrópole",
            icone: "flashlight.on.fill",
            fala: "Já perdi companheiros bons demais lá embaixo. Cuidado — e boa sorte.",
            nivelMinimoParaAparecer: 4),
        PNJ(id: "bruno", nome: "Bruno, o Veterano", titulo: "Guia das Ruínas e da Fortaleza",
            icone: "shield.lefthalf.filled",
            fala: "Servi sob as bandeiras daquela fortaleza, antes de cair. Encerre o que os renegados começaram.",
            nivelMinimoParaAparecer: 8),
        PNJ(id: "seraphine", nome: "Seraphine, a Guardiã", titulo: "Guia da Torre e do Abismo",
            icone: "eye.fill",
            fala: "Poucos voltam de onde você está indo. Prove que você é diferente.",
            nivelMinimoParaAparecer: 13),
        PNJ(id: "toren", nome: "Ancião Toren", titulo: "Guardião da Vila",
            icone: "person.fill.turn.down",
            fala: "Vejo em você o mesmo brilho que vi em tantos outros, há muito tempo. Continue subindo — a Vila guarda recompensas para quem chega longe.",
            nivelMinimoParaAparecer: 1),
        PNJ(id: "oriana", nome: "Capitã Oriana", titulo: "Comandante da Milícia da Vila",
            icone: "shield.checkered",
            fala: "As criaturas lá fora estão mudando. Mais ferozes. Mais... erradas. Me ajude a entender o que está acontecendo.",
            nivelMinimoParaAparecer: 10),
        // Kael aparece desde o nível 1 — a Forja (ver `TelaDeEquipamento.
        // forjaBox`) não pode ficar trancada atrás de um nível específico,
        // senão o jogador não tem onde evoluir arma/armadura até lá. As
        // missões dele continuam trancadas até o nível certo por conta
        // própria (`Missao.nivelMinimo: 20`, checado em
        // `Personagem.statusDaMissao`), então elas aparecem como
        // "Bloqueada" e destravam sozinhas quando o nível chega — só o
        // card do PNJ (e a Forja) não fica mais escondido até lá.
        PNJ(id: "kael", nome: "Kael, o Ferreiro", titulo: "Mestre Ferreiro da Vila",
            icone: "hammer.fill",
            fala: "Traga material raro o bastante e eu forjo qualquer coisa. Já vi metais estranhos ultimamente... vindos de longe.",
            nivelMinimoParaAparecer: 1),
        PNJ(id: "ithra", nome: "Ithra, a Vidente", titulo: "Oráculo da Vila",
            icone: "eye.trianglebadge.exclamationmark.fill",
            fala: "Eu vejo fragmentos do que está por vir. Nem tudo é claro... mas sei que você tem um papel nisso.",
            nivelMinimoParaAparecer: 30)
    ]
}
