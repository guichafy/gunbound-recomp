# Android v1 — design e contrato de implementação local

Data: 15/11/2026 (America/Sao_Paulo). Estado: **implementação local entregue; aceite físico/remoto pendente**.
O recorte de interface clássica com controles touch completos foi aprovado.
Tooling/exportação/CI/publicação já têm código e testes locais; a validação de
interface do APK candidato passou no AVD macOS ARM64/API36, incluindo retomada
explícita. [Relatórios/SHA/capturas](../android-v1/local-validation.md).
CI remota, assinatura persistente e aceite físico não foram executados.
Seguimento na conversa de voz: “Podemos seguir com essa base” confirmou o
recorte com controles auxiliares; não autorizou iniciar implementação.
Pedido posterior autorizou implementar e verificar localmente. Após testar o
emulador e confirmar “Agora funcionou”, o usuário autorizou commit/push da branch
`codex/android-v1` e issues; ele próprio abrirá o PR e fará o merge. Secrets,
administração, aparelho pessoal e publicação manual continuam fora desta execução.
Pendências na [issue #56](https://github.com/guichafy/gunbound-recomp/issues/56);
ergonomia na #55. Plano: [ANDROID_V1_PLAN.md](ANDROID_V1_PLAN.md).

## 1. Intenção, base e limites

Permitir baixar um APK produzido pelo GitHub Actions, instalar no Android e
concluir treino offline 1×1 apenas com toque, retornando à sala. Uma atualização
posterior deve conservar o perfil. Preservar aparência clássica, regras,
16 mobiles, 22 lados dos mapas, SOLO/JEWEL, avatares, loja e idiomas existentes.
Touch, encaixe e ciclo de vida são **adaptações de plataforma**, sem alegação
de regra ou interface Android nativa do cliente Thor's Hammer.

Base lida: `49fdeaa9a5b29b216ecd7ce44a44e8a840ef8bf4`, fonte 0.20.5, neste
worktree inicialmente limpo. Também foi lido, sem editar, o projeto salvo em
`/Users/guichafy/Workspaces/DemoGame`, no mesmo commit, com revisão JEWEL
não commitada. Ali o painel inferior tem variante por time, `JEWEL_PANEL`
reserva sua área de input, `in_world(point, mode)` exclui o placar e os extras
sobem no JEWEL. O plano deve ser reconciliado com essa revisão antes do código;
não copiar a versão antiga por cima dela. `AGENTS.local.md` foi preservado.

Fora da v1: rede, contas, multiplayer, ranking, iOS, Play Store/AAB, nova arte,
reescrita da engine, redesenho amplo do HUD e recuperação da partida após
morte do processo. A melhoria visual/ergonomia avançada já está na
[issue #55 — Android: reorganizar HUD e ergonomia dos controles para celular](https://github.com/guichafy/gunbound-recomp/issues/55).
Essa issue não adia controles utilizáveis, câmera, mira, safe area ou lifecycle.

Alternativas discutidas: preservar a interface e completar entrada touch
(escolhida pelo usuário: menor escopo e fidelidade visual), ou reorganizar o
HUD para celular (adiada na #55). Manter Godot/GDScript e Compatibility é o
ponto de partida; não há motivo identificado para trocar renderer/engine.

## 2. Diagnóstico confirmado no código

Referências são arquivo + símbolo, resistentes a deslocamentos de linhas.

| Área | Evidência local | Consequência para a v1 |
|---|---|---|
| Engine/tela | `project.godot`: features 4.7, canvas 1280×800, `canvas_items`, `gl_compatibility` também em mobile, ETC2/ASTC ativo | Exportar e medir em Android; configuração não comprova funcionamento |
| Entrada | `scripts/game.gd:build_hud`: movimento 40×32, flip 36×32, tiro 78×32; `button_down/up` chama carga/soltura | Extras atuais não completam o touch; ampliar alvos e incluir ângulo |
| Mira | `scripts/aim_control.gd:update_keys/step_angle/tick` | Ângulo usa W/S/↑/↓; Slice é 3 s, automático a 100%; Drag usa deslocamento horizontal e tremor próprios |
| Câmera/Drag | `game.gd:_input/_unhandled_input`, `camera_rig.gd:fit/update` | Mouse, toque emulado e raw touch coexistem; falta ownership por índice do dedo e câmera acessível em Drag |
| JEWEL | `game.gd:_unhandled_input`, `match.gd:choose_respawn`, revisão local de `battle_hud_layout.gd` | Retorno usa clique/toque no mundo; não deve atravessar HUD/placar ou disputar um gesto de câmera |
| Composição | `game.gd:replace_root`, `classic_chrome.gd:mount`, `menu_screen.gd`, `lobby_screen.gd` | Coordenadas fixas e palco clássico pedem transformação única de desenho/hit test |
| Loja | `avatar_shop.gd:setup/fit_viewport/_exit_tree` | Usa canvas 800×600, pixels de janela e troca `content_scale_*`; precisa entrar no mesmo contrato de safe area sem escala duplicada |
| Teclado | `menu_screen.gd:nickname_input`, `lobby_screen.gd:chat_input`, `settings_panel.gd` | Foco/teclado virtual não podem cobrir campo ou virar comando de batalha |
| Pausa/áudio | `game.gd:_process/_on_overlay_opened/_on_overlay_closed`, `sound.gd:request_music/update_music` | Pausa atual é de overlay; não há handler Android de suspensão/voltar em Game |
| Perfil | `profile.gd`, `options.gd`, `json_store.gd:write_atomic` | `user://` e transações existentes são a base; não criar perfil externo ou migração desktop automática |
| Export | `export_presets.cfg`, `ci/package_common.py:NOTICES` | Só macOS/Windows; copiar o contrato de recursos/exclusões e tornar licenças acessíveis no Android |
| Bootstrap | `.github/ci-tools.json`, `ci/bootstrap.py:prepare_godot` | Editor Linux existe, mas templates escolhidos pelo host só instalam Linux nesse host |
| Pacote | `ci/package.py:main/write_manifest`, `ci/smoke.gd:prepare/validate_arguments` | Smoke desktop exige caminho absoluto `gunbound-package-*/ci-profile.json`; não serve diretamente ao sandbox Android |
| Release | `ci/publish.py:validate_assets/publish` | Aceita exatamente seis entradas internas para dois ZIPs; upload escolhe somente `.zip` |
| Workflow | `.github/workflows/desktop.yml`, `.github/main-protection.json` | Quatro checks obrigatórios, main serializada desde versão, publisher isolado; novo job não pode enfraquecer isso |

A tabela acima registra o diagnóstico anterior à implementação. O delta local
agora contém preset, exportador e smokes Android; não descrevê-los como ausentes.
Houve exportação e execução em AVD macOS posteriormente, com correções guiadas
por falhas reais. Isso não comprova UI final aprovada, CI remota, aparelho físico
ou escuta. Resultados e SHA específicos ficam no HANDOFF e no ledger local.

## 3. Requisitos e rastreabilidade

`REQ-ANDROID-V1.*` é um namespace documental; não declara entrega nem consome
numeração global concorrente. Afeta REQ-01/02/03/19/20/27–30/34–41/45–50/52/53/55,
REQ-MAPS-45 e REQ-JEWEL-46, preservando as decisões atuais de combate.

| ID | Contrato de aceite | Tarefas do plano |
|---|---|---|
| A1 | APK Android paisagem, Compatibility, identidade estável, versão única, ABI e assinatura verificadas | T1, T5–T8 |
| A2 | Só toque: movimento, ângulo, direção, armas, itens, passar, Slice/Drag, câmera, pausa e respawn JEWEL | T2, T3, T9 |
| A3 | Safe area, escalas e teclado virtual mantêm desenho/hitboxes correspondentes e ações acessíveis | T2, T3, T4, T9 |
| A4 | Interrupção/voltar cancela comandos; retorno não dispara nem avança o tempo suspenso | T4, T9 |
| A5 | Perfil/opções em `user://`, transações e XP idempotentes; atualização mantém progresso | T4–T6, T9 |
| A6 | PR gera APK sem secrets; main gera APK assinado; publicação exige conjunto completo e mesma versão/SHA | T1, T5–T8 |
| A7 | Evidência separa modelos, APK diagnóstico, APK final/emulador e ARM64 físico | T6–T9 |
| A8 | Preparar/build/AVD descartável/install/open/check reproduzíveis no macOS, executando APK Android real e registrando SHA/API/ABI/logs | T10 |

## 4. Decisões técnicas e estado da implementação

### D1 — Contrato de distribuição

Nome de distribuição `Gunbound Recomp`, package `com.chafy.gunboundrecomp`.
Diagnóstico e candidato usam `com.chafy.gunboundrecomp.ci` e nome visível
`Gunbound Recomp Test`; assinatura efêmera e dados separados do app público.
A disponibilidade/implantação da identidade pública ainda é gate externo.
APK único com **arm64-v8a + x86_64**, sem ARMv7. O mesmo arquivo final deve
rodar no emulador x86_64; isso não comprova ARM64 físico.

Exportação legacy com templates pré-compilados, sem Gradle customizado, plugin
Android ou NDK. `bootstrap.py --target android` verifica o TPZ oficial e extrai
`version.txt/android_debug.apk/android_release.apk` em `.tools/android/templates`.
`android_package.export_apk` usa espelho temporário, editor copiado em modo
`_sc_`, settings isolados e templates explícitos; no macOS assina ad-hoc somente
a cópia do editor. Antes de importar/exportar exige `--version` compatível com
o pin `4.7.2.stable`, proveniente de `.github/ci-tools.json`. O editor instalado
não tem suas preferências alteradas; `shutdown_adb_on_exit=false` preserva ADB.
[Exportador pinado](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/export_plugin.cpp).

Templates/APKs reais confirmaram **min 24/target 36**. No legacy,
`gradle_build/min_sdk` e `target_sdk` ficam vazios: overrides explícitos exigem
Gradle e foram rejeitados pelo exportador real. O inspector exige 24/36 nos
bytes exportados. `config.gradle` da tag aponta Java 17/compile 36/Build Tools 36.1.0;
a página stable genérica não substitui esse pin.
[Configuração da tag](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/java/app/config.gradle).

Lock Linux: JDK 17.0.21+9, command-line tools 19.0 (arquivo numerado 13114758),
platform-tools 37.0.3, Build Tools 36.1.0, SDK 36 r2, emulator 37.3.9 e imagens AOSP
x86_64 API 24 r8/API 36 r2. URLs/revisões/SHA256 estão em `ci-tools.json`; para
Google, os SHA256 foram derivados após validar tamanho/SHA1 dos metadados
oficiais. `android_tools.py --emulator` prepara tudo sob `.tools`, revalida
archives inclusive em cache e rejeita revisão/extração insegura. JDK permite
seus links internos legítimos sem aceitar escapes. Archives reais foram
verificados/extraídos; executar toda a toolchain Linux/AVDs na CI segue pendente.
Não há resolução permanente de `latest`, NDK ou CMake nessa preparação.
O fluxo macOS usa SDK existente read-only e lock separado; ver [guia](../ANDROID.md).

`versionName` vem de `application/config/version` aplicada pelo job version.
`versionCode = major*1_000_000 + minor*1_000 + patch`, com cada componente
entre 0 e 999, resultado positivo e ≤ 2.100.000.000; overflow e versões fora
do contrato falham. Ex.: 0.20.5 → 20005; versão futura é calculada pela CI,
não escolhida neste plano. Não usar run number/retry como versão de produto.
Android distingue nome/código e usa o código na ordenação de atualizações.
[Versionamento Android](https://developer.android.com/studio/publish/versioning).

Conservar app ID, chave e schema para atualização. A assinatura de distribuição
é persistente; a de PR nunca a substitui. Chaves, alias e senhas serão
provisionados futuramente em ambiente seguro, fora do Git e de artifacts.
Certificado público/fingerprint esperado pode ser versionado.
[Assinatura Android](https://developer.android.com/studio/publish/app-signing).

### D2 — Coordenadas e UI clássica

Paisagem usa `display/window/handheld/orientation.android=4`
(`SCREEN_SENSOR_LANDSCAPE` do Godot). Na tag 4.7.2 o exportador mapeia isso para
Android **11/0xb, `userLandscape`**; não confundir com enum nativo 6 ou com
valor 6 do enum Godot (`SCREEN_SENSOR`, que exporta 13/fullUser). A inspeção exige 0xb.
[Mapeamento pinado](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/gradle_export_util.cpp).
Preservar canvas de batalha 1280×800, palco clássico
800×600 e geometria de mundo/câmera. Ajustar uniformemente à área segura da
janela; sobras viram margens, sem esticar, cortar HUD ou mudar colisão.
O encaixe deve abranger desenho direto de Game, controles, overlays, figuras
e efeitos; transformar apenas o `root` deixaria o mundo/HUD desenhado fora dele.

`platform_layout.gd` proposto centraliza safe rect e transformações inversas
janela↔canvas. Loja mantém seu fit 800×600, usando esse safe rect e restaurando
as propriedades da Window ao sair. Recalcular em resize, mudança de insets,
teclado, suspensão/retorno e inversão de paisagem. Área inválida usa o tamanho
da janela; nunca dividir por zero. API de referência:
`DisplayServer.get_display_safe_area()`; converter coordenadas de display
para janela antes do fit. [DisplayServer](https://docs.godotengine.org/en/stable/classes/class_displayserver.html).

Adicionar clusters auxiliares discretos de toque sobre as bordas do mundo,
sem mover a arte clássica: esquerda com movimento/ângulo; direita com tiro,
flip, câmera e acesso aos seletores de armas/itens. Seletores compactos só
abrem quando necessários e chamam as ações existentes. Alvo proposto de
48 dp nos controles auxiliares, sem sobreposição; medir densidade real.
Seletores resolvem os slots nativos pequenos, preservando sua arte e indicação
de estado. Menus/loja mantêm composição, com correções locais de alvos/foco
quando indispensáveis para operar por toque. Não esconder placar JEWEL,
barra de força, mobile ativo ou OK. Um helper `touch_controls.gd` compartilha
os retângulos desenhados e usados pelo input; alvos transparentes sem indicação
visual não são solução. T2 registra retângulos e capturas da configuração mínima.

Matriz inicial de layout: áreas úteis 640×360 dp e 800×360 dp, telas 8:5,
16:9, 20:9 e tablet 4:3, com e sem recortes/barra de navegação. Se os controles
não couberem, usar seletores temporários e corrigir no escopo v1; não remeter
uma ação inacessível à #55. Recursos de combate continuam em pixels nativos.

### D3 — Um dono por dedo, ações compartilhadas

`touch_input.gd` mantém ownership por `InputEventScreenTouch.index` até
soltura/cancelamento. Prioridade ao iniciar: modal/teclado → controles →
placar/HUD bloqueado → mundo. Dedos adicionais não herdam comandos. Duas
direções opostas se anulam. Movimento e ângulo podem coexistir; iniciar tiro
zera movimento/ângulo e bloqueia novos comandos de combate até encerrar carga.
Armas/itens não mudam durante a carga pelo adaptador touch.

Android trata raw touch na batalha e não usa mouse emulado para essas ações.
Preservar a emulação para Controls de lobby/sala/loja, mas consumir os eventos
touch já capturados e filtrar mouse com origem touch no caminho de batalha.
Validar isso no runtime pinado; se a origem não for distinguível, desligar
emulação apenas na batalha e restaurar ao sair. Não desligá-la globalmente
sem substituir a entrada dos menus. Mouse real/teclado desktop seguem funcionando.
O pipeline de Godot passa por `_input` antes da GUI; término de gesto capturado
precisa ser observado mesmo sobre o HUD, sem iniciar gesto de mundo nesse local.
[Fluxo de InputEvent](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html).

| Ação | Proposta de gesto | Destino existente/regra preservada |
|---|---|---|
| Andar / ângulo | Segurar ←/→ ou −/+; soltar para parar | `Match.move_actor`; `AimControl.step_angle`, limites por arma e apoio; repetição igual à do teclado |
| Direção / arma / passe | Toque confirmado no mesmo alvo | `Game.flip/select_weapon/pass_turn`; travas SS existentes |
| Itens | Abrir seletor; tocar slot visível | `ItemBar.press`, uso/fila/bloqueio/compactação existentes, não duplicar índice por posição |
| Slice | Segurar ●; soltar dispara; 3 s dispara uma vez a 100% | `begin_charge/release_charge/tick`; soltura posterior não dispara outra vez |
| Drag | Com câmera desligada, iniciar no mundo e arrastar horizontalmente | `begin_drag/update_drag/release_drag`, coordenadas lógicas, potência/tremor/mínimo existentes |
| Câmera | Toggle visível CAMERA; arrastar mundo; vale também em Drag | `CameraRig.fit`, scroll factor; toggle impede disparo; indicador ativo e toque para sair |
| Respawn JEWEL | Câmera desligada: toque/soltura no mundo sem arraste | `Match.choose_respawn`, x via transformação inversa + câmera; painel excluído; decisão de elegibilidade fica no modelo |

Soltar o dedo proprietário do Slice fora do botão também dispara uma vez;
`canceled` e interrupções cancelam sem disparar. CAMERA fica desabilitado
durante Slice/Drag ativo e nenhum segundo dedo muda seu estado. Ao iniciar
carga, cancelar qualquer pan anterior; pan e carga não coexistem. Se CAMERA
estiver ligado, desabilitar início de carga/Drag até o usuário desligá-lo.
Slice permite pan no mundo quando não há carga. Em Drag, CAMERA é a forma
explícita de inspecionar sem atirar; não tentar deduzir intenção pela distância.
Em espera JEWEL, CAMERA permite pan e bloqueia retorno; fora desse modo só um
tap de até 12 dp de deslocamento escolhe retorno, uma vez na soltura.
Modo de câmera volta ao padrão no próximo turno/tiro/saída; nunca libera tiro
por encerrar o toggle. Cancelar um dedo (`canceled`), perder foco, suspender,
trocar tela, abrir modal, redimensionar ou perder turno cancela ownership,
carga/Drag e movimento sem chamar release que dispare. Soltar sobre HUD um
Drag já iniciado no mundo encerra aquele gesto uma vez, preservando a regra
atual; não aciona o botão sob o dedo. Uma nova carga exige novo press.

### D4 — Voltar, suspensão, áudio e persistência

Usar o sinal `Window.go_back_requested` e desativar quit automático por Back
somente no Android; não encaminhar uma suposta WMnotification ao filho.
A tag 4.7.2 pode produzir dois caminhos do mesmo Back: Activity imediato e
AndroidInputHandler/KEY_BACK diferido. Prova do AVD mostrou shop→lobby e outro
callback 160 ms depois no lobby; dedupe só por frame não bastou.
`PlatformLifecycle.accept_back(now)` aplica janela de 300 ms ao roteamento. Limite
explícito: um segundo Back intencional em menos de 300 ms também é ignorado.
Back e viewport passaram no fluxo AVD final; isso não declara aceite físico.
A documentação também prevê suspensão e morte de processo
sem callback final. [Ciclo de saída Godot](https://docs.godotengine.org/en/stable/tutorials/inputs/handling_quit_requests.html).

Ordem de Back: ocultar teclado/foco → cancelar modal/rascunho → sair da loja
para a origem/sala para lobby → na batalha abrir pausa → no lobby confirmar
saída. Resultado usa a mesma conclusão idempotente do OK. Loading deve ser
cancelável para a sala antes do start, descartando contexto resolvido; se já
entrou em partida, aplicar pausa. Não criar um segundo caminho de recompensa.

`platform_lifecycle.gd` mantém trava de suspensão independente do overlay.
`paused = overlay_aberto || suspenso || aguarda_retomada`. Nenhum `close_overlay`
pode remover a trava de suspensão. Paused/focus-out cancela input e pausa
loading/modelo/aplicação da CPU/apresentação. A busca pura já iniciada pode terminar
no snapshot privado; preservar task/search/plan e só aplicar após retomada explícita.
Reiniciar a busca no mesmo turno consumiria RNG novamente. Não acumular delta do tempo
em background. Retorno mostra continuação/pausa e exige toque em Retomar;
não simular soltura pendente. Pausa não reinicia o turno nem o RNG da partida.

Áudio para em background (BGM/SFX), preserva a solicitação da faixa da tela e
volumes; restaura de forma controlada após retomar, sem duplicar players.
Manter a faixa de batalha sob o resultado. Validar Home, bloqueio de tela,
perda de foco/áudio e retorno; nenhum compromisso de posição exata do MP3.

Perfil/opções persistem por ações e ao suspender usando transações existentes,
sem depender da saída limpa. Falha de gravação mantém rollback e informa erro.
Partida viva pode continuar se o processo existir; processo morto abre lobby
com perfil válido. Não recuperar terreno, turno, RNG ou recompensas pendentes
por um snapshot novo nesta v1. Sem permissão de storage externo, microfone,
câmera, localização ou rede no APK de distribuição. Testes usam sandbox dedicado,
nunca o perfil real de desktop ou um telefone pessoal sem isolamento.

## 5. APK, smoke e publicação

### D5 — Três níveis de evidência

1. **Harness da fonte:** modelos e cenas desktop, incluindo input sintético;
   não comprova Android.
2. **APK diagnóstico:** feature `android_ci`, package `.ci`, export debug com
   argumentos embutidos só nesse preset temporário (`command_line/extra_args`).
   Antes de criar Profile normal, validar versão e token hexadecimal de 32
   caracteres e derivar internamente
   `user://ci/gunbound-package-<token>/ci-profile.json`; não aceitar caminho
   externo vindo de argumento. Executar lobby/sala/loja, 48 tiros, 66 casos de
   mapa, JEWEL 22 lados e persistência isolada. Gerar relatório com token,
   versão e contagens; falhar em erro, timeout ou marcador antigo. O APK final
   rejeita esse modo no Android sem feature `android_ci`.
3. **APK de distribuição:** arquivo universal final, sem flags de smoke,
   `debuggable=false`, certificado persistente na main. Instalar os mesmos
   bytes/SHA no emulador x86_64 e testar lançamento normal, lobby/sala/loja,
   início de SOLO/JEWEL, toque real via adb, pausa/Home/Back e ausência de crash.
   Não alegar os 48 tiros internos como execução deste APK. Touch multitouch
   continua com testes sintéticos e aceite físico, pois `adb input` simples
   não reproduz dois dedos independentes.

Não assumir que `am start --es` injeta argumentos no APK final: a
`GodotActivity.sanitizeLaunchIntent` pinada remove parâmetros de Activities
exportadas. A separação acima evita adicionar bridge nativa ou deixar o app
final permanentemente em smoke. [Activity Godot 4.7.2](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/java/lib/src/main/java/org/godotengine/godot/GodotActivity.kt).

No emulador usar app/AVD descartável. O harness de UI não conhece `user://`
do aparelho: observa tela/logs e reinicia o app para conferir o apelido persistido;
não enfraquecer o release para permitir `run-as`. Desinstalação/limpeza só no
AVD dedicado. O harness exige serial`emulator-*`, qemu e nome de AVD permitido,
aguarda transporte ADB antes de consultar propriedades e não repete input
automaticamente após erro. `logs` mantém guard de processo vivo e coleta
logcat pelo UID do app desde o único clear pós-instalação, incluindo PIDs
anteriores de relaunch. Timeout/ANR/SCRIPT ERROR/GL error/textura acima do
limite falham, inclusive após marcador interno de PASS.

O exportador corrige `_cl_` do diagnóstico unsigned antes de alinhamento e
assinatura: a tag 4.7.2 acrescenta opções engine após `extra_args`; a normalização
valida prefixo versão/token e tail pinado, então move engine antes de`--`.
O parser Android continua estrito. Final/candidato não recebem esse ajuste CI.
Licenças runtime estão em `assets/licenses`. Previews Android usam22 recortes
HD 544×336 exatos e catálogo próprio, evitando a folha de 11968 px acima do limite GL;
o inspector exige catálogo,22 imports e remaps resolvidos, preservando a fonteHD.

UI adb usa alvos renderizados OCR/TSV, rejeita label ausente/ambígua e aguarda
IME/foco/layout. Dispensa apenas a assinatura específica do onboarding Android.
O relatório separa `actions_attempted` de resultados: pan ou hold de 3500 ms não
comprovam deslocamento/tiro. O smoke final de UI passou no AVD API36/ARM64;
o [relatório](../android-v1/ui-report.json) inclui a retomada explícita.

Inspeção estática verifica assinatura (`apksigner`), alinhamento, app ID,
`versionName/versionCode`, min/target, ABIs/ELF, permissões, ausência de debugger,
licenças, recursos e exclusões. Inspecionar inventário importado/PCK ou assets
reais do APK, não apenas procurar nomes `.png` (Godot remapeia recursos).
Licenças de `package_common.NOTICES` devem existir em assets empacotados e
ser acessíveis por uma entrada de licenças nas configurações, sem arte nova.
Reprodutibilidade aqui significa insumos e contrato verificáveis; igualdade
binária entre builds só pode ser afirmada após medir timestamps e assinatura.

### D6 — Jobs e segredos

O workflow `.github/workflows/desktop.yml` preserva nomes dos quatro checks e
main `queue:max/cancel-in-progress:false`. Job `android`, nome exibido
**Build and smoke Android candidate**, Ubuntu 24.04, `needs:[lint,version]`,
timeout de 120 min. Usa a mesma versão/SHA dos desktops, insumos verificados e
AVDs descartáveis API 36 e 24. Boot tem limite de 300 s; diagnóstico 900 s; UI tem
esperas por estado. As suítes fonte Android continuam no harness desktop.

PR/fork: diagnóstico debug e candidato release-template `.ci`, nome de teste,
sem secrets. Artifacts: `android-test-candidates-not-for-distribution` e
`android-evidence` (este em `always`). Main: a etapa protegida por push/main
**tenta** gerar o final com chave persistente, inspeciona e executa os mesmos
bytes, e só depois sobe `android-package` (APK/JSON/sidecar). Isso ainda não foi
executado na CI e não garante disponibilidade/correção de secrets ou QA.
Ausência/troca de chave/certificado falha; nenhum fallback debug publicável.

Secrets futuros: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`, `ANDROID_KEYSTORE_PASSWORD`; fingerprint público via
variável `ANDROID_CERT_SHA256`. Keystore existe só em runner temp, modo 0600, cleanup
por trap; apksigner recebe senhas por env. Não provisionados por esta entrega.
Builds usam `contents:read`; aceite/publisher usam `actions:read` para histórico;
só publisher tem `contents:write`. Actions estão por SHA completo e não há
`pull_request_target`. Não promover cache de PR a executável de assinatura sem
revalidar bytes. Artifacts têm retenção de 14 dias; evidência de aceite precisa ser durável.

`android-acceptance` e `release` exigem push/main **e**
`vars.ANDROID_PUBLICATION_ENABLED == 'true'`. A variável ausente mantém nova
publicação desativada. Habilitá-la, criar environment/reviewers/secrets e
alterar proteção são implantação externa com autorização própria; não ocorreram.

### D7 — ARM64 e gate de publicação

O APK único evita trocar bytes entre smoke x86 e distribuição, mas não executa
a biblioteca ARM64. **Gate operacional ainda pendente:** antes de tornar pública
uma release Android, um responsável baixa o artifact assinado da main e faz
aceite em aparelho ARM64, inclusive uma partida SOLO e uma JEWEL apenas com
toque, retorno e atualização preservando perfil. Registra SHA do APK/run/commit,
modelo/API/GPU, resultado de instalação, toque, lifecycle, áudio e atualização.

O código referencia environment `android-device-acceptance` com reviewer, após upload do APK
assinado e antes do publisher; a aprovação deve referenciar relatório de QA
com o SHA exato, guardado com as evidências da entrega. Não é teste automatizado
nem dispensa relatório. O manifesto do pacote permanece imutável com
`arm64_acceptance=manual_gate_required`. O aceite é um atestado **separado**:
comentário estruturado na aprovação contém run, commit, SHA do APK, versão,
aparelho/API/ABI, resultados de SOLO/JEWEL/touch/lifecycle/áudio/update e URL
da evidência. O job de aceite consulta o histórico de reviews do próprio run,
exige environment correto, estado aprovado e todos os campos consistentes,
e grava `android-acceptance.json` em artifact separado. Publisher confere o
atestado e sua origem antes de qualquer escrita; resumo com reviewer, SHA,
aparelho e link vai às notas públicas da release para registro durável.
Não recompor/reassinar APK ou alterar manifesto após QA. Consulta implementada:
`GET /repos/{owner}/{repo}/actions/runs/{run_id}/approvals`, com `actions:read`.
[Histórico de reviews de workflow](https://docs.github.com/en/rest/actions/workflow-runs#get-the-review-history-for-a-workflow-run).
O comentário inicia com `ANDROID_ACCEPTANCE_V1` seguido de JSON com
`run_id,commit,apk_sha256,version,device,api,abi="arm64-v8a",gpu,evidence_url`
e `results` contendo `install,solo,jewel,touch,lifecycle,audio,update="passed"`.
`validate_reviews` exige environment e reviewer da allowlist externa
`ANDROID_TRUSTED_REVIEWERS`; identidade vem da API, não do JSON. `fetch_acceptance`
confere run push/main/head SHA. CLI real:
`android_acceptance.py --manifest PATH --output PATH`, usando
`GITHUB_RUN_ID/GITHUB_REPOSITORY/GH_TOKEN/ANDROID_TRUSTED_REVIEWERS`.
O job grava artifact separado `android-acceptance`; publisher refaz a consulta à API
e exige igualdade com esse atestado antes de qualquer escrita.

Até existir esse mecanismo operacional, não habilitar
publicação Android: APK permanece artifact candidato. Confirmar disponibilidade
de environments/reviewers no repositório/plano e combinar o local durável do
relatório na implantação; se indisponível, manter a publicação bloqueada e
definir equivalente rastreável, sem declarar ARM64 aprovado.
[Revisão de deployments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments).

Não usar aparelho pessoal/self-hosted runner com secrets para executar PRs de
forks. Se houver laboratório ARM64 confiável futuramente, pode automatizar o
gate do artefato final, sem confundir arquitetura do host com ABI executada.
A fila inteira da main ficará aguardando esse aceite: custo operacional
explícito da proposta; não cancelar silenciosamente a fila para contorná-lo.

### D8 — Conjunto atômico e compatibilidade histórica

Release Android passa a exigir três pacotes: dois ZIPs desktop +
`Gunbound-Recomp-<versão>-Android.apk`, cada um com manifesto e sidecar SHA256
(nove entradas internas), mesma versão/commit. Manifesto Android schema 2
usa campos efetivos `schema:2, platform:"android", version, commit,
godot:"4.7.2", file, size, sha256, package_id, version_code, min_sdk, target_sdk,
abis, certificate_sha256`, mais metadados de inspeção. Estados são planos:
`smoke:"passed", diagnostic:"passed", final_x86_64:"passed",
arm64_acceptance:"manual_gate_required"`; não há objeto `smoke` aninhado nem
campo `signer_sha256`. Godot vem do pin e publisher exige esse mesmo valor.
Os relatórios separados identificam o APK efetivamente executado; finalização
exige SHA/versão/status e ABI x86_64 do smoke final. Não transformar a execução
ARM64 do AVD macOS em atestado físico nem em smoke x86_64.
Não converter `smoke=passed` em alegação de toque/aparelho sem prova.

`publish.py --version VERSION --sha COMMIT --acceptance PATH` usa run/allowlist
do ambiente, valida pacotes e atestado separado antes de reservar tag/criar draft; upload público
contém três pacotes + `SHA256SUMS`. Manifestos/relatórios ficam nos artifacts
e na evidência durável da release. Falta/falha Android bloqueia publicação do
conjunto; tentativa de upload incompleta fica draft. Retry conserva versão,
tag/commit e política de idempotência. O discriminador é o estado remoto:
somente release **já publicada**, com tag/commit verificados e layout histórico
reconhecido (dois ZIPs+SHA256SUMS ou seis arquivos antigos), pode seguir a saída
idempotente read-only. Para release inexistente ou draft, o novo publisher
exige sempre nove entradas e aceite Android; ausência de APK nunca seleciona
contrato antigo. Consultar estado é read-only; nenhuma tag/upload/alteração
ocorre antes da validação do conjunto novo. Não migrar releases publicadas.

Adicionar o novo check Android à proteção é implantação administrativa
separada: só após o job existir e passar no head, com autorização própria.
Os quatro checks atuais, strict/main atualizada, histórico linear, ausência de
bypass e rebase obrigatório permanecem. Nenhuma alteração administrativa faz
parte desta implementação local.

## 6. Critérios de saída e riscos

V1 só está aceita com download do APK da CI, instalação ARM64, partidas SOLO e
JEWEL por toque, resultado/OK/sala, atualização com mesma chave e perfil intacto,
sem controles presos/tiro ao retomar, e relatório do arquivo testado. O harness
completo de regressão desktop e os dois pacotes desktop devem continuar verdes.

| Risco | Verificação/resposta dentro do plano |
|---|---|
| HUD clássico pequeno no telefone | Matriz dp, seletores/alvos auxiliares e aceite físico T2/T9; redesign amplo continua #55 |
| Multitouch/emulação disputa disparo ou retorno | Ownership, cancelamento e testes de sequência T3; validação no runtime |
| Insets/loja acumulam escalas | Transformação única com inversa e ida/volta repetida T2/T4 |
| Perda do processo/perfil | Escrita transacional por ação, testes de atualização T4/T9; sem promessa de restore de partida |
| Renderer/texturas/CPU/RAM | Medir carregamento, maior mapa, 16 mobiles, luzes/aditivos, busca CPU e memória em ARM64; sem remover assets aprovados para esconder falha |
| Chave perdida/trocada | Backup seguro e fingerprint esperado; falhar T5/T8 e testar update antes da distribuição |
| Emulador verde, ARM falha | Gate físico do mesmo SHA T9; não publicar como validado sem ele |
| CI longa/cara e QA segura main | Timeouts e logs por etapa; medir duração, manter fila e limites do harness; prever operador para aceite |

Orçamento de desempenho proposto para aparelho de referência: frame time
p95 ≤ 33,3 ms durante 60 s de batalha representativa, sem ANR/crash e sem OOM
no maior mapa e visitas repetidas à loja. Registrar aquecimento, CPU planning,
RAM de pico, tamanho do APK e tempo de carga; estes valores ainda não foram
medidos. T9 confirma ou documenta ajuste fundamentado antes do aceite, sem
reduzir física, resolução de colisão, roster ou mapas silenciosamente.

## 7. Validação desta documentação

Reconciliação com as CLIs e workflow atuais: `.tools/android-v1/py313/bin/python`
reportou **Python 3.13.11**; `-m unittest discover -s tests -p 'test_ci_*.py' -v`
passou **93 testes em 4,649s**, exit0. Log:
`.tools/android-v1/ci-tests-py313-doc-reconcile.log`. Esse resultado valida
contratos de automação, não constitui PASS de UI final nem CI remota.

Leitura da base, comparação read-only do delta JEWEL, consulta a fontes
primárias acima, revisão independente e revisão de cobertura design→plano.
A revisão corrigiu referência a `settings_panel.gd`, explicitou Slice/CAMERA,
separou atestado ARM64 do manifesto e fixou o discriminador histórico.
Requisitos instáveis
devem ser reconferidos na execução: a página [exportação Android stable](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
recomenda JDK17 mas enumera ferramentas diferentes da tag pinada; não copiá-las
como lockfile do projeto. Spike/exportações/inspeções e diagnóstico local
ocorreram posteriormente. O fluxo UI final e diagnóstico passaram no AVDmacOS
API36/ARM64; limites em [validação local](../android-v1/local-validation.md).
Continuam pendentes CI remota,
assinatura/update persistentes e aparelho/input/áudio físicos/aceite humano.
Nenhum desses resultados é inferido dos testes desktop históricos.

## 8. Entrega local macOS — A8 (pedido posterior)

O usuário acrescentou Android rodando localmente no macOS como requisito de
entrega. `scripts/android_local.py` oferece prepare/build/boot/open/check
com guia em `docs/ANDROID.md`. Reusar SDK existente em modo leitura, JDK/templates
verificados em `.tools`, AVD/perfil/chave efêmeros e serial de emulador explícito.
Não executar a versão macOS como se validasse Android. Registrar comandos,
APK exato, API/ABI, capturas/logs e limites de execução no host macOS.
Emulador ARM64 não equivale a aparelho físico; gate D7 permanece separado.
