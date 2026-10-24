# Revisão de qualidade e design — 0.18.6

Data: 2026-10-23. Análise feita na base 0.15.0 (branch
`claude/spec-code-quality-review-4c786a`); a execução foi reaplicada sobre a
`main` 0.18.5 na branch `claude/quality-review-0186`. As referências
`arquivo:linha` dos achados abaixo são da base 0.15.0 e servem de histórico.
REQ-12 (aprender lendo o código) com REQ-01, REQ-35 e REQ-43 afetados;
ADR-081. Primeiro a análise; o usuário pediu em seguida executar P1–P4 e abrir PR.
A seção «Plano de execução» no fim define escopo, portões e reduções de escopo.

Restrições que valem para qualquer refatoração aprovada:

- Mudança em combate exige `test_matches` com seeds 81–93 idênticas.
- `FlightSnapshot` deve acompanhar todo estado de voo que sair do `match.gd`.
- A CPU lê só o snapshot (thread); `battle_art` nunca escreve no modelo.
- Mover/renomear script preserva o `.gd.uid`; mudanças de input exigem testes de cena.

---

## P1 — Incoerências concretas e de baixo custo

| # | Achado | Evidência | Proposta | Custo / combate |
|---|---|---|---|---|
| 1.1 | Menu mostra versão errada | `scripts/game.gd:191` fixa `"0.14.5"`; `export_presets.cfg:21-22` diz `0.15.0`; `project.godot` não tem `application/config/version` | Fonte única: `application/config/version` no `project.godot`, lida pelo menu e pelo `build_macos.py` | Baixo / não |
| 1.2 | Nak sem aura UsingItem | `item_art.gd:35,56-57` só carrega `bigfoot`/`mage`; `draw_using` (`item_art.gd:193-197`) retorna em silêncio; `game.gd:749` chama para qualquer mobile | Decidir: fallback genérico (sem HD) ou registrar no descritor do mobile (ver 2.1) | Baixo / não |
| 1.3 | Testes validam um integrador que a produção não usa | `Combat.predict` (`combat.gd:127`) só é usado em `tests/test_refinement.gd:44`, `tests/test_map.gd:115`, `tests/capture_map.gd:45`; ignora clima, tornado, burrow, ghost, itens e salvas | Migrar para `model.predict_shot` e remover `Combat.predict` (invariante "previsão = disparo real") | Baixo-médio / só testes |
| 1.4 | Teste instável | HANDOFF 0.15: `test_items_scene` falha ~1 em 5–6 com seed aleatória | Fixar seed (ou injetar RNG) na suite | Baixo / não |
| 1.5 | Índices mágicos de atributos | `Attributes.points(actor, 0..7)` em `match.gd:147,178,237,480,737`, `damage.gd:39`, `mobiles.gd:115`; `values[1]` em `match.gd:90` | `enum Attribute { ATTACK, HEALTH, DEFENSE, REGEN, DELAY, ITEM_DELAY, DIG, POPULARITY }` em `player_attributes.gd` (conferir ordem do C#) | Baixo / sim (sem mudar valor) |
| 1.6 | Conversão de delay espalhada e com ida-e-volta | `/ 7.5` em `mobiles.gd:17,28-30`, `bigfoot_attacks.gd:7-9`, `player_attributes.gd:31`; `match.gd:239` faz `delay * 7.5` para depois dividir de novo; só `items.gd:11` tem `DELAY_SCALE` | Catálogo guarda o delay original (unidade C#) e uma única função converte; constante compartilhada | Baixo-médio / sim (arredondamento: conferir seeds) |
| 1.7 | Literais repetidos | voo máximo `12.0` (`match.gd:319,464`); margem `24.0` (`match.gd:211,508,634`); força `15/100` (`match.gd:353,703`); vida baixa `0.3` (`battle_art.gd:109,161,162`); epsilon `0.0000001` (`match.gd:405,412,416`); turno `30.0`, passe `80.0` (`turn_table.gd:24`) | Constantes nomeadas no dono da regra (`Combat`, `Match`, `TurnTable`) | Baixo / sim (sem mudar valor) |
| 1.8 | Código morto | `BattleArt.draw_explosion` (`battle_art.gd:166`), `ui.metal_panel`, wrapper `game.make_overlay` (`game.gd:671`), alias `Match.MAGE_WEAPONS` (`match.gd:28`), parâmetro `_scale_amount` (`game.gd:917`) — sem uso em scripts/tests/scenes | Remover | Baixo / não |
| 1.9 | API usada só por testes | `game.displayed_queue`, `game.actor_frame` | Manter, mas marcar como API de teste (comentário) ou mover acesso para helper de teste | Baixo / não |

## P2 — OCP e DRY estrutural

### 2.1 Adicionar um mobile exige editar 4–5 arquivos (OCP)

`mobiles.gd` resolveu o combate ("sem ramo por ID"), mas a apresentação ainda
ramifica por string/ID:

- `mobile_rig.gd:23-141`: `HD_KINDS`, assento, corpo, canhão, hull `49/46`,
  linha da folha e **duração de morte `1.6/1.15` duplicando `Mobiles.death`** (`:77`).
- `projectile_art.gd:10-33`: `kind in ["bigfoot","mage"]`, linha por kind.
- `item_art.gd:35`: `USING_CELL` duplica `CELL` de `bigfoot_sprite.gd:6` e o
  tamanho de `mage_sprite.gd:31`.
- `game.gd:15-17,151-153`: preloads e `sprites[1]=mage...` fixos.
- `mobiles.gd:103-105`: `emission` escolhe a salva do Bigfoot pelo flag
  `spread_after_clamp` (flag com dois significados).

Proposta: **descritor de apresentação por mobile** (dados: layout do rig, linha
HD, célula UsingItem, script de sprite) + **registro/fábrica** de sprites lido do
catálogo; `emission` vira campo próprio do catálogo (`"emission": "bigfoot_salvo"`
ou tabela). Custo médio; não toca combate se `emission` mantiver o resultado.

### 2.2 Sprites repetem a mesma montagem (Template Method)

`bigfoot_sprite.gd:35-48`, `mage_sprite.gd:30-46`, `nak_sprite.gd:44-55`
repetem: sons `Shoot/Blast{S1,S2,SS}`, `effects[]`, `effect_capacity`,
`effect_sizes`, `ProjectileArt.new()`, `HDSheet.new("effects.png")`.
`mobile_sprite.gd:28-29` carrega `RiderBody/RiderHead` da pasta do **Bigfoot**
para todos. Proposta: `MobileSprite` com ganchos (`folder()`, `effect_cell(w)`,
`draw_projectile`) e carregamento comum. Custo baixo-médio; só apresentação.

### 2.3 `MobileSprite.draw` com 13 parâmetros posicionais

`mobile_sprite.gd:60`, sobrescrito em `nak_sprite.gd:70`, chamado em
`battle_art.gd:161` e `game.gd:921`. Proposta: **Parameter Object**
(`DrawRequest`/`PoseContext`). Custo baixo; só apresentação.

### 2.4 Efeitos de item em cadeias de `if`/`match`

`items.gd:74-79` (`attack`/`dig` por if), `match.gd:180-196` (`use_item`),
`match.gd:274-299` (`shot_shells`). Proposta: valores (`attack`, `dig`,
`heal_percent`) como **dados** em `Items.DEFINITIONS`; efeitos instantâneos/de
tiro como **Strategy** registrada por id. Custo médio; toca combate (seeds).

### 2.5 Persistência JSON duplicada

`options.gd:29-61` e `profile.gd:29-93` repetem leitura/parse e gravação
`.tmp` + `rename`; `options.gd:39-48` repete `is float or is int` + clamp.
Proposta: `JsonStore` (`read_dict`, `write_atomic`) e helpers `read_int(data,
key, min, max)`. Custo baixo; não toca combate (testes de perfil cobrem).

### 2.6 Lógica de ordem de turno em três lugares

Desempate "menor `ready`, empate favorece o outro" em `turn_table.gd:15-16`,
`turn_table.gd:33` e reimplementado em `game.gd:612-617` (`current_order`).
Proposta: `TurnTable.order(ready_by_actor, active)` única. Custo baixo; toca a
fila do HUD (testes de cena/refinamento).

### 2.7 Duplicações menores no modelo e na arte

- Thor/Electricity + ouro repetidos em `explode` e `land_beacon` (`match.gd:485-489` e `499-503`) → `run_explode_actions`.
- "Morte por queda" (`hp=0` + evento `fall`) em `match.gd:219-222,512-514,652-654` → `kill_by_fall(index)`.
- Máximo de `spawn_at` calculado em `match.gd:276-278` e `316-318` → helper.
- `battle_art.react` repete `pose=…; pose_age=0` em cada ramo (`:18-49`) → `set_pose`.
- Arma exibida calculada em `battle_art.gd:98-103` e de novo em `:156-158`.
- Expressão "CPU carregando" repetida em `game.gd:365,449,507` → método.
- Tempos de pose duplicados entre `battle_art` e `mobile_rig` (recuo `1.16`, UsingItem `20/19`, hurt `1.05`).

### 2.8 Harness de testes

35 suites redefinem `check/checks/failures` (ex.: `tests/test_nak.gd:10`,
`tests/test_items.gd:8`); 40 montam perfil isolado à mão. Em
`scripts/check.sh:13-14`, `ALL` e `QUICK` são listas manuais quase iguais.
Proposta: base `tests/support/suite.gd` (check, perfil isolado, resumo) e
`QUICK = ALL − test_matches` (ou glob `tests/test_*.gd`). Custo baixo.

## P3 — Responsabilidade única (maior valor, maior risco)

### 3.1 `match.gd` (740 linhas) ainda concentra muitos motivos de mudança

Turno/voo (núcleo) + interação com clima (`weather_interact`, `tornado_step`,
`apply_weather_contact`), Thor/raio, itens, ouro (`collect_gold_damage`,
`finish_gold_shot`), planejamento da CPU (`begin/search/finish_cpu_plan`).
Proposta, sempre atrás da fachada do Match (como `Damage`/`TurnTable`):

- `WeatherInteraction` com **Strategy** por tipo de coluna (`match.gd:567-590`).
- `GoldTracker` (estado `shot_gold` + coleta + fechamento).
- `CpuPlanner` (busca estática já existe; erros por dificuldade em tabela).
- Estado de fase como `enum` em vez de strings `"aim"/"flight"/"settle"/"finished"`.

Risco: alto (combate, previsão, thread). Exige seeds 81–93 e testes de performance.

### 3.2 `game.gd` (921 linhas): extração cosmética e acoplamento invertido

- ~15 propriedades proxy (`game.gd:59-122`: `angle`, `power`, `weapon`,
  `charging`, `camera`…) — **Middle Man**, mantido por compatibilidade com testes.
- `match_overlay.gd`, `item_bar.gd`, `aim_control.gd` recebem `host` sem tipo e
  escrevem `host.overlay`, `host.paused`, `host.root`, `host.options_popup`
  (`match_overlay.gd:6-42`) e leem `host.model.actors` (`item_bar.gd:35,64,127`)
  — **Feature Envy / Inappropriate Intimacy**: o estado continua no `game.gd`.
- Mesmo arquivo monta o menu (`show_menu`, 70 linhas), HUD, input, CPU em
  thread, eventos, recompensa e o desenho de todas as camadas.
- `screen`/`overlay_kind` são strings; `for index in range(3)`/`% 3` ignoram
  `Mobiles.weapon_count` (`game.gd:335,383`).

Proposta: componentes donos do próprio estado com **sinais** (Observer) e
interfaces estreitas; extrair `MenuScreen`, `CpuTurnController` (task/espera/
disparo) e um `WorldRenderer` com camadas. Risco médio-alto (input/cena).

### 3.3 Dicionários sem tipo para atores, projéteis e eventos (Primitive Obsession)

Ator com ~16 chaves (`match.gd:91-92`), projétil com ~25 (`match.gd:261-266`),
eventos identificados por string. Sinais: `int(actor.hp)` e
`.get("turn_item", "")` sobre chaves que sempre existem; erro de digitação só
aparece em runtime. Proposta: classes `Actor`/`Shell` (`RefCounted` com
campos tipados e `copy()` explícito) e constantes de tipo de evento.
Atenção: afeta `FlightSnapshot` (`duplicate(true)`), a thread da CPU e quase
todos os testes. Risco alto; fazer por último e em etapas.

## P4 — Documentação SDD desatualizada

- `SPEC.md:1` ainda diz 0.7.0; a tabela de requisitos cobre só REQ-01..12 e
  descreve Escaravelho/armas genéricas/arena 1280×800 como "regras concretas".
- `DESIGN.md:3` diz "Estado vigente: 0.12".
- `AGENTS.md` (seção SOLID) cita "catálogo IDs 1 e 2"; há textos sem espaço
  ("com4 bombas").
- `HANDOFF.md` tem 1333 linhas, histórico misturado ao estado atual.

Proposta: índice vivo REQ-01..43 (status, documento, substituído por) no topo da
SPEC; mover histórico para seção/arquivo de arquivo. Custo baixo; não toca código.

## Pendências de especificação ainda não implementadas

| Pendência | Origem | Observação |
|---|---|---|
| Arte HD do Nak | REQ-43, TASKS | Adiada pelo usuário; rig/projéteis/miras/aura só Bigfoot/Mage |
| CPU usar itens | REQ-35, TASKS | Exige rebaselinar seeds 81–93 |
| Mouse Speed | REQ-34, `aim_control.gd:6`, `options_popup.gd:37` | Escalar `DRAG_FULL_POWER`; slider desabilitado |
| Team Teleport sem efeito real | ITEMS_0_13.md:43 | 1×1 sem aliado: só chamas/som, mas cobra delay |
| CPU não se move | Limite conhecido | IA estacionária desde o baseline |
| Builds Windows/Linux/Android/iOS | REQ-01 | Só macOS testado |
| Pico no primeiro frame da partida | PERF_LIMITS_0_11 | Fora do escopo 0.11 |
| App 0.15.0 não reexportado | HANDOFF 0.15 | Aguarda pedido |
| Outros mobiles | REQ-19 | Aguardam nova solicitação (2.1 reduz o custo) |
| Preço em ouro de itens | TASKS 0.13 | Fora do treino |

Validações manuais pendentes do usuário (várias versões) não são dívida de código.
Multiplayer, 2×2/N atores e mobile seguem só como roadmap; vários pontos acima
(`TurnTable.other = 1 − index`, `PLAYER/CPU` fixos, `shot_gold.dead` com dois
índices) teriam de mudar nessa etapa, sem ação agora.

---

## Plano de execução (pedido: executar P1–P4 e abrir PR)

Versão alvo **0.18.6** (refatoração; única mudança visível é o rótulo do menu).
Um commit por item ou grupo pequeno, para isolar regressões.

### Oráculos e portões

- **Golden master local** (`.tools/golden/`, fora do Git): 26 partidas CPU×CPU
  (seeds 81–93 × clima original sem itens / clima "todos" com as três cargas
  que cobrem os 11 itens e atributos), hash MD5 de todos os eventos e de uma
  projeção explícita dos campos do ator. Determinístico em duas execuções.
  Commits que tocam o modelo exigem hashes idênticos.
- `check.sh --quick` a cada commit; contagem por suíte igual à baseline
  (na `main` 0.18.5: 5313 checks + 13 partidas), salvo checks novos documentados.
- Parse de todos os `tests/*.gd`, incluindo `capture_*` fora do harness.
- Commits de apresentação: suítes de cena e capturas GPU comparadas (imagens
  regeneradas não entram no PR).

### Reduções de escopo (motivo registrado)

- **3.3 — classes tipadas `Actor`/`Shell`: adiado.** `duplicate(true)` não copia
  Objects (o snapshot da CPU passaria a compartilhar atores vivos com a thread
  do worker e `predict_shot` alteraria o HP real); `Object.get(k, default)` não
  existe; ~40 suítes montam fixtures como Dictionary. Entregue a versão segura:
  fábricas únicas (`actor_state.gd`, `shell_state.gd`) com o formato e as chaves
  em um só lugar; `FlightSnapshot` inalterado.
- **Fases:** constantes string (`Match.PHASE_AIM := "aim"`…), não enum, para não
  quebrar testes nem eventos.
- **1.2 — aura do Nak:** o estado `item` do `tank3.epa` é só um salto do corpo
  (quadros 203–222 conferidos); não há folha UsingItem do Nak no fork. O
  descritor declara "sem aura" explicitamente; arte nova continua com o HD
  adiado pelo usuário.
- **1.4 — teste instável:** causa reproduzida na seed 28 (spawns próximos, o
  primeiro Dual vence antes do turno da CPU); suposição do teste, não bug. A
  cena ganha `match_seed` e a suíte fixa a seed.
- App não reexportado; nada em `builds/` nem novas imagens em `docs/`.

### Resultado

Reaplicado sobre a `main` 0.18.5 (regras de batalha ADR-076/077, loja XFS)
em commits pequenos, um por item ou grupo. Adaptações ao que a `main` mudou:
custos de delay do Nak 770/920/1320 e dos itens do `itemdata.dat` entram como
`cost`; `TurnTable.DELAY_SCALE` usa `DelayUnits.SCALE`; `TurnTable.order` passa
a ser a regra única também de `current_order`/`shot_cost`; `CpuPlanner` leva o
refino da busca e o congelamento do relógio (`cpu_thinking`); `ItemEffects`
usa `posmod` no Change Wind; suítes e capturas novas da `main` migradas para a
base de suítes e para o `SpritePose`. Um `SCRIPT ERROR` deixava o Godot
headless aberto e travava o `check.sh` por horas: cada suíte agora tem
`SUITE_TIMEOUT`.

Portões finais: parse de todos os scripts e capturas; 5318 checks (5313 da
`main` + 1 de versão + 4 do catálogo de apresentação) e 13 partidas com seeds
81–93 idênticas à `main`; golden de 26 partidas idêntico ao gravado na `main`
0.18.5; quadro de partida com seed fixa e folha de sprites dos três mobiles
pixel-idênticos à `main`. `match.gd` 783 → 609 linhas; `game.gd` 921 → 801.
O extra «WorldRenderer» virou Extract Method (`draw_projectiles`,
`draw_floating`); as builders de `MatchOverlay` ainda recebem a cena, só para
ler dados e chamar ações.

