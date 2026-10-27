# HUD em duas faixas — REQ-27/28/30/35/48

> Correção posterior do fundo: ADR-136, `FOOTER_BACKGROUND_NATIVE.md`
> (em docs/sdd). Capturas anteriores preservam o raster com preto transparente;
> a validação atual está em `docs/footer-background/`.

> Correção posterior: [MOVE_BAR_NATIVE.md](MOVE_BAR_NATIVE.md), ADR-135.
> A posição acima do footer e o desenho MOVE descritos abaixo são históricos.
> O manifesto desta entrega anterior conserva seus hashes; a validação atual
> da barra está em `docs/move-bar/verified-source.json`.

Correção solicitada na validação visual de 27/10/2026. As quatro imagens do
usuário mostram o erro: arte nativa recomposta no rodapé antigo. A segunda
imagem define o footer; a terceira define o header; a quarta demonstra uma
variante Jewel, não autoriza implementar esse modo.

## Contrato e plano

- [x] Extrair de `play_back.img` a faixa superior800×40 (quadro0, crop20/12),
  inferior800×44 (quadro1), Gold roxo178, rótulos Slice/Drag9/11 e controles
  nativos sem redimensionar cada peça. Catálogo/hash/fallback continuam ativos.
- [x] Header: Options à esquerda, clima, Gold no centro, seis slots de itens,
  Skip à direita. Footer: S1/S2/SS, ângulo, modo de mira, carga e movimento.
  Modelo/consumo de item/turno/dano/carga permanecem os mesmos.
- [x] UI mantém escala uniforme1,6 no canvas1280×800: header64 px, footer70,4 px;
  mundo entre as faixas. Bloqueio de input cobre ambas; câmera/draw traduzem
  somente a apresentação. Extras mouse/toque continuam acessíveis no mundo.
- [x] Os frames172/173 (vidas),175..178 (painéis de equipe/Gold) e179/180
  (score Jewel) ficam identificados por semântica. TreinoSolo usa Gold; não
  apresentar vidas/placar fictícios. Outros modos permanecem no roadmap.
- [x] Oráculos com pixels fonte independentes, cenas/input e fallback corrompido.
- [x] GPU1920×1080 com pausa e README atualizado.
- [x] Harness completo29partidas.

Fonte fixada: graphics.xfs SHA256a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08,
PE4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde.
Arte/variantes comprovadas pelos IMG; posições também confrontadas às imagens
fornecidas. A adaptação de aspecto800×500 do porte permanece explícita; não
se anuncia execução/paridade dinâmica do cliente Windows.

## Extensão solicitada: cronômetro e vento

Pedido adicional do usuário durante a validação: garantir recursos originais
no tempo de ação e na indicação do vento. Substituir os dígitos recompostos e
os cinco componentes de bússola herdados por numfont/moon.xtf, preservando o
relógio do modelo, a regra de30 segundos e o vetor físico. Cronômetro deve exibir
segundos+décimos conforme consumidor nativo; não arredondar a apresentação
para segundos inteiros. Cobrir30.0,12.7,0.0, mudança de turno e pausa; vento0,
força máxima e quatro cardinais, fallback e direção coerente com a física.

- [x] Oráculo de fonte/pivô de numfont146..177 e textura moon.xtf.
- [x] Cronômetro/décimos e vento nativos no renderer; fallback por conjunto.
- [x] Testes dirigidos, GPU e README repetidos; harness completo final.

## Inventário dos consumidores corrigidos

| Consumidor atual | Uso anterior | Recurso atual do cliente | Estado |
|---|---|---|---|
| `hud_art.gd:313` duas faixas | ActionBar recomposta800×85 | NativeHeader/NativeFooter, play_back0/1 | ativo; crop pela janela/pivô, sem deformar peças |
| `hud_art.gd:150` tiros/Options/Skip | células37×37/60×23 encaixadas | b_play_weapon1/2/3, b_play_option/skip, Native* | ativo35×34/40×30; input reposicionado |
| `hud_art.gd:313` Gold | numberfont227 encaixado em15×15 no rodapé | play_back178; numfont135..144, NativeGoldDigits | ativo no headerSolo |
| `item_bar.gd:27/68`, `item_art.gd:99` itens | bandeja antiga inferior; ícones com margem | item1/2, recorte sem margem; play_backbandeja | ativo no header,35/71×31 |
| `hud_art.gd:351` clima | faixa inferiorWeatherIcons | play_back85/45/65/25/105/125/145+165..171 | ativo no header; categorias sem equivalente usam fallback declarado |
| `hud_art.gd:422` tempo de ação | numberfont75..84 ampliado66×82/segundos inteiros | numfont146..166/ponto156, NativeTimer* | ativo com segundos+décimos; conjunto validado |
| `hud_art.gd:390` vento | CompassBackground/Foreground/3setas herdadas + fontWind | moon.xtfUV(.755,.005,.24), numfont167..177, NativeWind* | ativo; ponteiro embutido na textura, texto imóvel |
| `game.gd:334/960`, `battle_hud_layout.gd` input | bloqueio só do rodapé antigo | mesmas caixas das faixas/botões nativos | cliques reais e Drag/pan cobertos |
| `game.gd:745`, `camera_rig.gd` mundo | origem do mundo y0, vista664 | origem visualy64, vista665,6 | só apresentação/câmera; colisão inalterada |

NativeLifePanel(play_back172) e NativeJewelPanel(179) foram identificados e
extraídos; não têm consumidor ativo porque faltam modelos desses modos no
escopoSolo. Não são usados como se fossem Gold.

## Cronômetro e vento: apresentação atual

`timer_digits` converte apenas a apresentação ao contador20 Hz do cliente:
`/200`, `/20%10`, `/2%10`. O relógio do modelo continua30 s e não é quantizado.
A pequena tolerância1e-6tick só restaura limites exatos após subtraçãofloat.
`display_seconds` anterior permanece para os consumidores de áudio/balão;
o desenho agora usa segundos e décimos. Render preserva as posições/pivôs
diferentes dos dois tamanhos, inclusive os dígitos estreitos1/3/4/7.

O círculo/ponteiro é o recorte UV de `moon.xtf`, sem fabricar outra seta.
O renderer gira o anel, deixando os dígitos e WIND imóveis; ângulo0=direita,
90=cima,180=esquerda,270=baixo, coerente com `Weather.wind_vector`.
A força0 continua legível. O renderer nativo não usa o squash/spin nem as
setas branca/amarela/vermelha herdadas; elas ficam só no fallback integral.
As três partes de cada grupo precisam passar tamanho/tipo/hash. Uma falha
ativa o conjunto antigo inteiro, sem cronômetro parcial ou vento sem número.

`moon.xtf` mantém também oRGB sob alpha0: o primeiro teste independente
pegou a composição que zerava essesRGB. Importação corrigida para cópiaRGBA
exata; nova suíte passa byte a byte. Uma revisão apontou deslocamento1px
nos dígitos do vento; oráculo de coordenadas adicionado e valor corrigido.

`test_hud_clock_wind.gd`:60 checks/0; relógio30.0/12.7/12.3/9.9/0.0,
quatro forças × quatro cardinais, registro de dígitos e fallback por conjunto.
OráculoPython agora10 testes/0, incluindo imagensinteiras, numfont e moon.
As aliasesCompass*/WeatherFrame antigas em catalog.gaps pertencem à camada
de compatibilidade; não significam lacuna no indicador de vento nativo atual.
A provaGPU de direção mede o centroide dos pixels vermelhos do ponteiro: os
quatro produtos escalares com cardinais físicos excedem0,9999.

## Evidência e resultados

`play_back.img` é carregado como recurso7000 em0x4df02a..4df039.
Ghidra12.2/JDK26, projeto local `builds/ghidra-client-assets`, PE fixado acima:

| Evidência | Contrato confirmado |
|---|---|
| 0x4bb730, ASM4bb853..4bb89f | Options11,3/40×30; Skip750,3/40×30; S2x47y562/35×34 |
| 0x406990, ASM406a52..406a70 | footer frame1 em0,556 |
| ASM406d19..406d3a | fill frame2 em244,569, dimensão400×22 |
| ASM407b6f..407b8f | painel roxo178 em321,0 |
| ASM407758..4077db | numfont179..188, ângulo em145/153,581, avanço8; sinal178 |
| ASM407c18..407ca7 | numfont135..144, Gold desde350,6, avanço20, cinco posições |
| ASM407005..40701a e4070b8..4070cd | cronômetro146..155 em700/729,42: ticks/200 e ticks/20%10 |
| ASM407413 e407487..40749c | ponto156 em759,81; décimo157..166 em767,59: ticks/2%10 |
| ASM40757d..4075ba e407608..407629 | vento167..176 em390/401 ou396,60; WIND177 em391,79 |
| ASM4caf8a..4cafd7 / helper4ecc70 | moon.xtf UV(.755,.005)+.24; quad64×64/centro400,71/rotação negativa |

Extratos completos, manifestos e comandos em `.tools/hud-layout/05-hud-init`
e `10-bands`; `ok=true`, hashes preservados. Perguntas intermediárias sem função
reconhecida não são tratadas como prova. A tabela de recursos diferencia
`numfont.img` (recurso500, usado por esses readouts) de `numberfont.img`.
Loader40eec4..40eed3 confirma `numfont.img` no recurso500;
40f119 carrega separadamente `numberfont.img`. Numfont135..144 é19×24;179..188 tem pivôs variáveis registrados em células8×10.

Importador produz55 atlas (27 compatíveis anteriores e28 novos),12 entradas
nativas. Novos recortes não sofrem fit/stretch; o único encaixe global é1,6.
Fontes do mundo e popup continuam nos contratos anteriores. O footer antigo
continua disponível somente como fallback, em novas caixas lógicas.

`battle_hud_layout.gd` centraliza header/footer/mundo, botões e região de
carga. `camera_rig.gd` usa o tamanho do miolo; draw soma64 px somente à posição
visual. Terreno/ator/projétil/colisão/previsão não recebem o deslocamento.
Footer nativo y556 vira456 pela diferença do canvas; recuos internos intactos.

O banner ITEM LOCKED fica217×38 no header. Botões de item usam os pixels
nativos35/71×31, sem a margem1px dos atlas de compatibilidade. Movimento mostra
a faixa MOVE original enquanto há input de movimento no turno próprio; sua
visibilidade permanece uma adaptação de apresentação declarada. Nenhuma
regra de movimento foi trocada. F4/área amarela estão pintados no fundo
original e permanecem inativos no treino; não foi implementado Tag.

As variantesLife172/173 e Jewel179/180 são distintas do Gold178. SóSolo tem
consumidor ativo; Life/Jewel extraídos servem à identificação, sem ligar modos,
placares ou zeros fictícios no treino.

Testes red/green: o oráculo de fontes falhou por falta dosPNGNative* e o teste
de cena falhou15/17 antes da correção. A suíte atual verifica posições,
fallbackclima, tamanho do lock, cliques reais nos novos controles e bloqueio
Drag esquerdo/pan nas faixas. Revisão independente levantou fallback ausente
do clima e compressão vertical do lock; ambos corrigidos e reavaliados.

GPU final:360 quadros1920×1080 (Slice/Drag/movimento,120cada),30 quadrosRGBA
idênticos em cada pausa, retomada diferente,21 PNGs incluindoEclipse/fallback
clima/opções. `docs/battle-hud-layout/capture.json` guarda hashes/contagens.
Captura é do Godot M4 Pro, áudio mudo; não comprova60 FPS nem execuçãoWindows.

Harness completo final: **109 suítes, 28.131 checks Godot, 85 testes Python e 29 partidas, zero falhas**, parse aprovado, exit0.
Log `.tools/hud-layout/full-harness-final.log`; manifestos/hash de fonte/assets/
medias em `docs/battle-hud-layout/verified-source.json`. A rodada intermediária
teve runnereditado durante execução e terminouexit2 por offset de leitura do
shell; não foi tomada como validação final. `sh -n` passou e tudo foi repetido
com fonte/runner estabilizados. Capturas finais limpas de erros/leaks;
importador/editor só registrou editor_settings fora do sandbox (ambiental).

GPU total960 quadros/8 casos/8×30pausa com retomada,45 PNGsFullHD. README final:
4 telas+86 quadrosT1real, MP41920×1080/30Hz, GIF640×360/15Hz43quadros.
OráculosPython10/0; clock/wind60/0; layout/input42/0; assetsHUD446/0.
Escuta, execuçãoWindows e aceite humano desta correção continuam pendentes.
Sem versão/app/PCK/ZIP atualizado, commit ou push.

A preservação do layout antigo na ADR-133 é substituída apenas
para as faixas do HUD por esta correção. Originais e derivados anteriores
continuam preservados. Sem commit/push ou exportação solicitados.
