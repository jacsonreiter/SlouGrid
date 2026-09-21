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

## Deploy: GitHub + TestFlight — RESOLVIDO (sessão seguinte)

O 401 documentado abaixo não era mais o problema real nesta sessão (a
autenticação da API Key já funcionava sozinha, por motivo não confirmado —
possivelmente a chave nova gerada pelo usuário, sugerida no fim da seção
anterior, propagou). A causa real, descoberta lendo os logs reais do GitHub
Actions run a run: `CODE_SIGN_STYLE = Automatic` sem `CODE_SIGN_IDENTITY`
explícito faz o Xcode sempre exigir um certificado de **Desenvolvimento**
no passo de Archive — é assim que a assinatura automática da Apple
funciona, distribuição só entra no passo de export — mas só havia
certificado de Distribuição importado no keychain do CI. Forçar
`CODE_SIGN_IDENTITY=Apple Distribution` sem mudar o estilo gerou outro erro
("conflicting provisioning settings"). Corrigido trocando só o passo de
Archive pra assinatura **manual** (`CODE_SIGN_STYLE=Manual` +
`CODE_SIGN_IDENTITY=Apple Distribution` + `PROVISIONING_PROFILE=<UUID
extraído do .mobileprovision importado>`), sem negociar nada com a Apple
nesse passo — o Export continua automático com a API Key, já que
`-exportArchive` com method `app-store-connect` não tem ambiguidade sobre
precisar de Distribuição. Validado disparando o workflow direto na branch
via API do GitHub e lendo os logs a cada tentativa, até um run passar de
ponta a ponta com "Upload succeeded" no App Store Connect. PR:
https://github.com/jacsonreiter/SlouGrid/pull/1.

## Deploy: GitHub + TestFlight (histórico da sessão anterior, já resolvido acima)

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

## Sessão de melhorias pós-TestFlight (combate + exploração)

Depois do deploy resolvido, o usuário pediu pra continuar puxando
referências de Elden Ring e melhorar as áreas de exploração especificamente.

- **Bug corrigido: Defesa do inimigo nunca era usada em combate.** O campo
  `Inimigo.defesa` (calculado em `Zona.swift` pra todo inimigo/chefe) nunca
  era lido em `TelaDeCombate.atacar()`/`lancarMagia()` — todo inimigo tinha
  defesa efetiva zero, só a força dele importava. Corrigido subtraindo
  `inimigo.defesa` do dano final nos dois pontos (dano básico e dano de
  magia/Golpe de Arma, que reaproveita `lancarMagia`), espelhando como a
  Defesa do herói já funcionava em `Personagem.sofrerDano`. Veneno (dano por
  turno) continua ignorando defesa de propósito, como sangramento/veneno em
  Elden Ring. **Isso deixa os combates (principalmente chefes, cuja defesa
  escala mais rápido: `4 + nível*2` vs `1 + nível` do comum) mais difíceis
  do que qualquer sensação prévia — primeira coisa a sentir jogando.**
- **Sistema de exploração com variedade** (`Zona.sortearEncontro()`,
  `TipoDeEncontro`): botão "Explorar" agora sorteia entre 3 resultados,
  estilo o mapa aberto de Elden Ring — 80% inimigo comum (como antes), 8%
  inimigo de **Elite** (`Zona.gerarInimigoDeElite`: um "field boss" — vida
  ×1.6, força ×1.3, +3 defesa, recompensa ×2.2/×2 — sem contar pra vitórias
  do chefe nem dar Grande Rúnica), 12% **Descoberta** pacífica
  (`Personagem.receberDescoberta`: Runas + chance de item, sem combate
  nenhum, tipo um cadáver ou baú achado no caminho). Como uma Descoberta nem
  abre a tela de combate, `TelaDeMasmorras` teve que trocar o botão
  "Explorar" de `NavigationLink` estático pra `Button` +
  `.navigationDestination(item:)` (o sorteio acontece antes de navegar) — um
  novo tipo `EncontroPendente` guarda a zona + se é elite; a Descoberta
  mostra um `.alert` na hora, sem navegar. "Desafiar Chefe" continua
  `NavigationLink` normal (determinístico, não precisa desse fluxo).
- Nenhum arquivo novo foi criado (só editados os existentes), então não
  precisou mexer no `project.pbxproj` (ver aviso técnico sobre isso mais
  abaixo).
- Validado só lendo o código com cuidado — **sem Xcode/simulador neste
  ambiente** (container Linux, `swiftc`/`xcodebuild` não existem aqui). A
  validação real veio de disparar o workflow de TestFlight (que faz um
  `xcodebuild archive` de verdade num runner macOS) depois dessas mudanças —
  ver resultado no PR #1. Ainda assim, **nenhum playtest humano** dessas
  mudanças específicas foi feito.
- Ideias discutidas mas não implementadas ainda, se quiser continuar nessa
  linha: infusões/afinidades de arma (trocar o atributo de escala de uma
  arma via um item consumível, tipo pedra de reforço), Spirit Ashes
  (invocação que luta junto — provavelmente grande demais pro combate 1v1
  atual), pontos de interesse temáticos por zona (textos de descoberta
  únicos por lugar em vez de genéricos), pequenos "field bosses" com nomes
  próprios (não só "<Inimigo> de Elite") pra ganhar mais personalidade.

## Sistema de evolução virou "menu de nível" de verdade (sessão seguinte)

Pedido do usuário: o sistema de evoluir devia funcionar **igual** ao menu de
nível de Elden Ring — aloca pontos em vários atributos, o custo sobe
conforme o nível geral (não por atributo), e só gasta Runas de verdade ao
confirmar. A versão anterior (`comprarPonto`) comprava 1 ponto por vez,
na hora, com custo por atributo individual (soft cap tipo Ragnarok Online)
— não era isso que o usuário queria.

- `Personagem.custoEmRunas(valorAtual:)` (por atributo) foi substituído por
  `custoEmRunas(pontosTotaisComprados:)` — o custo do próximo ponto depende
  só de quantos pontos o personagem já tem no total (proxy do nível), nunca
  de qual atributo está sendo melhorado. Concentrar tudo numa coisa só
  custa exatamente o mesmo que espalhar — é assim que funciona no jogo de
  referência (o soft cap por atributo que existia antes foi removido de
  propósito).
- `comprarPonto(em:)` (compra imediata, 1 por vez) foi substituído por
  `confirmarEvolucao(_ alocacoes: [AtributoPrimario: Int])` — aplica vários
  pontos de uma vez e cobra o custo total (soma do custo de cada ponto,
  incrementando o "nível provisório" a cada um). Tudo ou nada: sem Runas
  suficientes pro total, nada é alterado.
- Novos helpers: `custoDoProximoPonto(pontosPendentes:)`,
  `custoTotal(pontosPendentes:)`, `nivelPrevisto(comPontosPendentes:)` — pra
  UI pré-visualizar custo/nível antes de confirmar.
- `TelaDeEquipamento` ganhou `@State private var alocacoes: [AtributoPrimario: Int]`
  — estado local, não persistido (sair da tela sem confirmar descarta a
  alocação sem custo, igual sair do menu de nível sem confirmar no jogo de
  referência). Cada linha de atributo agora tem botões "-"/"+" que só
  ajustam a alocação pendente (mostrada em laranja ao lado do valor base e
  do bônus de equipamento); uma caixa de confirmação aparece só quando há
  pontos pendentes, mostrando pontos alocados, "Nível X → Y" previsto, custo
  total, e os botões Confirmar/Cancelar.
- Validado só lendo o código com cuidado — sem Xcode/simulador neste
  ambiente. **Ainda não jogado** com essa versão.

## Mercado com abas + expansão grande do catálogo (sessão seguinte)

Pedido do usuário: organizar o Mercado em abas (Poções/Armas/Armaduras/
Acessórios/Talismãs) e criar itens novos "usando a imaginação", pra todas
as classes.

- **`TelaDoMercado` ganhou abas** (`AbaDoMercado`, `Picker` segmentado no
  topo). Acessórios e Talismãs usam o mesmo `TipoDeItem.acessorio` por
  baixo — a separação é feita por `Item.ehTalisma` (computed: true se
  algum campo de efeito passivo do `BonusDeAtributos` estiver preenchido),
  não por um campo novo salvo. Cada aba ordena por `nivelMinimo`.
- **Poções de fortalecimento — item novo que fechou uma lacuna antiga**
  (a seção "Ainda não feito" já citava isso há duas sessões: "não há
  poções de buff temporário"). 12 poções novas (4 atributos × 3 tiers:
  Força/Defesa/Inteligência/Agilidade, cada uma leve/média/forte), usando
  um novo `EfeitoDePocao.fortalecimento` + `Item.efeitoDeBuffTemporario:
  Magia?` — reaproveita o mesmo `Magia.tipo == .fortalecimento` das magias
  de fortalecimento do grimório, só que em garrafa, disponível pra
  qualquer classe. A lógica de aplicar o buff (`bonusForcaTemporario` etc.
  em `TelaDeCombate`) foi extraída pra `aplicarFortalecimento(_ magia:)`,
  reaproveitada tanto por `lancarMagia` quanto pelo novo caminho em
  `usarItem`. **Importante**: só funciona em combate (mexe em `@State` que
  só existe em `TelaDeCombate`); `Personagem.usarItem` só consome o item e
  devolve uma mensagem genérica quando `efeito == .fortalecimento` — quem
  aplica o bônus de verdade é `TelaDeCombate.usarItem`. Por isso
  `TelaDoPersonagem.linhaDaMochila` esconde o botão "Usar" desse tipo de
  poção fora de combate (mostra "Use em combate" em cinza), senão o
  jogador desperdiçaria o item sem efeito nenhum.
- **6 armas novas** (2 por classe, níveis 7 e 13, preenchendo os buracos
  entre os tiers já existentes de 1/5/10/15/18): Martelo da Fúria/Alabarda
  Rúnica (Guerreiro), Tomo Sombrio/Cristal do Abismo (Mago), Kunais
  Gêmeas/Foice das Sombras (Ladino) — cada uma com identidade própria
  (ex: Martelo troca Destreza por mais Força; Tomo Sombrio aposta em
  veneno em vez de dano direto), todas com seu próprio Golpe de Arma.
- **6 armaduras novas** (2 por classe, mesmos níveis 7/13): Cota
  Reforçada/Armadura do Bastião (Guerreiro), Manto Etéreo/Vestes do
  Oráculo (Mago), Capa Élfica/Manto do Andarilho (Ladino).
- **3 acessórios novos**: Anel Gêmeo (Força+Agilidade) e Colar do
  Estudioso (Inteligência+Sorte) no nível 7, e Anel do Equilíbrio (+3 em
  TODOS os 6 atributos) no nível 16 como item de fim de jogo "sem
  resposta errada".
- **3 talismãs novos**: Talismã do Mercador Itinerante (ouro+chance de
  item combinados, nível 4), Talismã do Caçador (chance de item, nível 5),
  Talismã do Vínculo Sombrio (os dois regens — vida E energia — numa peça
  só, nível 9).
- Nenhum arquivo novo foi criado (só editados os existentes), então não
  precisou mexer no `project.pbxproj`.
- Validado só lendo o código com cuidado, incluindo checagem de
  parênteses/colchetes/chaves balanceados via script — sem Xcode/simulador
  neste ambiente. **Ainda não jogado** com essa versão.

## Masmorras mais desafiadoras: golpe telegrafado de chefe + sequência de risco/recompensa (sessão seguinte)

Pedido do usuário: melhorar as masmorras pra desafiar de verdade e dar
vontade de continuar jogando/evoluindo. Pesquisei (via busca na web)
princípios de design de roguelike e Souls-like antes de implementar —
resumo do que voltou e como virou código:

- **Telegraphing de boss é o padrão-ouro de dificuldade justa** (fontes:
  gamedesignskills.com, game-wisdom.com, itch.io sobre boss design) —
  ataques fortes devem ser avisados com antecedência, o jogador aprende o
  padrão e reage, em vez de tomar dano "surpresa" que parece injusto.
  Implementado como `TelaDeCombate.aplicarAtaqueDoChefe()`: só chefes (não
  inimigos comuns) intercalam ataques normais com um golpe carregado — a
  cada 3 turnos, em vez de atacar, o chefe avisa ("começa a carregar um
  golpe devastador!") e o jogador ganha o turno seguinte pra reagir (curar,
  fortalecer a Defesa, beber o Frasco); no turno depois, o golpe vem com
  ×2.2 de força. Indicador visual "Carregando golpe!" no card do inimigo
  além da mensagem no log. Chefes agora são mecanicamente diferentes de
  inimigos comuns, não só "mais HP e força".
- **Push-your-luck é o padrão de risco/recompensa de roguelike** (fontes:
  Medium sobre RNG justo em roguelikes, exemplos como Greedy Warlock/Space
  Dungeon) — decidir entre continuar arriscando por recompensa maior ou
  recuar com segurança é o que dá peso a continuar jogando. Implementado
  como `Personagem.sequenciaDeExploracao` (novo campo persistido): cada
  vitória ou Descoberta sem descansar soma 1 e dá +4% de Runas (até +40%
  no topo, sequência 10); `descansar()` ou ser derrotado zera tudo. Mostra
  em `TelaDeMasmorras` (nova `sequenciaBox`, only quando > 0) e no
  `statusBox` de `TelaDoPersonagem` — o jogador sempre vê o que tem a
  perder antes de decidir "mais uma masmorra" ou "melhor descansar".
- Nenhum arquivo novo, nenhuma mudança em `project.pbxproj`. Validado só
  lendo o código (incluindo checagem de parênteses/colchetes/chaves
  balanceados) — sem Xcode/simulador neste ambiente. **Ainda não jogado**
  com essa versão — o multiplicador ×2.2 do golpe carregado e o +4%/ponto
  da sequência são estimativas, não calibradas jogando de verdade.
- Ideias de design pesquisadas mas não implementadas ainda, se quiser
  continuar nessa linha: mecânica de fases por % de vida específica por
  chefe (não só o golpe carregado genérico), telegraphs com sabor único
  por chefe em vez do texto genérico atual, e um "pity" de loot (item
  garantido depois de N explorações sem nada cair, técnica citada nas
  fontes pesquisadas pra evitar frustração de RNG ruim).

## Rebalanceamento de dificuldade + exploração encadeada dentro da masmorra (sessão seguinte)

Três pedidos do usuário: (1) resolver de vez a pergunta de criptografia do
App Store Connect que aparecia a cada envio, (2) pesquisar como o Elden
Ring equilibra a força dos inimigos pra não ficar fácil nem impossível, e
(3) mudar "Continuar" depois de uma vitória pra não sair da masmorra —
precisa ter Sair E Continuar, e Continuar deve ir pro próximo inimigo
dentro da mesma visita, não voltar pro menu.

- **Pergunta de criptografia resolvida via `Info.plist`** (era o que a
  própria mensagem amarela do App Store Connect sugeria): adicionado
  `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` em Debug e Release no
  `project.pbxproj` (o projeto usa `GENERATE_INFOPLIST_FILE = YES`, sem
  arquivo `Info.plist` físico — por isso a chave via `INFOPLIST_KEY_*`, não
  um plist editado à mão). Toda entrega futura pula essa pergunta.
- **Pesquisei** (busca na web) os soft caps reais do Elden Ring antes de
  mexer em número nenhum. Dois achados viraram código:
  1. **Atributos têm dois patamares de retorno decrescente** (Vigor 40/60,
     Força/Destreza 54/80 etc. — valor cheio até o 1º patamar, metade até
     o 2º, bem pouco depois). Isso era uma lacuna real: o novo sistema de
     evolução (custo por nível, sem soft cap por atributo, da sessão
     anterior) deixava jogar 95 pontos só em Força sem penalidade nenhuma,
     trivializando o jogo no fim. Adicionado
     `Personagem.valorEfetivoDeDano(_:)` — dois patamares (40/70, valor
     cheio / metade / 20%) aplicado só no atributo que dá DANO
     (Força/Inteligência/Agilidade, tanto no ataque básico quanto nas
     magias em `TelaDeCombate.lancarMagia`). Acerto/esquiva/crítico não
     precisaram disso — já têm teto absoluto nas próprias fórmulas. O
     custo em Runas continua igual pra qualquer atributo (não é sobre
     "qual é mais barato", é sobre "quanto cada ponto realmente rende”).
  2. **Inimigos no Elden Ring não escalam infinitamente com o jogador** —
     são fixos por região, com escala parcial e limitada ao revisitar
     áreas antigas, pra preservar a sensação de superar um lugar. Antes,
     `Zona.gerarInimigoComum`/`gerarChefe` faziam
     `max(nivelBaseInimigos, nivelHeroi)` — escalava pra sempre, sem teto,
     então voltar a uma zona antiga nunca ficava fácil de verdade.
     Adicionado `Zona.alcanceDeEscalaAcimaDaZona = 6`: agora
     `min(nivelBaseInimigos + 6, max(nivelBaseInimigos, nivelHeroi))` —
     escala com o jogador até 6 níveis acima da base da zona, depois para.
     Como a recompensa usa o mesmo `nivel`, também para de compensar
     treinar numa zona já superada.
- **Exploração encadeada**: `TelaDeCombate.resultadoBox` agora mostra,
  numa vitória, dois botões — "Sair da Masmorra" (sai, igual antes) e
  "Continuar Explorando" (sorteia o próximo encontro com
  `Zona.sortearEncontro()`, igual o botão Explorar das Masmorras, SEM sair
  da tela). `continuarExplorando()` gera um novo inimigo (ou aplica uma
  Descoberta direto, sem combate) e `iniciarNovoEncontro()` reseta o
  estado de UM combate (veneno, atordoado, fortalecimentos, golpe de
  chefe) sem tocar em vida/energia do herói, que continuam de onde
  pararam — literalmente "ir mais fundo na masmorra" em vez de reiniciar.
  Depois de vencer um chefe, Continuar nunca gera outro chefe (só
  `sortearEncontro()`, que não inclui chefe). Derrota continua sem opção
  de continuar (só "Voltar"). Isso também faz a Sequência de Exploração
  (sessão anterior) fazer mais sentido — antes precisava voltar ao menu e
  clicar Explorar de novo a cada luta pra manter a sequência; agora dá pra
  simplesmente continuar.
- Nenhum arquivo novo, nenhuma mudança em referências do
  `project.pbxproj` (só a chave de criptografia, uma linha em cada
  configuração). Validado só lendo o código (parênteses/colchetes/chaves
  balanceados verificados via script) — sem Xcode/simulador neste
  ambiente. **Ainda não jogado** — os números do soft cap (40/70) e do
  teto de escala (+6 níveis) são estimativas informadas pela pesquisa, não
  calibradas jogando de verdade.

## Ícone recentrado + logo dentro do app (sessão seguinte)

Pedido do usuário: o ícone do app estava torto/cortado, precisava
centralizar; e queria a logo (`IMG_6153.JPG`, enviada direto pro
repositório via upload no GitHub, peguei com `git merge origin/main`)
aparecendo dentro do app também, nas telas principais.

- **Ícone recentralizado**: o corte antigo (`AppIcon-1024.png`) cortava a
  espada/hexágono de forma assimétrica, o que dava a sensação de "torto".
  Usei Python (Pillow, instalado neste ambiente) pra achar
  automaticamente a caixa delimitadora do emblema (excluindo o texto
  "Soul Grid RPG" abaixo, que a Apple recomenda não ter no ícone) via
  detecção de pixels não-pretos, e gerei um recorte quadrado centralizado
  nele, com margem uniforme dos lados e o mínimo de margem embaixo (pra
  não reincluir o texto, que fica bem colado no emblema na imagem
  original). Resultado: emblema inteiro visível, sem corte, sem texto,
  bem centralizado.
- **Logo dentro do app**: criado um novo imageset `Assets.xcassets/
  Logo.imageset` (pasta nova dentro do catálogo de assets já existente —
  não precisou mexer no `project.pbxproj`, que referencia `Assets.xcassets`
  como uma pasta só, não arquivo por arquivo) com um recorte mais generoso
  da imagem original (emblema + texto "Soul Grid RPG", a versão completa),
  cortado só pra tirar o excesso de fundo preto ao redor. Usado em duas
  telas "de entrada": `TelaDeCadastro` (primeira tela que aparece, troquei
  o ícone genérico do SF Symbols pela logo de verdade — e removi o texto
  "Bem-vindo(a) ao Soul Grid" que ficou redundante, já que a logo já diz
  isso) e `TelaDeHerois` (tela principal ao reabrir o app depois do
  cadastro, logo menor no topo).
- `IMG_6153.JPG` ficou na raiz do repositório (não faz parte do projeto
  Xcode, não é referenciada em lugar nenhum do build) — só o arquivo-fonte
  pra referência futura, igual já era antes com o ícone.
- Validado só lendo o código com cuidado (parênteses/colchetes/chaves
  balanceados via script) e inspecionando as imagens geradas visualmente
  — sem Xcode/simulador neste ambiente.

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

## Dificuldade: combate em grupo, defesa vs. magia, chefe com fúria (sessão seguinte)

Feedback real de playtest do usuário: jogando de Mago, nível 16, a última
masmorra do jogo (nível 13+) estava fácil demais — só os chefes ofereciam
alguma resistência. Diagnóstico com os números na mão, não só sensação:

- **A magia de maior dano do Mago (Meteoro, multiplicador 3.5x) com
  Inteligência no teto praticamente ignorava a Defesa de um inimigo comum
  de nível 16** (`defesa = 1 + nível` era só 17), matando em 1-2 golpes
  qualquer coisa fora um chefe. `Personagem.valorEfetivoDeDano` (soft cap
  de Inteligência) já existia, mas a Defesa do inimigo não escalava rápido
  o bastante pra compensar o multiplicador alto das magias de fim de jogo.
- **Bug real de balanceamento, não só "fácil": um chefe podia ser
  atordoado (`Anel de Congelamento` etc.) em loop.** `inimigoAtordoado`
  fazia o inimigo perder o turno inteiro; se o jogador conseguisse lançar
  uma magia atordoante todo turno, o chefe nunca chegava a agir — o
  "telegraph" do golpe carregado, pensado pra dar uma janela de reação,
  virava trava permanente. Bosses de Elden Ring de verdade têm poise/
  hyperarmor e não ficam perma-stunados por CC repetido; era esse o
  princípio que faltava aqui.
- **Todo combate era 1 herói vs. 1 inimigo**, sem exceção fora do chefe/
  elite — sem "quantidade" nenhuma pra gerar pressão, diferente das áreas
  mais avançadas de Elden Ring, que colocam vários inimigos juntos
  (acampamentos, grupos de soldados/lobos) justamente pra isso.

Mudanças (`Zona.swift`, `TelaDeCombate.swift`):

- **Defesa dobrou de inclinação**: comum `1 + nível` → `2 + nível × 2`;
  chefe `4 + nível × 2` → `6 + nível × 3`. Vida e Força de cada inimigo
  ficaram como estavam — o objetivo era especificamente cortar o burst de
  nuke mágico/físico de fim de jogo, não deixar cada inimigo individual
  mais "esponja de dano" (isso combina mal com combate em grupo, ver
  abaixo). Nível baixo quase não sente (defesa 2→4 no nível 1); nível alto
  sente bastante (defesa 17→34 no nível 16).
- **`Zona.gerarGrupoComum(nivelHeroi:)`**: encontros comuns agora podem
  vir em grupo de 1-3 inimigos, com a chance subindo por faixa de zona —
  faixa 1 quase sempre 1, faixa 4 (nível 13+) até 30% de chance de 3 de
  uma vez. `TelaDeMasmorras` não precisou mudar nada: já delegava pro
  init de `TelaDeCombate`, que agora chama `gerarGrupoComum` internamente
  quando não é chefe nem elite.
- **`TelaDeCombate` reescrita pra suportar `[Inimigo]` em vez de um só**
  (chefe/elite continuam array de 1, mesmo caminho de código pros três
  casos). Cartão de cada inimigo agora é tocável pra focar o alvo dos
  ataques/magias (`indiceAlvo`); veneno e atordoamento passaram a ser
  rastreados por índice (`venenoPorAlvo`/`atordoadoPorAlvo`), permitindo
  vários inimigos envenenados ao mesmo tempo num grupo. **Todo inimigo
  vivo age no turno dele** — é isso que torna o grupo perigoso de verdade:
  ignorar 2 dos 3 pra focar fogo custa levar o ataque dos 2 ignorados
  todo turno, uma tensão que 1v1 nunca tinha.
- **Chefe ganhou fase de fúria (abaixo de 40% de vida)**: carrega o golpe
  mais rápido (2 turnos em vez de 3) e bate mais forte (2.6x em vez de
  2.2x) — o equivalente à fase 2 mais agressiva dos chefes de Elden Ring,
  recalculado a cada turno a partir da vida atual (não é um estado fixo
  que possa ser burlado).
- **Corrigido o loop de atordoamento**: elite agora é sempre imune a
  atordoante (grande/resistente demais); chefe pode ser atordoado, mas
  fica 2 turnos imune depois de sofrer um — perde o turno uma vez, não
  pode ser travado pra sempre. Inimigo comum continua livre pra ser
  atordoado sem restrição (são só "mooks").
- `finalizarCombate` agora soma a recompensa de todos os inimigos
  derrotados no encontro (Runas + até um item por inimigo) — um grupo de
  3 dá mais loot que um só, o risco extra tem retorno extra.

Ainda não implementado (fora do escopo desta rodada, considerado e
descartado por tamanho): elite com escolta de inimigos comuns junto
(field boss guardado), pool de inimigos élite variado por zona. Validado
só por leitura cuidadosa + balanceamento de parênteses/chaves via script —
**sem playtest real de novo**, é a mesma ressalva já registrada acima.

## Vila: NPCs e missões (mesma sessão)

Pedido do usuário junto com o rebalanceamento acima: mais motivo pra
evoluir e explorar além das masmorras — perguntou explicitamente se dava
pra ter uma vila/cidade com NPCs oferecendo missões, estilo os NPCs de
bounty/pedido espalhados por Roundtable Hold em Elden Ring (Irina, White
Mask Varré, D...).

Arquivos novos: `Missao.swift`, `PNJ.swift`, `TelaDaVila.swift` (com as
4 entradas de `project.pbxproj` cada — PBXBuildFile, PBXFileReference,
grupo e Sources, seguindo o padrão dos arquivos existentes, já que este
projeto usa referências explícitas em vez do modelo de pasta sincronizada
do Xcode moderno).

- **`Missao`**: struct simples (não Codable — é só catálogo estático) com
  `id` string estável, tipo (`cacar`/`derrotarChefe`/`alcancarNivel`),
  zona-alvo, quantidade-alvo, recompensa em Runas e opcionalmente um item
  exclusivo. O truque de design: **nenhum progresso novo é rastreado**.
  Caçada reaproveita `Personagem.progressoZonas` (já contava vitórias por
  zona pra outra coisa), chefe reaproveita `runicasConquistadas` (só é
  concedida na primeira derrota do chefe daquela zona), nível reaproveita
  o `nivel` computed que já existe. O único campo novo persistido no
  herói é `missoesEntregues: Set<String>` — quais já foram resgatadas.
  Isso significa que progresso feito ANTES de visitar a Vila pela
  primeira vez já conta (o jogador não perde nada por não saber que a
  Vila existia).
- **16 missões de zona** (caçar N + derrotar o chefe, uma dupla por cada
  uma das 8 zonas) mais **2 marcos de progressão** oferecidos pelo Ancião
  da Vila: nível 5 (acessório universal, "Broche do Aventureiro") e nível
  16 (arma épica exclusiva por classe — "Fúria do Ancião" pro Guerreiro,
  "Cajado do Vazio Sussurrante" pro Mago, "Garras da Vila Esquecida" pro
  Ladino). Essas 3 armas nunca aparecem no mercado (não estão em
  `Item.catalogoMercado`) — só existem entregando a missão, o "conquistar
  armas fazendo quest" que foi pedido.
- **`PNJ`**: 5 moradores (Milo/Yara/Bruno/Seraphine, um por faixa de duas
  zonas, mais o Ancião Toren pros marcos), cada um só com nome, ícone e
  uma fala de ambientação — sem diálogo ramificado, escopo deliberadamente
  simples pra não virar um sistema de diálogo inteiro.
- **`TelaDaVila`**: lista os PNJs e, pra cada um, as missões dele com um
  selo de status (Bloqueada/X de Y/Concluída!/Entregue) e botão
  "Entregar" quando pronta. Filtra as 3 variantes de missão de nível 16
  pra só mostrar a que combina com a classe do herói atual (senão apareceria
  3 vezes a "mesma" missão lado a lado). Navegação: novo botão "Ir à
  Vila" em `TelaDoPersonagem`, ao lado de Masmorras/Mercado.
- **`Personagem.statusDaMissao(_:)`** calcula o status sob demanda (não
  armazenado) e **`entregarMissao(_:)`** paga a recompensa (com o mesmo
  bônus percentual de Runas de talismã que as outras fontes já usam) e
  marca como entregue — tudo ou nada, protegido por um `guard` igual ao
  de `confirmarEvolucao`.

Ainda não implementado: nenhuma missão de "coletar item" ou "escoltar" —
só caça/chefe/nível, que cobrem a maior parte do valor com o menor
código novo. Sem diálogo de NPC além da fala única. Válido considerar no
futuro: uma missão recorrente/repetível pra dar o que fazer depois de
zerar o catálogo fixo.
