# Android v1 — plano técnico de implementação

> **Para execução por agentes:** quando houver autorização de implementação,
> usar `superpowers:executing-plans` ou, se escolhida delegação,
> `superpowers:subagent-driven-development`, tarefa por tarefa. Os checkboxes
> abaixo acompanham a execução. Pedido posterior autorizou implementação e
> verificações locais. No fechamento, commit/push e issues foram autorizados;
> PR e merge serão feitos pelo usuário. Secrets/administração/publicação manual
> continuam fora desta execução, com pendências na issue56.

**Objetivo:** produzir APK Android instalável pela CI, com treino offline 1×1
inteiramente operável por toque e atualização que preserve o perfil.

**Arquitetura:** Godot/GDScript e Compatibility existentes, com adaptadores
de layout, touch e lifecycle na apresentação. Match/CPU conservam as regras
e física comuns; exportação/validação Android estendem o contrato da CI e
publicação atômica desktop.

**Tecnologias:** Godot 4.7.2, GDScript, Python 3.13, GitHub Actions,
JDK17/SDK Android pinados, adb/emulador, APK com arm64-v8a e x86_64.

**Entrega local:** T1–T8 implementados; T9 regressões locais e T10/macOS
executados. CandidatoUI e diagnóstico reais passaram no AVD ARM64/API36.
Faixa final22suítes/3370checks,98CItests Python3.13.11 e2testes de pixels,
zero falhas. O agregado103partidas precede últimos ajustes de plataforma,
cobertos pela faixa dirigida. [Evidência por SHA](../android-v1/local-validation.md).
Os checklists abaixo conservam critérios detalhados; gates físicos/remotos,
assinatura persistente e update não foram encerrados pela implementação local.

**Fechamento após aceite do emulador:** agregado fresco1055,875s/103partidas/
140suítes Godot/92.765checks/228Python/56%, zero falhas;100testesCI.
[Relatório de fechamento](../android-v1/closing-regression.json). Main7d1e66d4
com JEWEL já integrado; PR/merge do usuário, gates da issue56 ainda abertos.

**Especificação:** [ANDROID_V1_DESIGN.md](ANDROID_V1_DESIGN.md), incluindo
REQ-ANDROID-V1.A1–A8 e decisões D1–D8. Ler ambos antes de executar.

## Restrições globais

- Recorte aprovado: interface clássica, paisagem, touch completo; não reabrir
  a escolha do HUD. Redesign/ergonomia avançada estão na [issue #55](https://github.com/guichafy/gunbound-recomp/issues/55), já criada.
- Preservar offline1×1, 16 mobiles, 22 lados, SOLO/JEWEL, avatares/loja,
  arte/áudio, perfil, idiomas, regras e separação Match decide/Game apresenta.
- Fonte atual 0.20.5, base/delta JEWEL descritos no design. Reconciliar a
  revisão JEWEL local antes de editar; não transportar código antigo sobre ela.
- Implementação, ferramentas e fechamento com commit/push/issues autorizados.
  PR/merge pertencem ao usuário; sem provisionamento de secrets/administração
  ou publicação manual. Bloqueios de distribuição registrados na issue56.
- Futuro runtime Android não pode usar perfil real de desktop nem smoke em
  perfil normal; preservar `.gd.uid`, imports e originais. Sem storage externo/rede novos.
- Contrato implementado no delta local: package `com.chafy.gunboundrecomp`, diagnóstico `.ci`, APK único
  arm64-v8a+x86_64, API mínima24/target36, Compatibility, sem Gradle customizado.
- `versionName` é a versão única; `versionCode = major*1_000_000 + minor*1_000 + patch`,
  componentes 0..999, código positivo ≤2.100.000.000. Não usar run number.
- Quatro checks atuais, main serializada `queue:max/cancel:false`, proteção
  sem bypass, release main-only e Actions por SHA completo permanecem.
- Substituir proposta técnica só com evidência registrada no design e
  revisão de impacto, sem ampliar escopo silenciosamente.

## Pontos de revisão que precisam de testes explícitos

1. Soltura fora do alvo, dedo cancelado, touch seguido de mouse emulado e
   dois dedos: um gesto não pode produzir dois tiros/itens/retornos (T3/T6/T9).
2. Suspensão com carga, overlay/resultado/loading ou CPU em busca: nenhuma
   retomada avança turno/recompensa ou dispara por soltura antiga (T4/T9).
3. Insets/densidade/teclado e ida/volta da loja: desenho, alvo e coordenada
   de respawn precisam coincidir em cada orientação paisagem (T2/T4/T9).
4. PR de fork, retry, chave ausente/trocada e APK adulterado: nunca usar
   assinatura de produção em PR nem publicar conjunto incompleto (T5/T7/T8).
5. Emulador x86 verde com ABI ARM quebrada, ou relatório de outro APK: não
   atribuir validação física ao SHA publicado sem aceite exato (T5/T8/T9).

## Mapa de arquivos e responsabilidades

Os arquivos de plataforma e tooling já existem no delta local. A tabela define
responsabilidades; checkboxes de aceite não equivalem à inexistência do código.
Resultados observados ficam no HANDOFF/ledger, sem inferir CI ou aceite físico.

| Arquivos | Responsabilidade proposta |
|---|---|
| `scripts/platform_layout.gd` (novo) | Safe rect, fit e transformação inversa, sem input/regras |
| `scripts/touch_controls.gd` (novo) | Apresentação dos alvos auxiliares/seletores e mapa compartilhado de regiões |
| `scripts/touch_input.gd` (novo) | Ownership/gestos e comandos sem executar física |
| `scripts/platform_lifecycle.gd` (novo) | Estado de suspensão/retomada/Back, independente de overlay |
| `scripts/game.gd` | Integra adaptadores a entrada, desenho, ações existentes e ciclo de vida |
| `scripts/aim_control.gd` | Extrai repetição de ângulo para direção lógica compartilhada |
| `scripts/{classic_chrome,avatar_shop,menu_screen,lobby_screen,settings_panel,match_overlay,sound}.gd` | Encaixe seguro, teclado, navegação, áudio/licenças; sem redesign |
| `project.godot`, `export_presets.cfg` | Overrides Android, preset final e configuração temporária de diagnóstico |
| `.github/ci-tools.json`, `scripts/ci/bootstrap.py`, `scripts/ci/android_tools.py` (novo) | Insumos pinados, templates por target e SDK isolado |
| `scripts/build_android.py` (novo), `scripts/ci/android_package.py` (novo) | Exportação e inspeção de APK, assinatura e manifesto |
| `scripts/ci/{smoke,android_smoke}.gd` (segundo novo) | Adaptador de sandbox do diagnóstico, núcleo dos smokes preservado |
| `scripts/ci/android_ui_smoke.py` (novo) | Instalar/lançar APK final no AVD e testar interface normal por adb |
| `scripts/ci/android_acceptance.py`, `tests/test_ci_android_acceptance.py` (novos) | Validar atestado humano do environment contra run/commit/SHA e histórico de reviews |
| `.github/workflows/desktop.yml`, `scripts/ci/{publish,package_common,release,check}.py`, `scripts/check.sh` | Jobs, artefatos, licenças, publicação e descoberta dos testes |
| `tests/test_android_*.gd`, `tests/test_ci_android*.py` (novos) | Contratos touch/layout/lifecycle, exportação, tooling e smoke Android |
| `tests/test_ci_{bootstrap,packages,publish,release,runner,workflow}.py` (existentes) | Regressões da automação e dos contratos históricos |
| `docs/sdd/{SPEC,DESIGN,DECISIONS,TASKS,HANDOFF,ANDROID_V1_DESIGN,ANDROID_V1_PLAN}.md` | Rastreabilidade, execução observada, limites e retomada |
| `docs/JOGAR.md`, `docs/DESENVOLVIMENTO.md`, `docs/VALIDACAO.md` | Instalação/sideload, assinatura/update, desenvolvimento e QA futuros |

Não extrair um framework de UI nem reescrever Game. Helpers devem ter
responsabilidade pequena; o restante da estrutura atual permanece.

## Ordem e gates

T1 fecha toolchain/template; T2 → T3 → T4 fecha experiência touch;
T1 → T5 → T6 fecha pacotes/smokes; T7 depende dessas duas trilhas;
T8 depende T7; T9 fecha validação e implantação. Tarefas podem ser revisadas
separadamente, mas Android só fica pronto com todas. Antes de iniciar código,
atualizar SPEC/DESIGN com contrato da implementação e registrar decisões ainda
propostas como validadas apenas após a prova pertinente. Commits/integração
remota exigem autorização própria e não são passos desta entrega.

### T1 — Fechar toolchain Android e seleção de templates

**Arquivos:** modificar `.github/ci-tools.json`, `scripts/ci/bootstrap.py`;
criar `scripts/ci/android_tools.py`, `tests/test_ci_android_tools.py`;
estender `tests/test_ci_bootstrap.py`; registrar prova no design.

**Interfaces implementadas (T1):**

- `prepare_godot(root: Path, templates: bool = True, target: str | None = None) -> Path`;
  `None` mantém comportamento por host, `android` seleciona APKs Android no Linux.
- `android_tools.prepare(root: Path, emulator: bool) -> dict[str, str]`,
  retorna `JAVA_HOME`, `ANDROID_SDK_ROOT`, `GODOT_TEMPLATES`, `ADB`, `APKSIGNER`, `ZIPALIGN`, `AAPT`;
  não reutilizar HOME do usuário como diretório temporário.
- CLI `bootstrap.py --target android` prepara editor/templates e fontes atuais;
  CLI `android_tools.py [--emulator]` prepara SDK/JDK sob `.tools`;
  `--boot-api 24|36` inicia AVD descartável. Settings são emitidos pelo exportador.

- [x] Escrever testes de template por target: Linux+Android seleciona
  `version.txt/android_debug.apk/android_release.apk`; Linux sem target mantém
  templates Linux; macOS/Windows inalterados; target desconhecido falha.
- [x] Acrescentar teste de checksum incorreto, extração traversal/symlink,
  pacote SDK/revisão divergente e cache parcial: falha antes de usar ferramenta.
  Rodar os testes novos e registrar RED por suporte Android ausente.
- [x] Em execução local autorizada, inspecionar o TPZ com hash já pinado e
  manifest dos APKs. Exportar um candidato mínimo do projeto sem mudar gameplay;
  conferir min 24/target 36/ABIs e export legacy sem Gradle. Esse spike é evidência
  técnica, não entrega ou aceite do jogo.
- [x] Fixar em `ci-tools.json` versão/URL/hash oficial de JDK17 com patch exato,
  command-line tools com revisão numérica, platform-tools, Build Tools 36.1.0,
  SDK36 e emulador/imagens AOSP x86_64 API36/API24. Usar repositório oficial
  Android/Adoptium e registrar metadados de pacotes; não baixar `latest` na CI.
  Se o template real divergir, corrigir D1 com prova antes do preset.
- [x] Implementar instalação isolada e seleção de templates mantendo
  `verify_digest/safe_extract`; validar saída `--version`/package metadata.
  Configurar caminhos SDK/JDK em editor settings temporários, fora do export.
  Não instalar NDK/CMake/plugins sem demonstrar que o export escolhido exige.
- [x] Rodar `python -m unittest discover -s tests -p 'test_ci_*bootstrap*.py' -v`
  e `python -m unittest discover -s tests -p 'test_ci_android_tools.py' -v`;
  esperado exit0, regressões existentes verdes. Gate: lockfile e candidato
  documentados, nenhuma promessa de compatibilidade física.

**Estado observado T1:** seleção por target, testes e lock implementados. TPZ e
APKs reais confirmam min 24/target 36/ABIs. JDK Linux e sete archives SDK foram
verificados/extraídos; seus bináriosLinux/AVDs ainda não foram executados neste
Mac. Export macOS usa SDK read-only/lock separado. Editor portátil exige
`--version` do pin 4.7.2.stable e não encerra o servidorADB ao sair. Detalhes D1.

### T2 — Safe area, escala e apresentação dos controles

**Arquivos:** criar `platform_layout.gd`, `touch_controls.gd`,
`tests/test_android_layout.gd`, `tests/capture_android_layout.gd` e UIDs;
modificar `game.gd`, `classic_chrome.gd`, `avatar_shop.gd`,
`battle_hud_layout.gd` somente se necessário para consumir layout por modo.

**Interfaces propostas:**

- `PlatformLayout.fit(window_size: Vector2, safe_window: Rect2, canvas_size: Vector2) -> Transform2D`;
  `to_canvas(window_point: Vector2, transform: Transform2D) -> Vector2`.
  APIs puras recebem retângulo já convertido de display para janela.
- `TouchControls.regions(safe_dp: Rect2, mode: String) -> Dictionary` retorna
  ação → Rect2 em dp; instância transforma para janela e expõe as mesmas
  regiões para desenho/hit test. `selection` carrega IDs de arma/slot reais.
- Game guarda transformação de apresentação e usa inversa antes de consultar
  `Layout.in_world(point, model.mode)` da revisão JEWEL e adicionar câmera.

- [ ] Criar testes de fit uniforme e round-trip: centro/bordas/world/placar
  mantêm erro ≤0,01px em 8:5/16:9/20:9/4:3; área zero não divide por zero;
  notch esquerdo/direito e barras de sistema ficam fora dos alvos.
- [ ] Testar 640×360 e800×360 dp: auxiliares ≥48×48dp, sem interseção entre
  alvos, sem encobrir placar JEWEL/força/OK. Testar seletores abertos/fechados
  e 16 entradas/armas/itens alcançáveis pelos respectivos menus/seletores.
  Executar e registrar RED antes de introduzir helper.
- [ ] Definir retângulos concretos dos clusters da proposta D2 no helper;
  desenho e hit test usam o mesmo retorno. Usar UI/fontes existentes e
  seletores temporários com indicação de câmera e estados disabled.
- [ ] Aplicar fit a todos os draws/efeitos/Game e UI, sem alterar terreno ou
  `CameraRig.VIEW_SIZE`. Ajustar loja para safe rect 800×600, sem escala dupla;
  testar entrar/sair dez vezes e restaurar `content_scale_*` exatamente.
- [ ] Rodar `python scripts/ci/check.py --suites test_android_layout test_battle_hud_layout test_hud test_shop_wide test_shop_original test_classic_maps_scene test_jewel_scene test_jewel_maps_scene`.
  Acrescentar `test_jewel_hud` quando reconciliada a revisão local. Esperado
  zero falhas/erros; capturar GPU real nos formatos acima com insets simulados,
  distinguindo simulação de safe area do aparelho.

### T3 — Touch completo e ownership dos gestos

**Arquivos:** criar `touch_input.gd`, `tests/test_android_touch.gd`;
modificar `game.gd`, `aim_control.gd`, `touch_controls.gd`; ampliar
`tests/test_aiming.gd`, `tests/test_items_scene.gd`, `tests/test_jewel_scene.gd`.

**Interfaces propostas:**

- `TouchInput.handle(event: InputEvent, context: Dictionary) -> bool` retorna
  consumido; `commands: Array[Dictionary]` guarda comandos por ordem;
  `drain_commands() -> Array[Dictionary]`, `cancel_all(reason: String) -> void`.
- Contexto contém `can_act`, `overlay`, `mode`, `waiting`, `drag_mode`,
  `camera_mode`, `regions`, `world_rect`, `blocked_rects`, `window_to_canvas`,
  `pixels_per_dp`; router não lê Match/terreno/RNG nem decide elegibilidade.
- Comandos fechados: `move(direction)`, `aim(direction)`, `flip`,
  `weapon(index)`, `item(slot)`, `pass`, `charge_begin/end/cancel`,
  `drag_begin(x)/update(x,relative_x)/end/cancel`, `pan(relative)`,
  `camera_toggle`, `respawn(canvas_position)`. End e cancel são distintos.
- `AimControl.update_direction(host, direction: int, delta: float) -> void`
  recebe −1/0/1 e contém a repetição atual; `update_keys` apenas converte teclas.
  Game aplica comandos com suas funções existentes/`ItemBar.press`.

- [ ] Escrever sequências sintéticas raw touch + mouse emulado: dedo0 carrega,
  dedo1 toca arma/item/câmera, soltura sobre HUD, cancelamento, inversão de
  ordem de solturas, índice reutilizado. Asserções: um tiro no máximo,
  cancelamento zero tiros, zero comandos presos, nenhum botão sob soltura dispara.
- [ ] Testar Slice aos2,99s/3s e soltura após100% (um disparo); Drag preserva
  mínimo/tremor/queda de força e só solta uma vez; direção de ângulo respeita
  limites por arma/apoio e repetição0,15→0,03s; direções opostas anulam.
  Slice solto fora do botão dispara uma vez; cancelamento zero. CAMERA não
  alterna durante carga/Drag, nem segundo dedo altera o estado; câmera ligada
  bloqueia carga. Começar carga cancela pan existente, sem pan simultâneo.
- [ ] Testar CAMERA ligado em Drag/esperaJEWEL: pan não atira nem escolhe retorno;
  câmera desligada, tapJEWEL ≤12dp chama `choose_respawn` uma vez; arraste
  maior/placar/HUD/modal/carga/pause não retorna. Não mudar a regra do modelo.
  Registrar RED dos testes novos antes do código.
- [ ] Implementar mapa dedo→dono, captura até soltura, consumo sem click-through,
  terminação em `_input` somente para gesto já capturado. Integrar prioridade
  GUI e hitboxes, emulação conforme D3 e restauração ao sair da batalha.
- [ ] Roteamento de itens conserva slot real, fila no turnoCPU, item2slots,
  compactação imediata e lock; toque não cria uso duplicado. Manter mouse real
  e teclado desktop, seletores auxiliares somente no modo touch Android.
- [ ] Rodar `python scripts/ci/check.py --suites test_android_touch test_aiming test_scene test_items_scene test_jewel_scene test_classic_maps_scene test_jewel_maps_scene`;
  zero falhas. Verificar raw touch/emulação no diagnóstico Android em T6;
  `adb input` de um dedo não substitui as sequências multitouch nem T9.

### T4 — Lifecycle, Back, teclado e perfil

**Arquivos:** criar `platform_lifecycle.gd`, `tests/test_android_lifecycle.gd`;
modificar `game.gd`, `sound.gd`, `match_overlay.gd`, `avatar_shop.gd`,
`menu_screen.gd`, `lobby_screen.gd`, `settings_panel.gd`, `project.godot`;
estender testes de perfil/resultado/música quando atingidos.

**Interfaces propostas:**

- `PlatformLifecycle.suspend(reason: String) -> void`, `resume() -> void`,
  `confirm_resume() -> void`, `is_blocked() -> bool`; `resume` mantém
  `awaiting_resume=true` e não libera comandos sozinho.
- Game centraliza `effective_paused() -> bool` e
  `cancel_platform_input(reason: String) -> void`; `_notification(what: int)`
  encaminha pausa/foco; Back chega por `Window.go_back_requested`. O veto de
  plataforma é independente de overlay.
- `Game.handle_back() -> void` segue D4. `Sound.set_suspended(value: bool) -> void`
  mantém music_request/volumes e suspende todos os players.

- [ ] Testar suspensão durante Slice/Drag/movimento, loading, voo, resultado,
  loja/modal e buscaCPU; fechar overlay suspenso não libera jogo; dois eventos
  pausa/foco-out são idempotentes; resume+soltura antiga não atira. Simular
  60s em background sem mudança de turno, terreno, RNG ou XP.
- [ ] Testar Back com teclado, rascunho, sala, loja com origem lobby/sala,
  loading antes/depois do start, batalha e resultado. Confirmar resultado usa
  OK idempotente; cancelar loading descarta seleção resolvida. Registrar RED.
- [x] Implementar veto antes de `_tick_loading` e antes de tick/animação/CPU;
  cancelar input e preservar task/search/plan puro em andamento sem ler estado vivo
  na thread nem sortear novamente; aplicar plano só depois de confirmação. Testar que nenhum
  plano antigo é aplicado no turno errado. Não fazer join bloqueante no callback.
- [ ] Validar Back via `Window.go_back_requested` e retomada explícita.
  Implementação atual usa `PlatformLifecycle.accept_back(now)` com janela de 300 ms para os
  callbacks Activity/imediato e KEY_BACK/diferido observados na tag 4.7.2;
  somente por frame não bastou. Back intencional dentro de 300 ms também é ignorado,
  limite declarado. Não usar suposta WMnotification ao filho. Teclado mantém campo
  focado visível sem redesenhar tela, IME submit e acentos respeitam clean/limit
  existentes. Foco em LineEdit bloqueia ações de batalha. Redimensionar pela
  IME cancela gestos e recalcula fit sem acumular transformações.
- [ ] Persistir ações/perfil/opções com caminhos atuais e rollback; testar
  falha de escrita, reload e resultado duplicado em diretório temporário.
  Simular morte/relaunch: retorna lobby, perfil consistente, sem restore de
  partida nem concessão/recompensa repetida. Licenças terão entrada acessível
  em settings, consumindo arquivos T5, sem texto técnico no fluxo normal.
- [ ] Rodar `python scripts/ci/check.py --suites test_android_lifecycle test_android_touch test_avatar_profile test_avatar_continuity test_result_screen test_music_screens test_match_loading test_lobby_settings test_performance`.
  Esperado zero falhas; Home/lock/IME/áudio reais ficam em T6/T9.

### T5 — Exportador, assinatura e inspeção do APK

**Arquivos implementados:** `scripts/build_android.py`, `scripts/ci/android_package.py`,
`tests/test_ci_android_package.py`, `export_presets.cfg`. Contratos existentes de
`package_common.py`, `release.py` e seus testes continuam compartilhados.

**Interfaces implementadas:**

- `android_package.version_code(version: str) -> int`; única fórmula Android,
  derivada da versão do projeto. `release.py` segue aplicando a versão comum.
- `GODOT=/path/editor python scripts/build_android.py --mode diagnostic|candidate|distribution --tools TOOLS.json --output APK [--token HEX32]`.
  Sem `--godot`/`--variant`. Diagnóstico/candidato usam `.ci`/nome `Gunbound Recomp Test`;
  somente diagnóstico tem feature `android_ci`. Final usa ID/nome públicos.
- Tools JSON: JAVA_HOME,ANDROID_SDK_ROOT,GODOT_TEMPLATES,ADB,APKSIGNER,ZIPALIGN,AAPT.
  Exportador cria espelho/preset/settings temporários, verifica editor 4.7.2.stable,
  exporta unsigned, normaliza args só diagnóstico, alinha 16 KiB e assina por apksigner.
- `inspect_apk(apk, tools, version, app_id, certificate=None, diagnostic=False)`
  verifica bytes reais. CLI `--finalize --mode distribution --output APK
  --diagnostic-report REPORT --ui-report REPORT --commit SHA` inspeciona de novo
  e cria manifesto/sidecar somente com relatório final do mesmo SHA/versão/x86_64.
- Secrets futuros: ANDROID_KEYSTORE_BASE64,ANDROID_KEY_ALIAS,ANDROID_KEY_PASSWORD,
  ANDROID_KEYSTORE_PASSWORD; variável pública ANDROID_CERT_SHA256. Workflow decodifica
  para runner temp, modo 0600, apksigner recebe senhas via env e cleanup usa trap.
  Main sem inputs válidos falha; sucesso de assinatura real ainda não observado.

- [x] Testar versão0.20.5→20005,0.21.0→21000,1.0.0→1000000, ordenação patch/minor/major,
  zeros iniciais inválidos, prerelease inválida, componente1000, código0 e
  overflow. Rodar RED antes da implementação.
- [ ] Criar fixtures de inspeção: ABI ausente/extra, ELF inválido, certificado
  inesperado, app ID/version/API divergentes, debuggable em release, arquivo
  adulterado, permissão proibida ou catálogo/licença faltante falham; fixtures
  não substituem `apksigner verify --verbose --print-certs` e inspeção real.
- [ ] Criar preset Android a partir do inventário dos filtros desktop;
  incluir JSON/binários/traduções/recursos remapeados e NOTICES em assets
  runtime de licenças. Preservar exclusões tests/docs privados/.tools/builds/
  override/export_credentials/.github/referências; checar APK/PCK efetivos.
- [ ] Implementar export APK com templates T1, orientação paisagem, ambas ABIs,
  API/template confirmado e ícone existente com fallback explicitamente
  verificado; não gerar arte. Sem permissão Internet/debug remoto no final.
- [ ] Assinar após alinhamento e verificar arquivo final; qualquer mudança
  posterior exige nova assinatura/inspeção/smoke. Logar fingerprint público,
  nunca keystore/secret; sem `set -x`, sem segredo na linha de comando persistida
  ou artifact. Chave ausente na release falha sem emitir APK debug publicável.
- [ ] Rodar `python -m unittest discover -s tests -p 'test_ci_android_package.py' -v`
  e suítes `test_ci_release.py/test_ci_packages.py`. Exportar e inspecionar
  candidato real em ambiente autorizado; guardar metadados observados e SHA.
  Gate: APK instalável ainda não equivale a teste de gameplay Android.

**Estado observado T5:** export/inspeção de candidatos reais e testes locais
implementados; APIs/ABIs/licenças/remaps/orientação foram conferidos. Legacy
mantém overrides Gradle vazios, Godot enum 4 exporta nativo 11/userLandscape.
Assinatura persistente/update/CI remota e matriz completa de adulterações
continuam gates separados; APK instalável não equivale a UI final aprovada.

### T6 — Smokes Android isolados e APK final no emulador

**Arquivos:** criar `scripts/ci/android_smoke.gd`,
`scripts/ci/android_ui_smoke.py`, `tests/test_android_smoke.gd`,
`tests/test_ci_android_ui_smoke.py`; modificar `game.gd:_ready`,
`scripts/ci/smoke.gd`; preservar `combat_smoke.gd/map_smoke.gd/jewel_smoke.gd`.

**Interfaces implementadas (host e diagnóstico):**

- `AndroidSmoke.prepare(target, arguments: PackedStringArray) -> bool`;
  exige Android+`android_ci`, versão exata e `--ci-run` hexadecimal32;
  calcula caminho fixo do design, injeta Profile/Options antes de startup normal.
- `AndroidSmoke.report` JSON com `schema:1, token, version, cases,
  failures, profile_isolated`; imprime marcador `ANDROID DIAGNOSTIC: PASS`
  apenas no fim. O host vincula esse relatório ao SHA do APK que instalou.
- CLI real `android_ui_smoke.py --serial SERIAL --adb PATH --apk APK
  --app-id ID --version VERSION --output DIR [--diagnostic --token HEX32]`.
  Não há `--package/--report/--diagnostic-apk`. Serial padrão `emulator-5554`;
  exige regex `emulator-*`, qemu e AVD permitido antes de modificar. Mac usa 5590.
  Relatório registra SHA/ABI/status/results/observations; API observada fica também
  no lançamento local/toolchain e na matriz de jobs, sem supor API do host.
- Diagnóstico usa nonce/contagens 48/66/22/UI 3, log por UID e drena erros após PASS.
  UI usa TSV renderizado, rejeita target ausente/ambíguo e erros GL/crash mesmo de
  PID anterior. `actions_attempted` não é prova de tiro/deslocamento; timer/hold
  pode ser não observado. Não há PASS integral de UI registrado nesta revisão.

- [ ] Escrever testes para rejeitar token inválido/duplicado, versão errada,
  feature ausente, argumento `--ci-profile` Android e path traversal. Sem
  request válida, perfil normal não é tocado nem substituído por fallback CI.
- [ ] Testar no host ausência de adb/AVD, timeout de boot, install/update
  rejeitado, PID/log antigo, SCRIPT ERROR/ANR/crash sem exitcode, marcador de
  token diferente e teste interrompido: todos falham; fixtures marcam RED.
- [ ] Implementar modo diagnóstico apenas em preset temporário com
  `command_line/extra_args` contendo separador `--`, smoke/versão/token.
  Conferir empacotamento/parsing na versão pinada em vez de assumir intent.
  Compartilhar casos internos sem liberar paths desktop no sandbox Android.
- [ ] Instalar diagnóstico no AVD e exigir contagens 48/66/22+lobby/sala/loja,
  perfil isolado e sucesso dos testes raw touch/emulação pertinentes; logs
  têm token único por execução. Coletar via logcat, sem depender de ler
  diretamente `user://` ou de exit code da Activity.
- [ ] Instalar o APK final/candidato após remover só o `.ci` no AVD dedicado;
  usar lançamento normal, adb tap/swipe e screenshots com timeouts por estado
  para lobby→sala→loja→sala→SOLO eJEWEL, tiro, câmera, Back/Home/retorno.
  Conferir apelido após force-stop/relaunch; nenhum teste interno é atribuído
  a esse arquivo. Capturas devem comprovar estado, não apenas processo vivo.
- [ ] Rodar testes unitários novos e `test_ci_smoke/test_ci_combat/test_jewel_package`
  pelo harness. Em AVD API36 rodar diagnóstico+final; API24 no mínimo instalar,
  abrir e começar partida com o final, além da inspeção minSdk. Gate registra
  exatamente qual ABI/API executou cada faixa; arquivo final é o mesmo SHA
  que seguirá para distribuição, sem reexportar depois do smoke.

### T7 — Integrar CI e artifacts sem enfraquecer desktop

**Arquivos:** `.github/workflows/desktop.yml`, `tests/test_ci_workflow.py`,
`tests/test_ci_runner.py`, `scripts/ci/check.py`, `scripts/check.sh`;
novos testes descobertos nas tarefas anteriores.

**Interfaces implementadas:** job `android`, nome **Build and smoke Android candidate**,
`needs:[lint,version]`, Ubuntu 24.04, timeout de 120 min. Artifacts:
`android-package` (apenas APK/manifesto/sidecar, main),
`android-test-candidates-not-for-distribution` (dois APKs de PR), `android-evidence`
(logs/relatórios/capturas/inspeções, always). Mesma versão/SHA de needs.version.
`android-acceptance` usa environment `android-device-acceptance` e artifact separado.
Release mantém nome existente e depende de version/desktop/android/android-acceptance.
Aceite/publicação exigem push/main e variável `ANDROID_PUBLICATION_ENABLED=true`;
ausente mantém nova publicação desligada. Nenhum secret/environment/proteção
foi provisionado e não há CI remota comprovada.

- [ ] Testar workflow PR/fork/main, needs/permissions, secrets só main,
  proteção por ref/evento, upload mesmo em erro, filtro de artifacts e inclusão
  de recursos/fixtures no checkout reduzido. Inventário novo de testes entra
  tanto no shell quanto no runner Python; não diminuir cobertura/timeout.
- [x] Testar os quatro nomes antigos e fila main imutáveis; nenhum cancelamento
  Android adicional foi configurado; a main mantém
  fila completa desde cálculo de versão até aceite/publicação.
- [ ] Implementar bootstrap+import+faixa Android+export/inspect+smokes; rodar
  source touch/layout/lifecycle no Linux sem repetir desnecessariamente as
  103 partidas ali, que continuam integrais nos dois jobs desktop existentes.
  Source Android suites também ficam no inventário normal desktop.
- [ ] PR sem secrets produz diagnóstico e candidato efêmeros, nome de teste;
  main tenta final assinado numa etapa limitada a push/main; secrets
  ausentes/inválidos impedem sucesso, sem fallback debug.
  Revalidar integridade dos insumos antes de uso no job de assinatura; cache
  de PR não é fonte confiável de executável/credencial. Fixar Actions por SHA.
- [ ] Timeouts implementados: job Android 120 min, boot AVD 5 min, diagnóstico 15 min,
  UI por estado 30/60 s e waits específicos; medir e registrar ajuste sem ignorar timeout. Logs/assets
  de qualidade sobem em `always`, artifacts de distribuição só após sucesso,
  retenção de 14 dias como desktop; SHA nos relatórios/manifestos; nenhum summary remoto observado.
- [x] Rodar `python -m unittest discover -s tests -p 'test_ci_*.py' -v`, lint
  de correção atual e actionlint com a mesma exceção estreita para queue.
  Futuramente validar em PR real/fork e main, após autorização remota; status
  local não comprova execução Actions. Não alterar proteção administrativa.

### T8 — Publicação atômica com APK e históricos preservados

**Arquivos:** `scripts/ci/publish.py`, `tests/test_ci_publish.py`,
criar `scripts/ci/android_acceptance.py`, `tests/test_ci_android_acceptance.py`,
`scripts/ci/android_package.py`, `.github/workflows/desktop.yml`;
planejar alteração futura separada em `.github/main-protection.json`.

**Interfaces implementadas:** `validate_assets(folder, version, sha)` exige nove
entradas para release nova/draft. Manifesto Android schema 2 contém
`version,commit,godot:"4.7.2",file,size,sha256,platform:"android",package_id,
version_code,min_sdk,target_sdk,abis,certificate_sha256`, metadadosinspeção e
camposplanos `smoke:"passed",diagnostic:"passed",final_x86_64:"passed",
arm64_acceptance:"manual_gate_required"`. Não há `signer_sha256` ou objeto smoke.
Godot deriva do config pinado e publisher exige o mesmo valor no Android.

Atestado separado: `android_acceptance.validate_reviews(reviews, manifest, run_id, trusted_reviewers)`
e `android_acceptance.fetch_acceptance(api, manifest, run_id, trusted_reviewers)`.
Comentário`ANDROID_ACCEPTANCE_V1`+JSON exige run_id/commit/apk_sha256/version,
device/api/abi=arm64-v8a/gpu/evidence_url e resultsinstall/solo/jewel/touch/
lifecycle/audio/update passed. Reviewer e environment vêm da API/allowlist,
não do comentário. CLI`android_acceptance.py --manifest PATH --output PATH`
usa GITHUB_RUN_ID/GITHUB_REPOSITORY/GH_TOKEN/ANDROID_TRUSTED_REVIEWERS.

`publish.py --version VERSION --sha SHA --acceptance PATH` usa run/allowlist
do ambiente e consulta reviews novamente antes de qualquer escrita. Atestado
fica fora do diretório das nove entradas. Publishedhistórico com tag/commit/layout
válidos é read-only; ausênciaAPK não seleciona legado para novo/draft.
Código e testesAPIoffline existem; ambiente/reviewer real, aceite ARM64,
assinatura persistente e publicação continuam externos e não executados.

- [ ] Escrever regressões para nove entradas válidas; falha por APK/manifesto/
  checksum ausentes, arquivo extra, digest/certificado/API/versão/SHA/ABI
  inconsistentes, diagnóstico no lugar do final, smoke final de outro hash.
  Asserção: nenhuma reserva de tag/chamada write ocorre antes da validação.
- [ ] Testar retry de draft após upload2de4 falhar, tag com outro commit,
  duplicata, conjunto incompleto e published release antiga com dois ZIPs+
  SHA256SUMS ou layout histórico de seis arquivos: não modificar published.
  Só release remotamente já publicada com tag/commit válidos e layout histórico
  reconhecido pode retornar pela saída read-only; novo/draft exige nove inputs,
  sem inferir contrato antigo por APK ausente. Chamadas GET podem preceder
  validação; nenhuma escrita/reserva de tag pode fazê-lo.
- [ ] Implementar seleção explícita de três pacotes (não glob só `.zip`),
  SHA256SUMS UTF8/LF e comparação dos quatro assets públicos antes de publicar.
  Atualizar notas com APK/install/update, assinatura e limites de QA; logs
  não afirmam que 48 tiros internos rodaram no arquivo final.
- [ ] Configurar dependências futuras: publisher precisa de version, desktop,
  android e job de aceite físico com environment após upload; só publisher
  recebe contents:write. Manter artifacts diagnósticos fora do diretório
  validado; actions download reúne só os dois desktops e Android distribution.
- [ ] Documentar gate humano: responsável associa relatórioARM64 ao SHA/run
  assinado antes de aprovar `android-device-acceptance`; aprovação do ambiente
  atesta revisão humana desse relatório, não execução automática. Ausência
  de mecanismo/operador mantém candidate sem publicação. O plano não supõe
  que metadata enviada por PR prove aceite físico.
  Implementar coleta/validação do comentário estruturado, testes de relatório
  de outro SHA/run, environment errado, JSON ausente, review rejeitado e
  campo de QA falho. Publisher valida origem e põe resumo/reviewer/SHA/link
  nas notas públicas, preservando evidência além da retenção de 14 dias do artifact.
  Reexportar após aceite invalida o atestado; não recompor manifesto depois.
- [ ] Rodar suítes `test_ci_publish.py`, `test_ci_workflow.py`,
  `test_ci_android_package.py` com API mock/falhas controladas. Nenhuma
  publicação real nesta validação local. Preparar lista administrativa T9;
  não aplicar arquivo de proteção nem criar ambientes agora.

### T9 — Regressão completa, aceite físico e implantação futura

**Arquivos:** documentos SDD e guias indicados; futuro relatório
`docs/android-v1/acceptance.md` com provas/run/sha e arquivos de QA necessários.
Alteração de GitHub/assinatura/required checks só na implantação autorizada.

**Interfaces:** relatório humano identifica `run_id, commit, apk_sha256,
version, version_code, signer_sha256, device, android_api, gpu, executed_abi`,
resultados e links duráveis para capturas/logs. Uma aprovação sem esse
vínculo não satisfaz A7. Não guardar identificadores pessoais do telefone.

- [ ] Após revisão do código integrado com JEWEL, rodar `python scripts/ci/check.py`
  completo (parse/modelos/cenas/Python/cobertura e inventário de partidas da
  base atual:29regressões+44mapas+30JEWEL). Confirmar zero erros/falhas e os
  quatro checks desktop existentes, sem repetir testes já verdes após
  mudanças só de texto que não afetam seu contrato.
- [ ] Em candidato CI, verificar controles auxiliares em640×360/800×360dp,
  ambas paisagens, notch/barras/IME/tablet. Capturar luzes/aditivos,16mobiles,
  mapas1600/1800/2000, SOLO/JEWEL, shop/loading/resultado; física/CPU não usa
  coordenada visual. Inspecionar sobreposição e clareza dos estados touch.
- [ ] Baixar artifact final assinado da main, conferir digest/certificado e
  instalar num aparelho ARM64 de teste; registrar ABI realmente executada.
  Concluir uma partida SOLO e uma JEWEL apenas com toque, incluindo ângulo,
  movimento/flip,3armas, item/lock/fila, ambos modos de mira, câmera no Drag,
  respawn, resultado e retorno à sala. Registrar qualquer cenário forçado
  separado da partida natural; teste automático48tiros cobre todo roster.
- [ ] Testar dois dedos, solte-fora/cancelamento, Home/lock/interrupção durante
  carga e CPU, Back/IME e retorno explícito; zero tiros acidentais/comandos
  presos/XP duplicado. Ouvir BGM/SFX por tela e retomada; medição física
  não pode ser inferida de captura muda ou teste sintético.
- [ ] Instalar versão anterior de QA com mesmo app ID/chave e schema atual
  em aparelho/AVD de teste; alterar apelido/equipamento/opções e obter XP;
  aplicar APK seguinte com `adb install -r` sem limpar dados. Comparar progresso
  e opções visíveis/relatório de teste. Primeira v1 exige dois candidatos
  assinados de versionCode crescente. PR debug não é predecessor da release.
- [ ] Medir orçamento do design (p95≤33,3ms/60s no aparelho de referência,
  sem OOM/ANR/crash), memória/carga/mapa maior/busca CPU, tamanho APK e ciclos
  loja/sala. Falha material corrige a v1; não remover roster/arte/regras.
- [ ] Registrar evidência ARM64 do mesmo SHA e revisar gate D7. Se relatório
  falhar/faltar ou APK mudar, não aprovar/publicar e repetir faixa atingida.
  Depois de sucesso, o responsável pode aprovar environment conforme a
  futura autorização de release; aprovação não entra no plano como já concedida.
- [ ] Separadamente, sob autorização administrativa futura: provisionar e
  fazer backup da chave, configurar secrets/ambiente restritos à main,
  reviewers/sem bypass e disponibilidade do gate; observar checkAndroid verde
  no head e acrescentá-lo aos quatro required checks existentes, sem remover
  nenhum. Confirmar política ativa e testar falha bloqueando merge/publicação.
- [ ] Atualizar SPEC/DESIGN/DECISIONS/TASKS/HANDOFF e guias com resultados
  observados, aparelhos suportados/testados, limitações, hashes e caminhos
  duráveis de evidência. Marcar implementação concluída só após critérios
  A1–A7, mantendo #55 como melhoria futura e pendências reais visíveis.

## Revisão documental e estado da entrega

Automação atual executada com Python 3.13.11:
`.tools/android-v1/py313/bin/python -m unittest discover -s tests -p 'test_ci_*.py' -v`
→ **93 testes, 4,649s, exit0**. Log em
`.tools/android-v1/ci-tests-py313-doc-reconcile.log`. Sem execução remota ou
PASS integral de UI atribuídos a esse agregado.

Este plano foi reconciliado com os símbolos e CLIs do delta local. As seções
T1/T5–T8 distinguem código/testes implementados de gates externos ainda pendentes;
os critérios UI/físicos não foram convertidos em PASS por existência de scripts.
Checks de links locais e whitespace verificam somente a documentação.
Os comandos acima descrevem verificações requeridas, não resultados presumidos.
Pedido posterior autorizou execução local após planejamento; progresso e resultados
efetivos ficam no HANDOFF e no ledger. Secrets, administração, integração remota e
aceite em aparelho pessoal continuam excluídos.

### T10 — Fluxo Android local no macOS (A8, autorização posterior)

**Arquivos:** criar `scripts/android_local.py`, `tests/test_ci_android_local.py`,
`docs/ANDROID.md`; manter estado isolado em `.tools/android-v1`.

- [x] RED: serial de telefone/porta inválida rejeitados, AVD sempre dentro worktree,
  SDK ausente não criado/mutado inadvertidamente.
- [x] Implementar prepare verificando JDK/templates oficiais e SDK existente read-only;
  build usa exportador comum, boot cria AVD descartável, open instala/abre apenas
  package CI no emulador explicitamente escolhido, check usa diagnóstico/UI smoke.
- [x] Executar prepare/build/boot/open/check no macOS disponível e registrar
  SHA/API/ABI/logs/capturas; nenhuma inferência de execução em aparelho físico.
- [x] Documentar instruções locais com pré-requisitos, comandos e limites; não
  depender exclusivamente de Linux/GitHub Actions ou do perfil real.
