import Foundation

struct Zona: Identifiable {
    let id = UUID()
    var nome: String
    var descricao: String
    var icone: String
    var nivelMinimo: Int
    var nivelBaseInimigos: Int
    var nomesInimigos: [String]
    var iconeInimigos: String
    var nomeChefe: String
    var iconeChefe: String
    var vitoriasParaChefe: Int = 3

    func gerarInimigoComum(nivelHeroi: Int) -> Inimigo {
        let nivel = max(nivelBaseInimigos, nivelHeroi)
        let vida = 24 + nivel * 11
        return Inimigo(
            nome: nomesInimigos.randomElement() ?? nome,
            icone: iconeInimigos,
            nivel: nivel,
            vidaMaxima: vida,
            vidaAtual: vida,
            forca: 5 + nivel * 3,
            defesa: 1 + nivel,
            xpRecompensa: 14 + nivel * 7,
            ouroRecompensa: (6 + nivel * 3)...(12 + nivel * 5),
            chefe: false,
            zonaOrigem: nome
        )
    }

    func gerarChefe(nivelHeroi: Int) -> Inimigo {
        let nivel = max(nivelBaseInimigos + 4, nivelHeroi + 2)
        let vida = 70 + nivel * 18
        return Inimigo(
            nome: nomeChefe,
            icone: iconeChefe,
            nivel: nivel,
            vidaMaxima: vida,
            vidaAtual: vida,
            forca: 10 + nivel * 4,
            defesa: 4 + nivel * 2,
            xpRecompensa: 120 + nivel * 14,
            ouroRecompensa: (60 + nivel * 8)...(110 + nivel * 12),
            chefe: true,
            zonaOrigem: nome
        )
    }

    // Um inimigo comum "inflado" para servir de field boss — mais vida,
    // força e defesa que o normal da zona, com recompensa maior, mas sem
    // contar pra vitórias do chefe nem dar Grande Rúnica.
    func gerarInimigoDeElite(nivelHeroi: Int) -> Inimigo {
        var inimigo = gerarInimigoComum(nivelHeroi: nivelHeroi)
        inimigo.nome = "\(inimigo.nome) de Elite"
        inimigo.vidaMaxima = Int(Double(inimigo.vidaMaxima) * 1.6)
        inimigo.vidaAtual = inimigo.vidaMaxima
        inimigo.forca = Int(Double(inimigo.forca) * 1.3)
        inimigo.defesa += 3
        inimigo.xpRecompensa = Int(Double(inimigo.xpRecompensa) * 2.2)
        inimigo.ouroRecompensa = (inimigo.ouroRecompensa.lowerBound * 2)...(inimigo.ouroRecompensa.upperBound * 2)
        inimigo.elite = true
        return inimigo
    }
}

// O que a exploração de uma zona pode render, estilo o mapa aberto de Elden
// Ring: na maior parte das vezes um inimigo comum, às vezes um "field boss"
// de elite (mais forte, loot melhor), e ocasionalmente uma descoberta
// pacífica — Runas/item de graça, sem risco de combate, como um cadáver ou
// baú escondido no caminho.
enum TipoDeEncontro {
    case comum
    case eliteDeCampo
    case descoberta
}

extension Zona {
    func sortearEncontro() -> TipoDeEncontro {
        let rolagem = Int.random(in: 1...100)
        if rolagem <= 8 { return .eliteDeCampo }
        if rolagem <= 20 { return .descoberta }
        return .comum
    }
}

// 4 faixas de nível (mesmos degraus de raridade de `Item.lootAleatorio`:
// comum <4, incomum 4-7, raro 8-12, épico 13+), 2 lugares por faixa — cada
// um com seu próprio elenco de inimigos e chefe, pra sempre existir mais de
// uma masmorra pra escolher em cada trecho da progressão.
let zonasDoJogo: [Zona] = [
    // Faixa 1 (nível 1+)
    Zona(nome: "Floresta Sombria",
         descricao: "Uma floresta antiga, lar de feras e batedores goblins.",
         icone: "leaf.fill",
         nivelMinimo: 1,
         nivelBaseInimigos: 1,
         nomesInimigos: ["Lobo Selvagem", "Goblin Batedor", "Aranha Gigante"],
         iconeInimigos: "pawprint.fill",
         nomeChefe: "Ent Corrompido",
         iconeChefe: "tree.fill"),

    Zona(nome: "Pântano Nebuloso",
         descricao: "Um brejo enevoado onde o ar parado esconde predadores.",
         icone: "cloud.fog.fill",
         nivelMinimo: 1,
         nivelBaseInimigos: 1,
         nomesInimigos: ["Sapo Venenoso", "Vagalume Corrompido", "Ceifador de Lodo"],
         iconeInimigos: "ant.fill",
         nomeChefe: "Verme das Profundezas",
         iconeChefe: "tornado"),

    // Faixa 2 (nível 4+)
    Zona(nome: "Cavernas de Pedra",
         descricao: "Túneis escuros escavados por criaturas famintas.",
         icone: "mountain.2.fill",
         nivelMinimo: 4,
         nivelBaseInimigos: 4,
         nomesInimigos: ["Morcego Gigante", "Troll das Cavernas", "Esqueleto Guerreiro"],
         iconeInimigos: "tortoise.fill",
         nomeChefe: "Golem de Pedra",
         iconeChefe: "cube.fill"),

    Zona(nome: "Necrópole Congelada",
         descricao: "Um cemitério tomado pelo gelo eterno, onde os mortos não descansam.",
         icone: "snowflake",
         nivelMinimo: 4,
         nivelBaseInimigos: 4,
         nomesInimigos: ["Zumbi Gélido", "Arauto da Geada", "Corvo Necromante"],
         iconeInimigos: "figure.walk",
         nomeChefe: "Cavaleiro Gélido",
         iconeChefe: "shield.righthalf.filled"),

    // Faixa 3 (nível 8+)
    Zona(nome: "Ruínas Antigas",
         descricao: "Restos de uma civilização esquecida, guardados por magia sombria.",
         icone: "building.columns.fill",
         nivelMinimo: 8,
         nivelBaseInimigos: 8,
         nomesInimigos: ["Guardião de Pedra", "Espectro Vingativo", "Cultista Sombrio"],
         iconeInimigos: "flame.fill",
         nomeChefe: "Lich Ancestral",
         iconeChefe: "crown.fill"),

    Zona(nome: "Fortaleza Abandonada",
         descricao: "Um forte em ruínas, ainda patrulhado por soldados renegados.",
         icone: "building.2.fill",
         nivelMinimo: 8,
         nivelBaseInimigos: 8,
         nomesInimigos: ["Sentinela Enferrujada", "Arqueiro Renegado", "Berserker Amaldiçoado"],
         iconeInimigos: "shield.slash.fill",
         nomeChefe: "General Caído",
         iconeChefe: "flag.checkered"),

    // Faixa 4 (nível 13+)
    Zona(nome: "Torre do Feiticeiro",
         descricao: "O covil final de um feiticeiro corrompido pelo poder.",
         icone: "sparkles",
         nivelMinimo: 13,
         nivelBaseInimigos: 13,
         nomesInimigos: ["Familiar Arcano", "Cavaleiro Amaldiçoado", "Elemental de Caos"],
         iconeInimigos: "bolt.fill",
         nomeChefe: "Arquimago Caído",
         iconeChefe: "wand.and.stars"),

    Zona(nome: "Abismo Estelar",
         descricao: "Uma fenda no mundo por onde algo de outro lugar está entrando.",
         icone: "moon.stars.fill",
         nivelMinimo: 13,
         nivelBaseInimigos: 13,
         nomesInimigos: ["Aberração do Vazio", "Guardião Estelar", "Eco Sombrio"],
         iconeInimigos: "eye.fill",
         nomeChefe: "Devorador de Mundos",
         iconeChefe: "smallcircle.filled.circle.fill")
]
