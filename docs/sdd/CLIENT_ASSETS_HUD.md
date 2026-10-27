# HUD do cliente Thor's Hammer — REQ-48 / ADR-133

> Correção posterior da composição: [HUD_CLIENT_LAYOUT.md](HUD_CLIENT_LAYOUT.md).
> A exigência de preservar o layout antigo foi substituída pela validação
> visual do usuário. Resultados e hashes abaixo pertencem à entrega anterior.

Pedido de 27/10/2026: substituir a arte ativa herdada/GPT por arquivos do
cliente, preservando layout, hitboxes e regras. Este grupo afeta REQ-27..31 e
a apresentação do vento/clima de REQ-23/24. Não altera carga, física,
colisão, temporizadores, dano, perfis nem opções habilitadas.

## Fonte e método

Fonte exclusiva: `TestClient/graphics.xfs` de jglim/gunbound-launcher,
commit `2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1`, SHA-256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
Importador: `python3 scripts/import_xfs_hud.py`. Leitura por
`gunbound_xfs.py`; IMG por `decode_gunbound_img.py`; XTF ARGB4444 convertido
para RGBA8888 por canal ×17. Nenhuma fonte de outra versão foi consultada.
As imagens antigas foram somente comparadas e preservadas como fallback.

O importador gera 27 atlas em `assets/xfs/hud`, com `catalog.json` contendo
hashes da entrada XFS, dimensões/pivôs de cada quadro e, para cada operação,
entrada/quadro/recorte/destino/rotação/modo de encaixe. Guarda SHA-256 tanto
do PNG quanto dos pixels RGBA. Rejeita outro SHA-256 do arquivo XFS. Não
reescreve o arquivo original nem os derivados HD anteriores.

Os arquivos do cliente são comprovados; **a composição do HUD permanece
adaptada**. Os quadros nativos usam duas faixas, outro popup e outro tamanho
de botão. O porte remonta somente recortes desses quadros nos espaços e
avanços existentes. Ajustes de tamanho usam NEAREST; ícones/fontes mantêm
aspecto dentro das células, painéis e preenchimentos de barra são estendidos.
Não se anuncia paridade de layout com a execução do cliente original.

`client_hud_assets.gd` valida versão/origem do catálogo, caminho restrito,
tipo, dimensão e SHA-256 dos pixels RGBA8 da textura carregada. A verificação
funciona também com `.png.remap`/`.ctex` em PCK, sem exigir PNG solto. Imports
nativos mantêm compressão sem perdas e `process/fix_alpha_border=false`,
pois a correção de borda padrão modifica RGB em pixels transparentes. Cada
falha cai isoladamente para o sprite herdado 1×; nenhum consumidor deste
grupo prioriza mais `assets/hd/hud`.

## Inventário por consumidor

Linhas referem-se ao estado desta mudança; o catálogo registra o detalhe de
cada recorte. “Adaptado” significa composição/encaixe do porte; os pixels de
origem são do cliente.

| Consumidor | Arquivo anterior | Equivalente no cliente | Existência e uso atual |
|---|---|---|---|
| `scripts/hud_art.gd:75` / `:91` barra | `openbound/hud/ActionBar.png`, HD GPT | `play_back.img:0/1/6` | presente; composição azul nativa adaptada 800×85 |
| `hud_art.gd:75` força/movimento | `StrenghtMetter.png`, `MovementMetter.png` + HD | `play_back.img:2/8` | presente; preenchimentos nativos em células existentes |
| `hud_art.gd:75/76` marcadores | `ShotStrenghtSelector.png`, `PreviousShootingStrenghtPointer.png` + HD | `play_back.img:3/4` | presente; encaixe adaptado |
| `hud_art.gd:79` tiros | `ShotSelector.png` + HD | `b_play_weapon1.img:0..4`, `b_play_weapon2.img:0..4`, `b_play_weapon3.img:0..4` | presente; cinco faces nativas por tiro, sem fabricar estados |
| `hud_art.gd:79` Options/Skip | `Options.png`, `SkipTurn.png` + HD | `b_play_option.img:0..3`, `b_play_skip.img:0..3` | presente; aspecto preservado nas hitboxes 60×23 |
| `hud_art.gd:33`/`:80` ângulo | `FontCurrentAngle.png` + HD | `numberfont.img:142..151`, sinal193 | presente; células15×15 |
| `hud_art.gd:34`/`:80` último ângulo | `FontPreviousAngle.png` + HD | `numberfont.img:183..192`, sinal193 | presente; células10×8 |
| `hud_art.gd:35`/`:80` Gold | `FontGold.png` + HD | `numberfont.img:227..236`, sinal193 | presente; células15×15 |
| `hud_art.gd:36`/`:80` delay | `FontDelay.png` + HD | `numberfont.img:279..288`, sinal193 | presente; células8×9 |
| `hud_art.gd:37`/`:80` dano | `FontDamage.png` + HD | `numberfont.img:172..182` | presente; sinal na primeira célula, como o contrato existente |
| `hud_art.gd:38`/`:80` ângulo da mira | `FontCrosshairAngle.png` + HD | `numberfont.img:204..213`, sinal172 | presente; linha usada0, espaço reservado da linha1 transparente |
| `hud_art.gd:39`/`:80` vento | `FontWindCompass.png` + HD | `numberfont.img:248..257` | presente; células13×19 |
| `hud_art.gd:40`/`:80` relógio | `FontTurnTimer.png` + HD | `numberfont.img:75..84` | presente; dez dígitos digitais nativos, arranjo5×2 adaptado |
| `hud_art.gd:41/42`/`:80` ordem azul/vermelha | `FontBlueTurnCounter.png`, `FontRedTurnCounter.png` + HD | `numberfont.img:152..159/173..180` | presente; dígitos decimais0..7 reais, preservado contrato anterior (as faixas40..63 são rótulos1..8 e não servem a este contrato) |
| `hud_art.gd:79` / `:344` ícones de clima | `openbound/weather/WeatherIcons.png` + HD | `playmode.img:165..171` | presentes sete categorias; linha inativa repete a arte original, sem fabricar variantes |
| `hud_art.gd:342` Weakness/Mirror/Random | mesma folha | sem categoria equivalente nesta build | lacuna declarada; recortes herdados1× ativos somente nessas três categorias |
| `hud_art.gd:78` / `:464` moldura de mira | `CrosshairFrame.png` + HD | `playinterface1.xtf`, UV166..250 em ambos eixos | presente; recorte/encaixe83×83 adaptado |
| `hud_art.gd:78` ponteiro de mira | `CrosshairPointer.png` + HD | `playinterface1.xtf`, recorte62/156/101/164 | presente; ponteiro vermelho girado90° para a orientação usada no porte |
| `hud_art.gd:82..86` wedges por mobile | `Crosshair{mobile}{shot}{side}.png` + HD | thumbnails de mobiles em `playinterface1..8.xtf` não são wedges isolados | lacuna; mantém wedges herdados1×, incluindo Mage/Bigfoot aprovados |
| `hud_art.gd:77/78` / `:349..359` bússola | `CompassBackground/Foreground/WhiteArrow/YellowArrow/RedArrow.png` + HD | sem composição equivalente confirmada | lacuna; cinco PNGs herdados1× |
| `hud_art.gd:76` seleção de turno | `SelectedPlayerTurnBG.png` + HD | sem faixa equivalente confirmada | lacuna; herdado1× |
| `hud_art.gd:76` / `:497` balão | `TurnCounterBalloon.png` + HD | `side1/2.img` são animações distintas, não uma contagem20..0 | lacuna; herdado1× |
| `hud_art.gd:78` / `:429` vida | `HealthBarFrame.png` + HD | sem moldura76px equivalente confirmada | lacuna; moldura herdada1× e preenchimento vetorial existente |
| `hud_art.gd:76` seleção de clima | `WeatherFrame.png` + HD | sem moldura22×23 isolada equivalente confirmada | lacuna; herdado1× |
| `hud_art.gd:92` som do relógio | `ClockSecond.mp3` | `turnwa.xes` tem candidato de nome, evento não comprovado | lacuna de áudio; arquivo anterior preservado |
| `scripts/options_popup.gd:57..59` painel | `OptionsBackground.png` + HD | `play_option.img:0` | presente; header/borda/painel vazio nativos recompostos nas dimensões323×328 |
| `options_popup.gd:57..59` slider | `OptionsBar.png`, `OptionsBarFrame.bmp`, `OptionsBarIntensityPointer.png` + HD | recortes de `play_option.img:0` e `play_back.img:3` | presente; mesma área e regra de entrada |
| `options_popup.gd:57..59` rádio | `OptionsRadioButton.png` + HD | bolha nativa de `play_option.img:0` + seleção de`:1` | presente; folha23×12 preserva células12+11 |
| `options_popup.gd:57..59` accept | `PopupAccept.png` + HD | checkmark do header de `play_option.img:0` | adaptação declarada; marca original repetida nas quatro faces; não existe ícone20×25 equivalente com quatro faces |
| `scripts/select_item_popup.gd:73` accept | `hd/hud/PopupAccept.png` | mesmo checkmark acima | cliente ativo; hitbox20×25 inalterada |
| `scripts/menu_screen.gd:804` rádio | `openbound/hud/OptionsRadioButton.png` | mesmo rádio nativo acima | cliente ativo; células e ícones dos botões inalterados |

As onze famílias de lacunas de imagem constam em `catalog.gaps`. Não se usa
thumbnail de mobile como se fosse uma máscara de mira, nem se fabrica um
novo balão/font/moldura quando o arquivo não fornece um equivalente. O
popup de itens/fundo/abas pertence ao grupo de itens; a única alteração nele
por este grupo é a imagem do botão aceitar.

## Validação

- `tests/test_client_hud_assets.gd`: 362 verificações, 0 falhas; todos os27
  atlas efetivamente selecionados, hashes RGBA válidos, rejeição independente
  de registro/hash/dimensão/caminho ausente e preservação de hitboxes.
- `python3 tests/test_import_xfs_hud.py`: 7 testes, 0 falhas; SHA das10
  entradas originais, PNG/dimensões/RGBA, amostragem independente das linhas
  do preenchimento nativo, ícones165..171 e transparência das lacunas; oráculos adicionais verificam os glifos0..7 e as cinco faces SS.
- `tests/test_scene.gd`: 27 verificações, 0 falhas.
- `tests/test_aiming.gd`: 25 verificações, 0 falhas.
- `tests/test_items_scene.gd`: 49 verificações, 0 falhas.
- `tests/test_hud.gd`: 569 verificações, 0 falhas.

Importação headless concluída. Logs em `.tools/hud-port`; houve erro
ambiental ao salvar `editor_settings-4.7.tres` fora do workspace. Os testes
diretos não tiveram erro de script; `test_hud` registra o aviso já existente
de reutilização de `InputEvent` na mesma frame. Captura GPU integrada produzida
pela tarefa principal: inspeção visual de `docs/client-assets/generic-030.png`
e `options.png` confirmou ordem0/1, botão SS nativo retangular, painel de
opções e controles dentro das áreas existentes. A leitura do ângulo branco
sobre o visor claro tem contraste limitado pelo encaixe atual. O resultado
temporal completo é registrado pela tarefa principal. Cliente original não
executado; escuta e aceite
visual do usuário não comprovados por estes testes. Nenhum app/ZIP foi
reexportado, nenhuma versão foi alterada e nada foi publicado.
