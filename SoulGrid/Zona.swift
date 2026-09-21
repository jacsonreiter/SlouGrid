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

    // Teto de quanto a zona escala pra cima do nível do herói — estilo
    // Elden Ring: inimigos não escalam pra sempre com você, só "acompanham"
    // até um limite. Sem isso, um herói bem acima do nível da zona nunca
    // sentiria que superou o lugar (o próprio "power fantasy" de voltar a
    // uma área antiga e arrasar nela desaparece); com o teto, passado esse
    // ponto a zona fica pra trás de verdade, e a recompensa (que usa o
    // mesmo `nivel`) também para de acompanhar — não compensa mais treinar
    // ali.
    private static let alcanceDeEscalaAcimaDaZona = 6

    // New Game+ (ver `Personagem.cicloNewGamePlus`): +25% de vida/força/
    // defesa/recompensa por ciclo, linear (não composto) de propósito —
    // depois de vários ciclos o número continua alto mas nunca absurdo,
    // já que o jogador pode iniciar quantos ciclos quiser em sequência.
    static func multiplicadorDeCiclo(_ ciclo: Int) -> Double {
        1.0 + Double(ciclo) * 0.25
    }

    // Defesa cresce mais rápido que antes (2×nível em vez de 1×) — o motivo
    // é puramente contra o burst de magia de alto Inteligência: antes um
    // nuke de mago no fim de jogo simplesmente ignorava a defesa e matava
    // em 1-2 golpes qualquer coisa, trivializando masmorras avançadas. Vida
    // e Força ficam como estavam: o principal reforço de perigo agora vem
    // da quantidade de inimigos por encontro (`gerarGrupoComum`), não de
    // cada um ficar individualmente mais tanque.
    func gerarInimigoComum(nivelHeroi: Int, cicloNewGamePlus: Int = 0) -> Inimigo {
        let nivel = min(nivelBaseInimigos + Zona.alcanceDeEscalaAcimaDaZona, max(nivelBaseInimigos, nivelHeroi))
        let multiplicador = Zona.multiplicadorDeCiclo(cicloNewGamePlus)
        let vida = Int(Double(24 + nivel * 11) * multiplicador)
        return Inimigo(
            nome: nomesInimigos.randomElement() ?? nome,
            icone: iconeInimigos,
            nivel: nivel,
            vidaMaxima: vida,
            vidaAtual: vida,
            forca: Int(Double(5 + nivel * 3) * multiplicador),
            defesa: Int(Double(2 + nivel * 2) * multiplicador),
            xpRecompensa: Int(Double(14 + nivel * 7) * multiplicador),
            ouroRecompensa: Int(Double(6 + nivel * 3) * multiplicador)...Int(Double(12 + nivel * 5) * multiplicador),
            chefe: false,
            zonaOrigem: nome
        )
    }

    func gerarChefe(nivelHeroi: Int, cicloNewGamePlus: Int = 0) -> Inimigo {
        let nivel = min(nivelBaseInimigos + 4 + Zona.alcanceDeEscalaAcimaDaZona, max(nivelBaseInimigos + 4, nivelHeroi + 2))
        let multiplicador = Zona.multiplicadorDeCiclo(cicloNewGamePlus)
        let vida = Int(Double(70 + nivel * 18) * multiplicador)
        return Inimigo(
            nome: nomeChefe,
            icone: iconeChefe,
            nivel: nivel,
            vidaMaxima: vida,
            vidaAtual: vida,
            forca: Int(Double(10 + nivel * 4) * multiplicador),
            defesa: Int(Double(6 + nivel * 3) * multiplicador),
            xpRecompensa: Int(Double(120 + nivel * 14) * multiplicador),
            ouroRecompensa: Int(Double(60 + nivel * 8) * multiplicador)...Int(Double(110 + nivel * 12) * multiplicador),
            chefe: true,
            zonaOrigem: nome
        )
    }

    // Grupo de inimigos comuns pra um único encontro — estilo os "camps" de
    // Elden Ring, onde áreas mais avançadas colocam vários inimigos juntos
    // em vez de só um mais forte. Quanto mais tardia a faixa da zona, maior
    // a chance de enfrentar 2 ou até 3 de uma vez: o perigo real de um
    // grupo não é a vida/força de cada um (que não mudou), é ter que
    // dividir atenção enquanto todos os que ainda estão de pé atacam a
    // cada turno.
    func gerarGrupoComum(nivelHeroi: Int, cicloNewGamePlus: Int = 0) -> [Inimigo] {
        (0..<Zona.tamanhoDoGrupo(nivelBaseInimigos: nivelBaseInimigos)).map { _ in
            gerarInimigoComum(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)
        }
    }

    private static func tamanhoDoGrupo(nivelBaseInimigos: Int) -> Int {
        let rolagem = Int.random(in: 1...100)
        switch nivelBaseInimigos {
        case ..<4: // Faixa 1
            return rolagem <= 75 ? 1 : 2
        case 4..<8: // Faixa 2
            if rolagem <= 55 { return 1 }
            if rolagem <= 95 { return 2 }
            return 3
        case 8..<13: // Faixa 3
            if rolagem <= 40 { return 1 }
            if rolagem <= 85 { return 2 }
            return 3
        default: // Faixa 4
            if rolagem <= 25 { return 1 }
            if rolagem <= 70 { return 2 }
            return 3
        }
    }

    // Um inimigo comum "inflado" para servir de field boss — mais vida,
    // força e defesa que o normal da zona, com recompensa maior, mas sem
    // contar pra vitórias do chefe nem dar Grande Rúnica.
    func gerarInimigoDeElite(nivelHeroi: Int, cicloNewGamePlus: Int = 0) -> Inimigo {
        var inimigo = gerarInimigoComum(nivelHeroi: nivelHeroi, cicloNewGamePlus: cicloNewGamePlus)
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
         nomesInimigos: ["Lobo Selvagem", "Goblin Batedor", "Aranha Gigante", "Urso Tocado pelo Vazio", "Ent Sussurrante"],
         iconeInimigos: "pawprint.fill",
         nomeChefe: "Ent Corrompido",
         iconeChefe: "tree.fill"),

    Zona(nome: "Pântano Nebuloso",
         descricao: "Um brejo enevoado onde o ar parado esconde predadores.",
         icone: "cloud.fog.fill",
         nivelMinimo: 1,
         nivelBaseInimigos: 1,
         nomesInimigos: ["Sapo Venenoso", "Vagalume Corrompido", "Ceifador de Lodo", "Sanguessuga do Vazio", "Bruxa do Brejo"],
         iconeInimigos: "ant.fill",
         nomeChefe: "Verme das Profundezas",
         iconeChefe: "tornado"),

    // Faixa 2 (nível 4+)
    Zona(nome: "Cavernas de Pedra",
         descricao: "Túneis escuros escavados por criaturas famintas.",
         icone: "mountain.2.fill",
         nivelMinimo: 4,
         nivelBaseInimigos: 4,
         nomesInimigos: ["Morcego Gigante", "Troll das Cavernas", "Esqueleto Guerreiro", "Aranha Cavernosa", "Anão Corrompido"],
         iconeInimigos: "tortoise.fill",
         nomeChefe: "Golem de Pedra",
         iconeChefe: "cube.fill"),

    Zona(nome: "Necrópole Congelada",
         descricao: "Um cemitério tomado pelo gelo eterno, onde os mortos não descansam.",
         icone: "snowflake",
         nivelMinimo: 4,
         nivelBaseInimigos: 4,
         nomesInimigos: ["Zumbi Gélido", "Arauto da Geada", "Corvo Necromante", "Espectro Gélido", "Ceifador das Sombras"],
         iconeInimigos: "figure.walk",
         nomeChefe: "Cavaleiro Gélido",
         iconeChefe: "shield.righthalf.filled"),

    // Faixa 3 (nível 8+)
    Zona(nome: "Ruínas Antigas",
         descricao: "Restos de uma civilização esquecida, guardados por magia sombria.",
         icone: "building.columns.fill",
         nivelMinimo: 8,
         nivelBaseInimigos: 8,
         nomesInimigos: ["Guardião de Pedra", "Espectro Vingativo", "Cultista Sombrio", "Estátua Desperta", "Sacerdote Caído"],
         iconeInimigos: "flame.fill",
         nomeChefe: "Lich Ancestral",
         iconeChefe: "crown.fill"),

    Zona(nome: "Fortaleza Abandonada",
         descricao: "Um forte em ruínas, ainda patrulhado por soldados renegados.",
         icone: "building.2.fill",
         nivelMinimo: 8,
         nivelBaseInimigos: 8,
         nomesInimigos: ["Sentinela Enferrujada", "Arqueiro Renegado", "Berserker Amaldiçoado", "Cão de Guerra Renegado", "Capitão Amaldiçoado"],
         iconeInimigos: "shield.slash.fill",
         nomeChefe: "General Caído",
         iconeChefe: "flag.checkered"),

    // Faixa 4 (nível 13+)
    Zona(nome: "Torre do Feiticeiro",
         descricao: "O covil final de um feiticeiro corrompido pelo poder.",
         icone: "sparkles",
         nivelMinimo: 13,
         nivelBaseInimigos: 13,
         nomesInimigos: ["Familiar Arcano", "Cavaleiro Amaldiçoado", "Elemental de Caos", "Grimório Vivo", "Espectro Arcano Instável"],
         iconeInimigos: "bolt.fill",
         nomeChefe: "Arquimago Caído",
         iconeChefe: "wand.and.stars"),

    Zona(nome: "Abismo Estelar",
         descricao: "Uma fenda no mundo por onde algo de outro lugar está entrando.",
         icone: "moon.stars.fill",
         nivelMinimo: 13,
         nivelBaseInimigos: 13,
         nomesInimigos: ["Aberração do Vazio", "Guardião Estelar", "Eco Sombrio", "Devorador Menor", "Fragmento Consciente"],
         iconeInimigos: "eye.fill",
         nomeChefe: "Devorador de Mundos",
         iconeChefe: "smallcircle.filled.circle.fill")
]
