# SoulGrid — Notas de Desenvolvimento

> Arquivo de contexto para a próxima sessão. Resume o que foi feito, por quê,
> e o rumo que o jogo está tomando. Não é documentação de referência
> permanente — é um retrato do momento em que foi escrito.

## O que é o SoulGrid hoje

App SwiftUI (iOS) de RPG por turnos, sem gráficos: você cria um herói de uma
das 3 classes, explora zonas (masmorras) derrotando inimigos e chefes, ganha
Runas/itens, gasta Runas pra evoluir de nível (estilo Elden Ring — ver seção
"Runas" abaixo) e equipa armas/armaduras/talismãs. Tudo persiste em
`UserDefaults` via `GameViewModel`.

## O que mudou nesta sessão (em ordem)

1. **Sistema de classes ficou compatível com a identidade de cada uma.**
   Antes, todo mundo evoluía igual. Agora cada classe cresce e joga
   diferente (ver seção de atributos).
2. **Tela de Equipamento** (`TelaDeEquipamento.swift`, nova): mostra os
   atributos do herói, o que está equipado com o bônus de cada peça, e
   permite remover equipamento. Acessível pela tela do personagem.
3. **Card de "Traço da Classe"** saiu da tela do personagem e foi para a
   criação de herói — ajuda a escolher a classe, não precisa repetir depois.
4. **Sistema de pontos de atributo ao subir de nível**, estilo Ragnarok
   Online: nada cresce sozinho, o jogador decide onde investir.
5. **Reformulação para 6 atributos** (Força/Vitalidade/Inteligência/
   Destreza/Agilidade/Sorte), baseada em pesquisa sobre RO e Dark Souls,
   substituindo o sistema anterior de 4 atributos (que tinha "Defesa" fixa
   e todo o recurso de combate escalando só com Inteligência, o que não
   fazia sentido para Guerreiro/Ladino).

## Sistema de atributos atual

| Atributo | Papel principal | Papel secundário |
|---|---|---|
| **Força** | Dano físico (ataque básico + magias `.forca`) | — |
| **Vitalidade** | Vida máxima | Defesa (mitigação) + governa Fôlego (Guerreiro) / Foco (Ladino) |
| **Inteligência** | Dano mágico (magias `.inteligencia`) | Governa a Mana (Mago) |
| **Destreza** | Chance de acerto (ataque básico e magias ofensivas) | — |
| **Agilidade** | Chance de esquiva | Parte do crítico + escala magias `.agilidade` (Ladino) |
| **Sorte** | Chance de crítico | Parte da esquiva |

Fórmulas (em `Personagem.swift`):
- `chanceDeAcerto = min(98, 85 + destrezaTotal / 2)` — sem Destreza ainda
  acerta 85% das vezes; nunca vira obrigatório, só compensa investir.
- `chanceDeCriticoBasico = min(60, 5 + sorteTotal + agilidadeTotal / 4)`
- `chanceDeEsquiva = min(35, agilidadeTotal / 3 + sorteTotal / 6)`
- `vidaMaxima = vidaBase da classe + (nível-1) × vidaBasePorNivel + vitalidadeTotal × 3`
- `energiaMaximaBase = energiaBase da classe + (nível-1) × energiaBasePorNivel + atributoDoRecurso × 2`
  (atributoDoRecurso = Inteligência pro Mago, Vitalidade pro Guerreiro/Ladino)
- Guerreiro tem `reducaoDeDanoPercentual = 0.15` (reduz 15% de todo dano
  recebido) — ninguém mais tem isso, é o traço passivo dele.

**Pontos de atributo**: todas as classes ganham 5 pontos por nível
(`classe.pontosPorNivel`), livres para qualquer um dos 6 atributos. Custo
por ponto sobe a cada 10 investidos: `1 + valorAtual / 10` (soft cap, evita
jogar tudo num atributo só). Gasta-se na tela de Equipamento.

Combate: ataques físicos e magias ofensivas agora podem **errar** (rolagem
de `chanceDeAcerto`) — mecânica nova. Cura e fortalecimento (buffs) nunca
erram, pois miram o próprio herói. Cada classe tem uma magia de nível 2
que ignora essa rolagem (`sempreAcerta: true`): Golpe Certeiro (Guerreiro),
Mísseis Arcanos (Mago), Investida Precisa (Ladino).

## Itens e equipamento

- `BonusDeAtributos` (em `Item.swift`) permite qualquer item dar bônus em
  qualquer combinação dos 6 atributos + Defesa direta + Energia, **mais 5
  campos passivos de talismã** (ver seção abaixo).
- Armas dão principalmente o atributo de dano da classe + um pouco de
  Destreza. Armaduras dão principalmente Vitalidade + uma defesa direta
  menor. Acessórios são universais e cobrem os 6 atributos individualmente,
  mais 2 acessórios épicos híbridos de fim de jogo.
- Todo item tem `nivelMinimo` — trava compra/equipar abaixo do nível, para
  sempre existir um próximo equipamento esperando.
- Catálogo atual: 49 itens (8 poções, 15 armas, 15 armaduras, 11
  acessórios de atributo, 11 talismãs — conferir contagem exata em
  `Item.catalogoMercado`).

### Talismãs (nesta sessão) — inspirado em Elden Ring

Pedido do usuário: itens de buff (regen de vida/mana por turno, +ouro,
+chance/raridade de drop), citando Elden Ring como referência de sistema de
personagem/itens que ele gosta e quer usar de inspiração daqui pra frente.

- **Acessório virou 3 slots** (`Personagem.acessoriosEquipados: [Item?]`,
  `Personagem.numeroDeSlotsDeAcessorio = 3`), estilo talismã de Elden Ring,
  em vez do slot único antigo. Migração de save: o `acessorioEquipado`
  antigo (chave legada `acessorioEquipadoLegado` no `CodingKeys` de
  `Personagem`) vira o slot 0; `Personagem` tem `encode(to:)` escrito à mão
  por causa dessa chave extra sem propriedade correspondente.
- Novos campos em `BonusDeAtributos`: `regenVidaPorTurno`,
  `regenEnergiaPorTurno` (flat, não percentual — aplicados no combate em
  `TelaDeCombate.aplicarRegenPassivaDeTalisma()` e somados ao regen fixo de
  +5 de energia por turno que já existia), `bonusOuroPercentual` (aplicado
  em `Personagem.receberRecompensa`), `bonusChanceDeItemPercentual` (soma
  direto na chance de drop), `bonusRaridadeDeItem` (probabilístico: cada
  ponto dá 20% de chance de subir 1 degrau de raridade no loot, em
  `Item.lootAleatorio` — não é garantido, pra não esvaziar o valor da
  raridade natural da zona).
- 11 talismãs novos no catálogo, universais, nivelMinimo de 2 a 19,
  incluindo 1 trade-off estilo Radagon's Soreseal (`Talismã do Saqueador
  Ganancioso`: +40% ouro, -3 defesa) e 1 combo de fim de jogo (`Grande
  Escaravelho Ancestral`: ouro + chance + raridade ao mesmo tempo).
- Equipar um talismã pela mochila preenche o primeiro slot vazio
  automaticamente; se os 3 estiverem cheios, pede pra remover um primeiro
  na Tela de Equipamento (que agora mostra os 3 slots + os efeitos de
  talismã ativos, só quando algum estiver ativo).
- Validado com `swiftc -typecheck` (ver aviso técnico abaixo) — **não
  testado no Xcode/simulador ainda**.

### Frasco Sagrado, Grande Rúnica e Golpe de Arma (mesma sessão, logo em seguida)

Pedido do usuário: "puxar o que puder encaixar" de Elden Ring pra somar
imersão. Três sistemas novos, todos em `Personagem.swift`:

- **Frasco Sagrado** (estilo Estus Flask): `cargasDeFrascoTotal` (começa em
  3), dividido livremente entre `frascosDeVidaAlocados` e
  `frascosDeEnergiaAlocados` (realocação instantânea, ver
  `realocarFrascos` e a caixa "Frasco Sagrado" em `TelaDeEquipamento`).
  `frascosDeVidaAtuais`/`frascosDeEnergiaAtuais` são as cargas restantes
  *agora*; só recarregam em `descansar()`. Cura 35% da vida máxima /
  restaura 30% da energia máxima por uso (`usarFrascoDeVida`/
  `usarFrascoDeEnergia`), 2 botões novos em `TelaDeCombate`. O total de
  cargas cresce consumindo o item "Lágrima Sagrada" (`EfeitoDePocao
  .aumentaFrascos`, 4 tiers no catálogo, preço alto de propósito — é um
  marco de progresso, não uma compra casual).
- **Grande Rúnica**: ao vencer o chefe de uma zona pela 1ª vez,
  `Personagem.receberRecompensa` adiciona o nome da zona a
  `runicasConquistadas` e retorna `novaRunica` (novo 4º campo na tupla de
  retorno — atualizar qualquer chamador se adicionar outro). Só uma fica
  ativa por vez (`runicaEquipadaAtiva`); escolher outra
  (`selecionarRunica`) só tem efeito depois do próximo `descansar()` —
  igual ativar uma Great Rune num Site of Grace. Bônus por zona vive em
  `Personagem.bonusDaRunica(zona:)`, uma tabela hardcoded pelos 4 nomes de
  zona atuais (**se adicionar uma 5ª zona em `Zona.swift`, adicionar o
  case correspondente aqui também, senão o chefe dela nunca dá bônus
  útil**).
- **Golpe de Arma** (estilo Ash of War): `Item.habilidadeDeArma: Magia?`
  reaproveita a própria `Magia`/`TelaDeCombate.lancarMagia` em vez de um
  sistema paralelo — qualquer arma pode carregar uma. As 15 armas do
  catálogo (5 por classe) ganharam uma cada, escalando no atributo de dano
  da própria arma (Força/Inteligência/Agilidade). Botão novo em
  `TelaDeCombate`, só aparece se a arma equipada tiver uma.
- Mudança colateral importante: **"Descansar" agora aparece sempre** em
  `TelaDoPersonagem` (antes só existia depois de morrer) — é o "Site of
  Grace" do jogo, necessário pra recarregar frasco/ativar rúnica a
  qualquer momento, não só depois de derrota.
- Refactor: todo bônus de atributo (equipamento + Grande Rúnica) passa por
  um único ponto, `Personagem.bonusAtivos: [BonusDeAtributos]` — qualquer
  computed `*Total` futuro deve somar por ali, não direto em
  `itensEquipados`, senão a Grande Rúnica para de contar nele.
- `Magia` virou `Codable` (precisa disso pra viver dentro de um `Item`
  salvo) — `TipoDeMagia` e `AtributoDeEscala` também, ambos agora
  `String`-backed. `Magia.id` virou `var` (era `let`) por causa de um
  warning de síntese de Codable.
- Validado só com `swiftc -typecheck`, mesma ressalva de sempre — **não
  jogado ainda**.

### Runas (substituiu XP) e expansão de masmorras (mesma sessão, logo em seguida)

Dois pedidos do usuário no mesmo turno: (1) trocar o nível por XP por um
sistema de Runas estilo Elden Ring; (2) mais masmorras, organizadas por
faixa de nível, com vários lugares e variedade de inimigos/chefes por
faixa — não só uma arena a cada tanto nível. Perguntei 3 coisas antes de
implementar (moeda única vs. duas moedas; penalidade de morte sim/não;
tamanho da expansão) e o usuário escolheu as 3 opções recomendadas.

- **`experiencia`/`xpNecessario`/`ganharExperiencia` foram removidos.**
  `ouro` (o campo continua com esse nome no código, só a UI virou "Runas" —
  ver comentário em cima do campo em `Personagem.swift`) agora é a única
  moeda: compra no mercado E paga pra melhorar atributos (ver próxima seção
  — o primeiro rascunho daqui tinha um botão "Evoluir" separado que dava 5
  pontos de uma vez; foi substituído no mesmo dia por compra direta por
  atributo, a pedido do usuário).
- **Sem penalidade de morte** — morrer continua só mandando descansar, não
  perde Runas (diferente do Elden Ring de verdade; foi decisão explícita do
  usuário pra não frustrar numa base já sem gráficos ricos).
- `Personagem.receberRecompensa` agora retorna `(runas: Int, item: Item?,
  novaRunica: String?)` em vez de `(xp:, ouro:, item:, novaRunica:)` — some
  `Inimigo.xpRecompensa + Int.random(in: ouroRecompensa)` num valor só. Os
  dois campos em `Inimigo`/`Zona.swift` continuam separados só pra não
  precisar reajustar todos os números de spawn de `Zona.swift`.
- **`zonasDoJogo` dobrou de 4 para 8**: cada uma das 4 faixas de nível
  (1+/4+/8+/13+, batendo com os degraus de raridade de
  `Item.lootAleatorio`) ganhou uma 2ª masmorra irmã (mesmo
  `nivelBaseInimigos`, elenco de inimigos/chefe próprio): Pântano Nebuloso,
  Necrópole Congelada, Fortaleza Abandonada, Abismo Estelar. Teto de nível
  do jogo continua ~20, nenhum item precisou de recalibração.
  `TelaDeMasmorras` agora agrupa as zonas por faixa com um cabeçalho de
  seção (`faixaBox`/`faixasDeNivel`/`rotuloDaFaixa`), calculado
  dinamicamente a partir dos `nivelMinimo` distintos — não hardcoded.
- **Toda zona nova precisa de um case em `Personagem.bonusDaRunica(zona:)`**
  (Grande Rúnica do chefe dela) — as 4 novas já têm, mas isso vale pra
  qualquer 9ª zona futura também.
- Validado só com `swiftc -typecheck` — **não jogado ainda**.

### Evolução por atributo direto + Lágrima/Semente separadas (mesma sessão, refinamento)

O usuário jogou pouco depois de ler o resumo e pediu 2 ajustes finos:

1. **O "Evoluir" (custo fixo → 5 pontos genéricos) virou compra direta por
   atributo**, exatamente como o menu de nível de Elden Ring: cada linha de
   atributo em `TelaDeEquipamento` já mostra o custo em Runas do próximo
   ponto *daquele* atributo (sobe a cada 10 pontos investidos, mesmo soft
   cap de antes) e comprar é 1 toque — sem selecionar/confirmar em duas
   telas diferentes. `Personagem.evoluir()`/`custoDeEvoluir()`/
   `distribuirPonto()`/`custoDoProximoPonto()`/`pontosDeAtributoDisponiveis`
   foram todos removidos; entra `comprarPonto(em:)` +
   `custoEmRunas(de:)`/`custoEmRunas(valorAtual:)` (fórmula:
   `(1 + valorAtual/10) * 20` Runas).
   `ClasseDePersonagem.pontosPorNivel` também saiu (não existe mais "pontos
   por nível", só pontos individuais).
2. **`nivel` virou computed**, `1 + pontosTotaisComprados / 5` — cada ponto
   comprado em QUALQUER atributo soma pra esse total, preservando a mesma
   curva de progressão de antes (5 pontos = 1 nível), só que sem o passo
   intermediário de "evoluir" antes de gastar. **Migração**: saves antigos
   tinham `nivel` guardado direto — agora tem uma chave legada
   (`nivelLegado`, mapeada pra `"nivel"` no JSON) que vira
   `pontosTotaisComprados = (nivelAntigo - 1) * 5` na primeira leitura,
   preservando o nível exato de heróis salvos antes desta mudança.
3. **Sementes Douradas ≠ Lágrimas Sagradas** — o usuário corrigiu que em
   Elden Ring são dois upgrades de frasco separados: Golden Seed aumenta a
   QUANTIDADE de cargas, Sacred Tear aumenta a POTÊNCIA (cura por uso). O
   catálogo antigo só tinha um (`aumentaFrascos`, chamado "Lágrima
   Sagrada") — renomeado pra "Semente Dourada" (mesmo efeito, quantidade) e
   criado um novo item "Lágrima Sagrada" de verdade, com efeito novo
   (`EfeitoDePocao.aumentaPotenciaDoFrasco` →
   `Personagem.potenciaDoFrasco`, um % somado à cura/restauração base de
   35%/30% em `usarFrascoDeVida`/`usarFrascoDeEnergia`). 4 tiers de cada,
   mesmos níveis de gate (1/6/11/16).
- Validado só com `swiftc -typecheck` — **ainda não jogado com essa
  versão**. A fórmula `custoEmRunas` é nova (20× o soft cap antigo) e não
  foi calibrada contra o ritmo real de ganho de Runas em combate — é o
  próximo número a sentir jogando de verdade.

## Telas

- `TelaCriacaoDePersonagem` — escolha de classe + traço passivo dela.
- `TelaDeHerois`, `TelaDoPersonagem` — hub principal do herói.
- `TelaDeEquipamento` (nova) — atributos, evoluir de nível, equipamento com
  opção de remover, frasco sagrado, grande rúnica.
- `TelaDeMasmorras` — agora agrupa as 8 zonas por faixa de nível.
- `TelaDeCombate`, `TelaDoMercado` — refletem Runas em vez de Ouro/XP.

## Avisos técnicos importantes

- **Este projeto usa referências explícitas no `project.pbxproj`** (não é
  o modelo novo de pastas sincronizadas do Xcode). Criar um arquivo `.swift`
  novo no disco **não** o adiciona ao target — precisa adicionar via Xcode
  ("Add Files to SoulGrid...") ou editar o `project.pbxproj` manualmente
  (4 seções: `PBXBuildFile`, `PBXFileReference`, grupo `SoulGrid` e
  `PBXSourcesBuildPhase`). Isso já causou um erro de build nesta sessão
  (`TelaDeEquipamento.swift` "Cannot find in scope") — resolvido, mas fica
  o alerta para o próximo arquivo novo.
- Não há Xcode.app instalado neste ambiente de terminal, só Command Line
  Tools — por isso a validação de código foi feita com
  `swiftc -typecheck` direto contra o SDK do macOS (stubando UIKit e
  `navigationBarTitleDisplayMode`), não com `xcodebuild` de verdade. **O
  build real e o playtest só podem ser feitos no Xcode do usuário.**
- Saves antigos (`UserDefaults`) decodificam de forma tolerante: heróis
  criados antes de um atributo existir recebem o valor base da classe para
  ele. Não há migração real de "Defesa antiga" para "Vitalidade" — quem
  tinha Defesa investida no sistema anterior perde esse investimento (só
  relevante para heróis de teste criados durante esta sessão).

## Deploy: GitHub + TestFlight (sessão separada, em aberto — RETOMAR DAQUI)

Pedido do usuário: colocar o projeto no GitHub e conseguir enviar pro
TestFlight/App Store. Isso é sobre infraestrutura de build/publicação, não
sobre o jogo em si — mas ficou em aberto (bloqueado num erro de
autenticação) e é a prioridade #1 da próxima sessão se o assunto for
retomado.

### O que já está pronto

- **Repositório**: https://github.com/jacsonreiter/SlouGrid (público),
  branch `main`. Git local configurado com autor "Jacson Reiter"
  (jacson_reiter@hotmail.com), `.gitignore` cobrindo build/DerivedData/
  xcuserdata/certificados.
- **Ícone do app**: `SoulGrid/Assets.xcassets/AppIcon.appiconset/
  AppIcon-1024.png` — recortado do emblema (espada+hexágono) de
  `~/Desktop/IMG_6153.JPG`, 1024×1024, RGB sem alpha, sem o texto "Soul
  Grid RPG" (Apple recomenda ícone sem o nome do app escrito nele).
- **Bundle ID** `jr.SoulGrid`, `DEVELOPMENT_TEAM = VFPXSCUCXD` (Team do
  usuário, capturado automaticamente quando ele configurou Signing &
  Capabilities no Xcode local).
- **Scheme compartilhado**: `SoulGrid.xcodeproj/xcshareddata/xcschemes/
  SoulGrid.xcscheme` — precisou ser criado à mão (o projeto só tinha
  scheme autocriado/local, que não vai pro git e não existe em CI). Sem
  isso `xcodebuild -scheme SoulGrid` falha em qualquer máquina que não seja
  a do usuário.

### O obstáculo real: hardware do usuário não roda o Xcode exigido

O Mac do usuário é um **MacBook Pro 13" de 2015 (MacBookPro12,1)**, preso
no **macOS Monterey 12.7.6** (é o teto oficial da Apple pra esse modelo —
não recebe Sequoia/Tahoe). Isso trava o Xcode local em no máximo **14.2**,
cujo SDK mais novo é o **iOS 16.2**. Desde 28/abr/2026 a Apple exige builds
com o **SDK do iOS 26 (Xcode 26+)** pra aceitar qualquer envio no App
Store Connect, e o Xcode 26 exige **macOS Sequoia 15.6+** — que a Apple
não libera pra esse hardware. **Não é config, é teto físico**: esse Mac
não vai conseguir enviar pro App Store Connect via Xcode local, ponto.
Codar/testar no simulador nesse Mac continua funcionando numa boa (SDK
iOS 16.2 é suficiente pra isso), só o envio final que não rola.

Opções discutidas com o usuário: GitHub Actions (escolhida), pedir
emprestado um Mac mais novo, alugar Mac na nuvem (MacInCloud etc.), ou
OpenCore Legacy Patcher (não oficial, arriscado). **Escolhida: GitHub
Actions**, já que o repositório já estava no GitHub.

### Solução em andamento: build + upload via GitHub Actions

Arquivos criados (todos já commitados/pushed):
- `.github/workflows/testflight.yml` — dispara só manualmente
  (`workflow_dispatch`, aba Actions → Run workflow), roda em `macos-26`
  (runner com Xcode 26 de verdade). Passos: checkout → importa
  certificado+provisioning profile num keychain temporário (receita
  oficial do GitHub) → importa a chave da App Store Connect API →
  `xcodebuild archive` → `xcodebuild -exportArchive` (com
  `destination: upload` no plist, exporta E envia pro App Store Connect
  num passo só, sem precisar de Apple ID/senha) → limpa keychain/chave no
  final.
- `ExportOptions.plist` (raiz do repo) — `method: app-store-connect`,
  `destination: upload`, `teamID: VFPXSCUCXD`, `signingStyle: automatic`.
- 7 GitHub Secrets criados pelo usuário (nomes exatos, todos no repo
  SlouGrid): `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`,
  `BUILD_PROVISION_PROFILE_BASE64`, `KEYCHAIN_PASSWORD`,
  `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`,
  `APP_STORE_CONNECT_API_KEY_BASE64`. **Importante**: o usuário tem outro
  projeto/repo, "Finvy", na mesma conta Apple Developer — foram criadas
  credenciais NOVAS e separadas pro SoulGrid (certificado adicional, API
  Key adicional) em vez de reaproveitar/revogar as do Finvy, exatamente
  pra não quebrar o Finvy. Segredos do GitHub são só-escrita (ninguém lê o
  valor de volta, nem pela API), então nunca dá pra "copiar" de um repo pro
  outro — só recriar.

### Estado atual: travado num 401 de autenticação (não resolvido ainda)

3 execuções do workflow, todas falhando no step **Archive**, sempre com o
mesmo erro:
```
error: Communication with Apple failed: A non-HTTP 200 response was
received (401) for URL .../listTeams.action?clientId=...
error: No profiles for 'jr.SoulGrid' were found: ... iOS App Development
provisioning profiles matching 'jr.SoulGrid'.
```
(runs: 35641020939, 35641547445, 35643077280 — todas no repo SlouGrid)

O 401 é a causa raiz (autenticação da chave da API falhando); o "no
profiles found" é consequência (sem autenticar, o Xcode não consegue
negociar signing automático). Adicionei um step de diagnóstico
("Sanity-check API key secrets", sem imprimir nenhum valor de secret) que
já confirmou que **o formato dos 3 segredos da API Key está correto**:
Key ID com 10 caracteres, Issuer ID com 36 (UUID), arquivo `.p8`
decodificado com 257 bytes e cabeçalho/rodapé `BEGIN/END PRIVATE KEY`
corretos. Ou seja, não é problema de copiar/colar quebrado — é a
**chave em si** que a Apple está rejeitando.

**Hipótese mais provável, ainda não testada**: o `APP_STORE_CONNECT_API_KEY_ID`
e o `APP_STORE_CONNECT_API_KEY_BASE64` podem ser de **duas gerações de
chave diferentes** (ex: copiou o ID de uma tentativa e o `.p8` de outra),
ou a chave usada não está com status "Active" em App Store Connect →
Users and Access → Integrations → App Store Connect API. Outras hipóteses
menos prováveis: Issuer ID de contexto de Team errado (se o usuário tiver
acesso a mais de um Team), ou delay de propagação de uma chave recém-criada
(geralmente resolve em poucos minutos).

**Próximo passo sugerido pro usuário** (ainda não confirmado se resolveu):
gerar uma chave de API nova do zero, copiar o Key ID e baixar/converter o
`.p8` NA MESMA sessão (sem misturar com arquivos de tentativas antigas),
conferir que aparece "Active" na lista, atualizar os 2 secrets juntos, e
rodar de novo.

### Se retomar esse assunto numa próxima sessão

1. Perguntar se o usuário já tentou de novo por conta própria, e se sim,
   pedir o log do step "Archive" da run mais recente (dá pra listar runs
   via `curl https://api.github.com/repos/jacsonreiter/SlouGrid/actions/runs`,
   é repo público, funciona sem autenticação — só não dá pra baixar o log
   bruto de um step sem permissão de admin no repo, por isso sempre foi
   pedido pro usuário colar o texto manualmente).
2. Se o 401 persistir mesmo com uma chave nova/confirmada "Active", pode
   valer testar a chave isoladamente com uma chamada de API mais simples
   (ex: `curl` gerando um JWT manualmente e chamando
   `https://api.appstoreconnect.apple.com/v1/apps`) pra isolar se o
   problema é mesmo a chave ou algo específico do fluxo do `xcodebuild`.
3. Uma vez o Archive funcionar, o próximo passo (`Export and upload`) usa
   as mesmas credenciais — se o Archive passar, é provável que o upload
   também passe, mas ainda não foi testado nem uma vez com sucesso.

## Ainda não feito / ideias em aberto

- **Nenhum playtest real** dos números foi feito — tudo é estimativa
  baseada em fórmulas de referência (RO, Dark Souls). Primeira coisa a
  fazer na próxima sessão: abrir no Xcode, rodar no simulador, jogar com
  as 3 classes e sentir se a curva de dificuldade/poder está boa.
- Inimigos (`Inimigo.swift`/`Zona.swift`) continuam simples (força/defesa
  únicos, sem Destreza/Agilidade própria) — a chance de acerto do jogador
  é uma fórmula fixa, não compara contra evasão real do inimigo. Se quiser
  mais profundidade, dava para dar atributos aos inimigos também.
- Nenhuma magia usa Destreza/Sorte como buff temporário ainda (só existem
  buffs de Força/Defesa/Inteligência/Agilidade) — ficou de fora para não
  inflar demais o escopo desta sessão.
- Poções continuam só com efeito instantâneo (vida/energia/antídoto); não
  há poções de buff temporário — o regen por turno agora existe, mas só via
  talismã equipado (passivo, permanente enquanto equipado), não como
  consumível de duração limitada.
- **Ash of War, Great Rune, Talismãs e Runas já entraram** (ver seções
  acima). Perda de Runas ao morrer (o "drop runas" de Elden Ring de
  verdade) foi perguntada explicitamente ao usuário e **recusada de
  propósito** — não é uma pendência, é uma decisão de design tomada.
  Outras ideias de Elden Ring ainda não avaliadas: algo equivalente a
  Spirit Ashes (invocação que luta junto — provavelmente demais para o
  escopo de combate 1v1 atual), infusões/afinidades de arma (trocar o
  atributo de escala de uma arma, não só a habilidade).
- **Playtest ficou ainda mais urgente** depois desta sessão: o custo de
  evoluir (`nivel * 100` Runas) nunca foi calibrado sabendo que a mesma
  Runa também compra equipamento — pode estar alto/baixo demais agora que
  compete de verdade com o mercado. Primeira coisa a sentir jogando de
  verdade.
- Golpe de Arma: as 15 magias de arma novas usam `nivelNecessario: 1`
  (irrelevante pra elas, já que quem trava é o `nivelMinimo` da própria
  arma) — se esse campo um dia passar a ser lido em outro contexto que não
  o grimório da classe, revisar.
