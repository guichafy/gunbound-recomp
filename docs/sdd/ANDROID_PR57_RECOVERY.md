# Recuperação do PR57 e desempenho Android — 16/11/2026

REQ-ANDROID-V1/A1–A8. Pedido atual autoriza corrigir, otimizar, enviar e fazer
merge do PR57 após todos os gates. Substitui a reserva anterior de merge pelo
usuário. Play Store, credenciais persistentes e redesenho continuam fora.

## Design e execução

Manter Godot/GL Compatibility e a apresentação aprovada. Medir antes/depois
no mesmo AVD ARM64/API36, resolução e cenários, declarando os limites de
emulação. Otimizar somente custos comprovados de apresentação/recursos;
CPU, física, colisão, roster, mapas e perfil permanecem equivalentes.
Não reduzir gates, omitir suítes ou aumentar timeout para esconder falhas.

- [x] Reproduzir falhas do run43750784089: fixture Android sem diretório em
  checkout limpo; seleção de bash/stub no Windows; registro do emulador no SDK.
  Fixar com regressões e executar testes de automação e cenas afetadas.
- [x] Instrumentar cenário reproduzível e coletar baseline de frame/CPU/memória.
  Identificar custo dominante e corrigir com teste de invariantes; comparar
  imagens, cenário e medidas antes/depois no mesmo ambiente.
- [ ] Executar regressão, exportar/inspecionar APK, executar smoke Android e
  solicitar revisão independente do delta antes de integrar.
- [ ] Atualizar requisitos/decisões/handoff/issues e descrição do PR com provas.
  Enviar branch; acompanhar todos os checks do SHA final sem bypass, fazer
  merge protegido e acompanhar a execução da main.

## Foco de revisão

Checkout vazio versus arquivos locais prévios; Git Bash versus WSL/quoting;
metadata do SDK versus bytes travados; invalidação de cache/recursos; pausa,
retomada, animação e entradas conservando a mesma saída visual e mecânica.

## Evidência inicial

Mac e Windows: layout acessa shop nula após save_profile retornar false;
lifecycle falha após a mesma navegação recusada. Falta .tools/android-v1 no
prepare_test_dirs. Windows: testes invocam bash do PATH e executável stub
POSIX; seleção precisa ser explícita/portável. Android: avdmanager informa
que package emulator não está instalado embora o binário tenha sido extraído.
As causas SDK/Windows serão confirmadas por reprodução específica.

## Decisão de desempenho

Inventário de texturas/AVD: aproximadamente835MB carregados,388texturas no
lobby desktop; o catálogo de16sprites é construído antes de qualquer seleção.
Maior folha ativa Bigfoot4× tem6880×6240 (171,7MB RGBA sem mipmaps).
Preservar essa folha aprovada. Em Android, iniciar catálogo vazio; carregar
somente os IDs apresentados e descartar os outros em transições sala/batalha.
Preparar ambos antes de BattleArt.reset para preservar native_animation/EPA.
Desktop e factory completa usada pelos testes continuam disponíveis.

Regressão: catálogo Android inicial vazio; selecionar os16IDs em sequência,
conservar ambos sprites/poses e manter somente IDs visíveis. InvalidID retorna
null. Comparar APKs e sequência raster idêntica com o mesmo seed/frames.
Diagnóstico mede240frames por cenário (60warmup+180amostras), passo1/60 fixo,
SOLO/rajadaBigfoot/JEWEL emNirvanaA; registra intervalos, CPU, drawcalls e bytes.
Não é o orçamento físico60s; não afirmar aceite físico com esses dados.

## Validação local observada — 17/11/2026

- Automação105 testes/4,789s, sem falhas, Ruff/diffOK.
- Recursos130/0; sete cenas962/0 antes do guard de minas.
- GPU comparação HEAD4be8312e versus implementação:3/0, raster final idêntico
  em SOLO/BigfootT2/JEWEL,1440frames processados no total,1280×800.
- APK diagnóstico1760ff1721d823314764ba8b1c912ac96ad61f1a80d76924a0c7ae4070afc7d4:
  assinatura/alinhamento16k/recursos aprovados; AVD ARM64/API36:48tiros,66mapas,
  22JEWEL eUI3, zero falhas.
- Texturas antes→depois:835863250→517618654 bytes SOLO (−38,1%);
  835203714→516959118 na rajada;835898234→242207890 JEWEL (−71,0%).
  Drawcalls91/92/102 iguais. JSONs em ../android-v1/pr57-recovery/.
- O depois foi medido enquanto o harness concorreu pelaCPU: intervalos de
  frames não são uma comparação justa deFPS. Não afirmar aceleração ou
  orçamento físico aprovado. Benefício comprovado é memória/carregamento.
- Matriz dos16 IDs passa; sprites auxiliares de Raon só carregam quando
  minas/cristais existem. Não iniciar catálogo completo no lobby Android.

Referência de dados modernos: implementação nativa AOSP
[createUserData](https://android.googlesource.com/platform/external/qemu/+/refs/heads/emu-32-release/android-qemu2-glue/main.cpp)
aceita data/empty_data_disk e cria ext4 no boot. A reprodução com CLI19
passou da falha de pacote à falha userdata.img após registrar package.xml,
comprovando as duas incompatibilidades antes de enviar a correção.
Boot completo Linux das duas imagens ainda depende do novo run remoto.

Revisão independente encontrou um P2 adicional: loading ainda desenhava o
modelo da partida anterior sob a sala, alternando carga/liberação da dupla
anterior e da nova a cada quadro. Loading agora usa o caminho frontal.
Regressão por cinco quadros reais: RED132/2, GREEN132/0; verifica
Bigfoot/Mage→Grub/Lightning sem nenhuma recarga dos IDs antigos.

Revisão final independente aprovou o delta sem P1/P2 pendente após esse ajuste.

## Segundo run remoto e legibilidade dos controles

Run44085206451/head0467d9f5: lint e versão PASS; API36 iniciou no Linux com a
definição moderna, mas o diagnóstico recusou erros de link de shader no
SwiftShader GLES legado (GL_MAX_FRAGMENT_UNIFORM_VECTORS261).
Fonte primária: [Godot109550](https://github.com/godotengine/godot/issues/109550),
mesma falha confirmada em4.7.2 com swiftshader_indirect. Usar backend moderno
`swiftshader`, já executado no AVD Mac via ANGLE, mantendo fail-closed nos logs.
Regressão de boot RED→GREEN prende driver e espera Android pronto.
Windows/macOS foram cancelados nesse run e não contam como gates aprovados.

APK candidato local mostrou rótulos cortados a160dpi (CAMERA→CAME,PAUSE→PAU),
mesmo tamanho do alvo48dp. Corrigir escala de fonte por dp e medir largura/altura
para texto completo; câmera ativa em duas linhas. Nenhuma mudança nas áreas de
toque, no mundo ou nas regras. RED332/1→GREEN352/0; faixa final552/0.
A comparação GPU3/0 acima precede somente essa correção intencional dos rótulos.

Regressão completa observada:1200,528s/103partidas/141suítes/92.895checks/
233Python, sem falhas. Inclui132checks de recursos e precede somente fonte
dos rótulos/driver de CI. Relatório durável em ../android-v1/pr57-recovery/.
Não repetir partidas por ajustes de texto ou do driver do emulador; manter
faixa afetada e os gates completos remotos do novo head.

Automação final106/0 em4,960s, Ruff/diffOK; revisão independente do delta
fonte/driver semP1/P2. Smoke local do candidato c75fffc6 foi interrompido
por desconexões transitórias do ADB após relaunch (emulator-5590 desaparece
e retorna); não conta como PASS. Não repetir ações de entrada cegamente.
O smoke completo no AVD limpo da CI continua obrigatório antes do merge.

## Seleção explícita de ANGLE no Linux

Run11744092615983/head7285fc50 manteve o erro261: o próprio log de boot
mostra OpenGL ES3.0 SwiftShader4.0.0.1, apesar do nome swiftshader.
O [código AOSP de seleção](https://android.googlesource.com/platform/external/qemu/+/refs/heads/emu-master-dev/android/android-ui/modules/aemu-gl-init/src/android/opengl/emugl_config.cpp)
explica a diferença: Mac redireciona swiftshader para swangle; Linux conserva
o GLES antigo. Usar `-gpu swangle` explicitamente nas duas APIs Linux.
[Documentação Android](https://developer.android.com/studio/run/emulator-acceleration)
define swangle como SwiftShader via ANGLE. Emulador instalado confirmou o
mesmo em -help-gpu. Regressão prende essa seleção: RED swiftshader≠swangle,
106testes de automação GREEN. Não mudar shader do jogo ou ignorar o erro.

## UI final e aviso do Android — fechamento local

Run11844094721710 com swangle passou o diagnóstico completo Linux/API36.
Candidato falhou no OCR do lobby: screenshot mostra aviso SystemUI, segunda
frase truncada pelo Tesseract. Consultar hierarquia uiautomator do AVD: exigir
package com.android.systemui, título exato, Got it único/habilitado/clicável,
bounds positivos dentro da screenshot. Apagar o XML temporário antes/depois.
Confirmação por ausência do aviso após um toque, sem aceitar diálogos do jogo.
Teste negativo recusa package do app, título ausente, duplicata e bounds inválidos.

Leitor de alvos agora une duas linhas somente com sobreposição horizontal≥70%
e distância≤altura de linha, mantendo fullmatch e rejeição de ambiguidade;
CAMERA/ON deve continuar comprovado. Pan pode ser repetido até3vezes somente
após observar de novo o toggle (turnos o resetam), mantendo ON antes/depois do
gesto final e sem repetir comando após falha de transporte. Não comprova
deslocamento numérico do mundo nem tiro/multitouch/áudio.

Candidato c75fffc646eb9b53061272419029a9eede38e4f1774ed24e2682dceec6b666f1
no AVD ARM64/API36: lobby/loja/SOLO/JEWEL/Back/Home/Retomar/IME/perfil e câmera
ON/OFF passaram. Em JEWEL, pan fez duas tentativas após reset; captura final
confirmou ON e depois OFF. Relatório ../android-v1/pr57-recovery/candidate-ui.json.
Isso sucede as tentativas interrompidas em5590 e a correção dos rótulos.

Consulta SystemUI nova testada separadamente no mesmo AVD: aviso reproduzido
com o estado de confirmação temporariamente limpo e restaurado no final;
alvo Got it observado, fechado e consulta posterior retornou None.
Prova em system-ui-real.txt. O fluxo completo da CI com essa consulta ainda
precisa passar no head novo, incluindo API24.

Automação109/0 em5,150s, Ruff/diffOK e revisão independente semP1/P2.
Novos testes tiveram RED antes das correções (wrap, reset da câmera e XML).

## Reconhecimento dos botões raster do cliente

Run119 removeu o aviso SystemUI corretamente; lobby.png mostra o lobby livre.
Tesseract não reconheceu CREATE/SETTINGS/AVATAR desenhados como sprites,
reproduzido localmente com Tesseract Ubuntu24 (inclusive3×/gray/threshold).
Adicionar observador visual para esses botões, START e placas SOLO/JEWEL.
Templates vêm dos PNGs/catálogos ativos, incluindo somente estados habilitados;
procurar no screenshot inteiro em escalas do canvas. Não inferir posições de
clique pelo layout: a correspondência dos pixels deve localizar o alvo.
Usar diferença quadrática normalizada/alpha, erro máximo0,04, juntar somente
detecções sobrepostas e recusar duplicatas separadas. O texto comum continuaOCR.

Experimento no screenshot real: CREATE0,00673 e AVATAR0,00679; melhor alvo
errado0,118/0,114. SETTINGS0,02683, próximo alvoerrado0,215. Fixture preserva
render real CI/API36; testes recusam alvo ausente, duplicado e tela escurecida.
OpenCV headless4.12.0.88 + NumPy2.2.6 travados, só automação/fora do APK.
Validar fluxo inteiro com Tesseract Linux no AVD local antes do próximo push.

Run119 macOS terminou com sucesso. Windows completou regras/cenas/partidas,
mas Python recusou a comparação literal do alias temporário RUNNER~1 com
runneradmin. O teste agora resolve o caminho como a implementação; nenhuma
regra de jogo ou gate foi removido.

Tesseract Ubuntu24 também exige gray/BICUBIC3× para ler CAMERA de8px; RGB3×
não resolveu. O observer conserva captura/OCR brutos e derivados, converte
caixas TSV de volta aos pixels originais e continua recusando ambiguidade.
A loja exige ausência dos controles CREATE/SETTINGS: GOLD/CASH sozinho podia
aceitar o quadro anterior do lobby. Testes cobrem essa transição e reprojeção.
Checkout reduzido inclui os catálogos/PNGs, com teste das seis famílias.
Automação117/0 em89,278s concorrendo com AVD/softwareGL; Ruff/actionlint/diffOK.
Fluxo Linux completo e CI do novo SHA permanecem pendentes até resultado real.

O fluxo estrito revelou Back duplicado após a loja real. APK temporário de
rastreio confirmou dois callbacks para uma única tecla: entrada14729ms/shop,
fim14857ms/lobby, segunda entrada14857ms/lobby. JNI `GodotLib_back` e
`AndroidInputHandler::process_key_event` emitem GO_BACK por caminhos distintos.
O gate anterior começava antes de reconstruir o lobby; uma transição lenta
pode consumir sua janela300ms. Reproduzir com leave_shop400ms no teste de cena.
Manter a janela300ms, mas renovar o relógio ao concluir a navegação, cobrindo
trabalho síncrono e o callback já enfileirado. Remover rastreio do APK final.

Reprodução RED27/2; fix GREEN28/0. Faixa8suítes787checks PASS, acesso host
permitido à CA do macOS. Rodada sandbox anterior teve zero assertivas falhas,
mas ERROR ambiental de CA; não foi contada como gate verde. Rastreio removido.

O fluxo v3 chegou à pausa com câmeraON/OFF, mas OCR não leu o OK raster.
Adicionar sétimo template: recorte do NativeOptionOK original, fallback
pixel-idêntico validado por ClassicBattleOptionsArt, canvasHUD800×500.
Positivo erro0,02146, abaixo do mesmo limite0,04; estado desabilitado recusado.
O gate composto ainda exige texto Configuration/Sound/etc observado na tela.
Separador entre OCR bruto e gray impede compor CAMERA/ON entre duas leituras.
Automação final119/0 em17,857s, Ruff/actionlint/diffOK. Candidato final e174f1dc
reexportado/verificado; fluxo completo Linux v4 em andamento antes do push.

v4 passou pausa/OK/Back/Home; Resume aparecia corretamente, mas Tesseract em
imagem inteira (psm3/6/11/12, RGB/gray3×) retornou vazio. Região clara detectada
pelos pixels + gray/binary80/padding branco leu Resume. Fallback limitado ao
pattern de retomada: componentes claros retangulares são apenas candidatos;
OCRpsm7 precisa reconhecer o texto e fornecer a caixa, convertida por escala e
origem. Nenhum candidato, texto ausente ou alvo ambíguo não autoriza clique.
Fixture real cobre região movida/reprojeção/ausência de texto.121testesCI/17,909s
PASS; Ruff/actionlint/diffOK. Fluxo completo v5 ainda em andamento neste registro.

## Fechamento local — evidência vigente

v5 expôs variação do OCR com o fundo atrás de CAMERA. Detectar bordas fechadas
dos controles, recortar o interior e exigir legendaOCR após contraste resolveu
OFF/ON nos dois fundos reais. Candidatos não autorizam clique sem texto; cache
limitado usa somente hash de pixels binários idênticos, não estado do jogo.
Regressão cobre controles movidos e espaçamento de glifos em duas linhas.
Revisão encontrou consultaOFF aceitandoON; corrigida com fullmatch no locator
e presençaCAMERA/ausênciaON no gate final. Captura pode preservar legendaON.

- Automação final123/0 em18,430s; Ruff/actionlint/diff aprovados.
- Revisão independente semP1/P2 após resolver a consultaOFF.
- APK final e174f1dc63e8072a5918330ec981162e9cec8ac9a61eb19399fc11abb573f0cc:
  assinatura/alinhamento16k/recursos verificados, ARM64/API36,1280×800/160dpi.
- FluxoLinux/TesseractUbuntu24 v6 completo PASS: loja real/perfil/IME/SOLO/JEWEL,
  câmeraON/OFF, pausa/Back/Home/retomada explícita. Relatório candidate-ui-linux.json.
- A rodada v6 precede somente o endurecimento final da consultaOFF. Probe do
  observer final com as capturas reais: OFF aceito, ON recusado, hash do observer
  em strict-camera-state.json;123testes incluem essa regressão. CI executará
  novamente o fluxo completo no SHA final, nas APIs36/24.
- Pan foi entregue e ON continuou visível; deslocamento do mundo não comprovado.
  Timer do jogador não foi lido nessa rodada: carga não tentada/tiro não provado.
  Multitouch, áudio e desempenho físico permanecem na issue56.

Todas as tentativas interrompidas acima são histórico; somente os resultados
explicitamente completos contam como PASS. Gates remotos e merge/main pendem.

## Run121 — custo do observer (REQ-ANDROID-V1/A8)

APK e diagnóstico Linux/API36 passaram; candidato foi exportado/inspecionado.
O step falhou em enhanced_ocr(shop): Tesseract excedeu30s no frame3×.
A ausênciaCREATE/SETTINGS já é verificada por pixels e GOLD/CASH estava lido;
ampliar a imagem nesse caminho era redundante. Priorizar regiões/controles
antes da ampliação total, mantendo todos os predicados positivos/negativos.
Limitar OpenMP do OCR e OpenCV a1worker para reduzir concorrência com softwareGL;
timeout30s e falha explícita preservados. Não alterar APK nem regras.
Reproduzir com teste que recusa ampliação redundante e verifica env do processo.
BenchmarkUbuntu24/2CPUs no PNG exato: padrão0,706s vs1thread0,582s, saída idêntica.
O timeout não reproduziu nesse host; contenção no runner é inferência, não prova
local. Orientação oficial: https://tesseract-ocr.github.io/tessdoc/FAQ.html

RED2falhas/1erro → GREEN125testes/16,638s. Ruff/actionlint/diff aprovados.
Replay no observer final do frame exato do CI: lobby recusado como loja,
enhanced_ocr não chamado,1,586s. ProbeOFFaceito/ONrecusado preservado; hash em
strict-camera-state.json. Comparação de threads em ocr-thread-benchmark.json.
