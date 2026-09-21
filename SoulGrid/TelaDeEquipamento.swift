import SwiftUI

// Área dedicada do personagem: os atributos totais (base + bônus dos itens)
// e cada peça equipada, com o bônus que ela dá e a opção de remover.
struct TelaDeEquipamento: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var mensagem = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                atributosBox

                slotBox(titulo: "Arma", icone: "bolt.fill", item: vm.heroi.armaEquipada, tipo: .arma)
                slotBox(titulo: "Armadura", icone: "shield.fill", item: vm.heroi.armaduraEquipada, tipo: .armadura)

                ForEach(0..<Personagem.numeroDeSlotsDeAcessorio, id: \.self) { indice in
                    slotBoxAcessorio(indice)
                }

                frascosBox
                runicaBox

                if !mensagem.isEmpty {
                    Text(mensagem)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Equipamento")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Atributos

    // Estilo Elden Ring: escolha o atributo, veja o custo em Runas daquele
    // ponto (sobe conforme o atributo já cresceu) e toque em "+" pra comprar
    // na hora — sem um passo separado de "evoluir" antes de gastar. Cada
    // ponto comprado (em qualquer atributo) também sobe o nível.
    var atributosBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Atributos do Personagem")
                    .font(.headline)
                Spacer()
                Label("Nível \(vm.heroi.nivel)", systemImage: "arrow.up.forward.circle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            Text("\(vm.heroi.ouro) Runas — a mesma moeda do mercado, gastar num atributo compete com comprar equipamento.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(AtributoPrimario.allCases, id: \.self) { atributo in
                linhaDeAtributoDistribuivel(atributo)
            }

            Divider().padding(.vertical, 2)

            linhaDeAtributoDerivado("Vida Máxima", valor: vm.heroi.vidaMaxima, icone: "bandage.fill", cor: .pink)
            linhaDeAtributoDerivado("Defesa", valor: vm.heroi.defesaTotal, icone: "shield.fill", cor: .cyan)
            linhaDeAtributoDerivado(vm.heroi.classe.nomeDoRecurso, valor: vm.heroi.energiaMaximaTotal, icone: "sparkles", cor: .purple)

            if temEfeitoDeTalisma {
                Divider().padding(.vertical, 2)
                if vm.heroi.regenVidaPorTurno > 0 {
                    linhaDeAtributoDerivado("Regen. de Vida/turno", valor: vm.heroi.regenVidaPorTurno, icone: "heart.circle.fill", cor: .red)
                }
                if vm.heroi.regenEnergiaPorTurno > 0 {
                    linhaDeAtributoDerivado("Regen. de \(vm.heroi.classe.nomeDoRecurso)/turno", valor: vm.heroi.regenEnergiaPorTurno, icone: "arrow.clockwise.circle.fill", cor: .blue)
                }
                if vm.heroi.bonusOuroPercentualTotal != 0 {
                    linhaDeAtributoDerivado("Bônus de Runas", valor: vm.heroi.bonusOuroPercentualTotal, icone: "circle.hexagongrid.fill", cor: .orange, sufixo: "%")
                }
                if vm.heroi.bonusChanceDeItemTotal != 0 {
                    linhaDeAtributoDerivado("Bônus de Chance de Item", valor: vm.heroi.bonusChanceDeItemTotal, icone: "shippingbox.fill", cor: .green, sufixo: "%")
                }
                if vm.heroi.bonusRaridadeDeItemTotal > 0 {
                    linhaDeAtributoDerivado("Sorte de Raridade", valor: vm.heroi.bonusRaridadeDeItemTotal, icone: "sparkle", cor: .purple)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }

    private func iconeDoAtributo(_ atributo: AtributoPrimario) -> (String, Color) {
        switch atributo {
        case .forca: return ("bolt.fill", .orange)
        case .vitalidade: return ("heart.fill", .red)
        case .inteligencia: return ("brain.head.profile", .blue)
        case .destreza: return ("scope", .yellow)
        case .agilidade: return ("hare.fill", .mint)
        case .sorte: return ("clover.fill", .green)
        }
    }

    // Mostra o valor base do personagem, o quanto o equipamento contribui, e
    // um botão que já mostra o custo em Runas do próximo ponto (sobe
    // conforme o atributo cresce) e compra na hora ao tocar.
    func linhaDeAtributoDistribuivel(_ atributo: AtributoPrimario) -> some View {
        let (icone, cor) = iconeDoAtributo(atributo)
        let base = vm.heroi.valor(de: atributo)
        let total = vm.heroi.totalDe(atributo)
        let custo = vm.heroi.custoEmRunas(de: atributo)
        let podeComprar = vm.heroi.ouro >= custo

        return HStack {
            Label(atributo.rawValue, systemImage: icone)
                .foregroundColor(cor)
            Spacer()
            if total != base {
                Text("\(base) ")
                    .foregroundColor(.secondary)
                + Text("+\(total - base) ")
                    .foregroundColor(.green)
                + Text("= \(total)")
                    .fontWeight(.semibold)
            } else {
                Text("\(total)")
                    .fontWeight(.semibold)
            }
            Button {
                mensagem = vm.heroi.comprarPonto(em: atributo)
            } label: {
                Label("\(custo) Runas", systemImage: "plus.circle.fill")
                    .font(.caption2)
            }
            .disabled(!podeComprar)
            .foregroundColor(podeComprar ? .green : .gray)
        }
        .font(.subheadline)
    }

    func linhaDeAtributoDerivado(_ nome: String, valor: Int, icone: String, cor: Color, sufixo: String = "") -> some View {
        HStack {
            Label(nome, systemImage: icone)
                .foregroundColor(cor)
            Spacer()
            Text("\(valor > 0 ? "+" : "")\(valor)\(sufixo)")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

    // Só mostra a seção de efeitos de talismã quando algum estiver ativo,
    // pra não poluir a tela de quem só usa acessórios de atributo puro.
    var temEfeitoDeTalisma: Bool {
        vm.heroi.regenVidaPorTurno > 0 || vm.heroi.regenEnergiaPorTurno > 0
            || vm.heroi.bonusOuroPercentualTotal != 0 || vm.heroi.bonusChanceDeItemTotal != 0
            || vm.heroi.bonusRaridadeDeItemTotal > 0
    }

    // MARK: - Slots de equipamento

    func slotBox(titulo: String, icone: String, item: Item?, tipo: TipoDeItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titulo, systemImage: icone)
                .font(.headline)

            if let item = item {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.nome)
                                .fontWeight(.semibold)
                            Text(item.raridade.nome)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(item.raridade.cor.opacity(0.2))
                                .foregroundColor(item.raridade.cor)
                                .cornerRadius(6)
                        }
                        Text(item.bonus.descricaoCurta)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // Ash of War: o Golpe de Arma da peça, só relevante
                        // para armas.
                        if tipo == .arma, let habilidade = item.habilidadeDeArma {
                            Label("\(habilidade.nome) (\(habilidade.custoEnergia) EN)", systemImage: habilidade.icone)
                                .font(.caption)
                                .foregroundColor(.indigo)
                        }
                    }
                    Spacer()
                    Button("Remover") {
                        mensagem = vm.heroi.removerEquipamento(tipo)
                    }
                    .foregroundColor(.red)
                }
            } else {
                Text("Nenhum equipado")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    // Talismã: mesmo visual do slotBox, mas o item vem de um índice do
    // array `acessoriosEquipados` (3 slots), não de uma propriedade única.
    // Equipar continua sendo feito pela mochila (preenche o 1º slot vazio);
    // aqui só se vê e remove.
    func slotBoxAcessorio(_ indice: Int) -> some View {
        let item = vm.heroi.acessoriosEquipados[indice]

        return VStack(alignment: .leading, spacing: 8) {
            Label("Talismã \(indice + 1)", systemImage: "seal.fill")
                .font(.headline)

            if let item = item {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.nome)
                                .fontWeight(.semibold)
                            Text(item.raridade.nome)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(item.raridade.cor.opacity(0.2))
                                .foregroundColor(item.raridade.cor)
                                .cornerRadius(6)
                        }
                        Text(item.bonus.descricaoCurta)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Remover") {
                        mensagem = vm.heroi.removerAcessorio(doSlot: indice)
                    }
                    .foregroundColor(.red)
                }
            } else {
                Text("Vazio — equipe um acessório pela mochila")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Frasco Sagrado

    // Realocação livre e instantânea entre os dois frascos (como o menu de
    // frascos de Elden Ring) — só as cargas atuais precisam de descanso.
    var frascosBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Frasco Sagrado", systemImage: "flask.fill")
                .font(.headline)
            Text("Cura/restaura uma % da vida ou de \(vm.heroi.classe.nomeDoRecurso.lowercased()) máxima, de graça. As cargas só recarregam ao descansar; realoque livremente entre os dois.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack {
                    Text("Vida").font(.caption).foregroundColor(.secondary)
                    Text("\(vm.heroi.frascosDeVidaAlocados)").font(.title3).fontWeight(.semibold).foregroundColor(.pink)
                }
                Spacer()
                VStack(spacing: 4) {
                    Button {
                        mensagem = vm.heroi.realocarFrascos(vida: vm.heroi.frascosDeVidaAlocados + 1, energia: vm.heroi.frascosDeEnergiaAlocados - 1)
                    } label: { Image(systemName: "arrow.left.circle.fill") }
                    .disabled(vm.heroi.frascosDeEnergiaAlocados <= 0)
                    Button {
                        mensagem = vm.heroi.realocarFrascos(vida: vm.heroi.frascosDeVidaAlocados - 1, energia: vm.heroi.frascosDeEnergiaAlocados + 1)
                    } label: { Image(systemName: "arrow.right.circle.fill") }
                    .disabled(vm.heroi.frascosDeVidaAlocados <= 0)
                }
                .font(.title2)
                Spacer()
                VStack {
                    Text(vm.heroi.classe.nomeDoRecurso).font(.caption).foregroundColor(.secondary)
                    Text("\(vm.heroi.frascosDeEnergiaAlocados)").font(.title3).fontWeight(.semibold).foregroundColor(.teal)
                }
            }
            Text("Total: \(vm.heroi.cargasDeFrascoTotal) cargas (Semente Dourada aumenta) · Potência: +\(vm.heroi.potenciaDoFrasco)% (Lágrima Sagrada aumenta)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.teal.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Grande Rúnica

    var runicaBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Grande Rúnica", systemImage: "seal.fill")
                .font(.headline)

            if vm.heroi.runicasConquistadas.isEmpty {
                Text("Derrote o chefe de uma zona pela primeira vez para conquistar sua Grande Rúnica.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Só uma fica ativa por vez. Escolher uma diferente exige descansar para ativá-la.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(Array(vm.heroi.runicasConquistadas).sorted(), id: \.self) { nomeDaZona in
                    linhaDeRunica(nomeDaZona)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    func linhaDeRunica(_ nomeDaZona: String) -> some View {
        let bonus = Personagem.bonusDaRunica(zona: nomeDaZona)
        let ativa = vm.heroi.runicaEquipadaAtiva == nomeDaZona
        let selecionadaPendente = vm.heroi.runicaSelecionada == nomeDaZona && !ativa

        return Button {
            mensagem = vm.heroi.selecionarRunica(nomeDaZona)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grande Rúnica de \(nomeDaZona)")
                        .fontWeight(.semibold)
                    Text(bonus.descricaoCurta)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if ativa {
                    Label("Ativa", systemImage: "checkmark.seal.fill").font(.caption2).foregroundColor(.green)
                } else if selecionadaPendente {
                    Label("Descanse para ativar", systemImage: "bed.double.fill").font(.caption2).foregroundColor(.orange)
                }
            }
        }
        .foregroundColor(.primary)
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(8)
    }
}

struct TelaDeEquipamento_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TelaDeEquipamento().environmentObject(GameViewModel())
        }
    }
}
