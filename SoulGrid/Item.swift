import SwiftUI

// Os tipos de item que existem no jogo
enum TipoDeItem: String, Codable {
    case pocao
    case arma
    case armadura
    case acessorio
}

enum EfeitoDePocao: String, Codable {
    case vida
    case energia
    case antidoto
    case aumentaFrascos          // Semente Dourada: aumenta o total de cargas do Frasco Sagrado
    case aumentaPotenciaDoFrasco // Lágrima Sagrada: aumenta a % de cura/restauração de cada uso do Frasco
}

enum Raridade: String, Codable {
    case comum
    case incomum
    case raro
    case epico

    var nome: String {
        switch self {
        case .comum: return "Comum"
        case .incomum: return "Incomum"
        case .raro: return "Raro"
        case .epico: return "Épico"
        }
    }

    var cor: Color {
        switch self {
        case .comum: return .gray
        case .incomum: return .green
        case .raro: return .blue
        case .epico: return .purple
        }
    }
}

// Conjunto de bônus de atributo que um equipamento pode conceder. Um item só
// preenche os campos relevantes para ele (uma espada mexe em força, um robe
// de mago pode mexer em vitalidade e inteligência ao mesmo tempo), o que
// permite criar equipamentos híbridos sem precisar de um tipo de item por
// atributo. `defesa` é proteção direta do próprio item (a "placa" dele),
// separada da Vitalidade do personagem — as duas se somam em combate.
struct BonusDeAtributos: Codable, Equatable {
    var forca: Int = 0
    var vitalidade: Int = 0
    var inteligencia: Int = 0
    var destreza: Int = 0
    var agilidade: Int = 0
    var sorte: Int = 0
    var defesa: Int = 0
    var energia: Int = 0

    // Efeitos passivos "de talismã" (estilo Elden Ring: Erdtree's Favor,
    // Green Turtle Talisman, Golden/Silver Scarab) — não empurram um
    // atributo de combate, mas mudam o ritmo da progressão: quanto de
    // vida/energia volta sozinho a cada turno, e quanta sorte extra o
    // jogador tem no ouro e no loot dos inimigos.
    var regenVidaPorTurno: Int = 0
    var regenEnergiaPorTurno: Int = 0
    var bonusOuroPercentual: Int = 0
    var bonusChanceDeItemPercentual: Int = 0
    var bonusRaridadeDeItem: Int = 0

    init(forca: Int = 0, vitalidade: Int = 0, inteligencia: Int = 0, destreza: Int = 0,
         agilidade: Int = 0, sorte: Int = 0, defesa: Int = 0, energia: Int = 0,
         regenVidaPorTurno: Int = 0, regenEnergiaPorTurno: Int = 0,
         bonusOuroPercentual: Int = 0, bonusChanceDeItemPercentual: Int = 0,
         bonusRaridadeDeItem: Int = 0) {
        self.forca = forca
        self.vitalidade = vitalidade
        self.inteligencia = inteligencia
        self.destreza = destreza
        self.agilidade = agilidade
        self.sorte = sorte
        self.defesa = defesa
        self.energia = energia
        self.regenVidaPorTurno = regenVidaPorTurno
        self.regenEnergiaPorTurno = regenEnergiaPorTurno
        self.bonusOuroPercentual = bonusOuroPercentual
        self.bonusChanceDeItemPercentual = bonusChanceDeItemPercentual
        self.bonusRaridadeDeItem = bonusRaridadeDeItem
    }

    // Decodificação tolerante: saves antigos têm um `bonus` só com os 8
    // campos originais. Sem isso, decodificar essa struct aninhada quebraria
    // o save inteiro assim que um dos 5 campos novos não fosse encontrado.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        forca = try c.decodeIfPresent(Int.self, forKey: .forca) ?? 0
        vitalidade = try c.decodeIfPresent(Int.self, forKey: .vitalidade) ?? 0
        inteligencia = try c.decodeIfPresent(Int.self, forKey: .inteligencia) ?? 0
        destreza = try c.decodeIfPresent(Int.self, forKey: .destreza) ?? 0
        agilidade = try c.decodeIfPresent(Int.self, forKey: .agilidade) ?? 0
        sorte = try c.decodeIfPresent(Int.self, forKey: .sorte) ?? 0
        defesa = try c.decodeIfPresent(Int.self, forKey: .defesa) ?? 0
        energia = try c.decodeIfPresent(Int.self, forKey: .energia) ?? 0
        regenVidaPorTurno = try c.decodeIfPresent(Int.self, forKey: .regenVidaPorTurno) ?? 0
        regenEnergiaPorTurno = try c.decodeIfPresent(Int.self, forKey: .regenEnergiaPorTurno) ?? 0
        bonusOuroPercentual = try c.decodeIfPresent(Int.self, forKey: .bonusOuroPercentual) ?? 0
        bonusChanceDeItemPercentual = try c.decodeIfPresent(Int.self, forKey: .bonusChanceDeItemPercentual) ?? 0
        bonusRaridadeDeItem = try c.decodeIfPresent(Int.self, forKey: .bonusRaridadeDeItem) ?? 0
    }

    var descricaoCurta: String {
        var partes: [String] = []
        if forca != 0 { partes.append("+\(forca) Força") }
        if vitalidade != 0 { partes.append("+\(vitalidade) Vitalidade") }
        if inteligencia != 0 { partes.append("+\(inteligencia) Inteligência") }
        if destreza != 0 { partes.append("+\(destreza) Destreza") }
        if agilidade != 0 { partes.append("+\(agilidade) Agilidade") }
        if sorte != 0 { partes.append("+\(sorte) Sorte") }
        if defesa != 0 { partes.append("+\(defesa) Defesa") }
        if energia != 0 { partes.append("+\(energia) Energia") }
        if regenVidaPorTurno != 0 { partes.append("+\(regenVidaPorTurno) Vida/turno") }
        if regenEnergiaPorTurno != 0 { partes.append("+\(regenEnergiaPorTurno) Energia/turno") }
        if bonusOuroPercentual != 0 { partes.append("+\(bonusOuroPercentual)% Runas") }
        if bonusChanceDeItemPercentual != 0 { partes.append("+\(bonusChanceDeItemPercentual)% Chance de Item") }
        if bonusRaridadeDeItem != 0 { partes.append("+\(bonusRaridadeDeItem) Sorte de Raridade") }
        return partes.joined(separator: ", ")
    }
}

struct Item: Codable, Identifiable {
    var id = UUID()
    var nome: String
    var tipo: TipoDeItem
    var valor: Int        // só usado por poções: intensidade do efeito
    var preco: Int        // quanto custa no mercado
    var raridade: Raridade = .comum
    var classeRestrita: ClasseDePersonagem? = nil   // nil = qualquer classe pode usar
    var efeitoDePocao: EfeitoDePocao? = nil          // só relevante quando tipo == .pocao
    var nivelMinimo: Int = 1                          // nível mínimo do herói para comprar/equipar
    var bonus: BonusDeAtributos = BonusDeAtributos()  // só relevante para arma/armadura/acessório
    // O "Golpe de Arma" da peça (estilo Ash of War de Elden Ring): uma
    // habilidade extra, só relevante quando `tipo == .arma`, reaproveitando
    // a própria `Magia` (mesmo motor de dano/efeito/buff do grimório) em
    // vez de um sistema paralelo.
    var habilidadeDeArma: Magia? = nil

    var descricao: String {
        switch tipo {
        case .pocao:
            switch efeitoDePocao {
            case .vida: return "Cura \(valor) de vida"
            case .energia: return "Restaura \(valor) de energia"
            case .antidoto: return "Remove venenos ativos"
            case .aumentaFrascos: return "Aumenta em \(valor) o total de cargas do Frasco Sagrado"
            case .aumentaPotenciaDoFrasco: return "Aumenta em \(valor)% a cura/restauração do Frasco Sagrado"
            case .none: return ""
            }
        case .arma, .armadura, .acessorio:
            return bonus.descricaoCurta
        }
    }

    init(nome: String, tipo: TipoDeItem, valor: Int, preco: Int, raridade: Raridade = .comum,
         classeRestrita: ClasseDePersonagem? = nil, efeitoDePocao: EfeitoDePocao? = nil,
         nivelMinimo: Int = 1, bonus: BonusDeAtributos = BonusDeAtributos(),
         habilidadeDeArma: Magia? = nil) {
        self.nome = nome
        self.tipo = tipo
        self.valor = valor
        self.preco = preco
        self.raridade = raridade
        self.classeRestrita = classeRestrita
        self.efeitoDePocao = efeitoDePocao
        self.nivelMinimo = nivelMinimo
        self.bonus = bonus
        self.habilidadeDeArma = habilidadeDeArma
    }

    // Decodificação tolerante: itens salvos antes do sistema de bônus por
    // atributo (`bonus`/`nivelMinimo`) continuam carregando normalmente. Um
    // equipamento antigo, que só tinha `valor` como bônus único, é
    // reconstruído no atributo que fazia sentido para o tipo dele na época.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        nome = try c.decode(String.self, forKey: .nome)
        tipo = try c.decode(TipoDeItem.self, forKey: .tipo)
        valor = try c.decode(Int.self, forKey: .valor)
        preco = try c.decode(Int.self, forKey: .preco)
        raridade = try c.decodeIfPresent(Raridade.self, forKey: .raridade) ?? .comum
        classeRestrita = try c.decodeIfPresent(ClasseDePersonagem.self, forKey: .classeRestrita)
        efeitoDePocao = try c.decodeIfPresent(EfeitoDePocao.self, forKey: .efeitoDePocao)
        nivelMinimo = try c.decodeIfPresent(Int.self, forKey: .nivelMinimo) ?? 1

        if let bonusDecodificado = try c.decodeIfPresent(BonusDeAtributos.self, forKey: .bonus) {
            bonus = bonusDecodificado
        } else {
            switch tipo {
            case .arma: bonus = BonusDeAtributos(forca: valor)
            case .armadura: bonus = BonusDeAtributos(defesa: valor)
            case .acessorio: bonus = BonusDeAtributos(energia: valor)
            case .pocao: bonus = BonusDeAtributos()
            }
        }

        habilidadeDeArma = try c.decodeIfPresent(Magia.self, forKey: .habilidadeDeArma) ?? nil
    }
}

// Uma pilha de itens iguais na mochila: o item + quantos
struct PilhaDeItens: Codable, Identifiable {
    var id = UUID()
    var item: Item
    var quantidade: Int
}

extension Item {
    // Catálogo único usado pelo mercado e como base para o loot das masmorras.
    // Os níveis mínimos crescem junto com o grimório de cada classe, para que
    // sempre exista um próximo equipamento valendo a pena esperar.
    static let catalogoMercado: [Item] = [
        // Poções (universais)
        Item(nome: "Poção de Vida", tipo: .pocao, valor: 30, preco: 20, raridade: .comum, efeitoDePocao: .vida, nivelMinimo: 1),
        Item(nome: "Poção de Mana Pequena", tipo: .pocao, valor: 25, preco: 18, raridade: .comum, efeitoDePocao: .energia, nivelMinimo: 1),
        Item(nome: "Antídoto", tipo: .pocao, valor: 0, preco: 15, raridade: .comum, efeitoDePocao: .antidoto, nivelMinimo: 1),
        Item(nome: "Poção Grande", tipo: .pocao, valor: 60, preco: 45, raridade: .incomum, efeitoDePocao: .vida, nivelMinimo: 5),
        Item(nome: "Poção de Mana Grande", tipo: .pocao, valor: 50, preco: 40, raridade: .incomum, efeitoDePocao: .energia, nivelMinimo: 5),
        Item(nome: "Elixir Maior", tipo: .pocao, valor: 120, preco: 90, raridade: .raro, efeitoDePocao: .vida, nivelMinimo: 10),
        Item(nome: "Elixir Supremo", tipo: .pocao, valor: 200, preco: 150, raridade: .raro, efeitoDePocao: .vida, nivelMinimo: 16),
        Item(nome: "Néctar Arcano", tipo: .pocao, valor: 90, preco: 120, raridade: .raro, efeitoDePocao: .energia, nivelMinimo: 16),

        // Semente Dourada — estilo Golden Seed de Elden Ring: consumível que
        // aumenta permanentemente o total de cargas do Frasco Sagrado (ver
        // `Personagem.cargasDeFrascoTotal`). Preço alto de propósito: é mais
        // um objetivo de farm/marco de progresso do que uma compra casual.
        Item(nome: "Semente Dourada Menor", tipo: .pocao, valor: 1, preco: 200, raridade: .incomum, efeitoDePocao: .aumentaFrascos, nivelMinimo: 1),
        Item(nome: "Semente Dourada", tipo: .pocao, valor: 1, preco: 400, raridade: .raro, efeitoDePocao: .aumentaFrascos, nivelMinimo: 6),
        Item(nome: "Semente Dourada Maior", tipo: .pocao, valor: 1, preco: 650, raridade: .raro, efeitoDePocao: .aumentaFrascos, nivelMinimo: 11),
        Item(nome: "Semente Dourada Suprema", tipo: .pocao, valor: 1, preco: 900, raridade: .epico, efeitoDePocao: .aumentaFrascos, nivelMinimo: 16),

        // Lágrima Sagrada — estilo Sacred Tear de Elden Ring: consumível que
        // aumenta permanentemente a potência (cura/restauração por uso) do
        // Frasco Sagrado (ver `Personagem.potenciaDoFrasco`) — o par da
        // Semente Dourada, que aumenta quantidade em vez de força.
        Item(nome: "Lágrima Sagrada Menor", tipo: .pocao, valor: 5, preco: 220, raridade: .incomum, efeitoDePocao: .aumentaPotenciaDoFrasco, nivelMinimo: 1),
        Item(nome: "Lágrima Sagrada", tipo: .pocao, valor: 8, preco: 420, raridade: .raro, efeitoDePocao: .aumentaPotenciaDoFrasco, nivelMinimo: 6),
        Item(nome: "Lágrima Sagrada Maior", tipo: .pocao, valor: 10, preco: 680, raridade: .raro, efeitoDePocao: .aumentaPotenciaDoFrasco, nivelMinimo: 11),
        Item(nome: "Lágrima Sagrada Suprema", tipo: .pocao, valor: 12, preco: 950, raridade: .epico, efeitoDePocao: .aumentaPotenciaDoFrasco, nivelMinimo: 16),

        // Armas do Guerreiro — Força pura, com um toque de Destreza (a arma
        // ajuda a acertar, mesmo que Destreza não seja o forte da classe).
        // Cada uma carrega seu próprio "Golpe de Arma" (`habilidadeDeArma`,
        // estilo Ash of War), reaproveitando o motor de `Magia`.
        Item(nome: "Espada Curta", tipo: .arma, valor: 0, preco: 90, raridade: .comum, classeRestrita: .guerreiro, nivelMinimo: 1, bonus: BonusDeAtributos(forca: 6, destreza: 2),
             habilidadeDeArma: Magia(nome: "Estocada Rápida", descricao: "Uma investida veloz com a lâmina.", icone: "bolt.fill", custoEnergia: 15, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 1.3)),
        Item(nome: "Espada Longa", tipo: .arma, valor: 0, preco: 160, raridade: .incomum, classeRestrita: .guerreiro, nivelMinimo: 5, bonus: BonusDeAtributos(forca: 10, destreza: 3),
             habilidadeDeArma: Magia(nome: "Corte Giratório", descricao: "Um golpe amplo com toda a força do braço.", icone: "tornado", custoEnergia: 22, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 1.8)),
        Item(nome: "Machado de Guerra", tipo: .arma, valor: 0, preco: 280, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 10, bonus: BonusDeAtributos(forca: 16, destreza: 5),
             habilidadeDeArma: Magia(nome: "Fenda-Terra", descricao: "Um golpe pesado que atordoa o alvo.", icone: "hammer.fill", custoEnergia: 35, nivelNecessario: 1, tipo: .atordoante, atributoDeEscala: .forca, multiplicadorDano: 1.6)),
        Item(nome: "Lâmina do Campeão", tipo: .arma, valor: 0, preco: 450, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 15, bonus: BonusDeAtributos(forca: 24, destreza: 7),
             habilidadeDeArma: Magia(nome: "Lâmina Sangrenta", descricao: "Corta fundo, abrindo um sangramento.", icone: "drop.triangle.fill", custoEnergia: 40, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .forca, multiplicadorDano: 1.4, multiplicadorDanoPorTurno: 0.7, duracaoEmTurnos: 3)),
        Item(nome: "Espada do Titã Ancestral", tipo: .arma, valor: 0, preco: 700, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 18, bonus: BonusDeAtributos(forca: 32, vitalidade: 5, destreza: 9),
             habilidadeDeArma: Magia(nome: "Golpe do Titã", descricao: "O golpe lendário do Titã Ancestral, certeiro e devastador.", icone: "burst.fill", custoEnergia: 55, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 3.2, sempreAcerta: true)),

        // Armas do Mago — cajados que escalam Inteligência, não Força
        Item(nome: "Cajado de Aprendiz", tipo: .arma, valor: 0, preco: 90, raridade: .comum, classeRestrita: .mago, nivelMinimo: 1, bonus: BonusDeAtributos(inteligencia: 7, destreza: 2),
             habilidadeDeArma: Magia(nome: "Faísca Arcana", descricao: "Uma centelha de energia arcana crua.", icone: "sparkle", custoEnergia: 18, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 1.3)),
        Item(nome: "Cajado Élfico", tipo: .arma, valor: 0, preco: 160, raridade: .incomum, classeRestrita: .mago, nivelMinimo: 5, bonus: BonusDeAtributos(inteligencia: 11, destreza: 3),
             habilidadeDeArma: Magia(nome: "Rajada Élfica", descricao: "Uma sequência de projéteis élficos.", icone: "wind", custoEnergia: 26, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 1.9)),
        Item(nome: "Cetro Arcano", tipo: .arma, valor: 0, preco: 280, raridade: .raro, classeRestrita: .mago, nivelMinimo: 10, bonus: BonusDeAtributos(inteligencia: 18, destreza: 5),
             habilidadeDeArma: Magia(nome: "Gélido Cortante", descricao: "Um golpe de gelo que atordoa o alvo.", icone: "snowflake", custoEnergia: 38, nivelNecessario: 1, tipo: .atordoante, atributoDeEscala: .inteligencia, multiplicadorDano: 1.5)),
        Item(nome: "Bastão dos Videntes", tipo: .arma, valor: 0, preco: 450, raridade: .epico, classeRestrita: .mago, nivelMinimo: 15, bonus: BonusDeAtributos(inteligencia: 26, destreza: 7),
             habilidadeDeArma: Magia(nome: "Chama Persistente", descricao: "Fogo arcano que continua queimando o alvo.", icone: "flame.fill", custoEnergia: 42, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .inteligencia, multiplicadorDano: 1.3, multiplicadorDanoPorTurno: 0.6, duracaoEmTurnos: 3)),
        Item(nome: "Cetro do Vazio Eterno", tipo: .arma, valor: 0, preco: 700, raridade: .epico, classeRestrita: .mago, nivelMinimo: 17, bonus: BonusDeAtributos(inteligencia: 36, destreza: 9, energia: 20),
             habilidadeDeArma: Magia(nome: "Colapso do Vazio", descricao: "Uma implosão arcana certeira que rasga o alvo.", icone: "smallcircle.filled.circle.fill", custoEnergia: 58, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 3.4, sempreAcerta: true)),

        // Armas do Ladino — Agilidade e Destreza, com Inteligência de apoio
        // para os venenos
        Item(nome: "Adagas Gêmeas", tipo: .arma, valor: 0, preco: 90, raridade: .comum, classeRestrita: .ladino, nivelMinimo: 1, bonus: BonusDeAtributos(destreza: 3, agilidade: 7),
             habilidadeDeArma: Magia(nome: "Golpe Sombrio", descricao: "Um golpe rápido vindo da sombra.", icone: "eye.slash.fill", custoEnergia: 14, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 1.35)),
        Item(nome: "Punhais Sombrios", tipo: .arma, valor: 0, preco: 160, raridade: .incomum, classeRestrita: .ladino, nivelMinimo: 5, bonus: BonusDeAtributos(inteligencia: 3, destreza: 4, agilidade: 10),
             habilidadeDeArma: Magia(nome: "Dança das Lâminas", descricao: "Uma sequência veloz de cortes.", icone: "wind", custoEnergia: 20, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 1.9)),
        Item(nome: "Lâminas do Vento", tipo: .arma, valor: 0, preco: 280, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 10, bonus: BonusDeAtributos(inteligencia: 5, destreza: 6, agilidade: 16),
             habilidadeDeArma: Magia(nome: "Rajada Cortante", descricao: "Um corte veloz que desequilibra o alvo.", icone: "wind.snow", custoEnergia: 32, nivelNecessario: 1, tipo: .atordoante, atributoDeEscala: .agilidade, multiplicadorDano: 1.55)),
        Item(nome: "Presas da Víbora", tipo: .arma, valor: 0, preco: 450, raridade: .epico, classeRestrita: .ladino, nivelMinimo: 15, bonus: BonusDeAtributos(inteligencia: 8, destreza: 8, agilidade: 22),
             habilidadeDeArma: Magia(nome: "Mordida Venenosa", descricao: "Um corte envenenado que corrói o alvo.", icone: "drop.fill", custoEnergia: 38, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .agilidade, multiplicadorDano: 1.35, multiplicadorDanoPorTurno: 0.75, duracaoEmTurnos: 3)),
        Item(nome: "Garras do Predador Noturno", tipo: .arma, valor: 0, preco: 700, raridade: .epico, classeRestrita: .ladino, nivelMinimo: 17, bonus: BonusDeAtributos(inteligencia: 12, destreza: 10, agilidade: 30),
             habilidadeDeArma: Magia(nome: "Instinto Predador", descricao: "O golpe final e certeiro do predador noturno.", icone: "target", custoEnergia: 52, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 3.3, sempreAcerta: true)),

        // Armaduras do Guerreiro — Vitalidade pesada (vida + defesa) e uma
        // proteção direta da própria placa
        Item(nome: "Cota de Malha", tipo: .armadura, valor: 0, preco: 80, raridade: .comum, classeRestrita: .guerreiro, nivelMinimo: 1, bonus: BonusDeAtributos(vitalidade: 4, defesa: 2)),
        Item(nome: "Armadura de Placas", tipo: .armadura, valor: 0, preco: 150, raridade: .incomum, classeRestrita: .guerreiro, nivelMinimo: 5, bonus: BonusDeAtributos(vitalidade: 7, defesa: 3)),
        Item(nome: "Armadura Rúnica", tipo: .armadura, valor: 0, preco: 260, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 10, bonus: BonusDeAtributos(vitalidade: 12, defesa: 5)),
        Item(nome: "Couraça do Titã", tipo: .armadura, valor: 0, preco: 420, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 15, bonus: BonusDeAtributos(vitalidade: 18, defesa: 7)),
        Item(nome: "Bastião Inabalável", tipo: .armadura, valor: 0, preco: 650, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 18, bonus: BonusDeAtributos(forca: 6, vitalidade: 24, defesa: 10)),

        // Armaduras do Mago — leves, Vitalidade menor com Inteligência embutida
        Item(nome: "Manto de Aprendiz", tipo: .armadura, valor: 0, preco: 80, raridade: .comum, classeRestrita: .mago, nivelMinimo: 1, bonus: BonusDeAtributos(vitalidade: 2, inteligencia: 2, defesa: 1)),
        Item(nome: "Robe Élfico", tipo: .armadura, valor: 0, preco: 150, raridade: .incomum, classeRestrita: .mago, nivelMinimo: 5, bonus: BonusDeAtributos(vitalidade: 4, inteligencia: 4, defesa: 2)),
        Item(nome: "Vestes Arcanas", tipo: .armadura, valor: 0, preco: 260, raridade: .raro, classeRestrita: .mago, nivelMinimo: 10, bonus: BonusDeAtributos(vitalidade: 6, inteligencia: 7, defesa: 3)),
        Item(nome: "Manto do Arquimago", tipo: .armadura, valor: 0, preco: 420, raridade: .epico, classeRestrita: .mago, nivelMinimo: 15, bonus: BonusDeAtributos(vitalidade: 9, inteligencia: 11, defesa: 5)),
        Item(nome: "Véu do Infinito", tipo: .armadura, valor: 0, preco: 650, raridade: .epico, classeRestrita: .mago, nivelMinimo: 17, bonus: BonusDeAtributos(vitalidade: 12, inteligencia: 18, defesa: 7)),

        // Armaduras do Ladino — leves, Vitalidade menor com Agilidade embutida
        Item(nome: "Colete de Couro", tipo: .armadura, valor: 0, preco: 80, raridade: .comum, classeRestrita: .ladino, nivelMinimo: 1, bonus: BonusDeAtributos(vitalidade: 3, agilidade: 3, defesa: 1)),
        Item(nome: "Capa de Sombras", tipo: .armadura, valor: 0, preco: 150, raridade: .incomum, classeRestrita: .ladino, nivelMinimo: 5, bonus: BonusDeAtributos(vitalidade: 5, agilidade: 6, defesa: 2)),
        Item(nome: "Traje do Assassino", tipo: .armadura, valor: 0, preco: 260, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 10, bonus: BonusDeAtributos(vitalidade: 7, agilidade: 10, defesa: 3)),
        Item(nome: "Manto Fantasma", tipo: .armadura, valor: 0, preco: 420, raridade: .epico, classeRestrita: .ladino, nivelMinimo: 15, bonus: BonusDeAtributos(vitalidade: 10, agilidade: 15, defesa: 5)),
        Item(nome: "Véu das Mil Sombras", tipo: .armadura, valor: 0, preco: 650, raridade: .epico, classeRestrita: .ladino, nivelMinimo: 17, bonus: BonusDeAtributos(vitalidade: 13, agilidade: 20, defesa: 7)),

        // Acessórios (universais) — cada um empurra a build para um lado
        // diferente, então qualquer classe tem escolhas reais de itemização,
        // incluindo agora Destreza e Sorte.
        Item(nome: "Anel de Foco", tipo: .acessorio, valor: 0, preco: 100, raridade: .comum, nivelMinimo: 1, bonus: BonusDeAtributos(energia: 10)),
        Item(nome: "Bracelete de Força", tipo: .acessorio, valor: 0, preco: 150, raridade: .incomum, nivelMinimo: 4, bonus: BonusDeAtributos(forca: 8)),
        Item(nome: "Amuleto da Mente", tipo: .acessorio, valor: 0, preco: 150, raridade: .incomum, nivelMinimo: 4, bonus: BonusDeAtributos(inteligencia: 8)),
        Item(nome: "Pingente da Agilidade", tipo: .acessorio, valor: 0, preco: 150, raridade: .incomum, nivelMinimo: 4, bonus: BonusDeAtributos(agilidade: 8)),
        Item(nome: "Luva do Atirador", tipo: .acessorio, valor: 0, preco: 150, raridade: .incomum, nivelMinimo: 4, bonus: BonusDeAtributos(destreza: 8)),
        Item(nome: "Moeda da Sorte", tipo: .acessorio, valor: 0, preco: 150, raridade: .incomum, nivelMinimo: 4, bonus: BonusDeAtributos(sorte: 8)),
        Item(nome: "Talismã Arcano", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(inteligencia: 6, energia: 25)),
        Item(nome: "Anel do Predador", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(forca: 4, agilidade: 14)),
        Item(nome: "Bússola da Fortuna", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(destreza: 6, sorte: 10)),
        Item(nome: "Coroa do Vazio", tipo: .acessorio, valor: 0, preco: 600, raridade: .epico, nivelMinimo: 14, bonus: BonusDeAtributos(forca: 8, inteligencia: 8, agilidade: 8, energia: 35)),
        Item(nome: "Relicário do Destino", tipo: .acessorio, valor: 0, preco: 600, raridade: .epico, nivelMinimo: 14, bonus: BonusDeAtributos(vitalidade: 10, destreza: 10, sorte: 10)),

        // Talismãs (universais) — efeitos passivos inspirados em Elden Ring
        // (Erdtree's Favor, Green/Blue Turtle Talisman, Golden/Silver Scarab):
        // não empurram dano ou defesa, mudam o ritmo do jogo (regen, ouro,
        // sorte de loot). Competem pelos mesmos 3 slots de acessório que os
        // itens de atributo puro acima, então equipar um é abrir mão de
        // atributo — a tensão de build que Elden Ring resolve com talismã.
        Item(nome: "Amuleto da Regeneração", tipo: .acessorio, valor: 0, preco: 130, raridade: .incomum, nivelMinimo: 3, bonus: BonusDeAtributos(regenVidaPorTurno: 2)),
        Item(nome: "Talismã do Fôlego Eterno", tipo: .acessorio, valor: 0, preco: 130, raridade: .incomum, nivelMinimo: 3, bonus: BonusDeAtributos(regenEnergiaPorTurno: 2)),
        Item(nome: "Bolsa do Mercador", tipo: .acessorio, valor: 0, preco: 140, raridade: .incomum, nivelMinimo: 2, bonus: BonusDeAtributos(bonusOuroPercentual: 20)),
        Item(nome: "Talismã do Saqueador Ganancioso", tipo: .acessorio, valor: 0, preco: 300, raridade: .raro, nivelMinimo: 8, bonus: BonusDeAtributos(defesa: -3, bonusOuroPercentual: 40)),
        Item(nome: "Olho do Caçador de Tesouros", tipo: .acessorio, valor: 0, preco: 220, raridade: .raro, nivelMinimo: 6, bonus: BonusDeAtributos(bonusChanceDeItemPercentual: 15)),
        Item(nome: "Escaravelho Dourado", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 11, bonus: BonusDeAtributos(bonusOuroPercentual: 35)),
        Item(nome: "Escaravelho Prateado", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 11, bonus: BonusDeAtributos(bonusChanceDeItemPercentual: 25)),
        Item(nome: "Relicário da Raridade", tipo: .acessorio, valor: 0, preco: 450, raridade: .raro, nivelMinimo: 13, bonus: BonusDeAtributos(bonusRaridadeDeItem: 1)),
        Item(nome: "Coração da Fênix", tipo: .acessorio, valor: 0, preco: 600, raridade: .epico, nivelMinimo: 16, bonus: BonusDeAtributos(vitalidade: 4, regenVidaPorTurno: 6)),
        Item(nome: "Poço sem Fundo", tipo: .acessorio, valor: 0, preco: 600, raridade: .epico, nivelMinimo: 16, bonus: BonusDeAtributos(inteligencia: 4, regenEnergiaPorTurno: 6)),
        Item(nome: "Grande Escaravelho Ancestral", tipo: .acessorio, valor: 0, preco: 800, raridade: .epico, nivelMinimo: 19, bonus: BonusDeAtributos(bonusOuroPercentual: 20, bonusChanceDeItemPercentual: 20, bonusRaridadeDeItem: 1))
    ]

    // Itens vendidos no mercado para uma classe: poções e acessórios (universais)
    // mais só as armas/armaduras daquela classe.
    static func catalogoParaClasse(_ classe: ClasseDePersonagem) -> [Item] {
        catalogoMercado.filter { $0.classeRestrita == nil || $0.classeRestrita == classe }
    }

    // Sorteia um item de loot com base no nível do inimigo derrotado e na classe do herói.
    // `garantido` (chefes) empurra o loot uma raridade acima do normal da zona.
    // `bonusRaridade` (soma dos talismãs equipados) dá uma chance extra e
    // probabilística de subir mais um degrau — não é garantido, senão um
    // único talismã tornaria a raridade da zona irrelevante.
    static func lootAleatorio(nivelInimigo: Int, garantido: Bool = false, bonusRaridade: Int = 0, classe: ClasseDePersonagem) -> Item {
        let ordem: [Raridade] = [.comum, .incomum, .raro, .epico]
        var indice: Int
        switch nivelInimigo {
        case ..<4: indice = 0
        case 4..<8: indice = 1
        case 8..<13: indice = 2
        default: indice = 3
        }
        if garantido { indice = min(indice + 1, ordem.count - 1) }
        if bonusRaridade > 0 && Int.random(in: 1...100) <= bonusRaridade * 20 {
            indice = min(indice + 1, ordem.count - 1)
        }

        let pool = catalogoMercado.filter {
            $0.raridade == ordem[indice] && ($0.classeRestrita == nil || $0.classeRestrita == classe)
        }
        return pool.randomElement() ?? catalogoMercado[0]
    }
}
