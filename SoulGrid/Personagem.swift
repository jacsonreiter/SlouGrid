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

    static let numeroDeSlotsDeMagia = 3
    static let numeroDeSlotsDeAcessorio = 3

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
             runicasConquistadas, runicaSelecionada, runicaEquipadaAtiva
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
        itensEquipados.map { $0.bonus } + [bonusDeRunicaAtiva]
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

    var bonusChanceDeItemTotal: Int {
        bonusAtivos.reduce(0) { $0 + $1.bonusChanceDeItemPercentual }
    }

    var bonusRaridadeDeItemTotal: Int {
        bonusAtivos.reduce(0) { $0 + $1.bonusRaridadeDeItem }
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

    // Sorte é quem mais rege o crítico (como LUK no Ragnarok); Agilidade
    // contribui um pouco, mantendo o Ladino "ágil e certeiro" mesmo sem
    // investir tudo em Sorte.
    var chanceDeCriticoBasico: Int {
        min(60, 5 + sorteTotal + agilidadeTotal / 4)
    }

    // Agilidade rege a esquiva (como AGI/FLEE); Sorte contribui um pouco
    // (a "esquiva perfeita" do LUK).
    var chanceDeEsquiva: Int {
        min(35, agilidadeTotal / 3 + sorteTotal / 6)
    }

    // Destreza rege a chance de acerto — física e mágica. Sem nenhum ponto
    // investido o herói ainda acerta a maior parte das vezes (85%): errar
    // é o "tempero" de não investir em Destreza, não uma punição severa.
    var chanceDeAcerto: Int {
        min(98, 85 + destrezaTotal / 2)
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

    // Custo em Runas do próximo ponto — estilo Elden Ring de verdade: o
    // preço depende de quantos pontos você já tem NO TOTAL (ou seja, do seu
    // nível), nunca de qual atributo está sendo melhorado. Custa exatamente
    // o mesmo comprar o 1º ponto de Força ou o 1º ponto de Sorte no mesmo
    // nível — e o mesmo pra investir tudo numa coisa só ou espalhar. A
    // escolha de onde investir é só sobre a build, nunca sobre "qual tá mais
    // barato agora" (esse soft cap por atributo existia antes; não existe
    // mais, de propósito).
    static func custoEmRunas(pontosTotaisComprados: Int) -> Int {
        (1 + pontosTotaisComprados / 10) * 20
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
    // selecionada (se for diferente da que já estava ativa).
    mutating func descansar() {
        if runicaSelecionada != runicaEquipadaAtiva {
            runicaEquipadaAtiva = runicaSelecionada
        }
        recalcularMaximos()
        vidaAtual = vidaMaxima
        energiaAtual = energiaMaximaTotal
        frascosDeVidaAtuais = frascosDeVidaAlocados
        frascosDeEnergiaAtuais = frascosDeEnergiaAlocados
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

    // Ataque básico: sempre disponível, com chance de crítico.
    // `bonusForca` inclui fortalecimentos temporários ativos só durante o combate.
    func calcularDanoBasico(bonusForca: Int = 0) -> (dano: Int, critico: Bool) {
        var dano = forcaTotal + bonusForca + Int.random(in: -2...4)
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

    // Aplica Runas e (às vezes) um item de loot pela derrota de um inimigo.
    // Runas = o que antes era XP + ouro separados, fundidos numa moeda só
    // (estilo Elden Ring) — inflada pelos talismãs equipados
    // (ver `bonusOuroPercentualTotal` etc.), como Golden/Silver Scarab.
    // Derrotar um chefe pela primeira vez também concede a Grande Rúnica da
    // zona (`novaRunica`, nil se já tinha sido conquistada antes).
    mutating func receberRecompensa(deInimigo inimigo: Inimigo) -> (runas: Int, item: Item?, novaRunica: String?) {
        var runasGanhas = inimigo.xpRecompensa + Int.random(in: inimigo.ouroRecompensa)
        if bonusOuroPercentualTotal > 0 {
            runasGanhas += runasGanhas * bonusOuroPercentualTotal / 100
        }
        ouro += runasGanhas

        var itemGanho: Item? = nil
        let chanceDeLoot = min(100, (inimigo.chefe ? 100 : (inimigo.elite ? 70 : 35)) + bonusChanceDeItemTotal)
        if Int.random(in: 1...100) <= chanceDeLoot {
            let item = Item.lootAleatorio(nivelInimigo: inimigo.nivel, garantido: inimigo.chefe || inimigo.elite, bonusRaridade: bonusRaridadeDeItemTotal, classe: classe)
            adicionarItem(item)
            itemGanho = item
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
    mutating func receberDescoberta(nivelZona: Int) -> (runas: Int, item: Item?) {
        var runasGanhas = Int.random(in: (4 + nivelZona)...(9 + nivelZona * 2))
        if bonusOuroPercentualTotal > 0 {
            runasGanhas += runasGanhas * bonusOuroPercentualTotal / 100
        }
        ouro += runasGanhas

        var itemGanho: Item? = nil
        let chanceDeItem = min(100, 40 + bonusChanceDeItemTotal)
        if Int.random(in: 1...100) <= chanceDeItem {
            let item = Item.lootAleatorio(nivelInimigo: nivelZona, bonusRaridade: bonusRaridadeDeItemTotal, classe: classe)
            adicionarItem(item)
            itemGanho = item
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
        if let indice = inventario.firstIndex(where: { $0.item.nome == item.nome }) {
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
            cargasDeFrascoTotal += item.valor
            frascosDeVidaAlocados += item.valor
            frascosDeVidaAtuais += item.valor
            diminuirPilha(emIndice: indice)
            return "Você consumiu \(item.nome)! Total de cargas do Frasco Sagrado: \(cargasDeFrascoTotal)."
        case .aumentaPotenciaDoFrasco:
            // Lágrima Sagrada: mais força de cura/restauração por uso, não
            // mais cargas — o par da Semente Dourada.
            potenciaDoFrasco += item.valor
            diminuirPilha(emIndice: indice)
            return "Você consumiu \(item.nome)! O Frasco Sagrado agora cura/restaura +\(item.valor)% a mais por uso."
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

        case .pocao:
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
        case .pocao:
            return "Isso não é um equipamento."
        }
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
