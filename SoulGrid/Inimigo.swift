import Foundation

struct Inimigo {
    var nome: String
    var icone: String
    var nivel: Int
    var vidaMaxima: Int
    var vidaAtual: Int
    var forca: Int
    var defesa: Int
    // Os dois viram uma moeda só (Runas) em `Personagem.receberRecompensa`
    // — não há mais XP separado de ouro, mas os campos ficaram divididos
    // pra não precisar reajustar todos os números de `Zona.swift`.
    var xpRecompensa: Int
    var ouroRecompensa: ClosedRange<Int>
    var chefe: Bool
    // Inimigo de elite: um "field boss" estilo Elden Ring — raro de
    // encontrar explorando, mais forte que o comum da zona, mas sem dar
    // Grande Rúnica (isso continua exclusivo do chefe de verdade).
    var elite: Bool = false
    var zonaOrigem: String

    var estaVivo: Bool { vidaAtual > 0 }
}
