# Grub (ID 13, type 12) — porte pelo cliente — REQ-51 / ADR-150

Issue #8 (28/10/2026). Escopo: arte, animação, defesa, ataques e demais características do
Grub no treino 1×1, pelo cliente Thor's Hammer. Fora: os outros 15 mobiles, rede, HD novo,
OpenBound/Season 2. Cliente Windows **não** foi executado: a prova é análise estática com
Ghidra e **execução das rotinas do PE num emulador x86** (`tests/tools/grub_oracle`). Isso
não é execução do jogo.

## Fontes e identidade

| Item | Valor |
|---|---|
| `GunBound.gme` (`.tools/mobile-animation-port/`) | SHA-256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`, base `0x400000`, x86 LE 32, VA |
| `graphics.xfs` | `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08` |
| `sound.xfs` | `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023` |
| `characterdata.dat` | `b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf`, linha type 12 (83 células) |
| Ghidra | 12.2 headless direto, JDK 25 (`/opt/homebrew/opt/openjdk@25`), runner `skills/gunbound-client-port/scripts/run_ghidra.py` |
| Emulador | Unicorn 2.1.4 (venv fora do repositório), ver `tests/tools/grub_oracle/README.md` |

Comando da primeira leva (a do issue) e das seguintes, projeto `builds/ghidra-work/grub`:

```sh
python3 skills/gunbound-client-port/scripts/run_ghidra.py --ghidra-dir /opt/homebrew/Cellar/ghidra/12.2/libexec \
  --java-home /opt/homebrew/opt/openjdk@25 --binary .tools/mobile-animation-port/GunBound.gme \
  --work-dir /Users/guichafy/Workspaces/DemoGame/builds/ghidra-work/grub --output .tools/battle-re/grub-evidence-N \
  [--seed-known-entries] --functions <VA…> [--data 0x0055649c:64 0x0055620c:64]
```

| Execução | Saída | Funções | `ok` |
|---|---|---|---|
| 1 (comando do issue) | `grub-evidence` | 8 | **false**: `0x488780` (Animate do SS) é alvo de vtable, não reconhecido como função |
| 2 (`--seed-known-entries`; prólogo `51 53 55 56 8b f1` confirmado nos bytes e em `0x556214`) | `grub-evidence-2` | 20 | **true** |
| 3 helpers das células protegidas, rastro/CRT | `grub-evidence-3-helpers` | 51 | true |
| 4 varredores de terreno, `0x4a1740`, `0x4585e0`, explosão | `grub-evidence-4-ricochet` | 26 | true |
| 5 `CreateMobile` `0x41c360` | `grub-evidence-5-body` | 2 | true |
| 6 consumidores de `[33]/[34]` (`0x45d150`, `0x45d360`, `0x458b80`) | `grub-evidence-6-fields` | 3 | true |

Manifestos e `run.json` versionados em `docs/sdd/grub-evidence/`; `.asm/.c` ficam em
`.tools/battle-re/` (locais). Logs `console/analysis/scripts` sem erro.

## Células protegidas (ABI, comprovada por ASM e por execução)

`EnterCriticalSection` + `0x40a2e0` (EAX=célula → valor), `0x40a380` (EDI=célula, valor na pilha),
`0x40a4d0` (leitura travada), `0x40a470`/`0x40a4a0` (gravar/copiar), `0x40a5f0` (célula+imm),
`0x40a6e0` (célula−imm), `0x40aba0` (c+c), `0x40aca0` (c−c), `0x40b180` (SAR), `0x40b090` (SHL),
`0x40aab0` (célula += imm), `0x40b270`(==), `0x40b2a0`(≠), `0x40b2d0`(>), `0x40b300`(≥), `0x40b330`(<).
Constantes de WinMain (`PUSH imm; MOV EDI,célula; CALL 0x40a380`): `0xe9ba40=10`, `0x7a78b8=98`,
`0xe55ab8=20`, `0x796aa0=100`, `0x794e48=80` etc. (varredura em `tests/tools/grub_oracle/consts.py`).

## Matriz de evidência

Confiança: **E** = observado ao executar a rotina do PE no emulador; **D** = derivado de estática;
**I** = inferido. Decisão: Comprovado / Derivado / Adaptação / Pendente.

| # | Comportamento | Origem / VA | Contrato | Conf. | Decisão | Esperado independente e validação | Limite |
|---|---|---|---|---|---|---|---|
| 1 | Emissão T1 | `MainAction 0x471fd0`, evento 5, quadro 2 (`0x472066`) | 1 corpo, `Projectile`, θ+2 nativo (esq.: HUD −2), força P | E | Comprovado | `grub_emission_native.json` (96 linhas, MainAction rodando) ↔ `test_grub_model` (velocidades em ponto fixo) | Posição da boca: `muzzle()` genérico (offsets de EPA `0x53fc/0x5620/0x5844/0x5a68` não portados) |
| 2 | Emissão T2 | idem evento 6, quadro 2; ramo `θ>90` por `0x40b2d0(θ,90)` | **4** corpos no mesmo quadro: θ +1/0/−1/−2 (HUD; espelhado à esquerda), força nativa +5/0/−5/−10, sem clamp | E | Comprovado | idem; 8 colchetes `0x472367…0x473021` = 2 ramos × 4, só um ramo roda por disparo | índice Dual (0/8) não usado pelo Godot |
| 3 | Emissão SS | `0x471fd0` evento 10 → spawner `0x42de70` | 1 corpo, θ+2, força P | E | Comprovado | idem | idem |
| 4 | Velocidade de lançamento | spawner `0x42bbb0`: `((int(sen[(θ+90)%360]·P))<<8)/10`, `y=−…` | = `Physics.launch_velocity_fp` | E | Comprovado | cells reais `(5401,−5606)` para θ46/P305 | — |
| 5 | Varredura T2 | `Simulate 0x49e650` | passo 8 no eixo dominante, 1ª amostra a +1, `n+8` amostras, refino de 1 px (`0x458920` x-maior / `0x458a00` y-maior) em `[n−8,n)`, clima antes do terreno, terreno antes de mobile, mobile = `0x450e10→0x45d640` (AABB inclusivo), fora do mapa vira contato no limite (x∈[0,W−1], y∈[−0x113,H−1]) | E | Comprovado | `grub_flight_native.json`: 160 voos reais, 7.7k ticks | as fixtures rodaram sem colunas: `0x4510f0/0x451030/0x4511b0` são os amostradores de clima (linha 22), não objetos inexistentes |
| 6 | Varredura SS | `Simulate 0x4857f0` | igual, **sem** `0x450e10`: atravessa mobiles | E | Comprovado | idem (80 voos SS) | — |
| 7 | Máquina do tick | `0x49fd40` (T2) / `0x486ea0` (SS) | `x+=vx; y+=vy` → varredura → se contato **ou** `ctr==limite`: se `ctr≥limite` (ou mobile, T2) **detona**, senão **ricocheteia**; sem contato: sincroniza pixel; `v+=a` (exceto detonação); fora do mapa `x<0∨x>W∨y>H∨y<−1000` remove sem explosão | E | Comprovado | idem; contador −1 até o 1º ricochete, +1 por quadro (`Animate`); limite **44** (T2, literal `0x2c`) e **40** (SS, `2×[0xe55ab8]`) | `ctr==limite` sem contato detona na última posição sincronizada (observado) |
| 8 | Ricochete: encaixe | `0x49fd40` `0x49fe42…0x4a0259` | pixel de contato puxado até a face livre com `0x4e43d0/0x4e4410` (x±8) e `0x4e4340/0x4e4390` (y±8); `x_fp=x<<8`, `y_fp=y<<8` | E | Comprovado | idem | varredores sem limite inferior/superior reproduzem a leitura além da linha |
| 9 | Ricochete: normal tangencial | `0x4a1740` | 4 estágios (piso `D`, teto `U`, parede esq. `R`, dir. `L`) com 3 sondas (±4) a 6 px e limiares 10; ângulo pela tabela `0x598e7e` (mesma de `velocity_angle`) | E | Comprovado | `grub_surface_native.json`: 720 consultas em 12 mapas aleatórios; porte `grub_surface.gd` 720/0 | bordas do mapa: θ=90/180/0 |
| 10 | Ricochete: reflexão | `0x49fd40` `0x4a02b7…0x4a03e0` | `0x40a500` (**NEG**) inverte `vx` e `vy`; `H` = rumo quantizado (`0x4585e0`) da velocidade invertida; superfície achada → soma 90 à célula `0x3fa4` e `H'=2·(S+90)−H`; as 4 varreduras bloqueadas → `H'=H` (**volta**, pois `H` já é o rumo invertido); módulo **constante** `[69]=1800` (T2) / `[82]=1600` (SS) em 24.8; `vx=trunc(sen(H'+90)·m)`, `vy=trunc(−sen(H')·m)` | E | Comprovado | idem. Equivale a `2S−H_antes` e `H_antes+180` (o que a 1ª leitura sem o `NEG` parecia contradizer); estática e execução concordam | — |
| 11 | Energia do ricochete | acima | **fechada**: velocidade reposta a magnitude fixa, sem perda proporcional | E | Comprovado | idem | — |
| 12 | Detonação | `0x49fd40` bloco `0x4a09a3…` | crater `0x4e4970/0x4e4d00` no pixel `(ix,iy)` com dimensão `[60]/[73]` e aspecto `[63]/[76]`; dano `0x450eb0` em `(ix,iy)` | E | Comprovado | cratera real: 738 px idênticos a `crater_spans((1387,1001),38,120)` | efeitos visuais/sons: só os nomes (`0x436070/0x43af40/0x431d90`) |
| 13 | SS: dano repetido | `Animate 0x488780` → `0x450eb0(ix,iy)` **todo quadro**, mesmo ricocheteando; detonação final em `Explode 0x48de60` | dano `[70]=26` com queda elíptica a cada quadro enquanto o corpo estiver na caixa | E | Comprovado | `fx450eb0` registrado em cada tick dos 80 voos SS; `test_ss_passes_through_and_repeats` | atributo Attack/Dig do dono: divisor de `0x41da80` não exercitado (**adaptação**: 3×Attack no poder, Dig/2 na dimensão, divisor 1) |
| 14 | Dano/queda/defesa | `0x45db20` (mesmo de Mage/Aduka) | `falloff`, passes inteiros, `vulnerabilidade` do alvo | D | Derivado | reaproveita `AdukaCombat.amount` (fixtures próprias) | — |
| 15 | T1 | `Projectile` comum | voo/contato **atuais** (`Combat.trace_segment`); dano e cratera nativos `[44]/[47]/[50]` | D | Parcial | `test_grub_model` | contato do T1 pelo `0x455cc0` não foi reconferido (**adaptação**) |
| 16 | Linha type 12 | `characterdata.dat`, `CreateMobile 0x41c360` copia `[21..43]` | vida 1000 `[22]`, escudo 0 `[23]`, regen escudo 0 `[24]`, força `[25]=50`, atraso `[28]=490`+`[30/31/32]=250/400/800`, fator `[29]=10`, gravidade `[40]=98`, mira `[3/4,9/10,15/16]=60/30`, vulnerabilidade `[21]=92`, flags de defesa `[35]=2` | E | Comprovado | `test_grub_model.test_row` | — |
| 17 | Biônico (regen 10 / proteção 70 / Energy Up +3 %) | atalho `_body`; `item_effects.gd:17` | **a linha type 12 não contém 10 nem 70** (o `10` de `[29]` é o fator de tempo) e `CreateMobile 0x41c360` só copia `[21..43]`; os consumidores localizados são o de atraso `0x45d150` (`[33]→+0x989c`, ramo `+0x8bb4==1`) e `0x45d360`/`0x458b80` (`[33]/[34]`), nenhum cura | D | **Removido só do Grub** (decisão do usuário): `hp_regen 0`, `protection 35`, sem bônus de Energy Up | `test_grub_model` (Grub sem o par; Trico/Boomer/Ice/Turtle intactos); Ghidra execução 6 (`grub-evidence-6-fields`, `ok=true`) | O **35** é o padrão dos não-biônicos, não vem do PE (adaptação). Pergunta: o cliente cura o Grub por turno? Próximo experimento: rastrear escritas de HP em `BeginTurn` e o consumidor de `+0x9ac0` |
| 18 | Caixa/apoio | `AdukaCombat.catalog.bodies[13]` (28×24, origem y 21, flags 2) | já extraído do mesmo PE | D | Derivado | `test_aduka_native` | `Vector2(40,34)` do catálogo (hit-box de movimento) segue adaptado |
| 19 | Casco, poses, projéteis, impactos | `graphics.xfs`: `tank13.img/.epa/l`, `bullet13n/nl/s/sl/p`, `flame131/132/133`, `ssflame13` | quadros idênticos pixel a pixel, pivôs do piloto, EPA `fire1/fire2/sfire` (20 ticks), 1º spawn no tick 2 | E | Comprovado | `tests/test_grub_assets.py` (5 testes) | camadas/ordem: as do rig comum |
| 19b | Luz do casco e dos tiros | `graphics.xfs`: `tank13l.img` (362 quadros), `bullet13nl/sl.img` | pixels idênticos ao XFS (`CharacterSpritesheetLight.png`, `Bullet1/2Light.png`); desenho **aditivo** sobre o corpo (como Aduka/Lightning) | E / D | Comprovado (pixels) / Adaptação (mistura aditiva por precedência, não lida no PE) | `test_grub_assets.py::test_hull_light_pixels_and_registration`, `test_grub_model::test_light_layers`, GPU `docs/grub` | luz do casco desenhada acima do piloto; o passe vale só para a view que o abriu no quadro (batalha ou figuras da sala/loading) |
| 20 | Sons | tabelas do PE por type (índice 12): `0x56d1d0/0x56d210/0x56d250` → `131fire.xes`; `0x56d290/0x56d2d0` → `132blast.xes`; `0x56d310` → `11blast.xes` | S1/S2/SS atiram `131fire`; S1/S2 explodem `132blast`; SS explode `11blast` (som do Armor: **registrado, não trocado**) | E | Comprovado | `test_grub_assets.py` lê as tabelas no PE e os hashes em `assets/xfs/audio/catalog.json` | escuta humana não feita |
| 20b | Miras | `graphics.xfs` não tem entrada de mira (nenhum nome com `cross`; nada de `tank13` além de casco/luz/EPA) | `CrosshairGrub*` herdados **permanecem** (o cliente não traz a peça) | D | Mantido | TOC conferido na `test_grub_assets.py` | — |
| 21 | Rastro e espelho | slot 3 de ambas as vtables (`0x458690` T2, `0x488880` SS) | publicam x, y, rumo e o sinalizador `rumo>90 ∧ rumo<270`; **sem rastro** (ADR-120; o de 8 níveis foi retirado após relato de blur) e **espelho vertical só no SS** | D | Comprovado (publicação) / Adaptação (consumidor) | `test_raon_trail`, `test_grub_model` | ADR-120 continua para os outros mobiles; consumidor do espelho no T2 não provado (espelho não aplicado) |
| 22 | Clima no S2/SS (força, tornado, eletricidade) | varreduras `0x49e650`/`0x4857f0`: a cada amostra grossa, **antes** do terreno, `0x4510f0` (força: uma vez por varredura, +8, clamp 20..100), `0x451030` (tornado → `+0xf48`, só se a flag `+0xf4c` estiver livre, `0x406860`) e `0x4511b0` (eletricidade, só se `+0x3918` estiver livre, `0x4065a0`); tick `0x49fd40`/`0x486ea0`: com `+0xf48` o `v+=a` é trocado pelo ramo do tornado (\|vx\| ≥ 200 com o sinal de vx, borda estrita centro±largura/4, `NEG vx` até 3 voltas, depois solta) | mesmos amostradores de `AdukaWeather.sample/finish`; `grub_flight.gd` recebe o `Callable` de clima e chama `finish` no lugar da aceleração | D | **Comprovado (estática)** — corrige a leitura anterior de "objetos inexistentes" | `test_grub_model.test_weather_columns`: S2 e SS × eletricidade/tornado/força (amostra, raio elétrico na explosão, \|vx\| 200 sem gravidade, força 20..100) e previsão = execução com coluna; os 12 checks falham sem a ligação | emulador não exercitou colunas; Weakness/Mirror/Random não são amostrados por essas varreduras (como no Mage); T1 segue o contato comum |
| 23 | Itens, Dual, Thor | — | mesmas regras do passo comum | I | Adaptação | — | Dual duplica o disparo, não o índice 0/8 |

## Descobertas que corrigem leituras anteriores

- `0x458690` e `0x488880` (ADR-119: "rastro/espelho") são **publicadores de estado de render** (x, y,
  rumo, sinalizador `90<rumo<270`), não rotinas de desenho; o consumidor decide rastro/espelho.
- O SS **não** é um tiro sem dano ao cruzar mobiles: `Animate` aplica `0x450eb0` a cada quadro.
- A energia do ricochete não é fração da velocidade: é a constante `[69]/[82]` do próprio mobile.
- `0x450e10` é o teste de mobile (e joias); o T2 o chama, o SS não.

## Correção 28/10/2026 (relato do usuário na `main`)

Relato: tiros do Grub não interagem com eletricidade/tornado e a imagem do Grub na sala fica errada,
piorando depois do Start. Causas: (1) `advance_grub` não chamava nenhum clima; as varreduras nativas
chamam os amostradores da linha 22. (2) `GrubSprite.hull_active` era um flag global: no loading
seguinte a uma partida o `Game._draw` ainda desenha o mundo anterior e liga o flag, e as figuras da
sala desenhavam a luz `tank13l` num canvas aditivo que ninguém limpava, somando uma camada por
redesenho (estouro amarelo). Antes da partida a sala mostrava o casco sem a luz (áreas translúcidas).
Correção: `hull_view` por view; `draw_room_figures` abre o passe no próprio canvas a cada redesenho, então
a sala e o loading mostram o casco com a luz, como na batalha. Prova GPU (sonda local
`.tools/grub-room/proof.gd`, 1920×1080, `elapsed` fixo): recorte da figura idêntico entre 2 e 40 quadros,
após a partida e após 40 redesenhos no segundo loading.

## Perguntas abertas e próximos experimentos

1. Cura do biônico (linha 17). Achado lateral: `0x45d150` soma `[33]` (Grub 50) quando `+0x8bb4==1`; `TurnTable.shot_cost` não modela esse ramo.
2. Divisor de `0x41da80` para Attack/Dig do Grub: rodar o spawner com atributos no dono no emulador
   (hoje o dono é nulo: `0x4206f0` devolve 0).
3. Contato do T1 (`Projectile::Simulate 0x455cc0`): diferença de uma amostra com o T2 (`+1`); o T1 segue pelo trace atual.
4. Consumidor do espelho/rastro no render `0x4c4e93` para S2 (o espelho foi aplicado só ao SS por pedido do issue).
5. Cliente Windows (execução dinâmica) e escuta dos três sons.

## Arquivos

`scripts/grub_surface.gd` (0x4a1740 + varredores), `scripts/grub_flight.gd` (varredura, tick, ricochete),
`scripts/grub_combat.gd` + `assets/openbound/grub/combat_native.json` (`scripts/import_grub_combat.py`),
`scripts/match.gd` (`advance_grub`, emissão com `native_angle`), `scripts/classic_mobiles.gd` (linha 13),
`scripts/grub_sprite.gd` (luz aditiva de tiros e casco), `scripts/classic_sprite.gd` (espelho SS), `tests/test_grub_{surface,flight,model}.gd`,
`tests/test_grub_assets.py`, `tests/fixtures/grub_*_native.json`, `tests/tools/grub_oracle/`,
`tests/capture_grub.gd`.

## Validação (28/10/2026, macOS arm64, Godot 4.7.2, worktree `issue-8-acceptance-c299c8`)

| Prova | Resultado observado |
|---|---|
| `test_grub_surface` | 720 checks / 0 falhas (12 mapas aleatórios, consultas reais de `0x4a1740`) |
| `test_grub_flight` | 15.690 checks / 0 falhas: 160 voos reais (80 T2, 80 SS), ~7,7 mil ticks, ricochetes, detonações, saída do mapa, caixa de mobile |
| `test_grub_model` | 262 checks / 0 falhas: linha DAT, Grub sem o par biônico (os outros 4 intactos), 96 emissões do MainAction, execução = previsão (S2 e SS), SS atravessa e fere por quadro, Teleport+S2 não ricocheteia |
| `test_grub_assets.py` / `test_grub_evidence.py` | 7 + 5 testes OK (quadros pixel a pixel, EPA, tabelas de som lidas no PE, hashes de áudio, ausência de mira no XFS, manifestos) |
| Regressões tocadas | `test_classic_mobiles` 141/0 (expectativa do SS mudou de propósito), `test_raon_trail` 93/0 (rastro só no T1 do Raon), `test_special_mobiles_integration`, `test_classic_flight_parity`, `test_battle_rules`, `test_classic_ballistics` OK |
| Harness `./scripts/check.sh` (execução final, exit 5) | parse de todos os scripts OK; `test_matches` 13 partidas / 0; `test_classic_matches` 16 partidas / 0. 5 suítes Python falham **por ambiente**: `test_xfs_import` (falta `assets/xfs/reference/avatar.xfs`, ignorado pelo Git e ausente também na `main`) e `test_aduka/mage/lightning_assets` + `test_client_audio_source` (procuram `../GunboundClassic/.../sound.xfs`, caminho que não existe a partir de `.claude/worktrees`; com o caminho presente passam: 7, 4, 7 e 5 testes) |
| Captura GPU `tests/capture_grub.gd` | 270 quadros 1920×1080 a 60 Hz, T1/T2/SS à direita e à esquerda, 89 ricochetes, impactos, pausa 150–179 **idêntica** (comparação byte a byte), 0 erros no log; `docs/grub/time-*.png` e `grub-gpu-1920x1080.mp4` |
| Reprodutibilidade | os 3 JSONs de fixtures foram regenerados pelo `tests/tools/grub_oracle` com SHA-256 idêntico |

Não exercitados: cliente Windows, escuta dos sons, mouse físico, atributos do dono ≠ 0 no PE, colunas de clima no emulador (o clima do S2/SS vem da estática, linha 22).

## Aceite

- Revisão técnica: este documento, as suítes acima e a captura. Sem revisão independente humana.
- Aceite do usuário: **pendente** (visual e auditivo). Escopo: Grub (ID 13) no treino 1×1; não vale para os outros mobiles.

