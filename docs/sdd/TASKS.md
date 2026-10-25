# Entregas e próximos trabalhos

## Bigfoot com acabamento4× — 25/10/2026, ADR-115

- [x] Plano SDD e ADR antes do código; escopo nas nove folhas originais.
- [x] Gerar BICUBIC4× por quadro com o helper da skill, catálogo e relatórios.
- [x] Integrar densidade só nos recortes de origem, opt-in e fallback por folha.
- [x] test_bigfoot_smooth70/0, regressões1196/0+1772/0, GPU galeria/sala/arena e PCK30/0.
- [ ] Aceite visual do usuário; app novo somente em entrega solicitada.
- [ ] Avaliar o mesmo acabamento para piloto padrão, aura, Mage e demais mobiles se pedido.

## Aceite e versionamento dos ajustes da sala — 25/10/2026

- [x] Aceite visual final do usuário e autorização de commit local.
- [x] Reunir ADR-107 a114: código, assets, fonte original, testes e evidências.
- [x] Verificação atual:1350checksGodot/0,21Python/0,24hashes e diff limpo.
- [x] Manter versão/aplicativo atuais; publicação não solicitada.

## Alinhamento de SETTINGS — ADR-114

- [x] Abaixar os dois T em1px, preservando demais letras/fonte/acabamento.
- [x] Dois checks de topo visível reproduzem o erro;988checksGodot/0 finais.
- [x] GPU4estados/fallback/clique;START inteiro e transparência idênticos.
- [x] Revisão confirma delta exclusivo dos T e1436facesRGBA preservadas.
- [x] Aceite visual do usuário. Sem app novo; ver `SETTINGS_BASELINE.md`.

## Acabamento de SETTINGS — ADR-113

- [x] Preservar fonte nativa e transparência aprovada daADR112.
- [x] Compor contorno único/alpha suave e espaçamento2px sem emendas.
- [x]1436facesRGBA exatas;986checksGodot/0 eGPU4estados/fallback/clique.
- [x] START inteiroRGBA idêntico; quatro bordas transparentes nos dois atlas.
- [x] Revisão final aprovada;PCK96/0/exit0, semoverride local.
- [ ] Aceite visual do usuário. Semapp novo; verSETTINGS_WORD_FINISH.md.

## Alpha e composição da sala — ADR-112

- [x] Remover cenário opaco dos cantos nas texturas reais de START/SETTINGS.
- [x] Isolar glifos nativos, T de START, I limpo, espaçamento e topo comuns.
- [x]1436pixels de faceRGBA originais;1344checksGodot/0 em8suítes.
- [x] GPU confirma fundo nos cantos, lettering START idêntico e clique/modal.
- [x] Revisão final aprovada ePCK isolado96/0/exit0, semoverride local.
- [ ] Aceite visual do usuário. Semapp novo; verROOM_BUTTON_ALPHA.md.

## SETTINGS com fonte completa — ADR-111

- [x] Descartar reconstrução de preenchimento/contorno do catálogo ativo.
- [x] CopiarRGBA nativo completo, lapidando só fundo/junções e alinhamento.
- [x]629núcleos/3156contornos exatos;969checks/0,GPU4estados,PCK79/0.
- [x] Revisão aprovada; margem completa do push e4364pixels no canvas.
- [x] START aprovadoRGBA idêntico; modal e cliques preservados.
- [ ] Aceite visual do usuário. Semapp novo; verSETTINGS_ORIGINAL_LETTERS.md.

## Acabamento de SETTINGS — ADR-110

- [x] Remover mattes/contornos quebrados dos recortes; manter formas nativas.
- [x] Palavra única transparente, quatro estados, baseline/espaço/contorno comuns.
- [x]965checksGodot/0,GPUFullHD e revisão independente com atlas reproduzidos.
- [x] START aprovadoRGBA idêntico; fonte/modal/regras e cliques preservados.
- [ ] Aceite visual do usuário. Semnovoapp; verSETTINGS_LETTERING_FIX.md.

## SETTINGS, modal e fonte original — ADR-109

- [x] START semseta; SETTINGS substituiCHANGE esetacircular.
- [x] Lettering raster dos botões originais, semfonteTTF substituta.
- [x] Janela azul clássica, rádios eOK/Cancel nativos;95glifosASCII dofont.fnt.
- [x] Preservar rascunho/aceite/cancelamento; ESC funciona com foco de texto.
- [x]1317checksGodot/0,21Python/0,GPUFullHD,PCK70/0 e revisão aprovada.
- [ ] Aceite visual do usuário. Semnovoapp; verROOM_SETTINGS_CLASSIC.md.

## Dificuldade, contadores e START — ADR-108

- [x] Dificuldade confirmada ao lado deCPU, fora do painel central.
- [x] Números brancos transparentes sobre base laranja restaurada.
- [x] STARTGAME azul original107×45/quatro estados, alinhado ao rodapé.
- [x] Fonte/HD,catálogo43,extração e42registros/222PNGs prévios preservados.
- [x]1286checksGodot/0,752/0 finais,21Python/0,GPUFullHD,PCK55/0 e revisão aprovada.
- [ ] Aceite visual do usuário; semapp novo. Evidência:ROOM_FINAL_POLISH.md.

## Cards, Ready e placas da sala — ADR-107

- [x] Encaixar mobile na faixa em155 com posições105/563 derivadas do cliente.
- [x] Retirar nome do mobile dos dois cards, incluindoRandom; preservaridle/avatar.
- [x] Ready/chave e placas nativas, refletindo regras offline existentes.
- [x]7PNGs/25janelas4×conservador/fallback,64checks dearte e456assets intactos.
- [x]1093checksGodot/0,21Python/0,GPU17escolhas/24quadros,PCK40/0.
- [x]P2deinput corrigido, cliques automatizados e revisão final aprovada.
- [ ] Aceite visual do usuário; mouse físico/escuta separados. Semapp novo.

Evidência/limites:ROOM_CARD_FIDELITY.md e docs/room-card-fidelity.

## Sala: itens, apoio, mapa e Random — ADR-106

- [x] Catálogo nativo uniforme64×43 com indicação1/2slots e custo.
- [x] Equipamento35/71×31 sobre seis posições; setas encaixadas/rolagem.
- [x] Mobile sobre faixaA/B no chão144 e abaixo do nome, sem seno adicional.
- [x] Idle e avatar animados por elapsed; posição não congelada nem oscilante.
- [x] Random original com avatar real,12quadros4×/fallback e sorteio só noStart.
- [x] Somente título/setas laterais da prévia; um único mapa disponível.
- [x] Regressão1720/0 + rodada final1027/0,21Python, GPU24quadros ePCK109/0.
- [ ] Aceite visual do usuário; escuta/mouse físico separados. Semapp novo.

Evidência e limites: ROOM_POLISH.md e docs/room-polish/render.json.


## Sala conforme foto — 25/10/2026

- [x] Grade5×3 com14comuns+Random; esconder escolhas diretas14/15.
- [x] Random independente para piloto/CPU, sorteado noStart apenas14/15.
- [x] Catálogo único11itens,rolagem/setas,semabas e6slots preservados.
- [x] FaixasA/B nativas nos8lugares,nomes na base e mobiles acima.
- [x] Extrair11PNGs/15janelas conservadoras4×,sem sobrescrever fontes/HD.
- [x] Validar1669checks Godot,21Python,revisão455+7+81,GPU ePCK53/0.
- [x] AtualizarSDD/metadata, sem novoapp/versão/commit/publicação solicitados.
- [ ] Aceite visual do usuário.


## Sala clássica e acabamento4× — 25/10/2026

- [x] Confirmar base anterior versionadad8b50c7 e árvorelimpa.
- [x] Conferir recursos/posições viaGhidra/ASM e extrair39quadros nativos.
- [x] Gerar14PNGs/84células conservadores, catálogo/fallback e fonte preservada.
- [x] Completar mapa/retratos, cabeçalhoGM, clima, avisos e textos/tooltip.
- [x] Preservar grade8×2/16mobiles,estados,6slots,hitboxes e arte de batalha.
- [x] Validar1256checks Godot,21Python, revisão172/0+auditoria95/0,
  GPU1920×1080 ePCK183/0/exit0; documentar/versionar localmente.
- [ ] Aceite visual do usuário; appnovo somente quando solicitado.


## Lobby com acabamento4× — 25/10/2026

- [x] Versionar correção chat/GM:5732568,735checks/0 repetidos antes do commit.
- [x] Ampliar/integrar seis imagens restantes,54células, fallback e geometria.
- [x] Conferir1045checks Godot,21Python, revisão776/0 eGPU1920×1080.
- [x] Conferir PCKisolado223/0/exit0, semoverride/TLSlocal; originais intactos.
- [x] Documentar e versionar localmente o acabamento (ADR-103).
- [ ] Aceite visual do usuário; app novo somente em entrega solicitada.


## Lobby/chat e patente GM — REQ-02/10/12/19, ADR-102

- [x] REA no cliente original: convençãoThorWORD+4, GM20/quadros24.
- [x] Extrair50quadros de insígnias; catálogo/extrator reproduzível.
- [x] Patente separada deXP/level, defaultGM, migração e persistênciav4.
- [x] Corrigir cartão/carteiras, chat/rolagem/entrada e alinhamento dos filtros.
- [x] 1086checks/0; teste novo96/0 e comparaçãoXFS repetidos pelo revisor.
- [x] GPU1920×1080 normal/stress e PCK isolado109/0, semoverride/TLSlocal.
- [x] Revisão independente, parse/Python/whitespace e registros finais.
- [ ] Aceite visual pelo usuário; app exportado permanece anterior.

## Versionamento local autorizado — 25/10/2026

- [x] Revisar alterações da sessão anterior para commit local, sem envio ao remoto.
- [x] Reexecutar regressões dirigidas: 778 checks Godot/0 falhas e 21 testes Python aprovados.
- [x] Conferir whitespace e cópia Codex da skill client-port (9 arquivos idênticos).

## Aplicação bicúbica e skill — REQ-02/12/19/20, ADR-101

- [x] Registrar aprovação do EXIT e autorização para aplicar ao lote.
- [x] Helper BICUBIC por quadro, alpha preservado, grade/saída validados.
- [x] Gerar42atlas/197estados em `buttons_smooth_4x`; EXIT coincide com a prévia.
- [x] Manter180arquivos de fontes/exatos intactos e atualizar consumidor/preset.
- [x] Preservar layout/hitboxes/estados;778checks Godot e21testes Python aprovados.
- [x] GPU1920×1080: alterações só nos botões; PCK isolado92/0/exit0.
- [x] Skill com receita conservadora, modo exato e checker seguro; instalação sincronizada.
- [x] Revisão independente aprovada; estrutura/links/14arquivos/21testes da instalação conferidos.
- [ ] Inspeção visual integral pelo usuário e eventual reexportação do aplicativo.

Registro: `CLASSIC_BUTTONS_SMOOTHING.md`; capturas/ZIP em `docs/classic-buttons-smoothing`.

## EXIT — validar suavização antes de lote

- [x] Testar duas prévias IA; registrar desvios e rejeitá-las para produção.
- [x] Registrar escolha do usuário por suavização algorítmica conservadora.
- [x] Produzir EXIT BICUBIC1712×180, quatro estados alinhados, alpha preservado e zero padding.
- [x] Comparação antes/depois com quatro estados e slider conferidos; fontes/atlas ativo intactos.
- [ ] Aceite visual do usuário antes de qualquer integração ou lote.

Prévia: `docs/exit-restoration-preview/exit-4x-bicubic.png`. Registro:
`CLASSIC_HD_RESTORATION_SKILL.md`. Pixels/tons interpolados, sem alegar cópia exata.

## Botões4× integrados — REQ-02/12/19/20, ADR-100

- [x] Usar atlas4× em `ClassicChrome`, com validação e fallback nativo.
- [x] Manter tamanho lógico, layout, estados e hitboxes; recortes de textura×4.
- [x] Importar42PNGs; incluir JSON nativo eHD no preset de exportação.
- [x] Teste dirigido antes/depois; suíte nova544/0 e regressões, total735/0.
- [x] GPU1920×1080: lobby/sala idênticos em todos os bytesRGBA na troca de atlas.
- [x] PCK isolado91/0/exit0;42atlas/catálogos presentes, override/TLS local ausentes.
- [x] Revisão independente aprovada e hashes das fontes/PNGsHD preservados.
- [ ] Aceite visual do usuário, escuta/mouse manual; aplicativo não reexportado.

Registro: `CLASSIC_BUTTONS_HD_INTEGRATION.md`. Capturas em `docs/classic-buttons-integration`.

## Demais botões clássicos4× — REQ-12/19/20, ADR-099

- [x] Inventariar42atlas e conferir contra todos os PNGs de botão `b_*`.
- [x] Ampliar41atlas restantes e reunir o CREATE já validado em `assets/hd/classic/buttons_4x`.
- [x] Preservar197estados/ordem/células, cores, alpha e alinhamento, sem margens novas.
- [x] Checker42/42 e enumeração independente de8087792pixels, zero divergências.
- [x] Conferir95arquivos de origem por hash antes/depois, todos intactos.
- [x] Catálogo e relatórios por atlas; ZIP com42PNGs+catálogo, CRC/hashes válidos.

Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Sem integração ao runtime ou build.

## CREATE4× exato na skill HD — REQ-12/19/20, ADR-099

- [x] Repetir tentativa IA com contrato explícito; rejeitar2164×726 por aspecto/margens/cores.
- [x] Registrar escolha do usuário por ampliação determinística com pixels exatos.
- [x] Entregar PNG1712×180, quatro estados, sem margens acrescentadas.
- [x] Conferir308160pixels e648cores por enumeração independente, zero divergências.
- [x] Helper e checker `--exact-pixels`, com15testes aprovados.
- [x] Revisão independente aprovada; cópia instalada sincronizada e15testes aprovados também nela.

Arquivo: `docs/classic-hd-restoration/output/create-4x.png`. Registro em
`CLASSIC_HD_RESTORATION_SKILL.md`. Aceite visual/integração não presumidos.

## Skill HD: restauração fiel — REQ-12/19/20, ADR-099

- [x] Reproduzir reconstrução/volumes suaves na skill antiga em contexto independente.
- [x] Adotar prompt integral do usuário, fonte visual única e contrato4×/alpha/estados.
- [x] Separar restauração de adaptação/rig/efeitos aprovados.
- [x] Validar três PNGs de `assets/classic`: todos rejeitados; brutos/prompts/hashes preservados.
- [x] Avaliação comportamental posterior em cinco cenários; checker com9testes aprovados.
- [x] Sincronizar a skill instalada com backup e conferir9testes/estrutura/links/hashes.
- [ ] Aceite visual de arte futura e integração: nenhum candidato atual é conforme.

Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Runtime/build/versão preservados.

## Lobby clássico e sala — REQ-02, ADR-096

- [x] Extrair `gamelist_back`/`ready_back` e os botões EPA para `assets/classic`.
- [x] Abrir o lobby na entrada; Create chega à sala 1×1 já existente.
- [x] Deixar Buddy de fora; Ranking e Join desabilitados; sem rede.
- [x] Conservar mobile, CPU, itens, apelido, dificuldade, clima e Iniciar.
- [x] Loja volta à tela que a abriu. EXIT do lobby encerra; EXIT da sala volta ao lobby.
- [x] Suítes de cena: 336 checks, 0 falhas (`test_scene`, `test_items_scene`, `test_roster`, `test_bigfoot`, `test_classic_mobiles`, `test_shop_wide`).
- [x] A grade é a única escolha de mobile; lugares A/B mostram avatar do perfil e mobile. Sem modal de mobile.
- [x] Ícone de Knight e Aduka sem o Armor por baixo; item de 2 slots é uma peça só nos dois lugares.
- [ ] Aceite visual do lobby e da sala, e escuta. App não reexportado. Cliente original não executado.

## ASate/JD/Aduka/Raon 0.20.5 — ADR-094

- [x] Investigar os quatro mobiles com Ghidra/ASM/dados e fixtures independentes.
- [x] Corrigir Ion/filhos, cristais JD, Thor Aduka e tiros/minas Raon.
- [x] Integrar autoria, cópia profunda, fim de efeito/turno e candidatos da CPU.
- [x] Preservar Thunder/Thor anexos e impedir multiplicação por filhos.
- [x] Resolver minas S2 antes do input; SS mantém o turno até detonar.
- [x] EPA, recursos originais e laser Thor aditivo; PCM Ion T1/T2 separado.
- [x] Harness completo11493 checks Godot/29 Python/29 partidas e parse sem falhas.
- [x] App/ZIP0.20.5 assinados, versão/CRC e PCK isolado68/0 conferidos.
- [ ] Executar captura GPU: script pronto, bloqueio FontRegistry/LaunchServices antes do primeiro quadro.
- [ ] Aceite visual do usuário e escuta manual; cliente original não executado.

Plano e limites: SPECIAL_MOBILES_CLASSIC_FIX.md e quatro registros por família.

## Sala inicial 1×1 — REQ-02/09/36, ADR-092

- [x] Trocar o cartão “Preparar treino” pela sala com piloto, máquina e Miramo.
- [x] Menu da partida com apelido, dificuldade e clima; Aceitar grava, Cancelar restaura.
- [x] Mobile em popup próprio; itens no PopupSelectItem; Iniciar num clique.
- [ ] Aceite visual do usuário na sala, no menu da partida e no popup de mobile.
- [x] Botão CPU escolhe o mobile da máquina; o pareamento antigo segue como padrão (ADR-093).
- [ ] Aceite visual da escolha do mobile da CPU.
- [x] Sala desenha o mobile no casco nativo de 60 px (ADR-095).
- [ ] Aceite visual do tamanho do mobile na sala.

## Ghidra na skill de porte — REQ-12/19/44/45, ADR-091

- [x] Adotar Ghidra headless direto e incluir runner/exportador reproduzíveis.
- [x] Validar importação nova, entradas indicadas, dados/vtable e22extratos
      idênticos na reabertura; ausência de função retorna falha explícita.
- [x] Validar5testes do runner e8checks independentes de LUT/seção no Godot;
      suites dirigidas1368/0. Estrutura/links/UI/alias conferidos.
- [x] Aplicar a skill em contexto independente antes e depois da atualização;
      reproduzir/corrigir cleanup de descendentes resistentes ao timeout.
- [x] Revisão para commit local autorizada após pull/merge: cinco testes do
      runner aprovados; override local excluído do versionamento.

Registro: GHIDRA_SKILL_VALIDATION.md. Sem port/runtime/build novo nesta tarefa.

## Avaliação Ghidra — REQ-12/19/44/45

- [x] Testar instalação12.2/Java25 no PE local, com hash preservado.
- [x] Exportar8rotinas de tiros/render Mage após indicar4entradas conhecidas;
      reabrir projeto e conferir24extratos idênticos.
- [x] Comparar cobertura ASM com extratos Hopper e verificar política do REA:
      6.7.0 aceita12.1.x, rejeita12.2; CLI direta funciona.
- [x] Registrar comandos, ajustes de cache/projeto e limites em GHIDRA_EVALUATION.md.
- [ ] Integração MCP com12.2 depende de conector compatível; configuração global preservada.

## Bigfoot/Mage originais 0.20.3 — REQ-12/19/20/45

- [x] Extrair tank2/tank5, EPA, RiderPivot, tiros/luzes/impactos em original/.
- [x] Ativar ClassicSprite e composição Mage original, escala nativa, miras/auras originais.
- [x] Preservar HD anterior, avatares/equipamentos, regras, IDs e perfil.
- [x] Oráculo de pixels/hotspots; regressão ativa 39/0; harness 8059 checks,
      17 testes Python, 29 partidas e parse aprovados.
- [x] Galeria GPU 1920×1080/210 quadros/60 Hz; pausa 30 quadros idênticos.
- [x] App/ZIP 0.20.3, assinatura/CRC/versão e PCK isolado 44/0/exit0.
- [ ] Captura específica menu/loja/arena (UI timeout); galeria e suites concluídas.
- [ ] Aceite visual do usuário; escuta e mouse manual.

Ver ORIGINAL_MAGE_BIGFOOT.md e ADR-089; composição dos lasers Mage permanece adaptação.

## Catálogo clássico de avatares (REQ-46, ADR-089)

- [x] Conferir `avatar.xfs` com o TestClient do gunbound-launcher (mesmo SHA-256, versão 280, 562 registros).
- [x] Índice `classic.json` com slot, preços, status e texto CP949; nenhuma peça removida.
- [x] WORD/DWORD do gunbound-server: bit 15 masculino, slot corpo/cabeça/olho/bandeira, conjunto do `amigos` e padrões `/gender`.
- [x] Love Cupid (id 143) e `ff.dat` vazio permanecem fora do catálogo comprável.
- [x] Chaves e categoria da loja preservadas para equipamento já salvo.
- [x] `test_xfs_import.py` (12) e `test_xfs_catalog.gd` (3816 checks, zero falhas).
- [x] Regressão de loja/perfil/atributos/HD: 2178 checks, zero falhas.
- [x] No merge com a `main`, REQ-45/ADR-082 permanecem do roster e do chifre; este catálogo usa REQ-46/ADR-089.
- [ ] Usuário validar na loja as descrições com reticência e o nome coreano do concurso.
- [ ] App não reexportado nesta entrega.
