# Transição ao Start da sala — REQ-49 / ADR-138

Integrado à `main` local em 27/10/2026 (PR #5, branch `cursor/match-loading-screen-ba1a`).
O PR numerava esta entrega como REQ-48/ADR-133, já usados pelos assets de
batalha; foi renumerada para REQ-49/ADR-138 sem mudar o conteúdo.

O Start da sala 1×1 abre a tela de loading do cliente e só então entra na
partida. O tempo mínimo é 5 segundos. Random é resolvido nessa abertura:
os lugares A/B mostram Dragon ou Knight, com seus pilotos. O card central
continua mostrando a imagem e o título do mapa selecionado.

## Evidência

| Peça | Fonte | Confiança |
|---|---|---|
| Painel 800×244 e barra 156×14 | `load_back.img` quadros 0 e 1, `graphics.xfs` `a52f9f46…` | Extraído |
| Prévia do Miramo 748×209 | `load_stage01.img` quadro 0; o bitmap traz o rótulo MIRAMO TOWN | Visual no arquivo |
| Máscara do chão | quadro 1 do mesmo arquivo; primeiro pixel RGB565 não zero por coluna | VA `0x004430c0` no `GunBound.gme` `4af6283d…` |
| Coluna do nome | `spawn_x * 748 / largura`, divisão inteira | A mesma rotina |
| Linha do nome | linha da máscara + 18; sem máscara, y = 122 | A mesma rotina |
| Largura do mapa | 1800 px do foreground do Miramo neste porte | Adaptação do mundo já usado pela partida |
| Espera de 5 s | Pedido desta etapa; no cliente a tela dura o carregamento | Adaptação declarada |

A montagem `map_id * 11 + lado` aparece no código que escolhe o arquivo, mas
`load_stage11.img` é cópia byte a byte do Cave. O quadro usado é o que está
rotulado como Miramo. Outros mapas não entram enquanto a sala só tem o Miramo.

Os pontos continuam os da lista já usada por `Match.start`: o piloto na
metade esquerda, a máquina na direita. A tela mostra esses pontos e a
partida recebe o mesmo par, sem novo sorteio.

Correção da validação de 27/10/2026: o painel central conserva `room_maps[1]`
(`ready_selectmap.img`, janela 136×84), incluindo MIRAMO TOWN no próprio bitmap.
O loading não recebe mais um retrato de mobile nem cria um título sobreposto.
A sala oferece apenas Miramo Town A; nenhum mapa ou seletor novo foi adicionado.
O derivado conservador 4× e o fallback nativo já existentes são preservados.

Os lugares A/B usam o mesmo `draw_figure` da sala, com largura lógica 52,
registro, orientação, animação e equipamento do piloto intactos. A CPU conserva
a composição que já aparecia na sala. O caminho que desenhava apenas o casco
foi removido. Os nomes dos mobiles permanecem ocultos nos cabeçalhos dos slots.
Random continua sendo resolvido só uma vez e os mesmos IDs/spawns entram na batalha.
Os nomes no mapa usam a fonte 8×12 da sala, com contorno de 2 px.
A prévia fica recortada no vão de `load_back` (28, 30, 741×207), sem cobrir
a barra vermelha do cabeçalho. O pixel da máscara é o contorno escuro acima
do banco de neve. O ajuste extra20 usado inicialmente foi substituído pela
conversão nativa descrita na correção de posição abaixo.

## Limites

`start_match()` chamado direto não passa pela espera (a revanche saiu com a ADR-139). Não há
rede, barra ligada a download, nem prévias dos outros mapas. Não houve
execução do cliente Windows nem aceite visual.

## Regressão anterior ao reposicionamento dos nomes

O teste anterior exigia explicitamente o comportamento errado (retrato/nome do
mobile no mapa e rótulos nos slots). Antes da correção, os novos esperados
falharam em três checks; a captura comparativa de Mage falhou nos quatro
recortes: mapa/título, piloto A, piloto B e cabeçalhos. Evidência inicial local
em `.tools/match-loading/regression-headless.log` e `regression-gpu.json`.

A captura `tests/capture_match_loading.gd` compara os pixels da sala com os do
loading para os 16 mobiles, Random e mapa no fallback nativo. As figuras são
comparadas no mesmo relógio; Random usa como referência os IDs previstos com
uma cópia independente do RNG. PNGs e hashes estão em `docs/match-loading`.

Validação dirigida: `./scripts/check.sh test_match_loading test_room_ui
 test_room_reference test_room_polish test_room_settings test_scene
 test_battle_options test_aiming test_hud test_result_screen`: **10 suítes,
1.390 checks Godot, zero falhas/exit0**. Parse dos quatro scripts alterados
aprovado. Log local `.tools/match-loading/correction-tests.log`.

GPU real 1920×1080: **18 casos e 72 comparações RGBA idênticas** (16 mobiles,
Random e fallback nativo da prévia). Sequência de **295 passos de 1/60 s**:
zero desaparecimentos, mapa constante, 135 poses distintas; loading presente
até 4,916 s e batalha após 5 s. PNGs inspecionados, relatório de hashes em
`docs/match-loading/room-loading-proof.json`; log GPU sem ERROR/SCRIPT ERROR.
A cadência simulada não comprova performance de 60 FPS.

Menu clássico/áudio/overlay sem alterações; regressão `test_battle_options`
146/0. Sem nova execução do harness completo/29 partidas, pois a correção é
de apresentação e as regras de combate não mudaram. Cliente Windows não
executado, áudio mudo, aceite visual do usuário pendente. Fonte 0.20.5;
app/ZIP não reexportados. Sem commit ou push.

## Correção da posição dos nomes — 27/10/2026

O usuário esclareceu: somente reposicionar os nomes, sem adicionar mobiles
à prévia inferior. Ghidra 12.2 confirmou o scan em 0x4430c0 e seu consumidor
em 0x442280 (bloco 0x442680..0x44281f). O mapa nativo começa em (26,18), o
scan guarda y=linha+18 e o nome usa y+5. No mapa reposicionado pelo porte,
`STAGE_ORIGIN` já inclui sua margem: posição do texto = origem + linha +5,
sem repetir os 18 px nem aplicar o ajuste extra de 20 px. O texto sobe 33 px
nativos em relação à captura anterior; x continua centrado no mesmo spawn.

O PE usa `loadmode.img`/`loadstage.img`; o painel aprovado do porte conserva
`load_back.img`/`load_stage01.img` e sua própria máscara 748×209. A conversão
aplica a relação comprovada ao scan da imagem realmente exibida; não mistura
as linhas da prévia nativa 748×228 com as da imagem atual. Marcadores, fonte,
cor, layout, mínimo 5 s, Random e coordenadas da partida são preservados.

Plano: regressão dos nomes nos 11 spawns, captura Full HD e suítes de sala,
loading e menu clássico; depois commit local das correções da pré-partida,
conforme pedido atual. Sem push.

Validação final após a escolha do usuário: `names-final-tests.log`,10suítes,
1.401checks/0 (loading33/0,11spawns; menu146/0). `names-final-gpu.log`:18casos,
72comparações idênticas,295passos, sem falhas; PNGs e hashes regenerados.
Análise estática do PE4af6283d… por Ghidra12.2, sem executar o cliente Windows;
extratos em `docs/match-loading/native-surface`. Somente os nomes foram
reposicionados; nenhum novo asset ou personagem foi adicionado à prévia.
Commit local autorizado, sem push/app novo. Aceite visual pendente.
