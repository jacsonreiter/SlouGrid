import SwiftUI

// Os tipos de item que existem no jogo
enum TipoDeItem: String, Codable {
    case pocao
    case arma
    case armadura
    case acessorio
    // Material: troféu de combate que não equipa nem se "usa" — só serve
    // pra entregar em missões de coleta (ver `Missao.TipoDeMissao.coletar`)
    // ou vender por Runas. Alguns são específicos de uma zona (dropam só
    // lá, usados nas missões daquela zona); outros são "quinquilharia"
    // genérica sem uso em missão nenhuma, só pra vender mesmo.
    case material
}

enum EfeitoDePocao: String, Codable {
    case vida
    case energia
    case antidoto
    case aumentaFrascos          // Semente Dourada: aumenta o total de cargas do Frasco Sagrado
    case aumentaPotenciaDoFrasco // Lágrima Sagrada: aumenta a % de cura/restauração de cada uso do Frasco
    case fortalecimento          // poção de buff temporário — só tem efeito em combate, ver Item.efeitoDeBuffTemporario
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
    // O buff de uma poção de fortalecimento (só quando `efeitoDePocao ==
    // .fortalecimento`) — reaproveita `Magia` (o mesmo
    // `TelaDeCombate.aplicarFortalecimento` que já processa as magias de
    // fortalecimento do grimório), então uma poção de Força dá o mesmo tipo
    // de buff que a magia de fortalecimento de uma classe, só que qualquer
    // classe pode carregar uma comprando no mercado. Só faz efeito em
    // combate — `TelaDoPersonagem` esconde o botão "Usar" desse tipo de
    // poção na mochila fora de combate, pra não desperdiçar o item à toa.
    var efeitoDeBuffTemporario: Magia? = nil
    // Só relevante para `tipo == .material`: a zona onde esse material
    // dropa (ver `Item.materialDaZona`). `nil` = material "genérico", sem
    // zona nenhuma — só serve pra vender (ver `Item.materiaisGenericos`).
    var zonaDeOrigem: String? = nil

    // Um acessório conta como talismã (efeito passivo, estilo Elden Ring)
    // se mexer em qualquer um dos campos de efeito de talismã — os
    // acessórios de atributo puro não tocam esses campos. Usado só pra
    // organizar o mercado em abas (ver `TelaDoMercado`).
    var ehTalisma: Bool {
        bonus.regenVidaPorTurno != 0 || bonus.regenEnergiaPorTurno != 0
            || bonus.bonusOuroPercentual != 0 || bonus.bonusChanceDeItemPercentual != 0
            || bonus.bonusRaridadeDeItem != 0
    }

    var descricao: String {
        switch tipo {
        case .pocao:
            switch efeitoDePocao {
            case .vida: return "Cura \(valor) de vida"
            case .energia: return "Restaura \(valor) de energia"
            case .antidoto: return "Remove venenos ativos"
            case .aumentaFrascos: return "Aumenta em \(valor) o total de cargas do Frasco Sagrado"
            case .aumentaPotenciaDoFrasco: return "Aumenta em \(valor)% a cura/restauração do Frasco Sagrado"
            case .fortalecimento:
                guard let buff = efeitoDeBuffTemporario else { return "Fortalecimento temporário (só em combate)" }
                return "\(buff.descricao) (\(buff.duracaoEmTurnos) turnos, só em combate)"
            case .none: return ""
            }
        case .arma, .armadura, .acessorio:
            return bonus.descricaoCurta
        case .material:
            return zonaDeOrigem != nil
                ? "Material raro — entregue em missões de coleta ou venda por Runas."
                : "Quinquilharia sem uso — só serve pra vender por Runas."
        }
    }

    init(nome: String, tipo: TipoDeItem, valor: Int, preco: Int, raridade: Raridade = .comum,
         classeRestrita: ClasseDePersonagem? = nil, efeitoDePocao: EfeitoDePocao? = nil,
         nivelMinimo: Int = 1, bonus: BonusDeAtributos = BonusDeAtributos(),
         habilidadeDeArma: Magia? = nil, efeitoDeBuffTemporario: Magia? = nil,
         zonaDeOrigem: String? = nil) {
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
        self.efeitoDeBuffTemporario = efeitoDeBuffTemporario
        self.zonaDeOrigem = zonaDeOrigem
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
            case .pocao, .material: bonus = BonusDeAtributos()
            }
        }

        zonaDeOrigem = try c.decodeIfPresent(String.self, forKey: .zonaDeOrigem)
        habilidadeDeArma = try c.decodeIfPresent(Magia.self, forKey: .habilidadeDeArma) ?? nil
        efeitoDeBuffTemporario = try c.decodeIfPresent(Magia.self, forKey: .efeitoDeBuffTemporario) ?? nil
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

        // Poções de fortalecimento (universais) — o mesmo tipo de buff
        // temporário das magias de fortalecimento do grimório
        // (`Magia.tipo == .fortalecimento`), só que em garrafa: qualquer
        // classe pode carregar uma, mesmo sem ter essa magia. Só fazem
        // efeito em combate (ver `TelaDeCombate.usarItem` e
        // `Item.efeitoDeBuffTemporario`); usar pela mochila fora de combate
        // não é permitido (`TelaDoPersonagem` esconde o botão "Usar").
        Item(nome: "Fruta da Fúria", tipo: .pocao, valor: 0, preco: 50, raridade: .incomum, efeitoDePocao: .fortalecimento, nivelMinimo: 3,
             efeitoDeBuffTemporario: Magia(nome: "Fúria Momentânea", descricao: "Aumenta a Força por um breve momento.", icone: "bolt.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusForca: 4)),
        Item(nome: "Elixir do Touro Selvagem", tipo: .pocao, valor: 0, preco: 110, raridade: .raro, efeitoDePocao: .fortalecimento, nivelMinimo: 9,
             efeitoDeBuffTemporario: Magia(nome: "Fúria do Touro", descricao: "Aumenta bastante a Força por alguns turnos.", icone: "bolt.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusForca: 7)),
        Item(nome: "Sangue do Colosso", tipo: .pocao, valor: 0, preco: 200, raridade: .epico, efeitoDePocao: .fortalecimento, nivelMinimo: 15,
             efeitoDeBuffTemporario: Magia(nome: "Fúria do Colosso", descricao: "Aumenta violentamente a Força por vários turnos.", icone: "bolt.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 4, bonusForca: 12)),

        Item(nome: "Casca de Ferro", tipo: .pocao, valor: 0, preco: 50, raridade: .incomum, efeitoDePocao: .fortalecimento, nivelMinimo: 3,
             efeitoDeBuffTemporario: Magia(nome: "Pele Endurecida", descricao: "Aumenta a Defesa por um breve momento.", icone: "shield.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusDefesa: 4)),
        Item(nome: "Bálsamo da Muralha", tipo: .pocao, valor: 0, preco: 110, raridade: .raro, efeitoDePocao: .fortalecimento, nivelMinimo: 9,
             efeitoDeBuffTemporario: Magia(nome: "Muralha de Pedra", descricao: "Aumenta bastante a Defesa por alguns turnos.", icone: "shield.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusDefesa: 7)),
        Item(nome: "Couraça Líquida", tipo: .pocao, valor: 0, preco: 200, raridade: .epico, efeitoDePocao: .fortalecimento, nivelMinimo: 15,
             efeitoDeBuffTemporario: Magia(nome: "Bastião Vivo", descricao: "Aumenta violentamente a Defesa por vários turnos.", icone: "shield.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 4, bonusDefesa: 12)),

        Item(nome: "Gota Arcana", tipo: .pocao, valor: 0, preco: 50, raridade: .incomum, efeitoDePocao: .fortalecimento, nivelMinimo: 3,
             efeitoDeBuffTemporario: Magia(nome: "Clareza Arcana", descricao: "Aumenta a Inteligência por um breve momento.", icone: "brain.head.profile", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusInteligencia: 4)),
        Item(nome: "Essência do Vidente", tipo: .pocao, valor: 0, preco: 110, raridade: .raro, efeitoDePocao: .fortalecimento, nivelMinimo: 9,
             efeitoDeBuffTemporario: Magia(nome: "Visão do Vidente", descricao: "Aumenta bastante a Inteligência por alguns turnos.", icone: "brain.head.profile", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusInteligencia: 7)),
        Item(nome: "Lágrima do Cosmos", tipo: .pocao, valor: 0, preco: 200, raridade: .epico, efeitoDePocao: .fortalecimento, nivelMinimo: 15,
             efeitoDeBuffTemporario: Magia(nome: "Mente Cósmica", descricao: "Aumenta violentamente a Inteligência por vários turnos.", icone: "brain.head.profile", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 4, bonusInteligencia: 12)),

        Item(nome: "Pó de Pena", tipo: .pocao, valor: 0, preco: 50, raridade: .incomum, efeitoDePocao: .fortalecimento, nivelMinimo: 3,
             efeitoDeBuffTemporario: Magia(nome: "Passos Leves", descricao: "Aumenta a Agilidade por um breve momento.", icone: "hare.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusAgilidade: 4)),
        Item(nome: "Vento Engarrafado", tipo: .pocao, valor: 0, preco: 110, raridade: .raro, efeitoDePocao: .fortalecimento, nivelMinimo: 9,
             efeitoDeBuffTemporario: Magia(nome: "Rajada Veloz", descricao: "Aumenta bastante a Agilidade por alguns turnos.", icone: "hare.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 3, bonusAgilidade: 7)),
        Item(nome: "Sopro da Tempestade", tipo: .pocao, valor: 0, preco: 200, raridade: .epico, efeitoDePocao: .fortalecimento, nivelMinimo: 15,
             efeitoDeBuffTemporario: Magia(nome: "Fúria da Tempestade", descricao: "Aumenta violentamente a Agilidade por vários turnos.", icone: "hare.fill", custoEnergia: 0, nivelNecessario: 1, tipo: .fortalecimento, duracaoEmTurnos: 4, bonusAgilidade: 12)),

        // Armas do Guerreiro — Força pura, com um toque de Destreza (a arma
        // ajuda a acertar, mesmo que Destreza não seja o forte da classe).
        // Cada uma carrega seu próprio "Golpe de Arma" (`habilidadeDeArma`,
        // estilo Ash of War), reaproveitando o motor de `Magia`.
        Item(nome: "Espada Curta", tipo: .arma, valor: 0, preco: 90, raridade: .comum, classeRestrita: .guerreiro, nivelMinimo: 1, bonus: BonusDeAtributos(forca: 6, destreza: 2),
             habilidadeDeArma: Magia(nome: "Estocada Rápida", descricao: "Uma investida veloz com a lâmina.", icone: "bolt.fill", custoEnergia: 15, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 1.3)),
        Item(nome: "Espada Longa", tipo: .arma, valor: 0, preco: 160, raridade: .incomum, classeRestrita: .guerreiro, nivelMinimo: 5, bonus: BonusDeAtributos(forca: 10, destreza: 3),
             habilidadeDeArma: Magia(nome: "Corte Giratório", descricao: "Um golpe amplo com toda a força do braço.", icone: "tornado", custoEnergia: 22, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 1.8)),
        // Alternativa mais pesada à Espada Longa no mesmo patamar de nível —
        // troca Destreza por Força pura, pra quem quer bater mais forte e
        // não se importa de errar um pouco mais.
        Item(nome: "Martelo da Fúria", tipo: .arma, valor: 0, preco: 220, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 7, bonus: BonusDeAtributos(forca: 14, destreza: 1),
             habilidadeDeArma: Magia(nome: "Pisada Sísmica", descricao: "Um golpe de martelo que sacode o chão.", icone: "hammer.fill", custoEnergia: 30, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 2.0)),
        Item(nome: "Machado de Guerra", tipo: .arma, valor: 0, preco: 280, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 10, bonus: BonusDeAtributos(forca: 16, destreza: 5),
             habilidadeDeArma: Magia(nome: "Fenda-Terra", descricao: "Um golpe pesado que atordoa o alvo.", icone: "hammer.fill", custoEnergia: 35, nivelNecessario: 1, tipo: .atordoante, atributoDeEscala: .forca, multiplicadorDano: 1.6)),
        // Meio-termo entre o Machado (L10) e a Lâmina do Campeão (L15) —
        // alcance maior, um pouco de Vitalidade extra pra sobreviver ao
        // corpo a corpo mais tempo.
        Item(nome: "Alabarda Rúnica", tipo: .arma, valor: 0, preco: 360, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 13, bonus: BonusDeAtributos(forca: 20, vitalidade: 3, destreza: 4),
             habilidadeDeArma: Magia(nome: "Varredura Rúnica", descricao: "Um golpe amplo que atinge com força bruta.", icone: "wind", custoEnergia: 38, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 2.1)),
        Item(nome: "Lâmina do Campeão", tipo: .arma, valor: 0, preco: 450, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 15, bonus: BonusDeAtributos(forca: 24, destreza: 7),
             habilidadeDeArma: Magia(nome: "Lâmina Sangrenta", descricao: "Corta fundo, abrindo um sangramento.", icone: "drop.triangle.fill", custoEnergia: 40, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .forca, multiplicadorDano: 1.4, multiplicadorDanoPorTurno: 0.7, duracaoEmTurnos: 3)),
        Item(nome: "Espada do Titã Ancestral", tipo: .arma, valor: 0, preco: 700, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 18, bonus: BonusDeAtributos(forca: 32, vitalidade: 5, destreza: 9),
             habilidadeDeArma: Magia(nome: "Golpe do Titã", descricao: "O golpe lendário do Titã Ancestral, certeiro e devastador.", icone: "burst.fill", custoEnergia: 55, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .forca, multiplicadorDano: 3.2, sempreAcerta: true)),

        // Armas do Mago — cajados que escalam Inteligência, não Força
        Item(nome: "Cajado de Aprendiz", tipo: .arma, valor: 0, preco: 90, raridade: .comum, classeRestrita: .mago, nivelMinimo: 1, bonus: BonusDeAtributos(inteligencia: 7, destreza: 2),
             habilidadeDeArma: Magia(nome: "Faísca Arcana", descricao: "Uma centelha de energia arcana crua.", icone: "sparkle", custoEnergia: 18, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 1.3)),
        Item(nome: "Cajado Élfico", tipo: .arma, valor: 0, preco: 160, raridade: .incomum, classeRestrita: .mago, nivelMinimo: 5, bonus: BonusDeAtributos(inteligencia: 11, destreza: 3),
             habilidadeDeArma: Magia(nome: "Rajada Élfica", descricao: "Uma sequência de projéteis élficos.", icone: "wind", custoEnergia: 26, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 1.9)),
        // Cajado alternativo do mesmo patamar do Élfico, mais puro em
        // Inteligência e com uma habilidade que aposta em veneno em vez de
        // dano direto.
        Item(nome: "Tomo Sombrio", tipo: .arma, valor: 0, preco: 220, raridade: .raro, classeRestrita: .mago, nivelMinimo: 7, bonus: BonusDeAtributos(inteligencia: 14, destreza: 1),
             habilidadeDeArma: Magia(nome: "Praga Sussurrada", descricao: "Uma maldição que corrói o alvo aos poucos.", icone: "drop.fill", custoEnergia: 28, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .inteligencia, multiplicadorDano: 1.0, multiplicadorDanoPorTurno: 0.6, duracaoEmTurnos: 3)),
        Item(nome: "Cetro Arcano", tipo: .arma, valor: 0, preco: 280, raridade: .raro, classeRestrita: .mago, nivelMinimo: 10, bonus: BonusDeAtributos(inteligencia: 18, destreza: 5),
             habilidadeDeArma: Magia(nome: "Gélido Cortante", descricao: "Um golpe de gelo que atordoa o alvo.", icone: "snowflake", custoEnergia: 38, nivelNecessario: 1, tipo: .atordoante, atributoDeEscala: .inteligencia, multiplicadorDano: 1.5)),
        // Meio-termo entre o Cetro Arcano (L10) e o Bastão dos Videntes
        // (L15) — dá um pouco de Energia extra além do dano puro.
        Item(nome: "Cristal do Abismo", tipo: .arma, valor: 0, preco: 360, raridade: .raro, classeRestrita: .mago, nivelMinimo: 13, bonus: BonusDeAtributos(inteligencia: 22, destreza: 4, energia: 15),
             habilidadeDeArma: Magia(nome: "Fenda do Abismo", descricao: "Uma explosão de energia vinda do abismo.", icone: "sparkles", custoEnergia: 45, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .inteligencia, multiplicadorDano: 2.3)),
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
        // Alternativa mais equilibrada entre Destreza e Agilidade no mesmo
        // patamar dos Punhais Sombrios — menos crítico, mais acerto.
        Item(nome: "Kunais Gêmeas", tipo: .arma, valor: 0, preco: 220, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 7, bonus: BonusDeAtributos(destreza: 8, agilidade: 12),
             habilidadeDeArma: Magia(nome: "Chuva de Kunais", descricao: "Uma saraivada rápida de lâminas arremessadas.", icone: "wind", custoEnergia: 26, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 2.0)),
        Item(nome: "Lâminas do Vento", tipo: .arma, valor: 0, preco: 280, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 10, bonus: BonusDeAtributos(inteligencia: 5, destreza: 6, agilidade: 16),
             habilidadeDeArma: Magia(nome: "Rajada Cortante", descricao: "Um corte veloz que desequilibra o alvo.", icone: "wind.snow", custoEnergia: 32, nivelNecessario: 1, tipo: .atordoante, atributoDeEscala: .agilidade, multiplicadorDano: 1.55)),
        // Meio-termo entre as Lâminas do Vento (L10) e as Presas da Víbora
        // (L15) — aposta em veneno mais cedo, pra quem quer jogar de
        // controle em vez de dano direto.
        Item(nome: "Foice das Sombras", tipo: .arma, valor: 0, preco: 360, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 13, bonus: BonusDeAtributos(inteligencia: 6, destreza: 8, agilidade: 18),
             habilidadeDeArma: Magia(nome: "Colheita Sombria", descricao: "Um corte envenenado vindo das sombras.", icone: "drop.fill", custoEnergia: 36, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .agilidade, multiplicadorDano: 1.2, multiplicadorDanoPorTurno: 0.7, duracaoEmTurnos: 3)),
        Item(nome: "Presas da Víbora", tipo: .arma, valor: 0, preco: 450, raridade: .epico, classeRestrita: .ladino, nivelMinimo: 15, bonus: BonusDeAtributos(inteligencia: 8, destreza: 8, agilidade: 22),
             habilidadeDeArma: Magia(nome: "Mordida Venenosa", descricao: "Um corte envenenado que corrói o alvo.", icone: "drop.fill", custoEnergia: 38, nivelNecessario: 1, tipo: .danoComEfeito, atributoDeEscala: .agilidade, multiplicadorDano: 1.35, multiplicadorDanoPorTurno: 0.75, duracaoEmTurnos: 3)),
        Item(nome: "Garras do Predador Noturno", tipo: .arma, valor: 0, preco: 700, raridade: .epico, classeRestrita: .ladino, nivelMinimo: 17, bonus: BonusDeAtributos(inteligencia: 12, destreza: 10, agilidade: 30),
             habilidadeDeArma: Magia(nome: "Instinto Predador", descricao: "O golpe final e certeiro do predador noturno.", icone: "target", custoEnergia: 52, nivelNecessario: 1, tipo: .dano, atributoDeEscala: .agilidade, multiplicadorDano: 3.3, sempreAcerta: true)),

        // Armaduras do Guerreiro — Vitalidade pesada (vida + defesa) e uma
        // proteção direta da própria placa
        Item(nome: "Cota de Malha", tipo: .armadura, valor: 0, preco: 80, raridade: .comum, classeRestrita: .guerreiro, nivelMinimo: 1, bonus: BonusDeAtributos(vitalidade: 4, defesa: 2)),
        Item(nome: "Armadura de Placas", tipo: .armadura, valor: 0, preco: 150, raridade: .incomum, classeRestrita: .guerreiro, nivelMinimo: 5, bonus: BonusDeAtributos(vitalidade: 7, defesa: 3)),
        Item(nome: "Cota Reforçada", tipo: .armadura, valor: 0, preco: 200, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 7, bonus: BonusDeAtributos(vitalidade: 9, defesa: 4)),
        Item(nome: "Armadura Rúnica", tipo: .armadura, valor: 0, preco: 260, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 10, bonus: BonusDeAtributos(vitalidade: 12, defesa: 5)),
        Item(nome: "Armadura do Bastião", tipo: .armadura, valor: 0, preco: 340, raridade: .raro, classeRestrita: .guerreiro, nivelMinimo: 13, bonus: BonusDeAtributos(vitalidade: 15, defesa: 6)),
        Item(nome: "Couraça do Titã", tipo: .armadura, valor: 0, preco: 420, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 15, bonus: BonusDeAtributos(vitalidade: 18, defesa: 7)),
        Item(nome: "Bastião Inabalável", tipo: .armadura, valor: 0, preco: 650, raridade: .epico, classeRestrita: .guerreiro, nivelMinimo: 18, bonus: BonusDeAtributos(forca: 6, vitalidade: 24, defesa: 10)),

        // Armaduras do Mago — leves, Vitalidade menor com Inteligência embutida
        Item(nome: "Manto de Aprendiz", tipo: .armadura, valor: 0, preco: 80, raridade: .comum, classeRestrita: .mago, nivelMinimo: 1, bonus: BonusDeAtributos(vitalidade: 2, inteligencia: 2, defesa: 1)),
        Item(nome: "Robe Élfico", tipo: .armadura, valor: 0, preco: 150, raridade: .incomum, classeRestrita: .mago, nivelMinimo: 5, bonus: BonusDeAtributos(vitalidade: 4, inteligencia: 4, defesa: 2)),
        Item(nome: "Manto Etéreo", tipo: .armadura, valor: 0, preco: 200, raridade: .raro, classeRestrita: .mago, nivelMinimo: 7, bonus: BonusDeAtributos(vitalidade: 5, inteligencia: 5, defesa: 2)),
        Item(nome: "Vestes Arcanas", tipo: .armadura, valor: 0, preco: 260, raridade: .raro, classeRestrita: .mago, nivelMinimo: 10, bonus: BonusDeAtributos(vitalidade: 6, inteligencia: 7, defesa: 3)),
        Item(nome: "Vestes do Oráculo", tipo: .armadura, valor: 0, preco: 340, raridade: .raro, classeRestrita: .mago, nivelMinimo: 13, bonus: BonusDeAtributos(vitalidade: 7, inteligencia: 9, defesa: 4)),
        Item(nome: "Manto do Arquimago", tipo: .armadura, valor: 0, preco: 420, raridade: .epico, classeRestrita: .mago, nivelMinimo: 15, bonus: BonusDeAtributos(vitalidade: 9, inteligencia: 11, defesa: 5)),
        Item(nome: "Véu do Infinito", tipo: .armadura, valor: 0, preco: 650, raridade: .epico, classeRestrita: .mago, nivelMinimo: 17, bonus: BonusDeAtributos(vitalidade: 12, inteligencia: 18, defesa: 7)),

        // Armaduras do Ladino — leves, Vitalidade menor com Agilidade embutida
        Item(nome: "Colete de Couro", tipo: .armadura, valor: 0, preco: 80, raridade: .comum, classeRestrita: .ladino, nivelMinimo: 1, bonus: BonusDeAtributos(vitalidade: 3, agilidade: 3, defesa: 1)),
        Item(nome: "Capa de Sombras", tipo: .armadura, valor: 0, preco: 150, raridade: .incomum, classeRestrita: .ladino, nivelMinimo: 5, bonus: BonusDeAtributos(vitalidade: 5, agilidade: 6, defesa: 2)),
        Item(nome: "Capa Élfica", tipo: .armadura, valor: 0, preco: 200, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 7, bonus: BonusDeAtributos(vitalidade: 6, agilidade: 8, defesa: 2)),
        Item(nome: "Traje do Assassino", tipo: .armadura, valor: 0, preco: 260, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 10, bonus: BonusDeAtributos(vitalidade: 7, agilidade: 10, defesa: 3)),
        Item(nome: "Manto do Andarilho", tipo: .armadura, valor: 0, preco: 340, raridade: .raro, classeRestrita: .ladino, nivelMinimo: 13, bonus: BonusDeAtributos(vitalidade: 8, agilidade: 12, defesa: 4)),
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
        Item(nome: "Anel Gêmeo", tipo: .acessorio, valor: 0, preco: 240, raridade: .raro, nivelMinimo: 7, bonus: BonusDeAtributos(forca: 4, agilidade: 4)),
        Item(nome: "Colar do Estudioso", tipo: .acessorio, valor: 0, preco: 240, raridade: .raro, nivelMinimo: 7, bonus: BonusDeAtributos(inteligencia: 4, sorte: 4)),
        Item(nome: "Talismã Arcano", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(inteligencia: 6, energia: 25)),
        Item(nome: "Anel do Predador", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(forca: 4, agilidade: 14)),
        Item(nome: "Bússola da Fortuna", tipo: .acessorio, valor: 0, preco: 380, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(destreza: 6, sorte: 10)),
        Item(nome: "Coroa do Vazio", tipo: .acessorio, valor: 0, preco: 600, raridade: .epico, nivelMinimo: 14, bonus: BonusDeAtributos(forca: 8, inteligencia: 8, agilidade: 8, energia: 35)),
        Item(nome: "Relicário do Destino", tipo: .acessorio, valor: 0, preco: 600, raridade: .epico, nivelMinimo: 14, bonus: BonusDeAtributos(vitalidade: 10, destreza: 10, sorte: 10)),
        // Item de fim de jogo "sem resposta errada": um pouco de tudo, pra
        // builds híbridas ou pra quem só quer flexibilidade no último slot.
        Item(nome: "Anel do Equilíbrio", tipo: .acessorio, valor: 0, preco: 750, raridade: .epico, nivelMinimo: 16, bonus: BonusDeAtributos(forca: 3, vitalidade: 3, inteligencia: 3, destreza: 3, agilidade: 3, sorte: 3)),

        // Talismãs (universais) — efeitos passivos inspirados em Elden Ring
        // (Erdtree's Favor, Green/Blue Turtle Talisman, Golden/Silver Scarab):
        // não empurram dano ou defesa, mudam o ritmo do jogo (regen, ouro,
        // sorte de loot). Competem pelos mesmos 3 slots de acessório que os
        // itens de atributo puro acima, então equipar um é abrir mão de
        // atributo — a tensão de build que Elden Ring resolve com talismã.
        Item(nome: "Amuleto da Regeneração", tipo: .acessorio, valor: 0, preco: 130, raridade: .incomum, nivelMinimo: 3, bonus: BonusDeAtributos(regenVidaPorTurno: 2)),
        Item(nome: "Talismã do Fôlego Eterno", tipo: .acessorio, valor: 0, preco: 130, raridade: .incomum, nivelMinimo: 3, bonus: BonusDeAtributos(regenEnergiaPorTurno: 2)),
        Item(nome: "Bolsa do Mercador", tipo: .acessorio, valor: 0, preco: 140, raridade: .incomum, nivelMinimo: 2, bonus: BonusDeAtributos(bonusOuroPercentual: 20)),
        Item(nome: "Talismã do Mercador Itinerante", tipo: .acessorio, valor: 0, preco: 180, raridade: .incomum, nivelMinimo: 4, bonus: BonusDeAtributos(bonusOuroPercentual: 15, bonusChanceDeItemPercentual: 8)),
        Item(nome: "Talismã do Caçador", tipo: .acessorio, valor: 0, preco: 160, raridade: .incomum, nivelMinimo: 5, bonus: BonusDeAtributos(bonusChanceDeItemPercentual: 10)),
        Item(nome: "Talismã do Saqueador Ganancioso", tipo: .acessorio, valor: 0, preco: 300, raridade: .raro, nivelMinimo: 8, bonus: BonusDeAtributos(defesa: -3, bonusOuroPercentual: 40)),
        // Combo único: os dois regens numa peça só, pra quem não quer abrir
        // mão de um slot inteiro só pra um dos dois.
        Item(nome: "Talismã do Vínculo Sombrio", tipo: .acessorio, valor: 0, preco: 340, raridade: .raro, nivelMinimo: 9, bonus: BonusDeAtributos(regenVidaPorTurno: 3, regenEnergiaPorTurno: 3)),
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

    // MARK: - Materiais (troféus de combate)

    // Um material por zona — usado nas missões de coleta daquela zona (ver
    // `Missao.catalogo`) e sempre vendável. Preço sobe com a faixa da
    // zona, como o resto do loot. Nunca entram em `catalogoMercado`: só se
    // consegue dropando, nunca comprando.
    static let materiaisDeZona: [Item] = [
        Item(nome: "Pelo de Lobo Selvagem", tipo: .material, valor: 0, preco: 15, raridade: .comum, zonaDeOrigem: "Floresta Sombria"),
        Item(nome: "Glândula de Sapo Venenoso", tipo: .material, valor: 0, preco: 15, raridade: .comum, zonaDeOrigem: "Pântano Nebuloso"),
        Item(nome: "Fragmento de Cristal Bruto", tipo: .material, valor: 0, preco: 25, raridade: .incomum, zonaDeOrigem: "Cavernas de Pedra"),
        Item(nome: "Osso Gélido Amaldiçoado", tipo: .material, valor: 0, preco: 25, raridade: .incomum, zonaDeOrigem: "Necrópole Congelada"),
        Item(nome: "Fragmento de Runa Antiga", tipo: .material, valor: 0, preco: 40, raridade: .raro, zonaDeOrigem: "Ruínas Antigas"),
        Item(nome: "Emblema do Renegado", tipo: .material, valor: 0, preco: 40, raridade: .raro, zonaDeOrigem: "Fortaleza Abandonada"),
        Item(nome: "Pó Arcano Instável", tipo: .material, valor: 0, preco: 65, raridade: .epico, zonaDeOrigem: "Torre do Feiticeiro"),
        Item(nome: "Fragmento do Vazio", tipo: .material, valor: 0, preco: 65, raridade: .epico, zonaDeOrigem: "Abismo Estelar")
    ]

    // Quinquilharia sem zona nenhuma — dropa em qualquer lugar (chance
    // separada e pequena, ver `Personagem.receberRecompensa`), nenhuma
    // missão pede, só serve pra vender.
    static let materiaisGenericos: [Item] = [
        Item(nome: "Moeda Antiga Enferrujada", tipo: .material, valor: 0, preco: 12, raridade: .comum),
        Item(nome: "Relíquia Quebrada", tipo: .material, valor: 0, preco: 18, raridade: .comum),
        Item(nome: "Pedra Bruta Sem Valor", tipo: .material, valor: 0, preco: 8, raridade: .comum)
    ]

    static func materialDaZona(_ zona: String) -> Item? {
        materiaisDeZona.first { $0.zonaDeOrigem == zona }
    }
}
