import Foundation

// Os seis atributos em que o jogador investe pontos ao subir de nível —
// inspirados no clássico STR/AGI/VIT/INT/DEX/LUK (Ragnarok Online e afins).
// Cada um tem um papel único em combate (ver os computeds de `Personagem`
// logo abaixo), para que não exista "atributo inútil".
enum AtributoPrimario: String, CaseIterable {
    case forca = "Força"
    case vitalidade = "Vitalidade"
    case inteligencia = "Inteligência"
    case destreza = "Destreza"
    case agilidade = "Agilidade"
    case sorte = "Sorte"
}

struct Personagem: Codable {
    var id: UUID = UUID()
    var nome: String
    var classe: ClasseDePersonagem
    var vidaAtual: Int
    var vidaMaxima: Int
    var forca: Int
    var vitalidade: Int
    var inteligencia: Int
    var destreza: Int
    var agilidade: Int
    var sorte: Int
    var energiaAtual: Int
    var energiaMaximaBase: Int
    // Chamado de "Runas" na UI (estilo Elden Ring): a mesma moeda compra no
    // mercado E paga cada ponto de atributo alocado (`confirmarEvolucao`) —
    // não são duas moedas separadas. O nome do campo continua `ouro` só para
    // não precisar migrar saves antigos.
    var ouro: Int = 0
    // Nível é derivado, não guardado: cada 5 pontos de atributo confirmados
    // (qualquer combinação, ver `confirmarEvolucao`) rendem +1 nível — a
    // mesma curva de progressão de antes (evoluir dava 5 pontos por nível),
    // só que sem o passo intermediário de "evoluir" separado de "gastar o
    // ponto".
    var pontosTotaisComprados: Int = 0
    var nivel: Int {
        1 + pontosTotaisComprados / 5
    }
    var inventario: [PilhaDeItens] = []
    var armaEquipada: Item? = nil
    var armaduraEquipada: Item? = nil
    // 3 slots de talismã (estilo Elden Ring): cada um pode levar tanto um
    // acessório de atributo puro quanto um talismã de efeito passivo (ver
    // `BonusDeAtributos`) — a mesma peça nunca faz as duas coisas de graça.
    var acessoriosEquipados: [Item?] = Array(repeating: nil, count: Personagem.numeroDeSlotsDeAcessorio)
    var progressoZonas: [String: Int] = [:]
    var slotsDeMagias: [String] = []   // nomes das magias equipadas na barra de combate ("" = slot vazio)

    // Frasco Sagrado (estilo Estus Flask/Elden Ring): cargas gratuitas de
    // cura/energia, recarregam só ao `descansar()`. A quantidade de cargas
    // cresce achando Sementes Douradas; a potência (cura/turno) cresce
    // achando Lágrimas Sagradas — são upgrades separados, como em Elden
    // Ring. A alocação entre Vida e Energia é livre e instantânea (ver
    // `realocarFrascos`), só as cargas atuais é que precisam recarregar.
    var cargasDeFrascoTotal: Int = 3
    var frascosDeVidaAlocados: Int = 2
    var frascosDeEnergiaAlocados: Int = 1
    var frascosDeVidaAtuais: Int = 2
    var frascosDeEnergiaAtuais: Int = 1
    var potenciaDoFrasco: Int = 0   // % extra somado à cura/restauração base de cada uso

    // Grande Rúnica (estilo Elden Ring): conquistada ao derrotar o chefe de
    // uma zona pela primeira vez. Só uma fica ativa por vez — trocar exige
    // descansar (`runicaSelecionada` vira `runicaEquipadaAtiva` só depois).
    var runicasConquistadas: Set<String> = []
    var runicaSelecionada: String? = nil
    var runicaEquipadaAtiva: String? = nil

    // Sequência de exploração: cada vitória ou descoberta sem descansar soma
    // 1, e reseta ao descansar ou ser derrotado. Cada ponto aumenta as
    // Runas ganhas (`bonusDeSequenciaPercentual`) — a tensão de "arriscar
    // mais uma masmorra pela recompensa maior, ou recuar pra descansar com
    // segurança" que jogos roguelike (Hades, Diablo) usam pra dar peso a
    // continuar jogando em vez de parar a qualquer momento.
    var sequenciaDeExploracao: Int = 0

    // Missões já entregues na Vila (ver `Missao`/`PNJ`/`TelaDaVila`) — só
    // essa chave precisa ser salva. O progresso em si nunca é um contador
    // novo: `statusDaMissao` reaproveita `progressoZonas` (caçada) e
    // `runicasConquistadas` (chefe), que o herói já guardava por outro
    // motivo, então uma missão nunca "perde" progresso feito antes dela
    // existir ou antes do jogador visitar a Vila pela primeira vez.
    var missoesEntregues: Set<String> = []

    // New Game+ (estilo Elden Ring): em vez de expandir o mundo pra sempre
    // com mais níveis/zonas/vilas, depois de completar a trama principal
    // ("O Selo Final", nível 40) o jogador pode iniciar um novo ciclo —
    // o personagem, equipamento, Runas e progresso continuam exatamente
    // como estavam, só o mundo (força/vida/defesa/recompensa de todo
    // inimigo, ver `Zona.multiplicadorDeCiclo`) fica mais difícil e mais
    // generoso. Escolhido no lugar de criar mundos 2/3/4 porque escala
    // indefinidamente sem precisar de conteúdo novo pra cada faixa de
    // nível, e é fiel ao próprio jogo em que o projeto se inspira.
    var cicloNewGamePlus: Int = 0

    // Maestria de Arma (estilo Mastery de Melvor Idle): nome da arma →
    // quantos golpes já foram acertados com ela equipada, ao longo de toda
    // a carreira do herói. Puramente aditivo — nunca esquece, nunca reseta
    // ao trocar de arma e voltar — então dominar uma build específica vira
    // uma recompensa de longo prazo por si só, sem depender de sorte de
    // loot nem custar Runas (ver `nivelDeMaestriaArmaAtual`).
    var maestriaDeArmas: [String: Int] = [:]

    static let numeroDeSlotsDeMagia = 3
    static let numeroDeSlotsDeAcessorio = 3
    // Limites do Frasco Sagrado: sem teto, Sementes/Lágrimas compradas ou
    // achadas sem parar deixariam o herói praticamente imortal. Com um
    // total fixo de cargas pra distribuir e uma potência máxima, o upgrade
    // continua valioso (permite escolher Vida vs. Energia) sem quebrar o
    // combate.
    static let cargasDeFrascoMaximo = 12
    static let potenciaDoFrascoMaxima = 100
    // Teto de cada um dos 6 atributos, estilo Elden Ring (Vigor/Mente/
    // Fortitude/Força/Destreza/Inteligência/Fé/Arcano todos vão até 99, nunca
    // mais) — sem isso, Runas o bastante deixavam um atributo crescer pra
    // sempre, o que não é "build", é só "quem farmou mais". Com o teto, a
    // decisão de build vira genuinamente ONDE investir os pontos, não SE dá
    // pra continuar empilhando um atributo só.
    static let atributoMaximo = 99

    init(nome: String, classe: ClasseDePersonagem) {
        self.id = UUID()
        self.nome = nome
        self.classe = classe
        self.forca = classe.forcaBase
        self.vitalidade = classe.vitalidadeBase
        self.inteligencia = classe.inteligenciaBase
        self.destreza = classe.destrezaBase
        self.agilidade = classe.agilidadeBase
        self.sorte = classe.sorteBase
        self.vidaMaxima = 0
        self.vidaAtual = 0
        self.energiaMaximaBase = 0
        self.energiaAtual = 0
        self.ouro = 25
        self.inventario = [PilhaDeItens(item: Item.catalogoMercado[0], quantidade: 2)]

        // Já começa com a primeira magia da classe equipada no primeiro slot.
        var slots = Array(repeating: "", count: Personagem.numeroDeSlotsDeMagia)
        slots[0] = classe.grimorio.first?.nome ?? ""
        self.slotsDeMagias = slots

        recalcularMaximos()
        vidaAtual = vidaMaxima
        energiaAtual = energiaMaximaTotal
    }

    // CodingKeys explícito por causa de duas chaves legadas:
    // `acessorioEquipadoLegado` (o `acessorioEquipado` de antes dos 3 slots
    // de talismã) e `nivelLegado` (o `nivel` de antes dele virar computed a
    // partir de `pontosTotaisComprados`). Sem essas chaves não haveria como
    // ler os valores salvos por versões anteriores do app na migração abaixo.
    enum CodingKeys: String, CodingKey {
        case id, nome, classe, vidaAtual, vidaMaxima, forca, vitalidade, inteligencia,
             destreza, agilidade, sorte, energiaAtual, energiaMaximaBase, ouro,
             inventario, armaEquipada, armaduraEquipada, acessoriosEquipados, progressoZonas,
             slotsDeMagias, pontosTotaisComprados,
             cargasDeFrascoTotal, frascosDeVidaAlocados, frascosDeEnergiaAlocados,
             frascosDeVidaAtuais, frascosDeEnergiaAtuais, potenciaDoFrasco,
             runicasConquistadas, runicaSelecionada, runicaEquipadaAtiva,
             sequenciaDeExploracao, missoesEntregues, cicloNewGamePlus, maestriaDeArmas
        case acessorioEquipadoLegado = "acessorioEquipado"
        case nivelLegado = "nivel"
    }

    // Decodificação tolerante: heróis salvos antes de um campo existir (como
    // os atributos Vitalidade/Destreza/Sorte, adicionados quando o sistema
    // de Defesa fixa virou o sistema de 6 atributos) continuam carregando
    // normalmente, caindo no valor base da classe em vez de perder o save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        nome = try c.decode(String.self, forKey: .nome)
        classe = try c.decode(ClasseDePersonagem.self, forKey: .classe)

        // Migração: saves antigos guardavam `nivel` direto. Agora ele é
        // derivado de `pontosTotaisComprados` (ver o computed acima) — um
        // save antigo no nível N vira (N-1)*5 pontos comprados, preservando
        // o nível (e portanto o que está desbloqueado) exatamente igual.
        if let pontos = try c.decodeIfPresent(Int.self, forKey: .pontosTotaisComprados) {
            pontosTotaisComprados = pontos
        } else {
            let nivelAntigo = try c.decodeIfPresent(Int.self, forKey: .nivelLegado) ?? 1
            pontosTotaisComprados = max(0, (nivelAntigo - 1) * 5)
        }

        vidaAtual = try c.decode(Int.self, forKey: .vidaAtual)
        vidaMaxima = try c.decode(Int.self, forKey: .vidaMaxima)
        forca = try c.decode(Int.self, forKey: .forca)
        vitalidade = try c.decodeIfPresent(Int.self, forKey: .vitalidade) ?? classe.vitalidadeBase
        inteligencia = try c.decodeIfPresent(Int.self, forKey: .inteligencia) ?? classe.inteligenciaBase
        destreza = try c.decodeIfPresent(Int.self, forKey: .destreza) ?? classe.destrezaBase
        agilidade = try c.decodeIfPresent(Int.self, forKey: .agilidade) ?? classe.agilidadeBase
        sorte = try c.decodeIfPresent(Int.self, forKey: .sorte) ?? classe.sorteBase
        energiaAtual = try c.decode(Int.self, forKey: .energiaAtual)
        energiaMaximaBase = try c.decode(Int.self, forKey: .energiaMaximaBase)
        ouro = try c.decodeIfPresent(Int.self, forKey: .ouro) ?? 0
        inventario = try c.decodeIfPresent([PilhaDeItens].self, forKey: .inventario) ?? []
        armaEquipada = try c.decodeIfPresent(Item.self, forKey: .armaEquipada) ?? nil
        armaduraEquipada = try c.decodeIfPresent(Item.self, forKey: .armaduraEquipada) ?? nil

        if var slots = try c.decodeIfPresent([Item?].self, forKey: .acessoriosEquipados) {
            while slots.count < Personagem.numeroDeSlotsDeAcessorio { slots.append(nil) }
            acessoriosEquipados = slots
        } else {
            // Save de antes dos 3 slots: o único acessório antigo vira o
            // primeiro slot, os outros dois começam vazios.
            acessoriosEquipados = Array(repeating: nil, count: Personagem.numeroDeSlotsDeAcessorio)
            acessoriosEquipados[0] = try c.decodeIfPresent(Item.self, forKey: .acessorioEquipadoLegado) ?? nil
        }
        progressoZonas = try c.decodeIfPresent([String: Int].self, forKey: .progressoZonas) ?? [:]

        if let slots = try c.decodeIfPresent([String].self, forKey: .slotsDeMagias) {
            slotsDeMagias = slots
        } else {
            var slots = Array(repeating: "", count: Personagem.numeroDeSlotsDeMagia)
            slots[0] = classe.grimorio.first?.nome ?? ""
            slotsDeMagias = slots
        }

        cargasDeFrascoTotal = try c.decodeIfPresent(Int.self, forKey: .cargasDeFrascoTotal) ?? 3
        frascosDeVidaAlocados = try c.decodeIfPresent(Int.self, forKey: .frascosDeVidaAlocados) ?? 2
        frascosDeEnergiaAlocados = try c.decodeIfPresent(Int.self, forKey: .frascosDeEnergiaAlocados) ?? 1
        frascosDeVidaAtuais = try c.decodeIfPresent(Int.self, forKey: .frascosDeVidaAtuais) ?? frascosDeVidaAlocados
        frascosDeEnergiaAtuais = try c.decodeIfPresent(Int.self, forKey: .frascosDeEnergiaAtuais) ?? frascosDeEnergiaAlocados
        potenciaDoFrasco = try c.decodeIfPresent(Int.self, forKey: .potenciaDoFrasco) ?? 0

        runicasConquistadas = try c.decodeIfPresent(Set<String>.self, forKey: .runicasConquistadas) ?? []
        runicaSelecionada = try c.decodeIfPresent(String.self, forKey: .runicaSelecionada) ?? nil
        runicaEquipadaAtiva = try c.decodeIfPresent(String.self, forKey: .runicaEquipadaAtiva) ?? nil
        sequenciaDeExploracao = try c.decodeIfPresent(Int.self, forKey: .sequenciaDeExploracao) ?? 0
        missoesEntregues = try c.decodeIfPresent(Set<String>.self, forKey: .missoesEntregues) ?? []
        cicloNewGamePlus = try c.decodeIfPresent(Int.self, forKey: .cicloNewGamePlus) ?? 0
        maestriaDeArmas = try c.decodeIfPresent([String: Int].self, forKey: .maestriaDeArmas) ?? [:]
    }

    // Escrito à mão porque o `CodingKeys` tem chaves extras
    // (`acessorioEquipadoLegado`, `nivelLegado`) sem propriedade
    // correspondente, usadas só para migração na leitura — o que impede a
    // síntese automática de `encode(to:)`.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(nome, forKey: .nome)
        try c.encode(classe, forKey: .classe)
        try c.encode(pontosTotaisComprados, forKey: .pontosTotaisComprados)
        try c.encode(vidaAtual, forKey: .vidaAtual)
        try c.encode(vidaMaxima, forKey: .vidaMaxima)
        try c.encode(forca, forKey: .forca)
        try c.encode(vitalidade, forKey: .vitalidade)
        try c.encode(inteligencia, forKey: .inteligencia)
        try c.encode(destreza, forKey: .destreza)
        try c.encode(agilidade, forKey: .agilidade)
        try c.encode(sorte, forKey: .sorte)
        try c.encode(energiaAtual, forKey: .energiaAtual)
        try c.encode(energiaMaximaBase, forKey: .energiaMaximaBase)
        try c.encode(ouro, forKey: .ouro)
        try c.encode(inventario, forKey: .inventario)
        try c.encode(armaEquipada, forKey: .armaEquipada)
        try c.encode(armaduraEquipada, forKey: .armaduraEquipada)
        try c.encode(acessoriosEquipados, forKey: .acessoriosEquipados)
        try c.encode(progressoZonas, forKey: .progressoZonas)
        try c.encode(slotsDeMagias, forKey: .slotsDeMagias)
        try c.encode(cargasDeFrascoTotal, forKey: .cargasDeFrascoTotal)
        try c.encode(frascosDeVidaAlocados, forKey: .frascosDeVidaAlocados)
        try c.encode(frascosDeEnergiaAlocados, forKey: .frascosDeEnergiaAlocados)
        try c.encode(frascosDeVidaAtuais, forKey: .frascosDeVidaAtuais)
        try c.encode(frascosDeEnergiaAtuais, forKey: .frascosDeEnergiaAtuais)
        try c.encode(potenciaDoFrasco, forKey: .potenciaDoFrasco)
        try c.encode(runicasConquistadas, forKey: .runicasConquistadas)
        try c.encode(runicaSelecionada, forKey: .runicaSelecionada)
        try c.encode(runicaEquipadaAtiva, forKey: .runicaEquipadaAtiva)
        try c.encode(sequenciaDeExploracao, forKey: .sequenciaDeExploracao)
        try c.encode(missoesEntregues, forKey: .missoesEntregues)
        try c.encode(cicloNewGamePlus, forKey: .cicloNewGamePlus)
        try c.encode(maestriaDeArmas, forKey: .maestriaDeArmas)
    }

    var estaVivo: Bool {
        vidaAtual > 0
    }

    // Cada equipamento pode contribuir bônus em qualquer atributo (ver
    // `BonusDeAtributos`), então o total soma arma + armadura + os talismãs
    // equipados nos 3 slots de acessório.
    private var itensEquipados: [Item] {
        [armaEquipada, armaduraEquipada].compactMap { $0 } + acessoriosEquipados.compactMap { $0 }
    }

    // Todo bônus ativo agora, de qualquer fonte: equipamento + a Grande
    // Rúnica atual (se houver uma ativa). Ponto único de junção — qualquer
    // atributo/derivado que precise somar bônus passa por aqui, então a
    // Rúnica automaticamente "conta" em tudo que o equipamento já conta.
    private var bonusAtivos: [BonusDeAtributos] {
        itensEquipados.map { $0.bonusEvoluido } + [bonusDeRunicaAtiva]
    }

    var forcaTotal: Int {
        forca + bonusAtivos.reduce(0) { $0 + $1.forca }
    }

    var vitalidadeTotal: Int {
        vitalidade + bonusAtivos.reduce(0) { $0 + $1.vitalidade }
    }

    var inteligenciaTotal: Int {
        inteligencia + bonusAtivos.reduce(0) { $0 + $1.inteligencia }
    }

    var destrezaTotal: Int {
        destreza + bonusAtivos.reduce(0) { $0 + $1.destreza }
    }

    var agilidadeTotal: Int {
        agilidade + bonusAtivos.reduce(0) { $0 + $1.agilidade }
    }

    var sorteTotal: Int {
        sorte + bonusAtivos.reduce(0) { $0 + $1.sorte }
    }

    var energiaMaximaTotal: Int {
        energiaMaximaBase + bonusAtivos.reduce(0) { $0 + $1.energia }
    }

    // Defesa não é mais um atributo próprio: é Vitalidade (a resistência
    // física do personagem) somada à proteção direta do equipamento.
    var defesaTotal: Int {
        vitalidadeTotal + bonusAtivos.reduce(0) { $0 + $1.defesa }
    }

    // MARK: - Talismãs e Grande Rúnica (efeitos passivos)

    var regenVidaPorTurno: Int {
        bonusAtivos.reduce(0) { $0 + $1.regenVidaPorTurno }
    }

    var regenEnergiaPorTurno: Int {
        bonusAtivos.reduce(0) { $0 + $1.regenEnergiaPorTurno }
    }

    var bonusOuroPercentualTotal: Int {
        bonusAtivos.reduce(0) { $0 + $1.bonusOuroPercentual }
    }

    // Segunda vertente da Sorte (além do crítico, ver `chanceDeCriticoBasico`)
    // — sem teto formal (o `min(100, ...)` de cada rolagem de loot já cuida
    // disso), então continua valendo a pena investir mesmo depois do
    // crítico saturar. Puro tema de LUK: sorte também é sobre o que você
    // encontra, não só sobre acertar o golpe.
    var bonusChanceDeItemTotal: Int {
        bonusAtivos.reduce(0) { $0 + $1.bonusChanceDeItemPercentual } + sorteTotal / 4
    }

    var bonusRaridadeDeItemTotal: Int {
        bonusAtivos.reduce(0) { $0 + $1.bonusRaridadeDeItem } + sorteTotal / 40
    }

    // Bônus concedido pela Grande Rúnica atualmente ativa (vazio se nenhuma
    // estiver ativa, ou enquanto uma nova selecionada aguarda descanso).
    var bonusDeRunicaAtiva: BonusDeAtributos {
        guard let nome = runicaEquipadaAtiva else { return BonusDeAtributos() }
        return Personagem.bonusDaRunica(zona: nome)
    }

    // Tabela de bônus por zona — cada Grande Rúnica é temática à zona que a
    // concedeu, crescendo em poder conforme a faixa de nível da zona fica
    // mais tardia no jogo, igual às Great Runes de Elden Ring (Godrick <
    // Radahn/Rykard/Mohg). Toda zona nova em `Zona.swift` precisa de um case
    // aqui, senão o chefe dela não concede bônus nenhum.
    static func bonusDaRunica(zona: String) -> BonusDeAtributos {
        switch zona {
        // Faixa 1 (nível 1+)
        case "Floresta Sombria":
            return BonusDeAtributos(forca: 4, vitalidade: 4)
        case "Pântano Nebuloso":
            return BonusDeAtributos(destreza: 4, sorte: 4)
        // Faixa 2 (nível 4+)
        case "Cavernas de Pedra":
            return BonusDeAtributos(vitalidade: 6, defesa: 4)
        case "Necrópole Congelada":
            return BonusDeAtributos(vitalidade: 5, agilidade: 3, regenVidaPorTurno: 2)
        // Faixa 3 (nível 8+)
        case "Ruínas Antigas":
            return BonusDeAtributos(inteligencia: 8, regenEnergiaPorTurno: 2)
        case "Fortaleza Abandonada":
            return BonusDeAtributos(forca: 6, destreza: 4)
        // Faixa 4 (nível 13+)
        case "Torre do Feiticeiro":
            return BonusDeAtributos(forca: 5, inteligencia: 5, agilidade: 5, regenVidaPorTurno: 3)
        case "Abismo Estelar":
            return BonusDeAtributos(inteligencia: 6, sorte: 6, regenEnergiaPorTurno: 3)
        default:
            return BonusDeAtributos()
        }
    }

    // Retorno decrescente genérico pra atributos que regem uma % de
    // chance (acerto/crítico/esquiva) — mesma filosofia de
    // `valorEfetivoDeDano` (valor cheio até o 1º patamar, metade até o
    // 2º, um quinto depois), só que parametrizável, já que cada uma
    // dessas 3 fórmulas tem uma faixa de % bem menor pra trabalhar (no
    // máximo uns 15-95 pontos percentuais) do que o dano tem.
    //
    // Existia antes só como um teto absoluto (`min(98, 85 + Destreza/2)`
    // etc.) — Destreza saturava com só 26 pontos, Sorte com uns 55, e
    // depois disso QUALQUER ponto a mais virava puro desperdício. Bom
    // pro jogador nunca perceber (o menu de evolução não avisa "esse
    // atributo já não faz mais nada"), péssimo pra build: o sistema de
    // custo cúbico até o 99 (ver `custoEmRunas`) só faz sentido se todo
    // atributo continuar valendo alguma coisa até lá — com um teto
    // absoluto batido cedo, ninguém jamais investiria em Destreza/Sorte
    // além do mínimo, travando a build de qualquer classe no mesmo
    // padrão "acerto/crítico no básico, resto tudo no atributo
    // principal".
    static func valorEfetivoDeChance(_ bruto: Int, primeiroPatamar: Int, segundoPatamar: Int) -> Double {
        if bruto <= primeiroPatamar {
            return Double(bruto)
        }
        if bruto <= segundoPatamar {
            return Double(primeiroPatamar) + Double(bruto - primeiroPatamar) * 0.5
        }
        let atePrimeiroESegundo = Double(primeiroPatamar) + Double(segundoPatamar - primeiroPatamar) * 0.5
        return atePrimeiroESegundo + Double(bruto - segundoPatamar) * 0.2
    }

    // Sorte é quem mais rege o crítico (como LUK no Ragnarok); Agilidade
    // contribui um pouco, mantendo o Ladino "ágil e certeiro" mesmo sem
    // investir tudo em Sorte. Sorte sozinha (sem Agilidade nenhuma) sobe
    // de 5% no zero até ~49% perto do 99 — nunca satura de vez.
    var chanceDeCriticoBasico: Int {
        let sorteEfetiva = Personagem.valorEfetivoDeChance(sorteTotal, primeiroPatamar: 20, segundoPatamar: 50)
        return min(60, 5 + Int(sorteEfetiva) + agilidadeTotal / 4)
    }

    // Agilidade rege a esquiva (como AGI/FLEE); Sorte contribui um pouco
    // (a "esquiva perfeita" do LUK).
    var chanceDeEsquiva: Int {
        let agilidadeEfetiva = Personagem.valorEfetivoDeChance(agilidadeTotal, primeiroPatamar: 35, segundoPatamar: 70)
        return min(35, Int(agilidadeEfetiva / 1.6) + sorteTotal / 6)
    }

    // Destreza rege a chance de acerto — física e mágica. Sem nenhum ponto
    // investido o herói ainda acerta a maior parte das vezes (85%): errar
    // é o "tempero" de não investir em Destreza, não uma punição severa.
    // A faixa inteira (85%→99%) só se completa perto do 99 de Destreza —
    // antes saturava com só 26.
    var chanceDeAcerto: Int {
        let destrezaEfetiva = Personagem.valorEfetivoDeChance(destrezaTotal, primeiroPatamar: 25, segundoPatamar: 80)
        return min(99, 85 + Int(destrezaEfetiva / 3.9))
    }

    // O atributo que "alimenta" o recurso de combate da classe: Vitalidade
    // para quem luta corpo a corpo (Fôlego do Guerreiro, Foco do Ladino —
    // resistência física, como a Endurance/Stamina em jogos como Dark
    // Souls), Inteligência para o Mago (reserva arcana de Mana).
    private var totalDoAtributoDoRecurso: Int {
        switch classe {
        case .mago: return inteligenciaTotal
        case .guerreiro, .ladino: return vitalidadeTotal
        }
    }

    // Vida máxima = base da classe/nível + Vitalidade (com equipamento).
    // Recurso máximo = base da classe/nível + o atributo que rege o
    // recurso dessa classe. Como isso pode mudar tanto ao gastar pontos
    // quanto ao trocar de equipamento, é recalculado nos dois casos,
    // preservando a vida/energia atuais (só a diferença é somada).
    private mutating func recalcularMaximos() {
        let novaVidaMaxima = classe.vidaBase + (nivel - 1) * classe.vidaBasePorNivel + vitalidadeTotal * 3
        vidaAtual += novaVidaMaxima - vidaMaxima
        vidaMaxima = novaVidaMaxima

        let novaEnergiaMaximaBase = classe.energiaBase + (nivel - 1) * classe.energiaBasePorNivel + totalDoAtributoDoRecurso * 2
        energiaAtual += novaEnergiaMaximaBase - energiaMaximaBase
        energiaMaximaBase = novaEnergiaMaximaBase
    }

    // A partir de qual total de pontos comprados o custo de Runas passa a
    // escalar em cubo (ver `custoEmRunas`) — 300 pontos = nível 61, bem
    // depois do fim d'"O Selo Final" (nível 40). Tudo abaixo disso é jogo
    // normal e não muda em nada.
    static let limiarDeEscaladaDeCusto = 300

    // Custo em Runas do próximo ponto — estilo Elden Ring de verdade: o
    // preço depende de quantos pontos você já tem NO TOTAL (ou seja, do seu
    // nível), nunca de qual atributo está sendo melhorado. Custa exatamente
    // o mesmo comprar o 1º ponto de Força ou o 1º ponto de Sorte no mesmo
    // nível — e o mesmo pra investir tudo numa coisa só ou espalhar. A
    // escolha de onde investir é só sobre a build, nunca sobre "qual tá mais
    // barato agora" (esse soft cap por atributo existia antes; não existe
    // mais, de propósito).
    //
    // A curva real de Runas de Elden Ring é cúbica (nível 1→713 custa 1,69
    // bilhão de Runas no total, sendo suave até uns 70-80 níveis e só
    // "explodindo" depois disso — é por isso que chegar em 99 em TUDO
    // custa uma fortuna desproporcional, apesar de cada atributo isolado
    // não parecer tão alto). Sem isso, o teto de 99 por atributo (ver
    // `atributoMaximo`) virava alcançável cedo demais, e "personagem com
    // tudo no máximo" deixava de ser uma escolha de build rara pra virar
    // só o estado final óbvio de qualquer um. Replicamos a MESMA forma:
    // linear (sem mudar em nada) até `limiarDeEscaladaDeCusto`, cúbica daí
    // pra frente — chegar no nível 40 da trama principal continua custando
    // exatamente o mesmo de antes; chegar nos 99 em tudo (nível 111) passa
    // a custar ~1,4 milhão de Runas no total, uma meta de NG+ avançado.
    static func custoEmRunas(pontosTotaisComprados: Int) -> Int {
        let custoBase = (1 + pontosTotaisComprados / 10) * 20
        guard pontosTotaisComprados > limiarDeEscaladaDeCusto else { return custoBase }
        let excedente = pontosTotaisComprados - limiarDeEscaladaDeCusto
        let sobretaxaCubica = (excedente * excedente * excedente) / 900
        return custoBase + sobretaxaCubica
    }

    // Custo do próximo ponto considerando pontos já alocados nesta sessão de
    // evolução, ainda não confirmados — cada um sobe o "nível provisório",
    // então o seguinte já sai mais caro, exatamente como no menu de nível de
    // Elden Ring antes de apertar Confirmar.
    func custoDoProximoPonto(pontosPendentes: Int) -> Int {
        Personagem.custoEmRunas(pontosTotaisComprados: pontosTotaisComprados + pontosPendentes)
    }

    // Custo total pra confirmar N pontos pendentes de uma vez — soma o custo
    // de cada um, um de cada vez, já que cada ponto encarece o próximo.
    func custoTotal(pontosPendentes: Int) -> Int {
        guard pontosPendentes > 0 else { return 0 }
        var total = 0
        for i in 0..<pontosPendentes {
            total += custoDoProximoPonto(pontosPendentes: i)
        }
        return total
    }

    // Nível que o personagem teria após confirmar N pontos pendentes — pra
    // pré-visualizar "Nível X → Y" antes de gastar as Runas de verdade.
    func nivelPrevisto(comPontosPendentes pontosPendentes: Int) -> Int {
        1 + (pontosTotaisComprados + pontosPendentes) / 5
    }

    func valor(de atributo: AtributoPrimario) -> Int {
        switch atributo {
        case .forca: return forca
        case .vitalidade: return vitalidade
        case .inteligencia: return inteligencia
        case .destreza: return destreza
        case .agilidade: return agilidade
        case .sorte: return sorte
        }
    }

    // Total do atributo incluindo bônus de equipamento — o mesmo valor
    // usado em combate.
    func totalDe(_ atributo: AtributoPrimario) -> Int {
        switch atributo {
        case .forca: return forcaTotal
        case .vitalidade: return vitalidadeTotal
        case .inteligencia: return inteligenciaTotal
        case .destreza: return destrezaTotal
        case .agilidade: return agilidadeTotal
        case .sorte: return sorteTotal
        }
    }

    // Aplica de uma vez todos os pontos alocados numa sessão de evolução e
    // paga o custo total — exatamente como apertar "Confirmar" no menu de
    // nível de Elden Ring. É tudo ou nada: se faltarem Runas pro total, nada
    // é gasto nem alterado (o jogador ajusta a alocação e tenta de novo).
    mutating func confirmarEvolucao(_ alocacoes: [AtributoPrimario: Int]) -> String {
        let totalDePontos = alocacoes.values.reduce(0, +)
        guard totalDePontos > 0 else {
            return "Nenhum ponto alocado ainda."
        }
        for (atributo, pontos) in alocacoes where pontos > 0 {
            guard valor(de: atributo) + pontos <= Personagem.atributoMaximo else {
                return "\(atributo.rawValue) não pode passar de \(Personagem.atributoMaximo)."
            }
        }
        let custo = custoTotal(pontosPendentes: totalDePontos)
        guard ouro >= custo else {
            return "Runas insuficientes! Confirmar essa evolução custaria \(custo) Runas."
        }
        ouro -= custo
        for (atributo, pontos) in alocacoes where pontos > 0 {
            switch atributo {
            case .forca: forca += pontos
            case .vitalidade: vitalidade += pontos
            case .inteligencia: inteligencia += pontos
            case .destreza: destreza += pontos
            case .agilidade: agilidade += pontos
            case .sorte: sorte += pontos
            }
        }
        pontosTotaisComprados += totalDePontos
        recalcularMaximos()
        return "Evolução confirmada! +\(totalDePontos) \(totalDePontos == 1 ? "ponto" : "pontos"), agora nível \(nivel)."
    }

    // Descansar é o "Site of Grace" do SoulGrid: recupera vida/energia,
    // recarrega as cargas do Frasco Sagrado e ativa a Grande Rúnica
    // selecionada (se for diferente da que já estava ativa). Também zera a
    // sequência de exploração — descansar é a opção seguindo, então abre
    // mão do bônus acumulado em troca de recomeçar do zero sem risco.
    mutating func descansar() {
        if runicaSelecionada != runicaEquipadaAtiva {
            runicaEquipadaAtiva = runicaSelecionada
        }
        recalcularMaximos()
        vidaAtual = vidaMaxima
        energiaAtual = energiaMaximaTotal
        frascosDeVidaAtuais = frascosDeVidaAlocados
        frascosDeEnergiaAtuais = frascosDeEnergiaAlocados
        sequenciaDeExploracao = 0
    }

    // +4% de Runas por ponto de sequência de exploração, até +40% no topo
    // (sequência 10) — não escala pra sempre, senão a sequência dominaria
    // completamente a economia do jogo.
    var bonusDeSequenciaPercentual: Int {
        min(40, sequenciaDeExploracao * 4)
    }

    // MARK: - Frasco Sagrado

    // Potência base de cada frasco (% da vida/energia máxima), antes das
    // Lágrimas Sagradas (`potenciaDoFrasco`) — separado da quantidade de
    // cargas (Sementes Douradas), exatamente como em Elden Ring.
    mutating func usarFrascoDeVida() -> String {
        guard frascosDeVidaAtuais > 0 else {
            return "Seu Frasco de Vida está vazio! Descanse para recarregar."
        }
        frascosDeVidaAtuais -= 1
        let percentual = 35 + potenciaDoFrasco
        let cura = max(1, vidaMaxima * percentual / 100)
        vidaAtual = min(vidaMaxima, vidaAtual + cura)
        return "Você bebeu do Frasco Sagrado e recuperou \(cura) de vida! (\(frascosDeVidaAtuais)/\(frascosDeVidaAlocados) cargas restantes)"
    }

    mutating func usarFrascoDeEnergia() -> String {
        guard frascosDeEnergiaAtuais > 0 else {
            return "Seu Frasco de \(classe.nomeDoRecurso) está vazio! Descanse para recarregar."
        }
        frascosDeEnergiaAtuais -= 1
        let percentual = 30 + potenciaDoFrasco
        let restaurado = max(1, energiaMaximaTotal * percentual / 100)
        energiaAtual = min(energiaMaximaTotal, energiaAtual + restaurado)
        return "Você bebeu do Frasco Sagrado e recuperou \(restaurado) de \(classe.nomeDoRecurso.lowercased())! (\(frascosDeEnergiaAtuais)/\(frascosDeEnergiaAlocados) cargas restantes)"
    }

    // Redistribui livremente (e instantaneamente) as cargas totais entre os
    // dois frascos — como o menu de frascos de Elden Ring nos Sites of Grace.
    mutating func realocarFrascos(vida: Int, energia: Int) -> String {
        guard vida >= 0, energia >= 0, vida + energia == cargasDeFrascoTotal else {
            return "A soma precisa ser exatamente \(cargasDeFrascoTotal) cargas."
        }
        frascosDeVidaAlocados = vida
        frascosDeEnergiaAlocados = energia
        frascosDeVidaAtuais = min(frascosDeVidaAtuais, vida)
        frascosDeEnergiaAtuais = min(frascosDeEnergiaAtuais, energia)
        return "Frascos realocados: \(vida) de Vida, \(energia) de \(classe.nomeDoRecurso)."
    }

    // MARK: - Grande Rúnica

    // Escolhe qual Grande Rúnica conquistada fica ativa — só passa a valer
    // de verdade depois do próximo `descansar()`.
    mutating func selecionarRunica(_ novaRunica: String?) -> String {
        guard let nome = novaRunica else {
            runicaSelecionada = nil
            return "Nenhuma Grande Rúnica selecionada. Descanse para desativar a atual."
        }
        guard runicasConquistadas.contains(nome) else {
            return "Você ainda não conquistou a Grande Rúnica de \(nome)."
        }
        runicaSelecionada = nome
        return "Grande Rúnica de \(nome) selecionada! Descanse para ativá-la."
    }

    // MARK: - Combate por turnos

    // Quanto um ponto investido no atributo de dano (Força/Inteligência/
    // Agilidade, dependendo da classe/magia) realmente vale em combate —
    // dois patamares de retorno decrescente, estilo os soft caps de Elden
    // Ring (Vigor 40/60, Força/Destreza 54/80 etc.): valor cheio até o
    // primeiro patamar, metade do valor até o segundo, um quinto depois
    // disso. Isso é só sobre o quanto cada ponto CONTA no dano — o custo
    // pra comprar o ponto (`custoEmRunas`) continua igual pra qualquer
    // atributo, então focar tudo numa coisa só sempre dá mais dano puro que
    // espalhar, mas com retorno cada vez menor, não crescimento linear pra
    // sempre. Acerto/esquiva/crítico não precisam disso: já têm teto
    // absoluto nas próprias fórmulas (`chanceDeAcerto` etc.).
    static func valorEfetivoDeDano(_ bruto: Int) -> Double {
        let primeiroPatamar = 40
        let segundoPatamar = 70
        if bruto <= primeiroPatamar {
            return Double(bruto)
        }
        if bruto <= segundoPatamar {
            return Double(primeiroPatamar) + Double(bruto - primeiroPatamar) * 0.5
        }
        let ateSegundoPatamar = Double(primeiroPatamar) + Double(segundoPatamar - primeiroPatamar) * 0.5
        return ateSegundoPatamar + Double(bruto - segundoPatamar) * 0.2
    }

    // MARK: - Maestria de Arma

    static let nivelMaximoDeMaestria = 20

    // Curva de XP pra cada nível de maestria: custo por nível cresce
    // linearmente (15, 30, 45, ...), então dominar uma arma pede dedicação
    // real (centenas de golpes até o topo), não algumas dúzias de acertos.
    static func nivelDeMaestria(xp: Int) -> Int {
        var nivel = 0
        var custoAcumulado = 0
        while nivel < Personagem.nivelMaximoDeMaestria {
            custoAcumulado += (nivel + 1) * 15
            if xp < custoAcumulado { break }
            nivel += 1
        }
        return nivel
    }

    // Nível de maestria da arma EQUIPADA agora — 0 se nenhuma arma
    // equipada, já que maestria é sobre dominar uma arma específica, não um
    // bônus geral do personagem.
    var nivelDeMaestriaArmaAtual: Int {
        guard let nome = armaEquipada?.nome else { return 0 }
        return Personagem.nivelDeMaestria(xp: maestriaDeArmas[nome] ?? 0)
    }

    // +1% de dano por nível de maestria (até +20% no nível 20) — pura
    // recompensa por USAR a mesma arma golpe após golpe, estilo o sistema
    // de Mastery de Melvor Idle: a build que o jogador domina fica mais
    // forte com o tempo, sem depender de Runas nem de sorte de loot.
    var bonusDeMaestriaPercentual: Int { nivelDeMaestriaArmaAtual }

    // Chamado a cada golpe que acerta (ataque básico, Golpe de Arma ou
    // magia do grimório) enquanto uma arma está equipada — nunca esquece,
    // nunca reseta ao trocar de arma e voltar depois.
    mutating func ganharMaestriaComArmaEquipada() {
        guard let nome = armaEquipada?.nome else { return }
        maestriaDeArmas[nome, default: 0] += 1
    }

    // Ataque básico: sempre disponível, com chance de crítico.
    // `bonusForca` inclui fortalecimentos temporários ativos só durante o combate.
    func calcularDanoBasico(bonusForca: Int = 0) -> (dano: Int, critico: Bool) {
        let forcaEfetiva = Personagem.valorEfetivoDeDano(forcaTotal + bonusForca)
        var dano = Int(forcaEfetiva) + Int.random(in: -2...4)
        dano += dano * bonusDeMaestriaPercentual / 100
        let critico = Int.random(in: 1...100) <= chanceDeCriticoBasico
        if critico { dano = Int(Double(dano) * 1.8) }
        return (max(1, dano), critico)
    }

    // `bonusDefesa` inclui fortalecimentos temporários ativos só durante o combate.
    // Primeiro testa a esquiva (Agilidade/Sorte); se não esquivar, aplica a
    // redução de dano passiva da classe (a resistência do Guerreiro).
    mutating func sofrerDano(deInimigo forcaInimigo: Int, bonusDefesa: Int = 0) -> (dano: Int, esquivou: Bool) {
        if Int.random(in: 1...100) <= chanceDeEsquiva {
            return (0, true)
        }
        var dano = forcaInimigo - (defesaTotal + bonusDefesa) + Int.random(in: -2...3)
        dano = max(1, dano)
        dano = max(1, Int(Double(dano) * (1 - classe.reducaoDeDanoPercentual)))
        vidaAtual = max(0, vidaAtual - dano)
        return (dano, false)
    }

    mutating func regenerarEnergia(_ quantidade: Int) {
        energiaAtual = min(energiaMaximaTotal, energiaAtual + quantidade)
    }

    mutating func regenerarVida(_ quantidade: Int) {
        vidaAtual = min(vidaMaxima, vidaAtual + quantidade)
    }

    mutating func registrarVitoria(naZona nome: String) {
        progressoZonas[nome, default: 0] += 1
    }

    func vitoriasNaZona(_ nome: String) -> Int {
        progressoZonas[nome] ?? 0
    }

    // MARK: - Missões (Vila)

    // O que mostrar na Vila para cada missão: bloqueada (nível baixo
    // demais), em andamento (com o progresso atual/alvo), pronta pra
    // entregar, ou já entregue. Calculado sob demanda a partir de dados
    // que o herói já guarda por outro motivo (ver comentário em
    // `missoesEntregues`), nunca armazenado.
    enum StatusDeMissao: Equatable {
        case bloqueada
        case emAndamento(atual: Int, alvo: Int)
        case prontaParaEntrega
        case entregue
    }

    func statusDaMissao(_ missao: Missao) -> StatusDeMissao {
        if missoesEntregues.contains(missao.id) { return .entregue }
        guard nivel >= missao.nivelMinimo else { return .bloqueada }

        switch missao.tipo {
        case .cacar:
            let atual = missao.zonaAlvo.map { vitoriasNaZona($0) } ?? 0
            return atual >= missao.quantidadeAlvo
                ? .prontaParaEntrega
                : .emAndamento(atual: atual, alvo: missao.quantidadeAlvo)
        case .derrotarChefe:
            guard let zona = missao.zonaAlvo else { return .bloqueada }
            return runicasConquistadas.contains(zona)
                ? .prontaParaEntrega
                : .emAndamento(atual: 0, alvo: 1)
        case .alcancarNivel:
            return nivel >= missao.quantidadeAlvo
                ? .prontaParaEntrega
                : .emAndamento(atual: nivel, alvo: missao.quantidadeAlvo)
        case .coletar:
            guard let nomeItem = missao.itemAlvo else { return .bloqueada }
            let atual = quantidadeDoItem(nome: nomeItem)
            return atual >= missao.quantidadeAlvo
                ? .prontaParaEntrega
                : .emAndamento(atual: atual, alvo: missao.quantidadeAlvo)
        }
    }

    // Quantas unidades de um item (por nome) o herói carrega agora — usado
    // só pra checar progresso de missões de coleta (ver `statusDaMissao`).
    func quantidadeDoItem(nome: String) -> Int {
        inventario.first(where: { $0.item.nome == nome })?.quantidade ?? 0
    }

    // Remove N unidades de um item (por nome) da mochila — usado ao
    // entregar uma missão de coleta. `false` se não tinha o suficiente
    // (não deveria acontecer, já que `entregarMissao` só chama isso depois
    // de confirmar via `statusDaMissao`, mas fica a prova de falha).
    @discardableResult
    mutating func removerQuantidade(doItemNomeado nome: String, quantidade: Int) -> Bool {
        guard let indice = inventario.firstIndex(where: { $0.item.nome == nome }),
              inventario[indice].quantidade >= quantidade else { return false }
        inventario[indice].quantidade -= quantidade
        if inventario[indice].quantidade <= 0 {
            inventario.remove(at: indice)
        }
        return true
    }

    // Entrega uma missão pronta e concede a recompensa — Runas (com os
    // mesmos bônus percentuais de talismã/sequência das outras fontes de
    // Runas) e, se houver, um item exclusivo que não existe no mercado.
    mutating func entregarMissao(_ missao: Missao) -> String {
        guard statusDaMissao(missao) == .prontaParaEntrega else {
            return "Essa missão ainda não pode ser entregue."
        }
        missoesEntregues.insert(missao.id)

        if missao.tipo == .coletar, let nomeItem = missao.itemAlvo {
            removerQuantidade(doItemNomeado: nomeItem, quantidade: missao.quantidadeAlvo)
        }

        var runasGanhas = missao.recompensaRunas
        if bonusOuroPercentualTotal > 0 {
            runasGanhas += runasGanhas * bonusOuroPercentualTotal / 100
        }
        ouro += runasGanhas

        var texto = "Missão concluída! +\(runasGanhas) Runas."
        if let item = missao.recompensaItem {
            adicionarItem(item)
            texto += " Recompensa: \(item.nome)!"
        }
        if let lore = missao.loreAoEntregar {
            texto += "\n\n\(lore)"
        }
        return texto
    }

    // MARK: - New Game+

    // Disponível depois de fechar a trama principal (ver comentário em
    // `cicloNewGamePlus`). Fica disponível pra sempre depois disso — não
    // exige derrotar o Devorador de Mundos de novo a cada ciclo (como o
    // NG+ de verdade de Elden Ring exige), simplificado de propósito pra
    // não travar o jogador atrás de uma re-jogada inteira só pra avançar
    // de ciclo.
    var elegivelParaNewGamePlus: Bool {
        missoesEntregues.contains("marco_nivel_40")
    }

    // Inicia um novo ciclo: personagem, equipamento, Runas, missões e
    // progresso continuam exatamente como estavam — só o multiplicador
    // de dificuldade/recompensa do mundo (`Zona.multiplicadorDeCiclo`)
    // sobe. Nada é resetado nem perdido, de propósito: não é um "recomeço
    // de verdade", é o mundo ficando mais perigoso ao redor do mesmo herói.
    mutating func iniciarNovoCicloNewGamePlus() -> String {
        guard elegivelParaNewGamePlus else {
            return "Você ainda precisa completar 'O Selo Final' (nível 40) antes de iniciar um novo ciclo."
        }
        cicloNewGamePlus += 1
        return Personagem.textoDoNovoCiclo(cicloNewGamePlus)
    }

    private static func textoDoNovoCiclo(_ ciclo: Int) -> String {
        let aviso = "Ciclo \(ciclo) iniciado: todas as criaturas do mundo ficam mais fortes — e mais generosas em Runas."
        switch ciclo {
        case 1:
            return "Ancião Toren olha para o horizonte, sério. \"Eu temia isso. O Vazio nunca é destruído — apenas contido, e por pouco tempo. Um eco dele já se move lá fora, mais faminto que o Devorador que você derrotou. O mundo precisa de você mais uma vez.\"\n\n\(aviso)"
        case 2:
            return "Toren balança a cabeça, cansado. \"Dessa vez o eco voltou mais rápido que da última. Alguma coisa aprendeu com a própria derrota.\"\n\n\(aviso)"
        default:
            return "Toren já nem parece surpreso mais. \"Outro eco, outro ciclo. Você já não é o mesmo aventureiro que chegou aqui — e ainda bem, porque o Vazio também não é mais o mesmo.\"\n\n\(aviso)"
        }
    }

    // Aplica Runas e (às vezes) um item de loot pela derrota de um inimigo.
    // Runas = o que antes era XP + ouro separados, fundidos numa moeda só
    // (estilo Elden Ring) — inflada pelos talismãs equipados
    // (ver `bonusOuroPercentualTotal` etc.), como Golden/Silver Scarab.
    // Derrotar um chefe pela primeira vez também concede a Grande Rúnica da
    // zona (`novaRunica`, nil se já tinha sido conquistada antes).
    mutating func receberRecompensa(deInimigo inimigo: Inimigo) -> (runas: Int, item: Item?, novaRunica: String?) {
        var runasGanhas = inimigo.xpRecompensa + Int.random(in: inimigo.ouroRecompensa)
        let bonusPercentual = bonusOuroPercentualTotal + bonusDeSequenciaPercentual
        if bonusPercentual > 0 {
            runasGanhas += runasGanhas * bonusPercentual / 100
        }
        ouro += runasGanhas
        sequenciaDeExploracao += 1

        var itemGanho: Item? = nil
        let chanceDeLoot = min(100, (inimigo.chefe ? 100 : (inimigo.elite ? 70 : 35)) + bonusChanceDeItemTotal)
        if Int.random(in: 1...100) <= chanceDeLoot {
            let item = Item.lootAleatorio(nivelInimigo: inimigo.nivel, garantido: inimigo.chefe || inimigo.elite, bonusRaridade: bonusRaridadeDeItemTotal, classe: classe)
            adicionarItem(item)
            itemGanho = item
        }

        // Material da zona (troféu de combate, ver `Item.materiaisDeZona`):
        // rolagem independente do loot de equipamento acima, pra alimentar
        // as missões de coleta sem competir pela mesma chance de item.
        let chanceDeMaterial = min(100, (inimigo.chefe ? 70 : (inimigo.elite ? 45 : 20)) + bonusChanceDeItemTotal / 2)
        if Int.random(in: 1...100) <= chanceDeMaterial, let material = Item.materialDaZona(inimigo.zonaOrigem) {
            adicionarItem(material)
        }
        // Quinquilharia genérica: chance pequena e independente, sem zona
        // nenhuma — só pra vender (ver `Item.materiaisGenericos`).
        if Int.random(in: 1...100) <= 8, let quinquilharia = Item.materiaisGenericos.randomElement() {
            adicionarItem(quinquilharia)
        }
        // Pedra de Forja: alimenta a Forja (ver `evoluirArmaEquipada`), com
        // rolagem independente das demais — assim como o material de zona,
        // nunca compete pela mesma chance do loot de equipamento.
        let chanceDePedra = min(100, (inimigo.chefe ? 55 : (inimigo.elite ? 35 : 15)) + bonusChanceDeItemTotal / 2)
        if Int.random(in: 1...100) <= chanceDePedra {
            adicionarItem(Item.pedraDeForja(paraNivelInimigo: inimigo.nivel))
        }

        var novaRunica: String? = nil
        if inimigo.chefe && !runicasConquistadas.contains(inimigo.zonaOrigem) {
            runicasConquistadas.insert(inimigo.zonaOrigem)
            novaRunica = inimigo.zonaOrigem
        }

        registrarVitoria(naZona: inimigo.zonaOrigem)
        return (runasGanhas, itemGanho, novaRunica)
    }

    // Um achado pacífico durante a exploração — um cadáver caído, um baú
    // escondido — sem combate, estilo os itens espalhados pelo mapa aberto
    // de Elden Ring. Recompensa menor que vencer um inimigo, mas de graça.
    mutating func receberDescoberta(zonaNome: String, nivelZona: Int) -> (runas: Int, item: Item?) {
        var runasGanhas = Int.random(in: (4 + nivelZona)...(9 + nivelZona * 2))
        let bonusPercentual = bonusOuroPercentualTotal + bonusDeSequenciaPercentual
        if bonusPercentual > 0 {
            runasGanhas += runasGanhas * bonusPercentual / 100
        }
        ouro += runasGanhas
        sequenciaDeExploracao += 1

        var itemGanho: Item? = nil
        let chanceDeItem = min(100, 40 + bonusChanceDeItemTotal)
        if Int.random(in: 1...100) <= chanceDeItem {
            let item = Item.lootAleatorio(nivelInimigo: nivelZona, bonusRaridade: bonusRaridadeDeItemTotal, classe: classe)
            adicionarItem(item)
            itemGanho = item
        }

        if Int.random(in: 1...100) <= 25, let material = Item.materialDaZona(zonaNome) {
            adicionarItem(material)
        }
        if Int.random(in: 1...100) <= 12 {
            adicionarItem(Item.pedraDeForja(paraNivelInimigo: nivelZona))
        }
        return (runasGanhas, itemGanho)
    }

    // MARK: - Mercado e mochila

    // Comprar um item do mercado. Retorna o que aconteceu (texto).
    mutating func comprar(_ item: Item) -> String {
        guard nivel >= item.nivelMinimo else {
            return "Você precisa ser nível \(item.nivelMinimo) para comprar \(item.nome)."
        }
        if ouro >= item.preco {
            ouro -= item.preco
            adicionarItem(item)
            return "Você comprou \(item.nome) por \(item.preco) Runas."
        } else {
            return "Runas insuficientes! \(item.nome) custa \(item.preco)."
        }
    }

    // Vender uma pilha de item. Vende 1 unidade por vez, pela metade do preço.
    mutating func vender(_ pilha: PilhaDeItens) -> String {
        guard let indice = inventario.firstIndex(where: { $0.id == pilha.id }) else {
            return "Item não encontrado."
        }

        let item = inventario[indice].item
        let valorVenda = item.preco / 2

        ouro += valorVenda
        diminuirPilha(emIndice: indice)
        return "Você vendeu \(item.nome) por \(valorVenda) Runas."
    }

    // Adiciona um item: se já existe uma pilha igual, soma 1; senão cria nova
    mutating func adicionarItem(_ item: Item) {
        // Também compara `nivelDeEvolucao`: uma arma já reforçada na Forja
        // nunca pode se misturar numa pilha com uma cópia comum do mesmo
        // nome (senão devolver uma arma evoluída pra mochila — ao trocar
        // de equipamento — apagaria silenciosamente o reforço ao empilhar
        // com uma cópia +0 já existente).
        if let indice = inventario.firstIndex(where: {
            $0.item.nome == item.nome && $0.item.nivelDeEvolucao == item.nivelDeEvolucao
        }) {
            inventario[indice].quantidade += 1
        } else {
            inventario.append(PilhaDeItens(item: item, quantidade: 1))
        }
    }

    // Usa uma poção de uma pilha: diminui a quantidade; se zerar, remove a pilha
    mutating func usarItem(_ pilha: PilhaDeItens) -> String {
        guard let indice = inventario.firstIndex(where: { $0.id == pilha.id }) else {
            return "Item não encontrado."
        }

        let item = inventario[indice].item

        guard item.tipo == .pocao, let efeito = item.efeitoDePocao else {
            return "Esse item não pode ser usado assim."
        }

        switch efeito {
        case .vida:
            vidaAtual = min(vidaMaxima, vidaAtual + item.valor)
            diminuirPilha(emIndice: indice)
            return "Você usou \(item.nome) e recuperou \(item.valor) de vida!"
        case .energia:
            energiaAtual = min(energiaMaximaTotal, energiaAtual + item.valor)
            diminuirPilha(emIndice: indice)
            return "Você usou \(item.nome) e recuperou \(item.valor) de energia!"
        case .antidoto:
            diminuirPilha(emIndice: indice)
            return "Você usou \(item.nome) e removeu os venenos ativos."
        case .aumentaFrascos:
            // Semente Dourada: mais cargas totais (quantidade), não mais
            // força de cura — isso é a Lágrima Sagrada, logo abaixo.
            guard cargasDeFrascoTotal < Personagem.cargasDeFrascoMaximo else {
                return "O Frasco Sagrado já está no limite máximo de \(Personagem.cargasDeFrascoMaximo) cargas."
            }
            let incremento = min(item.valor, Personagem.cargasDeFrascoMaximo - cargasDeFrascoTotal)
            cargasDeFrascoTotal += incremento
            frascosDeVidaAlocados += incremento
            frascosDeVidaAtuais += incremento
            diminuirPilha(emIndice: indice)
            return "Você consumiu \(item.nome)! Total de cargas do Frasco Sagrado: \(cargasDeFrascoTotal)/\(Personagem.cargasDeFrascoMaximo)."
        case .aumentaPotenciaDoFrasco:
            // Lágrima Sagrada: mais força de cura/restauração por uso, não
            // mais cargas — o par da Semente Dourada.
            guard potenciaDoFrasco < Personagem.potenciaDoFrascoMaxima else {
                return "O Frasco Sagrado já está na potência máxima de \(Personagem.potenciaDoFrascoMaxima)%."
            }
            let incremento = min(item.valor, Personagem.potenciaDoFrascoMaxima - potenciaDoFrasco)
            potenciaDoFrasco += incremento
            diminuirPilha(emIndice: indice)
            return "Você consumiu \(item.nome)! O Frasco Sagrado agora cura/restaura +\(incremento)% a mais por uso (total: \(potenciaDoFrasco)%)."
        case .fortalecimento:
            // O buff em si (`item.efeitoDeBuffTemporario`) só é aplicado
            // por `TelaDeCombate.usarItem`, que tem acesso ao estado de
            // fortalecimento temporário do combate — aqui só consome o
            // item. A tela esconde o botão "Usar" desse tipo fora de
            // combate, então esse branch só roda quando já tem efeito real.
            diminuirPilha(emIndice: indice)
            return "Você usou \(item.nome)!"
        }
    }

    // Equipa uma arma/armadura/acessório de uma pilha
    mutating func equiparItem(_ pilha: PilhaDeItens) -> String {
        guard let indice = inventario.firstIndex(where: { $0.id == pilha.id }) else {
            return "Item não encontrado."
        }

        let item = inventario[indice].item

        if let restrita = item.classeRestrita, restrita != classe {
            return "Sua classe (\(classe.rawValue)) não pode usar \(item.nome)."
        }
        guard nivel >= item.nivelMinimo else {
            return "Você precisa ser nível \(item.nivelMinimo) para equipar \(item.nome)."
        }

        switch item.tipo {
        case .arma:
            diminuirPilha(emIndice: indice)
            if let antiga = armaEquipada { adicionarItem(antiga) }
            armaEquipada = item
            recalcularMaximos()
            return "Você equipou \(item.nome)! \(item.bonus.descricaoCurta)."

        case .armadura:
            diminuirPilha(emIndice: indice)
            if let antiga = armaduraEquipada { adicionarItem(antiga) }
            armaduraEquipada = item
            recalcularMaximos()
            return "Você equipou \(item.nome)! \(item.bonus.descricaoCurta)."

        case .acessorio:
            guard let indiceVazio = acessoriosEquipados.firstIndex(where: { $0 == nil }) else {
                return "Todos os slots de talismã estão cheios! Remova um na tela de Equipamento antes de equipar \(item.nome)."
            }
            diminuirPilha(emIndice: indice)
            acessoriosEquipados[indiceVazio] = item
            recalcularMaximos()
            return "Você equipou \(item.nome) no talismã \(indiceVazio + 1)! \(item.bonus.descricaoCurta)."

        case .pocao, .material:
            return "Esse item não pode ser equipado."
        }
    }

    // Desequipa arma/armadura e devolve ela para a mochila.
    mutating func removerEquipamento(_ tipo: TipoDeItem) -> String {
        switch tipo {
        case .arma:
            guard let item = armaEquipada else { return "Nenhuma arma equipada." }
            adicionarItem(item)
            armaEquipada = nil
            recalcularMaximos()
            return "Você guardou \(item.nome) na mochila."
        case .armadura:
            guard let item = armaduraEquipada else { return "Nenhuma armadura equipada." }
            adicionarItem(item)
            armaduraEquipada = nil
            recalcularMaximos()
            return "Você guardou \(item.nome) na mochila."
        case .acessorio:
            return "Use removerAcessorio(doSlot:) para talismãs."
        case .pocao, .material:
            return "Isso não é um equipamento."
        }
    }

    // MARK: - Forja (evolução de arma/armadura)

    // Custo pra levar uma peça do nível atual pro próximo, na trilha longa
    // de 25 (ver `Item.nivelMaximoDeEvolucao`): a TIER da pedra exigida
    // sobe com o progresso do reforço em si, não com a raridade da peça
    // (ver `Item.pedraDeForja(paraNivelDeEvolucao:)` — o motivo está lá).
    // A quantidade cresce devagar (2 a cada reforço, +1 a cada 3 níveis) —
    // farmar até +25 é uma meta de fim de jogo de verdade (~150+ pedras no
    // total), não algo pra terminar numa tarde. Público (não só usado
    // pelos `evoluir*`) pra a tela da Vila mostrar o custo antes de confirmar.
    func custoParaEvoluir(_ item: Item) -> (pedra: Item, quantidadePedra: Int, custoRunas: Int) {
        let pedra = Item.pedraDeForja(paraNivelDeEvolucao: item.nivelDeEvolucao)
        let quantidadePedra = 2 + item.nivelDeEvolucao / 3
        let custoRunas = 60 + item.nivelDeEvolucao * 35
        return (pedra, quantidadePedra, custoRunas)
    }

    // Evolui a peça equipada (arma OU armadura), consumindo Pedras de Forja
    // da tier da raridade dela + Runas. O bônus efetivo já reflete o novo
    // nível imediatamente (ver `Item.bonusEvoluido`), sem precisar
    // reequipar. Só a peça EQUIPADA evolui — nunca uma cópia parada na
    // mochila — pra não ambiguar qual unidade de uma pilha está sendo
    // reforçada.
    //
    // `evoluirArmaEquipada`/`evoluirArmaduraEquipada` abaixo repetem essa
    // lógica em vez de compartilhar um helper com `inout Item?` — Swift não
    // permite `self.evoluir(&self.armaEquipada, …)` (outro método
    // `mutating` do mesmo `self` recebendo um `inout` pra uma propriedade
    // desse mesmo `self`): "overlapping accesses to self", erro de
    // exclusividade só descoberto em tempo de compilação de verdade.
    mutating func evoluirArmaEquipada() -> String {
        guard var item = armaEquipada else {
            return "Você precisa equipar uma arma antes de evoluí-la na Forja."
        }
        guard item.nivelDeEvolucao < Item.nivelMaximoDeEvolucao else {
            return "\(item.nome) já está no nível máximo de evolução (+\(Item.nivelMaximoDeEvolucao))."
        }
        let (pedra, quantidadePedra, custoRunas) = custoParaEvoluir(item)
        guard quantidadeDoItem(nome: pedra.nome) >= quantidadePedra else {
            return "Faltam \(pedra.nome) para evoluir \(item.nome) (\(quantidadeDoItem(nome: pedra.nome))/\(quantidadePedra))."
        }
        guard ouro >= custoRunas else {
            return "Runas insuficientes! A Forja cobra \(custoRunas) Runas para esse reforço."
        }
        removerQuantidade(doItemNomeado: pedra.nome, quantidade: quantidadePedra)
        ouro -= custoRunas
        item.nivelDeEvolucao += 1
        armaEquipada = item
        recalcularMaximos()
        return "\(item.nome) evoluiu para +\(item.nivelDeEvolucao)! Novo bônus: \(item.bonusEvoluido.descricaoCurta)."
    }

    mutating func evoluirArmaduraEquipada() -> String {
        guard var item = armaduraEquipada else {
            return "Você precisa equipar uma armadura antes de evoluí-la na Forja."
        }
        guard item.nivelDeEvolucao < Item.nivelMaximoDeEvolucao else {
            return "\(item.nome) já está no nível máximo de evolução (+\(Item.nivelMaximoDeEvolucao))."
        }
        let (pedra, quantidadePedra, custoRunas) = custoParaEvoluir(item)
        guard quantidadeDoItem(nome: pedra.nome) >= quantidadePedra else {
            return "Faltam \(pedra.nome) para evoluir \(item.nome) (\(quantidadeDoItem(nome: pedra.nome))/\(quantidadePedra))."
        }
        guard ouro >= custoRunas else {
            return "Runas insuficientes! A Forja cobra \(custoRunas) Runas para esse reforço."
        }
        removerQuantidade(doItemNomeado: pedra.nome, quantidade: quantidadePedra)
        ouro -= custoRunas
        item.nivelDeEvolucao += 1
        armaduraEquipada = item
        recalcularMaximos()
        return "\(item.nome) evoluiu para +\(item.nivelDeEvolucao)! Novo bônus: \(item.bonusEvoluido.descricaoCurta)."
    }

    // Desequipa o talismã de um slot específico e devolve ele para a mochila.
    mutating func removerAcessorio(doSlot indice: Int) -> String {
        guard indice >= 0, indice < acessoriosEquipados.count, let item = acessoriosEquipados[indice] else {
            return "Nenhum talismã equipado nesse slot."
        }
        adicionarItem(item)
        acessoriosEquipados[indice] = nil
        recalcularMaximos()
        return "Você guardou \(item.nome) na mochila."
    }

    // MARK: - Slots de magia (barra de combate)

    func magiaNoSlot(_ indice: Int) -> Magia? {
        guard indice >= 0, indice < slotsDeMagias.count, !slotsDeMagias[indice].isEmpty else { return nil }
        let nome = slotsDeMagias[indice]
        return classe.grimorio.first(where: { $0.nome == nome })
    }

    mutating func equiparMagia(_ magia: Magia, noSlot indice: Int) {
        while slotsDeMagias.count <= indice { slotsDeMagias.append("") }
        slotsDeMagias[indice] = magia.nome
    }

    mutating func removerMagia(doSlot indice: Int) {
        guard indice >= 0, indice < slotsDeMagias.count else { return }
        slotsDeMagias[indice] = ""
    }

    // Tira 1 de uma pilha; se chegar a zero, remove a pilha da mochila
    mutating func diminuirPilha(emIndice indice: Int) {
        inventario[indice].quantidade -= 1
        if inventario[indice].quantidade <= 0 {
            inventario.remove(at: indice)
        }
    }
}
