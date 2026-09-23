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

## Missões de coleta, NPCs a cada 10 níveis, trama principal e UI (sessão seguinte)

Feedback do usuário depois de jogar: gostou do combate em grupo e das
missões, pediu pra aumentar — NPCs novos a cada 10 níveis com missões
mais difíceis, missões de coletar item (com itens novos pra isso,
inclusive alguns só pra vender), mais criaturas, e uma "história bem
robusta com uma trama". Também dois problemas de UI reais: o log de
combate crescia sem parar e empurrava os botões de ação pra baixo da
tela, e a mochila tinha virado uma lista enorme sem organização.

### UI

- **`TelaDeCombate.logDeCombate`**: agora tem altura fixa (140pt) com
  `ScrollView` própria em vez de crescer com `minHeight`. Ordem virou
  cronológica (mais antiga no topo) com auto-scroll pra última linha a
  cada evento novo (`ScrollViewReader` + `.onChange(of: log.count)`),
  como um log de chat de verdade — antes era mais nova no topo, sem
  scroll, só empurrando tudo pra baixo.
- **`TelaDoPersonagem.mochilaBox`**: ganhou abas (Poções/Armas/
  Armaduras/Acessórios/Materiais) com `Picker` segmentado, mesmo padrão
  de `TelaDoMercado.AbaDoMercado`. Item de material mostra "Missão ou
  venda" em vez de "Equipar" (não é equipável).

### Novo tipo de item: Material

`TipoDeItem.material` — troféu de combate que não equipa nem se "usa",
só entrega em missão de coleta ou vende. `Item.materiaisDeZona` (8, um
por zona, com `zonaDeOrigem` pra saber qual) e `Item.materiaisGenericos`
(3, sem zona, sem missão nenhuma — o "item que só serve pra vender"
pedido explicitamente). Nunca entram em `catalogoMercado`: só via drop.

Drop: `Personagem.receberRecompensa` ganhou uma rolagem **separada** da
de equipamento (20/45/70% comum/elite/chefe, metade do bônus de talismã
de item) pro material da zona do inimigo, mais uma rolagem própria de 8%
pra quinquilharia genérica. `receberDescoberta` (assinatura mudou, agora
recebe `zonaNome:` também — os dois call sites em `TelaDeMasmorras` e
`TelaDeCombate` foram atualizados) ganhou 25% de chance do material da
zona. Nenhuma das duas rolagens compete com o loot de equipamento
existente — são chances a mais, não substitutas.

### Missões de coleta

`Missao.TipoDeMissao.coletar` + campo `itemAlvo: String?` — progresso
calculado contando quantas unidades daquele item (por nome) o herói tem
agora (`Personagem.quantidadeDoItem`), sem contador novo persistido,
mesmo princípio das outras missões. Entregar remove a quantidade pedida
da mochila (`Personagem.removerQuantidade`). 8 missões de coleta novas,
uma por zona, mesmo PNJ que já oferecia a caçada/chefe daquela zona.

### NPCs novos a cada 10 níveis + trama principal ("O Selo Rompido")

`PNJ` ganhou `nivelMinimoParaAparecer` — `TelaDaVila` agora filtra quais
moradores mostrar por esse nível (`pnjsVisiveis`), não só mostra a
missão deles como "Bloqueada". 3 NPCs novos: **Capitã Oriana** (nível
10), **Kael, o Ferreiro** (nível 20), **Ithra, a Vidente** (nível 30) —
cada um com uma missão de marco (`alcancarNivel`) mais 1-2 missões de
coleta/caça de recompensa maior. Ancião Toren "retorna" no nível 40 pro
fechamento (mesmo `pnjID`, então é literalmente o mesmo personagem —
não precisou de PNJ novo, só de uma missão nova associada a ele).

A trama ("O Selo Rompido"): a ordem de guardiões de Toren selou algo no
Abismo Estelar há gerações; o selo está se rompendo, espalhando
corrupção do Vazio pelas zonas — explica retroativamente por que tantos
inimigos já se chamavam "Corrompido"/"Amaldiçoado" antes dessa trama
existir. Contada via `Missao.loreAoEntregar` (texto de ambientação
mostrado só nas 8 missões de marco de nível: 5/10/16/20/30/40), que
`Personagem.entregarMissao` anexa ao texto de recompensa — sem sistema de
diário/histórico novo, só texto acumulado na mesma mensagem que já
existia. Fecha no nível 40 com a derrota do Devorador de Mundos (o chefe
do Abismo Estelar, que já existia) sendo referenciada como o clímax.

### Mais criaturas

2 nomes novos de inimigo por zona (16 no total), metade deles temáticos
à corrupção do Vazio (ex.: "Urso Tocado pelo Vazio", "Espectro Arcano
Instável") — puramente variedade de nome/flavor, sem mecânica nova, zero
risco.

### Recompensas exclusivas novas

7 acessórios universais exclusivos de missão (Oriana/Kael/Ithra/Toren-40),
nenhum vendido no mercado — o "Selo do Vazio Contido" (marco de nível 40)
é o acessório mais forte do jogo de propósito, o fechamento mecânico da
trama.

Validado só por leitura cuidadosa + balanceamento de parênteses/chaves
via script em todos os arquivos tocados — **sem playtest real**, mesma
ressalva de sempre. Ponto de atenção pro próximo playtest: as 3 rolagens
de material novas (zona/quinquilharia/descoberta) nunca foram testadas
juntas, vale sentir se materiais estão dropando rápido demais ou devagar
demais pra completar as missões de coleta num ritmo razoável.

## New Game+ em vez de expandir o mundo até o nível 160 (mesma sessão)

O usuário gostou do resultado e pediu mais história — perguntou se
devíamos continuar expandindo o mundo (mais 3 histórias de 40 níveis
cada, novos mundos/vilas, convergindo num final geral no nível 160) ou,
alternativamente, fazer um New Game+ como o de Elden Ring, e deu
liberdade criativa total pra decidir.

**Decisão: New Game+.** Motivo: 3 mundos/vilas inteiros novos (cada um
precisando do mesmo tanto de conteúdo que a Vila atual — zonas, NPCs,
missões, itens, criaturas) é um projeto muito maior que tudo que já foi
feito nesta sessão somado, difícil de balancear sem playtest real, e
adia indefinidamente "focar no desenvolvimento de batalhas e
personagens" (a própria razão que o usuário deu pra considerar a
alternativa). New Game+ entrega o mesmo objetivo — um motivo real pra
continuar jogando depois do fim da trama — com uma fração do código, e é
literalmente fiel ao próprio jogo que inspira o projeto.

- **`Personagem.cicloNewGamePlus: Int`** (novo campo persistido). Elegível
  quando `missoesEntregues.contains("marco_nivel_40")` — ou seja, depois
  de fechar "O Selo Final". Diferente do NG+ de verdade de Elden Ring,
  **não** exige derrotar o chefe final de novo a cada ciclo (fica
  disponível pra sempre depois da primeira vez) — simplificado de
  propósito pra não travar o jogador atrás de uma rejogada inteira só
  pra avançar de ciclo.
- **`Personagem.iniciarNovoCicloNewGamePlus()`**: incrementa o ciclo.
  Personagem, nível, equipamento, Runas, inventário, missões — nada é
  resetado. Só o mundo muda.
- **`Zona.multiplicadorDeCiclo(_ ciclo:)`**: `1.0 + ciclo × 0.25` — linear,
  não composto, pra não virar número absurdo se o jogador iniciar vários
  ciclos em sequência sem jogar entre eles (não há trava pra isso).
  Aplicado a vida/força/defesa/recompensa (XP e Runas) de
  `gerarInimigoComum`/`gerarChefe`/`gerarInimigoDeElite` — todo mundo
  passou a receber `cicloNewGamePlus: Int = 0` (default, então nada
  quebra pra quem nunca inicia um ciclo). `TelaDeCombate` guarda o ciclo
  como `let` (mesmo motivo de guardar `nivelHeroi`: "Continuar
  Explorando" regenera inimigos sem sair da tela) e os dois pontos de
  `TelaDeMasmorras` que criam `TelaDeCombate` passam
  `vm.heroi.cicloNewGamePlus`.
- **UI**: `TelaDaVila` ganhou uma seção "Novo Ciclo" (só visível quando
  elegível) com um botão que chama `iniciarNovoCicloNewGamePlus()` — a
  mesma Ancião Toren narra a transição (3 textos diferentes: ciclo 1,
  ciclo 2, ciclo 3+). `TelaDoPersonagem` mostra "· Ciclo N" ao lado do
  nível no cabeçalho quando `cicloNewGamePlus > 0`.

Ainda não implementado (considerado, fora de escopo por ora): missões
exclusivas de New Game+ (o catálogo de missões continua o mesmo,
`missoesEntregues` não reseta — então nada pra fazer de novo na Vila
além de repetir masmorras mais difíceis); gate de "precisa derrotar o
chefe final de novo" por ciclo, como o Elden Ring de verdade faz. Os
dois dariam mais profundidade ao sistema se a base (o multiplicador em
si) se provar divertida no playtest.

## Sistema de status (Sangramento/Calafrio/Queimadura), Forja de equipamento e mais dificuldade (mesma sessão)

Depois de testar o primeiro ciclo de New Game+, o usuário reportou já
ter "zerado" ele só brincando — o jogo precisa de mais desafio/gameplay
mais imersiva pra segurar o jogador ("um jogo mto fácil ninguém vai
ficar"). No mesmo pedido, encomendou um "projeto de builds" pras 3
classes (Guerreiro: tank/sangramento/lança; Mago: fogo/gelo além do
arcano que já existia; Ladino: liberdade total) e, logo em seguida,
pediu também um sistema de evolução de arma/armadura via um ferreiro
(pedras de evolução dropando por tipo/masmorra) e um teto pro Frasco
Sagrado (achou que Sementes/Lágrimas sem limite deixava o jogo
"quebrado"). As duas frentes de dificuldade/build acabaram sendo a
mesma solução: um sistema de status novo que também é a espinha dorsal
mecânica das builds.

### Teto do Frasco Sagrado

`Personagem.cargasDeFrascoMaximo = 12` e `potenciaDoFrascoMaxima = 100`
(dois `static let` novos). `usarItem` (efeitos `.aumentaFrascos` e
`.aumentaPotenciaDoFrasco`) agora recusa consumir Semente/Lágrima além
do teto — ou consome parcialmente, se sobrar espaço pra menos que o
valor cheio do item — em vez de somar sem limite. Sementes e Lágrimas
já dropavam em combate/exploração antes disso (fazem parte do
`catalogoMercado`, de onde `lootAleatorio` sorteia), então "podem
dropar sempre" já valia; só faltava o teto.

### Forja: evolução de arma/armadura (Kael, o Ferreiro)

- **`Item.nivelDeEvolucao: Int = 0`** (novo campo, 0 a
  `Item.nivelMaximoDeEvolucao = 10`) — só relevante pra `.arma`/
  `.armadura`. **`Item.bonusEvoluido`**: retorna o `bonus` escalado em
  +8%/nível (até +80% no nível 10); todo item novo nasce em nível 0, ou
  seja, com `bonusEvoluido == bonus` — nada muda pra equipamento
  existente.
- **`Item.pedrasDeForja`**: 4 pedras (uma por raridade, mesma escala de
  `lootAleatorio`), drop-only — nunca entram no `catalogoMercado`.
  `Personagem.receberRecompensa`/`receberDescoberta` ganharam uma
  rolagem independente pra elas, igual ao material de zona.
- **`Personagem.evoluirArmaEquipada()`/`evoluirArmaduraEquipada()`**:
  consomem Pedras de Forja (tier da raridade da peça, quantidade =
  nível atual + 1) e Runas (`80 + nível×60`), e só evoluem a peça
  **equipada** — nunca uma cópia parada na mochila, pra não ambiguar
  qual unidade duma pilha está sendo reforçada. Só a peça equipada
  evolui é também a resposta direta ao pedido: "não sempre ter a arma e
  armadura sempre no máximo quando já equipa ela" — agora equipar uma
  arma nova é só o começo, o bônus real cresce aos poucos na Forja.
- Bug evitado: `Personagem.adicionarItem` empilhava por nome só —
  devolver uma arma evoluída pra mochila (trocar de equipamento)
  misturaria ela numa pilha de cópias +0 já existentes, apagando o
  reforço. Corrigido pra empilhar por nome **e** `nivelDeEvolucao`
  juntos.
- **UI**: a Forja mora dentro do card do Kael (`TelaDaVila`, PNJ que já
  existia desde o milestone de nível 20 e já tinha a fala "Traga
  material raro o bastante e eu forjo qualquer coisa" — só faltava a
  mecânica). Mostra a peça equipada, nível atual, custo do próximo
  reforço e um botão "Evoluir". `TelaDeEquipamento` e a descrição do
  item (`Item.descricao`) também passaram a mostrar o bônus evoluído e
  o "+N" quando aplicável.

### Sangramento, Calafrio e Queimadura — sistema de status novo

Três `TipoDeMagia` novos em `Magia.swift`, cada um com uma identidade
mecânica própria (não é só "veneno com nome diferente"):

- **Sangramento**: acúmulo por acerto (`acumuloDeStatus`); ao cruzar
  100, explode em dano = 20% da vida MÁXIMA do alvo e zera o acúmulo —
  ignora armadura, como o Bleed de Elden Ring. Base da build de
  sangramento do Guerreiro/Ladino.
- **Calafrio**: mesmo acúmulo até 100, mas ao explodir atordoa o alvo
  (reaproveita a mesma imunidade de chefe/elite do atordoante comum) em
  vez de causar dano. Base da build de gelo do Mago/Ladino.
- **Queimadura**: dano por turno como o veneno, **mais** uma redução
  percentual de Defesa (`reducaoDeDefesaPercentual`) enquanto ativa —
  `TelaDeCombate.defesaEfetiva(doAlvo:)` centraliza esse cálculo, usado
  tanto no ataque básico quanto nas magias. Base da build de fogo do
  Mago.

Os 2 campos novos de `Magia` (`acumuloDeStatus`, `reducaoDeDefesaPercentual`)
são **`Optional`**, de propósito — `Magia` não tem `init(from:)` próprio
(Codable sintetizado) e pode estar salva dentro do save de um jogador via
`Item.habilidadeDeArma`; só um campo `Optional` ganha `decodeIfPresent`
automático na síntese e cai em `nil` sem quebrar saves antigos.

`TelaDeCombate` ganhou os dicionários `sangramentoPorAlvo`/
`calafrioPorAlvo: [Int: Int]` (acúmulo) e `queimaduraPorAlvo: [Int:
(dano:Int, turnos:Int, reducaoDefesa:Int)]`, resetados em
`iniciarNovoEncontro()` e limpos na morte do alvo junto com veneno/
atordoamento via um helper novo, `limparEfeitosDoAlvo(_:)` (evita
"vazar" efeito de um índice do array pro próximo inimigo que ocupar a
mesma posição). Bug pego e corrigido durante a implementação: a
explosão do Sangramento pode matar o alvo DEPOIS do golpe inicial já
ter sido considerado "ainda vivo" — `alvoAindaVivo` virou `var` e é
reconferido depois da cadeia de efeitos, senão a mensagem de derrota e
a limpeza de estado nunca aconteciam pra uma morte por explosão de
sangramento.

### 8 magias novas + 8 armas novas — o "projeto de builds"

Grimório (`Magia.swift`): Guerreiro ganhou Corte Sangrento (sangramento,
nível 6) e Investida da Lança (certeira, nível 11). Mago ganhou Chama
Ardente/Explosão Flamejante (queimadura, níveis 7/13) e Lança de
Gelo/Nova Glacial (calafrio, níveis 10/16). Ladino ganhou Corte
Retalhante (sangramento, nível 6) e Lâmina Congelante (calafrio, nível
11) — junto com o veneno que já existia, agora tem 3 identidades
ofensivas.

Armas (`Item.swift`, todas como "alternativa no mesmo patamar" de uma
arma já existente, seguindo a convenção que o catálogo já usava):
Guerreiro — Lâmina e Broquel (tank, dá Defesa em vez de só Força),
Machado Serrilhado (sangramento), Lança Longa (certeira). Mago — Cajado
das Chamas e Cetro do Inferno (queimadura), Cajado Glacial (calafrio).
Ladino — Facas Serrilhadas (sangramento), Lâminas Congelantes
(calafrio). Cada uma carrega o status correspondente como Golpe de
Arma, então a build fica disponível mesmo antes do jogador chegar ao
nível da magia equivalente no grimório.

### Mais dificuldade/imersão

- **`Zona.multiplicadorDeCiclo`**: `+25%` → `+35%` por ciclo de New
  Game+ — resposta direta ao "já zerei o primeiro ciclo só em teste".
- **`Zona.tamanhoDoGrupo`** ganhou um parâmetro `cicloNewGamePlus`: cada
  ciclo empurra a rolagem de tamanho de grupo pra cima (até +30, nunca
  garante o grupo máximo), então NG+ também fica mais cheio de
  inimigos, não só mais tanque.
- **Telegraph do chefe randomizado**: `turnosAteGolpeDoChefe` deixou de
  ser fixo (3 turnos normal / 2 enfurecido) e virou uma faixa
  (`2...4` normal, `1...2` enfurecido) sorteada a cada carga — o padrão
  continua "aprendível" (o aviso de "carregando golpe!" sempre vem um
  turno antes), mas o timing exato não dá mais pra decorar e piloto
  automático.

Validado só por leitura cuidadosa + balanceamento de parênteses/chaves/
colchetes e auditoria de ordem de argumentos nomeados (script Python,
mesma técnica de sempre) em todos os arquivos tocados — **sem playtest
real**. Pontos de atenção pro próximo playtest: os limiares de 100 de
acúmulo pra Sangramento/Calafrio (rápido demais? devagar demais?), e se
o custo de Pedras de Forja (nível atual + 1, crescendo até 10 na peça
+10) soa justo dado o novo ritmo de drop.

## Rebalance real de dificuldade + Forja até +25, estilo Elden Ring (mesma sessão, primeiro playtest de verdade)

Essa é a primeira vez na sessão inteira que o usuário reportou um número
concreto de gameplay em vez de "gostei"/"quero mais": criou um Mago
novo e derrotava inimigo com **uma Bola de Fogo e um ataque básico**,
sem nem cajado equipado. Pediu pra estudar a fundo escala de
dificuldade em Elden Ring, todos os Dark Souls e jogos menores, e trazer
o sistema de evolução de arma de Elden Ring de verdade.

### O diagnóstico (matemática, não achismo)

Fazendo a conta com os números reais do jogo: um Mago recém-criado tem
Inteligência base 18 (`ClasseDePersonagem.inteligenciaBase`). Bola de
Fogo (`multiplicadorDano: 2.0`) contra um inimigo comum de zona 1,
nível 1: dano bruto = `18 × 2.0 = 36`. O inimigo tinha `vida: 24 + nível
× 11 = 35` e `defesa: 2 + nível × 2 = 4`. Dano final = `36 − 4 = 32`.
**Um cast matava um inimigo de 35 de vida.** Conferi Guerreiro (Golpe
Poderoso, `×2.2`) e o resultado era o mesmo problema: força inicial 14
(+6 da espada Comum) × 2.2 = 44 bruto, quase zerando o mesmo inimigo
sozinho. Não era bug de uma classe — era a fórmula de vida/defesa do
inimigo comum, calibrada há muitas sessões atrás e nunca revalidada
depois de tanto poder de dano ter entrado no jogo (evolução de arma,
magias novas, Grandes Rúnicas, talismãs). Toda nota de sessão anterior
tinha o aviso "sem playtest real" — esse era exatamente o tipo de
problema que só aparece jogando de verdade, não lendo código.

### O que a pesquisa trouxe

- **Filosofia Dark Souls/Elden Ring**: quando o dano do jogador cresce
  (build, equipamento, nível), o jogo raramente capa esse dano — ele
  aumenta a vida/resistência do mundo. Um chefe tem vida muito acima de
  um inimigo comum; NG+ deixa tudo mais tanque, nunca deixa o jogador
  mais fraco. Confirma a decisão de mexer nas fórmulas do `Inimigo`, não
  nos multiplicadores das magias/builds que acabaram de ser construídas.
- **Smithing Stones de Elden Ring** ([Fextralife](https://eldenring.wiki.fextralife.com/Smithing_Stones), [GameSpot](https://www.gamespot.com/articles/elden-ring-how-to-upgrade-weapons-smithing-stones-explained/1100-6501026/)):
  armas normais evoluem até **+25**, com a tier de pedra exigida subindo
  a cada poucos níveis de reforço (Pedra [1] pros primeiros níveis, [2]
  pros seguintes, e assim por diante) — a tier depende do **progresso do
  reforço em si**, não da raridade da arma. Armas especiais (Somber) vão
  só até +10. Base direta da nova Forja abaixo.
- **Design de dano em RPGs por turno** (fóruns RPG Maker/itch.io):
  fórmulas de subtração simples (`dano = ataque − defesa`, o mesmo
  modelo que este jogo já usa) são ótimas pra previsibilidade, mas
  quebram fácil se a defesa do inimigo não acompanhar o crescimento do
  ataque do jogador — exatamente o que tinha acontecido aqui.

### Fórmulas de `Inimigo` reescritas (`Zona.swift`)

Alvo calibrado à mão: um golpe/magia de abertura forte precisa de
**2-3 acertos** pra derrubar um inimigo comum do mesmo nível — nunca 1,
mas sem virar maratona; o ataque básico "de graça" (sem gastar energia)
fica mais fraco de propósito, {~5-6 golpes}, pra empurrar o jogador a
usar o grimório/Golpe de Arma como ferramenta principal, não só o botão
"Atacar".

| | Antes | Depois |
|---|---|---|
| Vida (comum) | `24 + nível×11` | `45 + nível×22` |
| Defesa (comum) | `2 + nível×2` | `6 + nível×3` |
| Força (comum) | `5 + nível×3` | `7 + nível×4` |
| Vida (chefe) | `70 + nível×18` | `130 + nível×34` |
| Defesa (chefe) | `6 + nível×3` | `11 + nível×5` |
| Força (chefe) | `10 + nível×4` | `15 + nível×6` |

Recompensas (XP/Runas) subiram na mesma proporção pra grind continuar
compensando. Conferido por simulação em Python (não só leitura): Mago
nível 1 sem cajado agora precisa de ~2-3 casts de Bola de Fogo pra
matar um comum (antes: 1); Guerreiro nível 1 com Espada Curta precisa
de ~6 ataques básicos ou ~2 Golpes Poderosos (antes: ~2 e ~1). Um chefe
de zona continua exigindo preparo de verdade antes de desafiar — igual
sempre foi, só que agora numa base de inimigo comum que não é mais
trivial.

### Forja: trilha longa até +25 (era até +10)

- **`Item.nivelMaximoDeEvolucao`**: `10` → `25`. **`Item.bonusEvoluido`**:
  `+8%/nível` (até +80%) → `+4%/nível` (até **+100%**, ou seja o dobro,
  em +25) — mantém o teto de poder final parecido, só espalhado por uma
  trilha bem mais longa.
- **Mudança mais fiel ao jogo original**: a tier de Pedra de Forja
  exigida pra um reforço agora depende do **nível de evolução ATUAL da
  peça** (`Item.pedraDeForja(paraNivelDeEvolucao:)`, níveis 0-5 pedem
  Comum, 6-11 Incomum, 12-17 Raro, 18-24 Épica), não mais da raridade da
  arma/armadura em si — exatamente como Smithing Stone [1] serve
  qualquer arma normal indo de +1 a +3, seja ela comum ou rara. A
  função antiga (`paraRaridade:`) continua existindo, só que agora só
  serve pro DROP (qual pedra um inimigo de tal zona pode largar), não
  mais pro custo.
- **`Personagem.custoParaEvoluir`**: quantidade de pedra por reforço caiu
  de `nível+1` pra `2 + nível/3` (cresce bem mais devagar, já que agora
  são 25 níveis em vez de 10); custo de Runas ajustado de `80 + nível×60`
  pra `60 + nível×35`. Upgradar uma peça do zero até +25 agora pede
  ~150+ pedras no total, somando as 4 tiers — uma meta de fim de jogo de
  verdade, não algo pra terminar numa tarde, igual ao jogo original.

Validado por leitura + balanceamento de chaves/parênteses + auditoria de
ordem de argumentos + **simulação numérica em Python** dos cenários de
combate acima (a primeira vez que uma mudança de balanceamento desta
sessão foi verificada com números de verdade antes de subir, não só
"parece razoável"). Ainda **sem playtest real no dispositivo** — o
próximo teste do usuário é o que vai validar se os alvos de "2-3
acertos" acertaram a mão ou precisam de mais um ajuste.

## Teto de atributos, resistência elemental por zona e Maestria de Arma (mesma sessão)

Depois de ver o build automático de um mago no Elden Ring de verdade
(print de tela do menu de nível: 8 atributos travados em 99, poder de
ataque/defesa por tipo de dano, tudo se somando numa build), o usuário
pediu pra estudar mais fundo Elden Ring E também **Melvor Idle** (jogo
de RPG idle da App Store, que ele jogou bastante) — a essência pedida:
"o player testar combinações, criar builds, e explorar as mecânicas",
com batalhas difíceis que precisam ser conquistadas.

Pesquisei os dois jogos e trouxe uma fatia concreta e bem-testada de
cada um, em vez de tentar portar os dois sistemas inteiros:

- **Teto de atributos em 99** ([soft caps do Elden Ring](https://eldenring.wiki.fextralife.com/Stats)):
  `Personagem.atributoMaximo = 99`. `confirmarEvolucao` recusa qualquer
  alocação que estourasse o teto num atributo (mensagem clara, nada é
  gasto), e o botão "+" de cada atributo em `TelaDeEquipamento` já
  desabilita ao chegar em 99. Sem isso, Runas o bastante deixavam um
  atributo crescer pra sempre — não era build, era só quem farmou mais.
- **Resistência/fraqueza elemental por zona** (o "Poder de defesa" por
  tipo de dano do menu do Elden Ring, adaptado): `Magia.elemento`
  (computado, nunca salvo, deriva de `tipo`/`atributoDeEscala` —
  Queimadura=fogo, Calafrio=gelo, Sangramento/dano-por-Força=físico,
  dano-por-Inteligência=arcano, Veneno=veneno) + `Inimigo.resistencias`
  + `Zona.resistenciasDaZona(_:)`, um perfil por zona (ex.: Necrópole
  Congelada resiste gelo e é fraca a fogo; Cavernas de Pedra resiste
  físico e é fraca a arcano). `TelaDeCombate` aplica o modificador (teto
  0.4x-1.5x) depois da mitigação de Defesa, em todo dano — básico,
  magia, explosão de Sangramento, DoT de Veneno/Queimadura — e avisa no
  log ("resistido"/"fraqueza explorada!") sem um painel explícito, pra
  o jogador aprender jogando. Isso é o que torna as builds construídas
  nas sessões anteriores (fogo/gelo/sangramento/veneno) taticamente
  relevantes de verdade: a masmorra certa recompensa a build certa.
- **Maestria de Arma** (Mastery de Melvor Idle): `Personagem.
  maestriaDeArmas: [String:Int]` conta golpes acertados por nome de
  arma, pra sempre — nunca reseta ao trocar de arma e voltar depois.
  `nivelDeMaestria(xp:)` sobe até 20, custo crescente por nível
  (15/30/45/...), concedendo +1% de dano por nível (até +20%) enquanto
  aquela arma está equipada. Puramente aditivo, sem custar Runas nem
  depender de sorte de loot — recompensa dominar uma build só de tanto
  usá-la, e é visível no slot de arma em `TelaDeEquipamento`.

Escopo deliberadamente menor que "portar os dois jogos inteiros":
Melvor Idle tem 9 skills de combate + triângulo Melee/Ranged/Magic +
mastery pool por skill inteira, e Elden Ring separa a resistência em
Físico/Esmagador/Cortante/Perfurante além de Mágico/Fogo/Relâmpago/
Sagrado. Adaptar tudo isso de uma vez faria mais sentido com playtest
real intercalado — por ora, entrou o que dava pra calibrar com confiança
e que mais diretamente atende "testar combinações, explorar mecânicas,
batalhas conquistadas" sem reescrever o combate inteiro de novo.

Validado por balanceamento de chaves/parênteses + auditoria de ordem de
argumentos em todos os arquivos (incluindo o `Inimigo` novo na lista).
`ElementoDeDano` é um enum simples sem valor associado — Hashable/
Equatable sintetizados automaticamente pelo Swift, então funciona como
chave de dicionário (`Inimigo.resistencias`) sem conformidade explícita.
Sem playtest real de novo — próximo teste do usuário valida se o teto
elemental (0.4x-1.5x) e a curva de maestria (15 golpes pro nível 1, 3150
no total pro nível 20 — deliberadamente uma meta de fim de jogo de longo
prazo, no espírito dos próprios níveis de Mastery de Melvor Idle, não
algo pra bater numa campanha normal) estão na medida certa.

## Custo de Runas cúbico após o teto de 99 (mesma sessão, correção rápida)

Levantei o teto de atributos em 99 na entrega anterior sem mexer no
custo em Runas de cada ponto (`custoEmRunas`, que era só linear no
total de pontos comprados). O usuário pegou o problema na hora,
perguntando se eu realmente entendia como o nível/Runas escala em Elden
Ring: lá, chegar em 99 em TUDO é nível 713 e custa **1,69 bilhão de
Runas no total** — a curva é cúbica, e é isso que torna "tudo maxado"
uma meta de fim de jogo real, não um objetivo natural de qualquer
personagem. Sem uma curva equivalente aqui, o teto de 99 sozinho não
bastava: com o custo antigo, maxar os 6 atributos custava só ~308 mil
Runas no total — um fim de semana de grind, não uma conquista de
verdade. E como o "nível" deste jogo é só `1 + pontosComprados/5`, sem
uma curva que realmente pese, o personagem ficaria "fraco" no sentido
de que qualquer build convergiria pro mesmo estado final maxado cedo
demais, matando a escolha de build que todo o resto desta sessão
construiu.

Fórmula nova, mesma forma da curva real de Elden Ring (suave nos
primeiros níveis, explode depois): `custoBase` continua idêntico até
`Personagem.limiarDeEscaladaDeCusto = 300` pontos comprados (nível 61,
bem depois do fim d'"O Selo Final" no nível 40 — **a trama principal
não fica um centavo mais cara**), e a partir daí soma uma sobretaxa
cúbica sobre o excedente (`excedente³ / 900`). Resultado calibrado por
simulação em Python: nível 40 continua custando ~40 mil Runas
(igual a antes), nível 90 já custa ~345 mil acumulados, e maxar os 6
atributos em 99 (nível 111) passa a custar **~1,4 milhão de Runas no
total** — não 1,69 bilhão como no jogo original (a economia deste jogo
é bem menor em escala absoluta), mas a MESMA relação: barato pra jogar
a campanha normal, uma fortuna desproporcional pra chegar no hard cap
de verdade.

## Seta de upgrade na mochila + Mochila unificada com Equipamento (mesma sessão)

Feedback de UX depois de mais uma rodada de teste: ficava difícil
comparar o que tem na mochila com o que já está equipado (a mochila
morava na tela inicial, o Equipamento era outra tela separada). Pedido:
uma seta verde/vermelha (ou bolinha neutra) indicando se um item da
mochila é melhor, pior ou igual ao que já está equipado, e avaliar se
valia a pena juntar Mochila dentro de Equipamento, renomeando pra
"Personagem".

- **`Item.pontuacaoDeComparacao`**: soma simples dos atributos do
  `bonusEvoluido` (pesando talismã de regen/ouro/chance de item um
  pouco mais alto, já que ocupam um slot inteiro sem dar atributo de
  combate nenhum) — só serve pra comparar "esse item é melhor?", nunca
  entra no cálculo de dano/defesa real do combate.
- **`TelaDeEquipamento.indicadorDeUpgrade`**: seta verde (`arrow.up`)
  se a pontuação da peça na mochila for maior que a equipada no mesmo
  slot, vermelha (`arrow.down`) se for menor, bolinha amarela se
  empatar — só pra arma/armadura (acessório tem 3 slots concorrentes,
  não dá pra comparar com "o" equipado). Nada equipado ainda = sempre
  verde (qualquer coisa é melhor que nada).
- **Mochila unificada**: `AbaDaMochila`/`itensDaAbaMochila`/
  `mochilaBox`/`linhaDaMochila` saíram de `TelaDoPersonagem` (a tela
  inicial) e foram pra dentro de `TelaDeEquipamento`, que também
  ganhou o título "Personagem" (era "Equipamento"). A tela inicial
  ficou mais enxuta (cabeçalho, status, o card que agora leva direto
  pra "Personagem e Mochila", magias equipadas, ações, trocar herói) —
  e a seta de upgrade só fazia sentido de verdade com as duas coisas
  juntas na mesma tela.

Validado por balanceamento de chaves/parênteses/colchetes + auditoria
de ordem de argumentos em todos os arquivos, e grep pra confirmar que
nenhuma referência a `AbaDaMochila`/`mochilaBox`/`linhaDaMochila`
ficou pra trás na tela antiga depois da mudança. Sem playtest real —
próximo teste do usuário valida se a pontuação de comparação bate com
a intuição dele (ela ignora Golpe de Arma/efeito de buff de propósito,
que são subjetivos demais pra virar seta).

## Destreza e Sorte deixam de saturar cedo + auditoria de harmonia entre as 3 classes (mesma sessão)

O usuário perguntou se Destreza e Sorte escalavam tão bem quanto
Inteligência pro Mago. Resposta: não. `chanceDeAcerto` (Destreza) tinha
um teto absoluto de 98% batido com só **26 pontos** — qualquer coisa
acima virava 100% desperdiçada. `chanceDeCriticoBasico` (Sorte) tinha
teto de 60% batido com **~55 pontos**. Comparado com Inteligência (soft
cap 40/70, nunca satura de vez, ainda escala Mana), isso quebrava o
propósito inteiro do sistema de custo cúbico até o 99 (ver a entrada
"Custo de Runas cúbico" acima) — sem retorno nenhum depois de 26/55,
ninguém investiria Runas ali de propósito, então "maxar em 99" só fazia
sentido pro atributo de dano principal de cada classe.

Pedido explícito: consertar E verificar as 3 classes, não só o caso do
Mago.

### O que mudou

- **`Personagem.valorEfetivoDeChance(_:primeiroPatamar:segundoPatamar:)`**:
  a mesma filosofia de soft cap de `valorEfetivoDeDano` (valor cheio até
  o 1º patamar, metade até o 2º, um quinto depois), só que parametrizável
  pra cada fórmula de %, já que cada uma tem uma faixa bem menor pra
  trabalhar (no máximo ~15-94 pontos percentuais) do que dano tem.
- **`chanceDeAcerto`** (Destreza): agora usa patamares 25/80 com divisor
  3.9 — de 85% no zero até 99% só perto do 99 de Destreza (antes
  saturava em 26). Continua crescendo em CADA faixa, nunca trava.
- **`chanceDeCriticoBasico`** (Sorte + Agilidade/4): patamares 20/50 —
  Sorte pura sobe de 5% até ~49% perto do 99 (antes travava em 60% já
  aos ~55 pontos).
- **`chanceDeEsquiva`** (Agilidade + Sorte/6): patamares 35/70 no termo
  de Agilidade — sobe suave até ~35% perto do 99 de Agilidade.
- **Segunda vertente da Sorte, sem teto formal**: `bonusChanceDeItemTotal`
  e `bonusRaridadeDeItemTotal` (que já existiam só a partir de talismãs)
  agora também somam `sorteTotal/4` e `sorteTotal/40` direto do atributo
  — sorte também é sobre o que você encontra, não só sobre acertar o
  golpe crítico. Como essas duas entram em 4 rolagens de loot diferentes
  (`receberRecompensa`/`receberDescoberta`), cada uma já com seu próprio
  `min(100, ...)`, não precisa de teto formal aqui: o teto de cada
  rolagem individual já cuida disso.

### Auditoria de harmonia — os 6 atributos, nas 3 classes

| Atributo | Onde afeta | Trava cedo? |
|---|---|---|
| Força | Dano (ataque básico de TODAS as classes + magias `.forca` do Guerreiro) | Não — soft cap 40/70 de `valorEfetivoDeDano`, nunca satura de vez |
| Vitalidade | Vida máxima (×3) + Defesa (×1) + recurso do Guerreiro/Ladino (×2) | Não — tudo linear, sem teto nenhum |
| Inteligência | Dano de magias `.inteligencia` (Mago + parte do Ladino) + Mana do Mago | Não — mesmo soft cap de Força, mais Mana linear |
| Destreza | Acerto físico E mágico, de qualquer classe | **Corrigido** (era 26, agora só perto de 99) |
| Agilidade | Esquiva + parte do crítico (todas as classes) + dano de magias `.agilidade` do Ladino | **Corrigido** a parte de esquiva/crítico; a parte de dano do Ladino já não travava (soft cap) |
| Sorte | Crítico (todas as classes) + esquiva (parte menor) + **agora também** chance/raridade de loot | **Corrigido** o crítico; loot é avenida nova sem teto |

Cada atributo tem pelo menos UMA vertente que nunca satura de vez pra
qualquer classe — mesmo Destreza (só acerto, por design: a descrição do
Ladino já dizia "Destreza garante que seus golpes não errem", separado
de "Agilidade e Sorte aumentam crítico e esquiva") continua rendendo
algo até o 99, só que devagar, igual toda fórmula de soft cap deste
jogo. Inteligência continuar "morta" pro Guerreiro puro (nenhuma magia
dele usa `.inteligencia`, e o recurso dele é Vitalidade) é intencional,
não bug — o mesmo vale pra qualquer stat fora do tema da classe em
qualquer RPG de referência; a build ainda é uma escolha real (investir
ali é phase puramente pra multiclasse/talismã, não pra combate).

Validado por simulação em Python (não só leitura) cobrindo builds puras
(só Destreza, só Sorte, só Agilidade) e híbridas (Ladino somando
Agilidade+Sorte nas mesmas duas fórmulas — nesse caso as duas saturam
mais cedo por design, já que estão investindo em duas fontes pro mesmo
teto ao mesmo tempo, o que é o trade-off esperado de um build híbrido,
não um bug). Balanceamento de chaves/parênteses + auditoria de ordem de
argumentos, sem regressão. Sem playtest real de novo — o próximo teste
valida se os novos patamares "sentem" bem em jogo.

## Kael (Forja) sempre visível na Vila, não mais trancado até o nível 20 (mesma sessão)

Bug de UX real reportado: Kael só aparecia na Vila a partir do nível 20
(`PNJ.nivelMinimoParaAparecer`), e como a Forja mora dentro do card
dele (`TelaDeEquipamento.forjaBox`, via `TelaDaVila`), isso trancava a
evolução de arma/armadura inteira até lá — ninguém conseguia gastar
Pedra de Forja nenhuma antes do nível 20, mesmo já tendo caçado uma
pilha delas.

Corrigido só mudando `nivelMinimoParaAparecer` de Kael pra `1` — as
missões dele continuam presas ao nível 20 por conta própria
(`Missao.nivelMinimo: 20`, checado direto em `Personagem.
statusDaMissao`, independente de o card do PNJ estar visível ou não),
então elas continuam aparecendo como "Bloqueada" e destravam sozinhas
quando o nível chega. Confirmado por leitura de `statusDaMissao`: o
gate de nível já era por missão, nunca dependeu do PNJ estar visível —
então essa era a única mudança necessária, sem risco de destravar as
missões de Kael cedo demais.
