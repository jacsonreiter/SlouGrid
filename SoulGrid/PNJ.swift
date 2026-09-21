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

    var missoes: [Missao] {
        Missao.catalogo.filter { $0.pnjID == id }
    }
}

extension PNJ {
    static let catalogo: [PNJ] = [
        PNJ(id: "milo", nome: "Milo, o Batedor", titulo: "Guia da Floresta e do Pântano",
            icone: "leaf.fill",
            fala: "Essas terras próximas escondem mais perigo do que parecem. Ajude a limpar o caminho, e não vai faltar recompensa."),
        PNJ(id: "yara", nome: "Yara, a Exploradora", titulo: "Guia das Cavernas e da Necrópole",
            icone: "flashlight.on.fill",
            fala: "Já perdi companheiros bons demais lá embaixo. Cuidado — e boa sorte."),
        PNJ(id: "bruno", nome: "Bruno, o Veterano", titulo: "Guia das Ruínas e da Fortaleza",
            icone: "shield.lefthalf.filled",
            fala: "Servi sob as bandeiras daquela fortaleza, antes de cair. Encerre o que os renegados começaram."),
        PNJ(id: "seraphine", nome: "Seraphine, a Guardiã", titulo: "Guia da Torre e do Abismo",
            icone: "eye.fill",
            fala: "Poucos voltam de onde você está indo. Prove que você é diferente."),
        PNJ(id: "toren", nome: "Ancião Toren", titulo: "Guardião da Vila",
            icone: "person.fill.turn.down",
            fala: "Vejo em você o mesmo brilho que vi em tantos outros, há muito tempo. Continue subindo — a Vila guarda recompensas para quem chega longe.")
    ]
}
