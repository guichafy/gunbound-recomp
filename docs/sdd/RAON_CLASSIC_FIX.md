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
