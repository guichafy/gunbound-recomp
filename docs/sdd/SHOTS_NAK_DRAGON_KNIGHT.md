# Tiros do Nak, Dragon e Knight pelo cliente — REQ-53 / ADR-152

Pedido de 07/11/2026: "Nak T1 e T2 estão com efeitos como se o tiro passasse pelo clima
eclipse ou algo que escurece os tiros"; "Dragon e Knight: T1, T2 e SS não estão
implementados igual ao GunBound clássico". Cliente fixado: `GunBound.gme` SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`, `graphics.xfs`
`a52f9f46…`, `characterdata.dat` da TestClient jglim.

Ferramenta: Ghidra 12.2 headless (runner da skill, projeto copiado em
`builds/ghidra-knight-dragon`). Extratos em `.tools/knight-dragon/01-main` … `08-consts`
(manifestos `ok`); as constantes e strings citadas foram relidas no Ghidra em `08-consts`.
Por decisão do usuário, o REA só deve ser usado com o provedor Ghidra (licença). Nenhuma execução do
cliente Windows. Classes: **C** comprovado no ASM/dados, **D** derivado, **A** adaptação.

## Plano

1. Nak: provar no PE como o cliente mistura as camadas `*l` dos tiros; corrigir só o
   desenho do T1/T2 (o SS e a arte ficam).
2. Dragon: emissão do MainAction, rastro de faíscas do S1/S2 e filhos do SS.
3. Knight: guia → Ion → filhos (S1 3, S2 5, SS 8), sobre a base do ASate.
4. Testes de modelo/apresentação com esperados escritos a partir das constantes do
   ASM, captura GPU, harness de combate com as 29 partidas.

## Mistura das luzes dos tiros (todos os publicados por `0x458690`)

| Fato | Evidência | Classe |
|---|---|---|
| `0x458690` publica a célula do corpo em `BulletTexture1` (ctx+0x20b94) e, se existir, a da luz em `BulletTexture2` (ctx+0x20b9c) | `06-vt/0x00458690.c`; strings `0x556880`/`0x556870` | C |
| `0x4c3020` desenha os corpos com estado 1 = `SRCBLEND 5 / DESTBLEND 6` (SRCALPHA/INVSRCALPHA) e **depois** as luzes com estado 2 = `5 / 2` (SRCALPHA/ONE) | `0x4c4d1c..4d50` e `0x4c4f66..4f9e` (`01-main/0x004c4e93.asm`) | C |
| Nível 0 com alfa `0xff − (nível<<5)` = 255 nos dois passes | `0x4c4e86..4e99`, `0x4c50da..50ed` | C |
| Nak S1 (`Projectile` 0x555c34) e S2 (`Shot2_Bullet3` 0x5563a8) usam esse publish | vtables `06-vt` slot [3] = `0x458690` | C |

O Godot do Nak desenhava `bullet3nl/sl` **por baixo** do corpo, em mistura normal com
alfa 0,75: no S2 o corpo `bullet3s` (cinza translúcido) cobria a eletricidade, e o halo
virava um véu — o "eclipse" do relato. Agora o corpo vai primeiro e a luz é somada por
cima (`nak_sprite.gd`, `AdditiveArt`), alfa 1. Os outros mobiles clássicos que ainda
desenham a luz em mistura normal (`ClassicSprite._draw_bullet`) **não** foram alterados
nesta entrega; Dragon e Knight usam a ordem do cliente (`ADDITIVE_LIGHT_KINDS`).

## Dragon (ID 14, client type 13)

| Comportamento | Evidência | Godot | Classe |
|---|---|---|---|
| S1: θ, P+10 no quadro 4 | `0x46d171..0x46d23e`: `[0xe9ba40]`(=10) somado a `0x7864` (força); `0x4d90` (θ) intacto; arg 4 = 0 | `native_power: 10` | C |
| S2: quadros 1/6/11/16 (tabela `0x46ddc8`), (θ+1,P+10), (θ+1,P−10), (θ−1,P+10), (θ−1,P−10) | ramos `0x46d2c3/491/659/827`, helpers `0x40a5f0`/`0x40a6e0` | quatro shells, `native_angle`/`native_power`; tempos do `shot_timing.json` | C |
| SS: θ, P+10 no quadro 4, por `0x42de70` | `0x46da17..0x46db1c` | `native_power: 10` | C |
| Deslocamentos somados após o clamp da mira | células `0x4d90`/`0x7864` já limitadas | `spread_after_clamp` | D |
| S1/S2 sem corpo: publish da vtable `0x555ea8` = `0x429800` (vazio) | `02-data` | sem sprite; só faíscas | C |
| Faíscas: em cada amostra de 8 px da varredura de `0x46fb20`, se o contador do tiro `0x3f9c` (mod 6) < qualidade `0x5f2f54`, `0x436fd0` faz 8 tentativas (`rand` par) em `prev + k·(amostra−prev)/8 ± 4`, ângulo `rand%360` | `01-main/0x0046fb20.c`, `0x00436fd0.c` | `dragon_sparks.gd` (RNG só na apresentação), evento `dragon_spark_sweep` | C (passo 8: D, igual ao `0x455cc0` comum; qualidade 3 como no Mage: A) |
| Faísca vive 16 ticks, ângulo +6/tick; desenho `CrashTexture` pelo quad `0x4ec840`: tamanho `(16−idade)·16/10`, u `(idade/2)·0.125`, v `0x3f1d70a4` (0,615), alfa `255−16·idade`, estado 2 (SRCALPHA/ONE) | `0x4711f0`, `04-seed/0x00471240.asm`, `05-quad/0x004ec840.asm`, `0x558040`=0,125 | `DragonSparks.quad` → `MageSparkArt.native_quad` | C |
| SS Explode `0x46ca60` (slot [8] da vtable `0x555e30`): 5 chamadas de `0x4388e0(i, x, y, θ, R, 5, pai)`, θ de `(45−[0x33c8])·2` passo `[0x33c8]`, R = `[0x35ec]`; linha type 13 `[81]=30`, `[82]=200` | `01-main/0x0046ca60.asm`; `characterdata.json` | `ClassicFlight.dragon_children` | C |
| Filho nasce em `impacto + (int(cos θ·R), −int(sen θ·R))` e voa para o centro: rumo θ+180, `v = (cos, −sen)·2560`, aceleração `0xaf4/0xd18` = 0 (sem gravidade nem vento) | `0x4388e0` ASM `0x438a08..0x438c56`, floats `0x55808c`=2560, `0x558088`=−2560 | `Physics.seed(..., Vector2i.ZERO)`, 10 px/tick | C |
| Filho: vtable `0x555e0c`, Animate `0x46c990` toca `normal` e troca para `fly`; publish `0x488880` (espelho vertical) | `07-child` | `dragon_child_frame`, espelho | C |
| Dano/raio do filho = linha SS (160/27); `0x41da80` com divisor 5 só nos bônus de atributo | `0x438df2` | dano do catálogo; divisor de bônus não portado | A |
| Contato do S1/S2/filhos: `0x455cc0`/`0x46fb20` | vtables | trace comum do Godot | A |

## Knight (ID 15, client type 14)

| Comportamento | Evidência | Godot | Classe |
|---|---|---|---|
| Um guia por tiro, sem deslocamentos: S1 quadro 1, S2 quadro 7, SS quadro 1 | MainAction `0x47ab90` (casos 5/6/10) | `flight: knight_guide` | C |
| Guia S1/S2 só tem as luzes `bullet15nl/sl` (não há `bullet15n/s.img`); SS corpo `bullet15p` + luz `bullet15pl` | `graphics.xfs`; frames.json do Knight | folha inteira no passe aditivo (`light_only`) | C |
| O guia não explode: acha o Ion (classe `0x186a5`) e chama `0x47c040` (S1/S2) ou `0x47c3f0` (SS) com o impacto | `0x47b2f0`, `0x47de50` | `KnightEffect.begin`, sem blast do guia | C |
| Ion (`0x438100`, vtable `0x556078`): parado sobre o dono a y−200 (−400 com a flag `0xfe8`), aproxima ⌈|d|/8⌉ ocioso e ⌈|d|/2⌉ ativo, mira `0x47bfd0` no alvo | Animate `0x47ca40` | `KnightEffect.step_ions` (`AsateEffect.aim_angle`) | C (flag −400: A, sempre −200) |
| Estados `normal/fire1/fire2/move`; S1 emite no quadro 2 de `fire1`, S2 no quadro 2 de `fire2`, SS no quadro 1 de `fire1` | `0x47ca40`; `knightion.epa` | `step` | C (quadro do disparo após chegar: D) |
| S1: 3 filhos θ, θ+4, θ−4, atrasos 3/7/7; S2: 5 filhos θ, +2, −2, +4, −4, atrasos 3/7/7/11/11 | argumentos de `0x4305c0` | `FANS` | C |
| Cada filho nasce em `alvo − R·(cos θₖ, −sen θₖ)`, R = ⌊√(dx²+dy²)⌋ do Ion ao alvo: o leque converge no alvo | `0x47d03a..0x47d0c7` | `KnightEffect.fan` | C |
| SS: altura y−400; passo X = ⌊tan(`0x558070`)·400⌋ = 27; início alvo−13−27; ângulos 276/272/268/264 e de volta; X avança 3 passos e retorna; 8 filhos no mesmo quadro com atraso i·2 | `0x47c3f0`, laço i<8 de `0x47ca40` | `KnightEffect.rain` | C (ramo do sinal em `iStack_c`: A, segue o ASate) |
| Filho (`0x4305c0`, vtable `0x556008`): `v = (cos, −sen)·6144`, `a = (cos, −sen)·768`, sem gravidade nem vento | floats `0x55809c/0x558098/0x558094/0x558090` | `KnightEffect.child` | C |
| Filho espera `[0x3f9c]` ticks parado e voa a partir do tick do atraso (toca o som de disparo ali) | Animate `0x47ab00` | `KnightEffect.waiting` (som: A, não tocado) | C |
| Dano: linha type 14 S1 136 / S2 128 / SS 126 por filho | `characterdata` | catálogo | C (fórmula e contato comuns: A) |
| Arte do Ion e do filho: `knightion(l)`, `knightbullet(l)`; corpo alfa + luz aditiva; Ion gira para θ e balança no `normal` (tabela de 22 passos de `0x47dc00`) | `graphics.xfs`; `0x47dc00` | `import_knight_ion.py`, `knight_art.gd` | C (mistura do Ion: D, mesma do bullet) |
| `bullet15p` e `bullet15pl` têm os mesmos pixels nos 20 quadros (só o cabeçalho difere): o guia do SS soma a própria imagem por cima de si | decodificação do XFS; `test_knight_assets.py` | corpo + luz aditiva | C |
| Impacto `knightflame` não existe no `graphics.xfs` | strings `0x553d20`; índice do XFS | sem quadro de impacto, como antes | C |

## Validação

`test_dragon_shots` (58), `test_knight_shots` (92), `test_nak` (62), `test_classic_mobiles`,
`test_classic_flight_parity`, `test_mage_spark_art`, `test_mage_sparks`. `test_knight_assets.py` confere cada quadro do Ion/filho com o `graphics.xfs`. Sonda local na cena
real (`main.tscn`, fora do repositório): Dragon S1 → 110 faíscas pelo `weather_art`, Knight S1/SS e
ASate desenhando os dois Ions, sem erros no log.
Captura GPU `tests/capture_mobile_shots.gd -- <id> [tag] [dark]` em
`docs/mobile-shots/` (Nak antes/depois, Dragon claro/escuro). Partidas completas no HANDOFF.
