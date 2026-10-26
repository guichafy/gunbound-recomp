# Raon — correção clássica delimitada

REQ-19/44/45. Plano/evidência inicial, 25/10/2026; integração e validação final
ficam com a tarefa principal. Preservar os 16 IDs, arte/avatares/HD e perfil.

## Escopo e plano antes do código

1. Reproduzir a divergência: S1 usa quatro órbitas C#; cliente emite três,
   com um carrier comum e dois tiros oscilantes. Minas usam relógio global de
   render, movimento S2 instantâneo sem alcance e autoria obtida do turno vivo.
2. Fixar cliente, ASM, dados e consumidores; construir fixtures independentes.
3. Acrescentar `RaonEffect`, puro e isolado: S1 em ponto fixo, estado/clocks
   privados das minas, proprietário explícito e passo compartilhável com previsão.
4. Integrar por hooks em ClassicFlight/Match/ClassicSprite na tarefa principal;
   testar limites, cópia, autoria, clocks/pausa e partidas completas.

## Fontes e confiança

Cliente PE x86, image base0x400000, `.tools/mobile-animation-port/GunBound.gme`,
SHA-256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Ghidra12.2/JDK25 direto, projeto exclusivo `builds/ghidra-raon-fix`;
extratos `.tools/raon-fix/{seed,mine,mine2,orbit}`. Endereços abaixo são VA.
Primeiro extrato `initial` foi parcial por função ausente; `seed` resolveu a
entrada0x49c050 comprovada pela vtable0x556424. `initial2` foi rejeitado por
lock enquanto a primeira análise terminava; não é evidência positiva.

| Comportamento | Fonte/ordem/unidade | Estado |
|---|---|---|
| S1 três emissões no quadro11 | MainAction0x49c13f, calls0x49c2dc/0x49c3fc/0x49c50d | Comprovado |
| S1 idx0 comum, idx1 fase180, idx2 fase0 | Spawner0x42bbb0/case6, `[obj+0x3f9c]=(idx&1)*180` | Comprovado |
| Fase avança40° antes da colisão | Animate0x497730 ADD0x28, IDIV360, call virtual+0x18 | Comprovado |
| Oscilação de13px perpendicular ao heading | Detonate0x495e80, LUT0x54c240; floats0x5580b8=−13,+13; FPU truncate, SHL8 | Comprovado; heading usa LUT comum já portada |
| Offset não integra no carrier |0x495e80 restaura velocidade e conserva posição-base em0x43ec/0x4610 | Comprovado |
| S2 nasce normal; SS nasce active | SpawnMine0x4375f0/SpawnSuperMine0x437870 | Comprovado |
| SS conta100 chamadas de movimento e detona |0x492f50 INC `[obj+0x441c]`, CMP100, call virtual+0x20 | Comprovado; agenda integrada a20Hz é adaptação delimitada |
| SS em chão plano acumula300/100=3px por chamada |0x492f50 `(100−slope)*3`, divisor protegido0x796aa0; WinMain0x40daa2 escreve100 | Derivado; terreno/queda/parede continuam adaptação |
| S2 alcance estrito<90px, pausa0,5s, orçamento90px/turno próprio | C# RaonLauncherMineS2.cs e Parameter.cs | Fallback identificado; não alegar paridade nativa |
| Proprietário/veículo/arma preservados e clocks pausáveis | contrato Godot; snapshot profundo dos dicionários | Adaptação de integração necessária |

O C# consultado é somente leitura em `/Users/guichafy/Workspaces/Gunbound`.
`RaonLauncherProjectile.cs:33–38` emite quatro; essa regra foi substituída pela
prova nativa do S1. EPA/atlas continuam originais em assets/openbound/raon:
rayonmine normal0..19/active20..36/move37..48; srayonmine
active0..19/move37..48. Uma duração vale um tick20Hz segundo frames.json.

Pesquisa adicional `mine-final`, manifesto `ok=true`: S2 movimento é
0x499930, comprovado pela vtable0x5563f0/slot+36. Rejeita proprietário
divergente, estado normal/tornado; termina a menos de4px do alvo ou
inclinação>70. A cada chamada usa resíduo `(100−inclinação)*3/100` e consome
o orçamento em `[obj+0x3fac]`. SpawnMine copia o orçamento do campo de regras
`[obj+0x35ec]`; sua ligação ao dado e agenda nativa não foi fechada nesta
tarefa. `0x498070` escolhe o alvo mais próximo dentro do raio do campo
`[obj+0x33c8]` e altera esse raio em+20%/−50% por flags do alvo. Esses detalhes
ficam pendentes; o módulo identifica seu orçamento90px/espera0,5s como fallback.

SS mine0x491b40 solicita chama73 e um recurso extra chamado `ssflame7`
(string em0x554e94). O TOC do graphics.xfs fixado acima contém
flame71/72/73.img/.epa e **não contém ssflame7.img/.epa**. Preservar chama73;
não criar textura ou metadados para preencher um recurso ausente.

## API de integração

`active/prepare/hit_point/finish_tick` para shells `flight=raon_orbit`.
Entradas da rajada devem conter `raon_component`0/1/2; `prepare` não interfere
em sinalizadores. `hit_point` amostra fase+40 no heading pré-aceleração e não
altera a base; `finish_tick` conserva a fase publicada para o próximo tick.

`create_mine(projectile,position,owner,vehicle,facing)` preserva a autoria
recebida; `begin_turn(mines,actors,owner)` agenda só S2 próprias com alvo;
`step_mines(mines,actors,terrain,delta)` atualiza relógios/movimento e retorna
índices de detonação em ordem reversa. O chamador aplica dano/Gold e remove.
`contact`, `refresh_target`, `visual_state`, `visual_age` não dependem do relógio
da máquina. `delta=0` não muda estado. A previsão deve copiar as minas antes
de chamar os mesmos hooks, sem compartilhar arrays/dicionários vivos.

## Limites

Não executamos o cliente original. Movimento numérico em encostas, tolerâncias
de colisão, influência de clima, ordem nativa de ativação de minas S2 e dano
continuam adaptações/C# identificados. Captura GPU do renderer e validação de
escuta/input devem ser registradas pela tarefa principal. Nenhum app exportado.

## Validação local do módulo

`tests/test_raon_effect.gd`:168 checks/0falhas em Godot4.7.2, com fases
0/180 e nove ticks completos, truncamento/cardinais, carrier intocado,
beacon, alcance90 anterior/exato, espera0,5s, pausa imutável, autoria,
contato com dono/ordem de remoção, limite SS99/100, borda e30/60/120FPS.

`python3 -m unittest discover -s tests -p test_raon_native_source.py -v`:
5testes/0falhas. Prova independente lê bytes do PE e TOC do XFS, confirma
calls reais, fase+40 antes do call virtual, constantes−13/+13, FPU/truncamento
antes doSHL8, expiração100 e ausência da textura extra. Não importa o módulo
GDScript portado. Sem PE/XFS locais essa suíte se declara pulada.

Comando Godot dirigido (log absoluto para não tocar perfil real):
`/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /Users/guichafy/Workspaces/DemoGame/.tools/raon-fix/test-engine.log --path . --script tests/test_raon_effect.gd`.
Integração completa, testes de modelos/partidas e GPU são responsabilidade da
tarefa principal; estes números não alegam validação do aplicativo exportado.

## Correção dos tiros T1/T2/SS — 26/10/2026 (ADR-116)

Pedido: “corrigir os tiros do Raon T1, T2 e SS”. REQ-19/44/45. Mesmo PE
(SHA-256 acima), Ghidra12.2 direto, projeto `builds/ghidra-raon-fix`,
extratos novos `.tools/raon-shots/q1..q9` (manifestos `ok=true`, salvo q3,
que registrou `function_not_found` e foi refeito com seeding em q4).
Captura “antes” com GPU real (1280×800, 60Hz) reproduziu: T2 com leque de
±3° e balas de mina plantando no corpo do alvo; SS sem deslocamento de força.

### Plano

1. Fixar ASM/dados e reproduzir com testes RED.
2. T1: componente→idx nativo 0/2/3; fase `(idx&1)*180` = comum/0/180.
3. T2: dois tiros com força nativa P+15 e P−15, mesmo ângulo, sem leque.
4. SS: um tiro com força nativa P+15.
5. Balas T2/SS só colidem com terreno (atravessam mobiles).
6. Direção da supermina: `vx>0` estrito → direita; senão esquerda.
7. Previsão = execução, Dual/Dual+/Teleport, partidas completas e GPU.

### Matriz

| Comportamento | Fonte/unidade/ordem | Estado |
|---|---|---|
| S1 idx imediatos 0/2/3 (Dual 8/10/11) | `0x49c219`/`0x49c350`/`0x49c470` MOV imediatos antes dos calls `0x49c2dc/3fc/50d` | Comprovado |
| idx%8=0 → Projectile comum; demais → órbita fase `(idx&1)*180` | `0x42c295` AND 0x80000001, `0x42c2af` IMUL0xb4 → `[obj+0x3f9c]` | Comprovado; corrige inversão comp1/comp2 da0.20.5 |
| S2 força A=P+15 (`0x40a5f0`), B=P−15 (`0x40a6e0`), ângulo `0x4d90` inalterado | `0x49c5c7–0x49c5e1`, `0x49c73b–0x49c74f`; helpers ADD/SUB em `0x40a659`/`0x40a742` | Comprovado |
| Constante 15 | WinMain `0x40d9d2` `6a0f bff04b7900` + call `0x40a380` | Comprovado |
| SS força P+15 | `0x49ca1f–0x49ca3d` → `FUN_0042de70` | Comprovado |
| Sem clamp do P deslocado no spawner | `0x42bbb0`: `(float)P` → ftol → `<<8 /10` | Derivado (sem instrução de clamp no trecho) |
| Balas S2/SS ignoram mobiles | Simulate `0x49aeb0` (vtables `0x555aa4`/`0x556424`) não chama `0x450e10`; a comum `0x455cc0` chama2× | Derivado; C# `RaonProjectile2/3.UpdateCollider` só testa terreno |
| Direção da supermina | Explode `0x49c064–0x49c077`: `[obj+0x488]` (vx) `SETG` → `SpawnSuperMine` param6 | Comprovado |
| Ponto exato do plantio, raio de contato, encostas, dano/raio das minas | — | Mantidos como na0.20.5 (adaptação/C#) |
| Rotação do sprite pelo heading | Nenhum consumidor nativo de render localizado | Pendente; renderer comum inalterado |

O ±3 do C# é `forceModifier` (força), não ângulo; o catálogo Godot o tratava
como ângulo. A força nativa vale P inteiro (`native_power` já quantizado),
somado depois; `P−15` pode ser ≤0, como no spawner nativo.

### Implementação e validação

`raon_effect.gd`: `NATIVE_INDEX=[0,2,3]`, fase `(idx&1)*180`; supermina
com `vx_fp>0`. `combat.gd`/`match.gd`: `native_offset` inteiro somado após
`native_power`, lido de `native_power` na entrada da emissão (mesma função
para `fire`, `predict_shot`, CPU e Dual). Catálogo Raon: T2 `[+15,−15]`,
SS `[+15]`, ambos `skip_actors`.

- `tests/test_raon_shots.gd` (novo): 95 checks; RED 39 falhas antes do código,
  0 depois. Cobre P=1/15/16/440 nos dois sentidos (P−15 ≤0 sem clamp),
  muzzle comum, T1 sem deslocamento, travessia da caixa e plantio no chão,
  T1 ainda acerta o mobile, direção vx=0→esquerda (só com `fp_ready`; antes
  disso usa a velocidade float), direção pelo caminho real `fire` e
  previsão=execução.
- `tests/test_raon_effect.gd`: 168/0 com a expectativa de fase corrigida.
- `tests/test_special_mobiles_integration.gd`: 263/0.
- `tests/test_raon_native_source.py`: 9/9 (4 novos: índices, ±15/WinMain,
  ausência de `CALL 0x450e10` em 0x49aeb0..0x49c04f, SETG vx).
- GPU real (Godot4.7.2 gl_compatibility, Apple M4 Pro, fora do sandbox):
  `tests/capture_raon_shots.gd`, 1280×800 nativo, 60Hz, 300 quadros, pausa
  90–119; T1/T2/SS × direita/esquerda: pausa30 idêntica e retomada nos seis.
  Plantio T2 970,5/1133,7 ↔ 309,5/146,3 (simétrico em 1280). Comparativo em
  `docs/raon-shots/before-after.png`. Captura Godot, não execução do cliente.

- `./scripts/check.sh`: 13062 checks Godot, 33 Python, 29 partidas, exit0.
  Depois dele, `create_mine` passou a exigir `fp_ready` e a suíte ganhou o
  caminho real (88→95); reexecutados test_raon_shots 95/0, test_raon_effect
  168/0, integração 263/0, Python 9/9 e parse dos arquivos alterados.

Pendências: ponto exato do plantio (C# usa a posição livre anterior), raio de
contato/encostas das minas, dano/raio das explosões, rotação do sprite pelo
heading, escuta/mouse e aceite visual do usuário. App não reexportado.

## Minas S2/SS no terreno — 26/10/2026 (ADR-117)

Relato do usuário após a ADR-116: robôs do T2 com orientação errada; mina
deve explodir ao encostar no mobile; minas que não estouravam por causa do
terreno. T1 "maior/mais extenso" sem divergência estática encontrada (abaixo).
Extratos novos `.tools/raon-shots/r1..r5` (manifestos `ok=true`).

| Comportamento | Fonte | Estado |
|---|---|---|
| Gatilho: qualquer mobile vivo com âncora (pés) a dx²+dy² < r² da mina | AnimateMine `0x498b60` / AnimateSuperMine `0x4921e0`: laço8 slots, `+0xbff7` (morto) pulado, `0x90c/0xb30` vs `0x40/0x264`, slot+0x20 = ExplodeMine | Comprovado |
| r = 8 (campo `+0x3198` = 10º do bloco; S2[66]=8, SS[79]=8) | `0x41da80` fontes `0xf61b4/0xf7d88/0xf995c` (S1/S2/SS), `0x41dc6f`; characterdata linha 6 | Comprovado |
| Âncora do mobile = pés (`0xb30`); caixa fica acima dela | HitTestMobile `0x45d640` | Derivado; Godot usa `pos+(0,stance)` |
| Dono também detona; mortos ignorados | sem filtro de dono no laço | Comprovado |
| Supermina também explode a <8 px de outra mina | `0x4921e0` laço tipo `0x186a3` | Comprovado |
| Chão sondado de y−15; encaixe se y ≥ chão−15; queda +1 px/tick; pouso com v≥5 quica para chão−v e v=1 | `0x498bab`, `0x498fe1` CMP5, `0x4990b6–0x499102` | Comprovado |
| Fora do mundo (x<0, x≥W, y≥H, y<−200) some sem explosão | `0x4991fe` PUSH −200, `+5=1` | Comprovado |
| Explosão em (x, y−10) | ExplodeMine `0x497b12` `[0xe9ba40]=10` | Comprovado |
| Inclinação: alturas x−10/x/x+10 (sonda y−15), penhasco >h0+20 espelhado, LUT int16 de ângulo (20,dy), >270 → −360 | `0x4986a0`, WinMain 10/20, LUT `0x598e7e` | Comprovado |
| Desenho: célula 32×32 com origem EPA em (16,24), quad girado anti-horário pelo ângulo, espelho U quando `0x3fa8`=direita | `0x499d50`, `0x497980`, `0x4c5b35`→`0x4ebbc0`, floats `0x557ff0..0x55803c` | Comprovado |
| `0x3fa8`: spawn `vx>0`; S2 alvo à direita (`0x49867c`); SS inverte em parede (`0x492fb7`) | — | Comprovado; o `dir` do Godot tinha o espelho invertido |
| Balas T2/SS não testam mobiles (Simulate e Detonate sem `0x450e10/0x45d640`) | `0x44c950`, `0x499ef0` chamadas diretas | Comprovado; ADR-116 mantida |
| Mina enterrada: busca nativa até 30 px | — | Adaptação: sobe para a superfície sondada |
| Grade de terreno 2 px quantiza alturas e inclinação | terrain.gd | Adaptação declarada |
| Brilho `rayonminel` desenhado por cima com modo de mistura próprio | RayonTexture2 | Pendente; mantém ordem/alfa anteriores |

T1: o passo `0x495e80` grava a posição com o deslocamento antes do desenho e
`0x4585e0` gira pela direção; bala comum e orbitais usam `bullet7n` e o mesmo
desenho. Nenhuma diferença de tamanho/rastro/explosão foi comprovada; pedir
referência do original ao usuário antes de mexer.

Validação ADR-117: `test_raon_mines` 33/0 (RED antes: API ausente),
`test_raon_shots` 102/0 com aceitação pelo caminho real, Python
11/11 (bytes de sonda/quique/−200/morto/10/20/quad/campo 0x3198 e valor 8),
harness 13102 Godot/80 suítes/29 partidas exit0, GPU em relevo 330 quadros com
pausa idêntica. Captura Godot, não execução do cliente original.

## Rastro das balas (T1 "maior/mais extenso") — 26/10/2026 (ADR-118)

Referência do usuário: vídeo “Gunbound : LIGHTING vs RAON” (YouTube
`fd9VsdZQbsI`, 1:15–1:20). Quadros 76,5–77,1 s (960×720) mostram as três
balas do T1 seguidas de uma cauda densa de cópias translúcidas do mesmo
sprite. O Godot desenhava só as três balas.

| Comportamento | Fonte | Estado |
|---|---|---|
| Cada bala publica x/y/ângulo por quadro desenhado (nível 0) | slot3 `0x458690` (Projectile e as três classes Raon), tabela `ctx+(nível*16+0x1a35+slot)*20` | Comprovado |
| Render desenha níveis 7..0, alfa `0xff−(k<<5)`, mesma célula de textura (quadro atual) | `0x4c4e93` → `0x4ebdd0`, BulletTexture1 | Comprovado |
| Fim do quadro desloca nível k ← k−1 e limpa o nível 0 | fim de `0x4c3020` | Comprovado |
| Desenho no máximo 1×/tick de 50 ms → nível = tick de 20 Hz | GameTick `0x413130` (`/0x32`, retorno sem tick) | Comprovado |
| Célula 64×64, pivô (48,32), giro pelo ângulo gravado | floats `0x557ff4..0x558054`, blit `0x455b60` | Comprovado |
| Ângulo de cada nível | campo `0x1c2c` (passos de 3°) | Adaptação: direção do deslocamento daquele tick |
| Sem espelho: flag do quad (`entrada+0x10`, lido em `0x4c4e84`) é sempre 0 em `0x4587bf`; robôs indo para a esquerda giram 180° | `0x458690` | Comprovado; Godot igual |
| Cauda continua após o impacto: sem nova publicação, o deslocamento esvazia um nível por quadro (≈0,35 s) | fim de `0x4c3020`; vídeo 1:17,7 | Comprovado + vídeo; Godot: efeito de cena `lingering` |
| 2ª passada de brilho (BulletTexture2) | passada 2 | Sem efeito no Raon (sem folha de brilho) |
| Mesma regra nas balas comuns dos outros mobiles | slot3 compartilhado | Comprovado, mas não ativado: muda visual aprovado |

Godot: `ClassicSprite.trail_levels` usa o histórico `trail` por tick, alfa
255−32k, níveis 7..1 antes da cabeça e a mesma fração de interpolação da
cabeça; ativado por `NATIVE_TRAIL_KINDS=["raon"]`. Após remover a bala, a cena
(`game.gd` `lingering`, `ClassicSprite.lingering_levels/draw_lingering`) esvazia os
níveis por tick no relógio pausável. Validação: `test_raon_trail` RED→45/0,
Python 12/12, `check.sh --quick` 13154/0, GPU T1 nos dois sentidos e T2/SS à
esquerda com pausa idêntica (`docs/raon-shots/t1-trail-godot.png`,
`docs/raon-shots/trail-left.png`). Comparação com o vídeo fica em
`.tools/raon-shots/t1-video-vs-godot.png` (quadro de terceiros, fora do Git).

## Rastro estendido aos outros mobiles — 26/10/2026 (ADR-119)

Pedido do usuário: “Adicione rastro” (resposta à extensão pendente da ADR-118).
Censo do slot3 (publicação de desenho) em todas as classes da matriz de tiros:

| Publicação | Classes | Godot |
|---|---|---|
| `0x458690` rastro | Projectile, Armor S2/SS, Nak S2, Trico S2, Bigfoot SS, Boomer, Raon, Lightning, JD, guia A.Sate, Ice, Turtle SS, Grub S2, Dragon SS, Knight, Aduka S1, Mage SS | `trail_style` = "trail" |
| `0x4ae1a0` rastro (sem espelho) | Trico SS | "trail" |
| `0x488880` rastro + espelho vertical se 90°<ângulo<270° | Nak SS, Grub SS, Aduka S2/SS | "facing" (ClassicSprite) |
| Desenho próprio, sem histórico | Mage S1/S2 (`0x47f1c0`/`0x4a6840`), Turtle S1/S2 (`0x4b30e0`), Dragon S1/S2 (NoOp), filhos/íon A.Sate, íon Knight, cristais JD | "" (caminhos próprios mantidos) |

`ClassicSprite` desenha os níveis com brilho e corpo e alfa 255−32k na ordem
de camadas já aprovada; a cena esvazia a cauda de qualquer mobile com rastro
(`leaves_trail`). O Nak mantém a orientação aprovada (sem giro no T1/T2,
espelho horizontal no SS) e ganha só as cópias: a rotação/espelho nativos do
Nak ficam como pendência visual. A passada nativa de brilho é desenhada depois
de todos os corpos (modo de mistura próprio); o Godot mantém brilho sob o corpo.

## Rastro só no T1 — 26/10/2026 (ADR-120)

O usuário recusou o rastro fora do T1 do Raon. `has_trail(kind, weapon)` liga só
`raon`/T1; T2/SS e os demais mobiles (inclusive o espelho Facing e o Nak) voltam
ao desenho anterior. `test_raon_trail` 93/0, `check.sh --quick` 13202/0.
A tabela de censo da ADR-119 acima é evidência do cliente, não comportamento ativo.
