# Menu clássico durante a batalha — REQ-31/33/34/48, ADR-137

Pedido de27/10/2026: portar o menu com REA e substituir os dois fluxos atuais
por somente o menu clássico. A pausa própria e o botão PAUSA saem do fluxo.
O canvas1280×800, treino1×1, perfil e combate permanecem; sem nova versão,
exportação, commit ou push neste pedido.

## Fonte e contrato

PE x86, imagebase0x400000, endereços VA: `.tools/mobile-animation-port/GunBound.gme`,
SHA256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
graphics.xfs SHA256 `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
REA6.7.0/Hopper, análise estática; não é execução do cliente Windows.

| Comportamento | Fonte VA/dado | Classificação e porte |
|---|---|---|
| Recurso ativo | 4df841..4df88c; play_option.img/3f3, b_option_cancel/exitgame/confirm | Comprovado; outra família playoption/poption não é usada neste caminho |
| Fundo | 4c9d84..4c9dbf, quadro0 em8,45; RLE276×408 | Comprovado; escala uniforme1,6, textos embutidos intactos, sem arrasto |
| Botões | 4b8850..4b88ed; X248,53/22×20, QUIT27,408/74×26, OK187,408/74×26 | Comprovado; arte com dimensões próprias, estados EPA0/1/2/3 |
| Shooting | 4b9efc..4b9f47; seleções2/0/1 em29/113/198,114 | Comprovado; bridge Drag0→nativo2, Slice1→nativo0; Sniper não portado/desabilitado |
| Scroll | 4b9f64..4ba00e; seis posições39/79/119/159/199/239,168, valores20..70 | Seleção comprovada; resposta de câmera continua adaptação existente |
| Música/Efeito | 4ba046..4ba56b; seis níveis0/80/90/95/98/100; setters4eeb10/30 | Seleção e atenuação comprovadas; `(valor-100)*100` centésimos de dB, convertidos para amplitude Godot; master−19dB mantido como adaptação |
| Background | 4ba5b7..4ba609; ON/OFF em35/219,374 | Comprovado; esconde somente backdrop |
| OK e cancelamento | dispatch4b9784, casos14→4b9343 e12→4b9115; backup4b88f2..4b8945 | Comprovado; OK confirma, X/ESC restauram valores pré-abertura e áudio |
| QUIT | caso13→4b927d, transição/saída do jogo de rede | Adaptado ao treino: volta à sala sem premiar abandono; não encerra aplicativo |
| Pausa e P | MatchOverlay/loop Godot | Adaptação offline mantida: abrir congela treino/carga; P é alias do mesmo menu |
| MIDI/MP3 e3d | recursos/ramos presentes no PE | MP3/Normal fixos, controles sem efeito desabilitados; não inventar suporte |

## Consumidores do porte

| Consumidor | Antes | Agora |
|---|---|---|
| `game.gd:637`, `match_overlay.gd:72/98` | ESC/Options e pausa própria P | Um único menu, P/show_pause são aliases |
| `options_popup.gd:52/140` | Fundo recomposto323×328, textos sobrepostos e sliders contínuos | Painel276×408 original; rádio e níveis/limites nativos |
| `classic_battle_options_art.gd:14` | Assets legados/GPT ou repack em caixas antigas | Cinco atlas nativos e fallback integral independente |
| `game.gd:699/705/708` | Accept/ESC gravavam; pausa salvava implicitamente | OK grava; X/ESC restauram; QUIT volta à sala |

## Plano

- [x] Inventariar os dois menus e rastrear recurso, desenho, input e dispatch no PE.
- [x] Extrair painel/rádio/botões sem deformação, com fallback nativo integral.
- [x] Reproduzir em testes geometria, limites estritos de input, níveis, OK/X/ESC/QUIT.
- [x] Substituir options_popup; remover pausa própria; ligar P ao único menu.
- [x] Rodar regressões, harness completo e GPU1920×1080 com pausa/retomada/input.
- [x] Registrar resultados observados em SPEC/DECISIONS/TASKS/HANDOFF.

## Limites

Sem execução do cliente Windows, aceite humano ou escuta por esta análise.
Sniper, MIDI e qualidade3d precisam de port separado; a UI não deve fingir
que esses comportamentos existem. Valores contínuos dos perfis antigos
são preservados; o novo menu grava os níveis nativos quando clicados. Scroll
desenha `trunc(valor/10)-2` quando o índice está em0..5; música/efeito só
desenham marcador para os seis valores exatos, conforme as LUTs do PE.
Os atalhos físicos ESC/P e o congelamento são bridges Godot: o dispatch
nativo comprova ações/backup, sem prova de execução do teclado Windows.

## Evidência e revisão

`docs/battle-options/rea-evidence.json` contém11 registros REA portáveis:
loader ev_b0093187…, dispatch ev_5ec9495e…, input ev_470c2487…,
render ev_29cf4a57…, draw dos botões ev_65c75884…; bytes de dispatch e
LUTs também preservados. Hopper omite alguns blocos do render; bytes
ev_610f5fe6…/ev_0b919b0b… preservam os seis ramos de rádio de áudio.
`asset-inventory.json` guarda entradas/frame sizes/pivôs e hashes.

Regressão inicial reproduziu4falhas de layout/duplicação. Revisão independente
encontrouP2 no marcador scroll de perfis antigos; teste29/55/79 falhou antes
e passou após portar a divisão inteira. Revisão final semP1/P2. O novo teste
tem146checks após a correção do áudio. Oito suítes dirigidas no snapshot
anterior ao último ajuste somaram1.254Godot+13Python/0; a dirigida final de
menu/HUD/áudio/mira somou925Godot/0, exit0.
GPU final360quadros1920×1080, Slice/Drag/voo,3×30quadros idênticos na pausa,
retomada e24PNGs. Cliques no viewport cobrem header, níveis, OK/X/QUIT;
P/ESC no fluxo do Game. Fallback igual por todos os pixels; conferência
Pillow independente dos PNGs em `pixel-proof.json`.

O rastreamento posterior de4eeb10/4eeb30 revelou que porcentagem linear era
incorreta: o setter soma−100 e multiplica100 antes do call[vtable+0x3c].
Os dois registros estão em `rea-audio-evidence.json`. A unidade do SetVolume
está na [documentação Microsoft](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/mt708939%28v%3Dvs.85%29).
`Options.volume_gain` aplica `10^((valor-100)/20)`; zero interrompe efeitos
ativos e impede novos, como os ramos nativos. A base de normalização−19dB,
o backend Godot e o agendamento de faixas continuam adaptações identificadas.
Valores1/19 não podem saturar no antigo piso linear0,0001. Testes falharam
antes dessas correções; vetores independentes0/1/19/50/80/90/95/98/100 e
um efeito ativo passam, com revisão final semP1/P2. Nenhuma escuta é alegada.

A primeira rodada completa foi interrompida após esse rastreamento de áudio
(exit143), e o log parcial preservado; não é considerada validação final.

Importação Godot final exit0, com avisos ambientais já conhecidos:
get_system_ca_certificates e gravação de editor_settings fora do sandbox.
O decoder global e os56atlas anteriores mantiveram seus pixels. O limite
histórico PopupAccept do catálogo se refere ao repack de compatibilidade,
fora do uso ativo do novo menu NativeOptions. Reexportar aplicativo não fez
parte deste pedido; a captura Godot não atualiza o app/ZIP anterior.

## Validação consolidada final

Harness completo final `./scripts/check.sh`: **110 suítes,28.279 checks Godot,88 testes Python e29 partidas, zero falhas/exit0**. Parse aprovado; fontes inalteradas durante a rodada final. Log `.tools/battle-menu/full-harness-final.log`, SHA256 `088fff0db999b93aa0dce5da7b924eb44a0d99f6fb42bc14b9d9352cf9bdc5f2`.

Manifesto `docs/battle-options/verified-source.json`:15fontes,123recursosHUD,
11recursosfallback, evidências/capturas e seisartefatosREADME conferidos porhash.
A rodada parcial interrompida não integra esses totais. Não houve alterações
de produção depois do início da rodada final. Aceite visual/escuta/input
humanos, execução do cliente Windows e app atualizado continuam pendentes.
