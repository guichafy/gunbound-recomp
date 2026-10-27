# Assets de batalha do cliente — inventário e porte (ADR-133)

> Correção posterior da composição: [HUD_CLIENT_LAYOUT.md](HUD_CLIENT_LAYOUT.md).
> A exigência de preservar o layout antigo foi substituída pela validação
> visual do usuário. Resultados e hashes abaixo pertencem à entrega anterior.

Pedido de 27/10/2026 (sessão iniciada a partir da ADR-132): trocar no jogo os
assets ativos que ainda vêm de `assets/openbound/` ou de derivados HD gerados
(GPT) pelos arquivos do cliente GunBound Thor's Hammer. Prioridade: Miramo
Town A, HUD de batalha, clima e Thor, itens, música e áudio. Lacunas sem
equivalente no cliente ficam declaradas, sem inventar arte. Requisito:
REQ-48. Afeta REQ-21/22 (mapa), REQ-27..31 (HUD), REQ-24/25 (clima),
REQ-35..37 (itens).

## Fontes

| Fonte | Identificação |
|---|---|
| `graphics.xfs` | `.tools/gunbound-client/`, SHA-256 `a52f9f46…0f08` (= jglim TestClient, commit `2bc43c49`) |
| `sound.xfs` | clone local `~/Workspaces/GunboundClassic/gunbound-launcher/TestClient/sound.xfs`, SHA-256 `081c1b9f…1023`, 96 entradas |
| `stage.dat` | SHA-256 `103c2b48…cfca`; registro 1 `MiramoTown` → prefixo gráfico `mos` |
| PE | `.tools/mobile-animation-port/GunBound.gme`, SHA-256 `4af6283d…fcde` |

`sound.xfs` contém 11 MP3 (`title`, `logo`, `channel`, `ready`, `stage1..6`,
`sudden`) e 85 `.xes`. Um `.xes` é um WAVEFORMATEX de 16 bytes (PCM, 2
canais, 22050 Hz, 16 bits) seguido das amostras.

## Inventário inicial

Registro recebido na retomada; a situação final por consumidor está nos
relatórios de cada grupo abaixo. “Atual” nas tabelas descreve a origem anterior
ao porte, não uma exigência de mantê-la ativa.

Estado: **cliente** = recurso do cliente já ativo; **idêntico** = o arquivo
herdado tem os mesmos pixels de uma entrada do cliente (prova por casamento
exato de RGBA); **composto** = o herdado é montagem de camadas do cliente;
**diferente** = desenho de outra versão; **ausente** = sem equivalente no
cliente desta build.

### Miramo Town A

| Consumidor | Asset anterior | Entrada do cliente | Estado |
|---|---|---|---|
| `scripts/terrain.gd:29/:73/:213` `load_map`/`original_visual`/`enable_native` (máscara) | `openbound/maps/miramo_town/ForegroundA.png` | `mos.img` quadro 0 (RLE 1800×1800) + `mos.lnd` | idêntico; agora **cliente** |
| `scripts/terrain.gd:29` `load_map` (visual) | HD GPT `hd/maps/miramo_town/foreground_a.png` 2560×661 | `mos.img` quadro 0, recorte (17,1344,1766,456) | **cliente** (densidade 1) |
| `scripts/game.gd:904` `map_background` | HD GPT `hd/maps/miramo_town/background.png` 1920×1536 | `mos.img` quadro 1 (RGB565 1300×1300) | **cliente** |
| `scripts/weather_art.gd:87` `reset` (partícula de chão) | `openbound/maps/miramo_town/Particle.png` | `pmos.img` 60 quadros com pivô | idêntico 60/60; agora **cliente** |
| — | — | `mos1..mos5.img/.epa` (animações de cenário) | não desenhadas: consumidor no PE não comprovado |

`mos.lnd`: u32 largura, u32 altura e um byte por pixel (0 vazio, 2 terra);
`lnd != 0 ⇔ alpha > 0` em todos os 3 240 000 pixels (680 299 de terra). O
importador recusa gravar quando diverge. A colisão não mudou (mesmos bits).

### HUD de batalha

| Consumidor | Asset atual | Entrada do cliente | Estado |
|---|---|---|---|
| `hud_art.gd:69-93` barra, bússola, mira, fontes, botões | `openbound/hud/*.png` (desenho HUD.cs) e HD GPT `hd/hud` | `playmode.img` 182 quadros (barra 800 px em duas faixas, MOVE, SLICE/SNIPER/DRAG, ícones de clima, placares), `play_back.img`, `play_mode.img`, `numberfont.img`, `side*.img`, `b_play_*.img`, `playinterface1..8.xtf` | diferente: o cliente tem outro layout |
| `hud_art.gd:93` som do relógio | `openbound/hud/ClockSecond.mp3` | `sound.xfs` `turnwa.xes`? | pendente de prova do evento |
| `options_popup.gd:60-62` | `openbound/hud/Options*.png` + HD | `play_option.img`, `playoption.img`, `b_play_option.img` | diferente |
| `select_item_popup.gd:73` | `hd/hud/PopupAccept.png` | — | pendente |
| `menu_screen.gd:804` | `openbound/hud/OptionsRadioButton.png` | — | pendente |
| `item_bar.gd:50` banner ITEM LOCKED | `openbound/items/MatchStatus.png` + HD | `playmode.img` quadros 15/16/17/181 | equivalente direto |

### Clima e Thor

| Consumidor | Asset atual | Entrada do cliente | Estado |
|---|---|---|---|
| `weather_art.gd:59` colunas fora de partidas com Mage | `openbound/weather/{Force,Electricity,Tornado}.png` | `FirewallTexture/LightningTexture/TornadoTexture.xtf` (já extraídos em `openbound/weather/native`, usados por `mage_weather_art.gd`) | diferente |
| `weather_art.gd:59` Weakness/Mirror/Random | `openbound/weather/*.png` | — | ausente: categorias fora desta build (ADR-128) |
| `weather_art.gd:60` Thor | `openbound/thor/Spritesheet.png` | `thor.img` 56 quadros + `thor.epa` | idêntico (39 quadros casados exatamente) |
| `weather_art.gd:61` laser do Thor | `openbound/thor/ThorLaser.png` | `ThorTexture1/2.xtf` | diferente |
| `weather_art.gd:62-64` raio/partículas | `LightningSE.png`, `ForceParticle.png`, `ElectricityParticle.png` | `Lightning.xtf`, `CrashTexture.xtf` | diferente |
| `weather_art.gd:66-69` sons | `Mirror/WindTransition/LightningS1/AdukaS2.mp3` | `lightingblast.xes`, `light-dem.xes`, `reflect.xes` | pendente de prova do evento |

### Itens

| Consumidor | Asset atual | Entrada do cliente | Estado |
|---|---|---|---|
| `item_art.gd:50-51` botões dos 11 itens | `openbound/items/Item*.png` + HD GPT | `item1.img` (58 quadros 35×34: ícones e molduras por estado), `item2.img` (22 quadros 71×34) | composto |
| `item_art.gd` Teleport1/2 | `openbound/items/Teleport1/2.png` | `teleport1/2.img` 19 quadros | mesmos desenhos; registro herdado difere (nativo ativo após retomada) |
| `item_art.gd` projétil de teleporte | `openbound/items/TeleportBullet.png` | `bulletiteml.img` 12 quadros | mesmos desenhos; registro herdado difere (nativo ativo após retomada) |
| `item_art.gd:54-55` sons de teleporte | `ShootTeleport/BlastTeleport.mp3` | `.xes` a confirmar | pendente |
| `select_item_popup.gd:196` fundo/abas | `SelectItemBackground.png`, `TabIndex.png` | — (popup próprio da versão herdada) | ausente |
| `item_art.gd` aura UsingItem | `UsingItem{Bigfoot,Mage}.png` + HD | — | ausente nesta build |

### Música e efeitos

| Consumidor | Asset atual | Entrada do cliente | Estado |
|---|---|---|---|
| `sound.gd:83` música de batalha | 12 temas `openbound/music/Theme*.mp3` | `stage1..6.mp3`, `sudden.mp3` | diferente |
| `sound.gd` `synthesize` (fire/explosion/turn/result) | tons sintetizados | `turn.xes`, `turn2.xes`, … | pendente de prova do evento |

## Resultado por grupo

Preenchido ao fim de cada grupo, com validação e limites.

### Miramo Town A — concluído

`scripts/import_xfs_map.py` extrai `assets/xfs/maps/mos/{foreground,background,particle}.png`
e `catalog.json` (SHA-256 da entrada XFS e do PNG, prova `.lnd`, registro do
`stage.dat`, `matches_legacy`). `maps.gd` aponta os três caminhos para o
cliente; `Maps.path` cai para as cópias anteriores idênticas e nunca para o
HD. HD GPT preservado em disco, fora do uso ativo. `.png.import` sem
compressão (`compress/mode=0`). `test_map` 48/0 cobre caminho, pixels,
hashes, `.lnd`, fallback, cratera em densidade 1, fundo 1300² e partícula.

## Plano de retomada — 27/10/2026

1. Preservar o delta existente e conferir extração/máscara/fallback de Miramo.
2. Portar HUD e popup com recursos disponíveis, conservando geometria/input.
3. Portar clima/Thor com texturas/EPA do cliente; conservar regras existentes.
4. Portar ícones/teleporte dos itens; declarar aura/popup sem equivalente.
5. Extrair áudio PCM/MP3 e mapear eventos somente com prova de origem.
6. Integrar testes por grupo, importar recursos, rodar harness completo,
   capturar GPU FullHD/pausa e regenerar README. Atualizar SDD e limites.

A retomada trabalha no checkout existente por solicitação do usuário; arquivos
já modificados são a base a concluir. Nenhum commit/push/export é autorizado.
Os grupos independentes HUD, clima e áudio são executados em paralelo; mapa,
itens e integração ficam com o agente principal. Resultados por grupo em
`CLIENT_ASSETS_HUD.md`, `CLIENT_ASSETS_WEATHER.md`, `CLIENT_ASSETS_AUDIO.md`.

### HUD — implementado

27atlas recompostos exclusivamente de recortes do cliente nas caixas atuais;
sem HD GPT ativo. Lacunas ficam em cópias herdadas1×. Manifesto de receitas,
hash PNG/RGBA e fallback por recurso; a validação runtime usa pixels importados,
compatível com PNG remapeado no PCK. Revisão independente encontrouP2 nos
glifos0..7 da fila; faixas decimais corretas e oráculo de pixels acrescentados.
SS agora usa as cinco faces de b_play_weapon3.img. Detalhe e inventário final:
[CLIENT_ASSETS_HUD.md](CLIENT_ASSETS_HUD.md).

### Clima e Thor — implementado

8folhas e metadata originais em xfs/weather+thor; fallback para extrações
nativas anteriores comprovadas. LaserEffect é o consumidor demonstrado,
não ThorTexture1/2 do inventário preliminar. Os renderers Mage/Aduka/Lightning
preservam seus contratos; outras duplas mantêm calendário/geometria adaptados
com arte nativa. Weakness/Mirror/Random continuam lacunas explícitas.
[CLIENT_ASSETS_WEATHER.md](CLIENT_ASSETS_WEATHER.md).

### Itens — implementado

Ícones nativos normal/desabilitado nas janelas atuais com margens transparentes;
beacon e19quadros de chamas conservam pivôs do cliente, Teleport2 reverso
comprovado. Banner ITEM LOCKED nativo. Fundo/abas do popup e aura UsingItem
sem equivalente mantêm originais1×. Sem GPT ativo. Correção do inventário:
os atlas de teleporte herdados não eram RGBA/pivô idênticos ao cliente.
[CLIENT_ASSETS_ITEMS.md](CLIENT_ASSETS_ITEMS.md).

### Música e áudio — implementado nos eventos comprovados

96entradas extraídas (11MP3/85XES); seis temas nativos stage1..6 ativos,
agenda aleatória declarada; turn2 local/turn adversário por ASM. Payload
MP3/PCM validado após import, com fallback testado. Eventos sem prova e nomes
pedidos pelo PE mas ausentes no arquivo permanecem lacunas, sem associação
inventada. [CLIENT_ASSETS_AUDIO.md](CLIENT_ASSETS_AUDIO.md).

## Validação integrada da retomada

As capturas finais já foram concluídas:720quadrosGPU1920×1080 em sete
casos, cada um com30quadros pausados idênticos e retomada;86quadros adicionais
do T1real via capture_readme. PNGs e MP4 do README são1920×1080 conferidos.
O script antigo capturava1728×1080 e gerava vídeo1920×1200; o enquadramento
foi corrigido para a janela física e passou a exigir a dimensão em cada snap.

Primeira execução completa:107suítes e29partidas concluídas; única falha era
uma assertiva test_room_ui que ainda exigia o caminho HD GPT de ItemDual.
Expectativa atualizada para xfs/items; repetição dirigida172/0. Rodada final completa aprovada: **107 suítes, 27.945 checks Godot, 82 testes Python e 29 partidas, zero falhas**,
parse aprovado e exit0. Log inicial preservado em
.tools/client-assets-full-harness-initial.log. Não usar contagens históricas
do HANDOFF como resultado deste porte.
Nenhuma alteração de versão, reexportação, commit ou push nesta solicitação.


Registro consolidado: `docs/client-assets/verified-source.json` guarda hashes
dos arquivos de código/recursos, métricas do harness, hashes de pausa e limites.
A fonte gráfica e a máscara continuam iguais à extração validada; o manifesto
não substitui o XFS/DAT original. Importadores recusam outra build antes de gravar.

A revisão independente não deixouP1/P2 aberto após corrigir a fila. Limite
visual conhecido: contraste reduzido do ângulo branco sobre painel claro.
Não houve escuta/input/aceite humanos nem execução do cliente Windows.
A validação de payload/controle de áudio não é validação auditiva.
