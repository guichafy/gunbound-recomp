# JEWEL — contrato de contato e dano isolado do PE

13/11/2026. Pesquisa independente, sem alteração de runtime/SDD. Fonte exclusiva:
Thor's Hammer `GunBound.gme`, SHA256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
VAs na imagem base `00400000`. Não foram consultadas versões posteriores.

## ABI e dados comprovados

`450eb0` recebe contexto de lista em ECX e seis argumentos de pilha; o
terceiro é shell. Em `450eb8` carrega esse terceiro argumento em EBP;
`450f54` faz `EDI=EBP` antes de `478cb0(jewel,impactX,impactY)`.
`478cb0` usa EDI como shell preservado; não é parâmetro indeterminado.
O retorno é `RET 0xc`. Dispatcher percorre mobiles primeiro, depois jewels
não removidos na ordem encadeada, em listas separadas. Não interrompe após
primeiro jewel, ao contrário da consulta de contato `450e10`.

Helpers aritméticos nativos conferidos em ASM e executados sem stubs:
`40a5f0(cell,out,k)` soma, `40a6e0` subtrai, `40a7d0` multiplica,
`40a8c0` divide signed; nesta última rotina somente denominador zero vira1.
`40a2e0` lê endereço em EAX; `40a380` escreve célula em EDI e argumento na
pilha. `40a470` escreve endereço em EAX; `40aab0` acumula em EAX.
Os casts de critical section do decompilador não fazem parte da fórmula.

WinMain `40d8e0`, trecho `40d9b8..40d9f3`, inicializa diretamente:

| Célula | Valor | Papel |
|---|---:|---|
| `e9ba40` |10| meia largura de contato, deslocamento do centro vertical e expansão de raio |
| `e55ab8` |20| altura de contato |
| `796aa0` |100| escala percentual (default previamente provado em jewel-native) |

São defaults comprovados de startup; não se afirma imutabilidade global.
`478a80` ignora exatamente `removed==1` e retorna contato inclusivo:
`jx−10 <= x <= jx+10` e `jy−20 <= y <= jy`. Não verifica tipo, HP, pose,
flag `drop` ou autoria. Dispatcher pode filtrar `removed!=0` antes dele.

## Fórmula inteira de `478cb0`

`q(a,b)` significa divisão signed com truncamento para zero; `i32` significa
resultado wrap32 das instruções IMUL/ADD quando extrapola o signed32.
As fixtures ficam no domínio numérico sem overflow; não transformam valores
arbitrários de inteiros64 do host em paridade nativa.

Se o bool protegido `context+6a7f74` é verdadeiro ou `jewel+14==1`, retorna.
Seleciona material da linha atual de mapa:

```
row = context + 0x1a1f48 + (read(context+0x475c8)*11 + u8(context+0x475c4))*0x7d28
m = read(row)
```

**m é material0/1/2, não weapon.** A origem desse dado no mapa é coerente
com as três células por material já portadas; o consumidor usa o valor inteiro.
Não existe multiplicador extra denominado stageCoef no dano: esse campo
seleciona o triplo do shell. Fora0..2 não há potência selecionada, portanto
sem dano positivo no domínio legal.

| material m | potência P | dimensão D | aspecto A |
|---:|---|---|---|
|0|shell+1e54|shell+24c0|shell+2b2c|
|1|shell+2078|shell+26e4|shell+2d50|
|2|shell+229c|shell+2908|shell+2f74|

Seja S=read(796aa0)=100, H=read(e9ba40)=10:

```
R  = q(D,2) + H
DX = q(i32(S * (jx-impactX)), max(1,A))
DY = jy - H - impactY
D2 = i32(DX*DX + DY*DY)
base = 0
if D2 < i32(R*R):                         # estrito, nenhum dano na borda
    f = trunc(((R - sqrt(D2))*1000.0)/R)  # helper53753c, x87
    base = q(i32(P*f),1000)
percent_damage = q(i32(read(shell+17e4)*base), S or 1)
damage = q(i32((S + read(shell+139c) + q(read(shell+15c0),2))*percent_damage), S)
```

O numerador `(R−sqrt(D2))*1000` é armazenado como double antes de dividir por
R no x87. `53753c` converte para inteiro truncando para zero. Não arredondar
DY, DX ou raio de novo e não juntar as três divisões. O primeiro percentual
é shell17e4; Force acumulada é shell15c0, cuja metade entra no último fator.
Shell139c é bônus adicional. Não entra vulnerabilidade/Defense dos mobiles.
Nenhum divisor adicional por componente é lido nesta rotina: spawner/41da80
já prepararam os valores P/D do shell, inclusive Attack/Dig e divisores.

Se `damage>0`, `40aab0` soma **o valor inteiro, sem clamp** em jewel+8c8;
publica número em `(jx,jy−15)`/slot+50, seleciona pose `damage`, e escreve
`u8(shell+3c)` em jewel+d14. A autoria é substituída inclusive por255.
Dano zero/negativo não muda autoria, acumulador ou pose. Overkill permanece
no acumulador. Não altera diretamente `jewel+6a4`, não remove o objeto nem
credita pontos. Isto pertence ao tick posterior. `drop` não impede blast;
fixture com flag1c18 ligada recebe o mesmo dano do objeto apoiado.

Se flag protegida `shell+3f98` estiver ligada, consulta objeto categoria186aa
com slot0 e soma o mesmo dano em seu +270, se encontrado. Essa contabilização
auxiliar não modifica a fórmula; o fixture padrão mantém a flag falsa.
A consulta/recompensa desse objeto não foi emulada nesta matriz.

## Shock e ataques auxiliares

`43af40` e `43b7a0` têm consumidores reais de JEWEL além dos mobiles. São
aplicação de estado de shock, **separada do blast**:

- Distância usa o pé `(jx,jy)`, sem deslocamento−10, e raio estrito.
- Ignoram jewel se `removed!=0`.
- Ligam bool protegido +f38; escrevem primary em+f40, secondary em+1164,
  radius em+1388; desligam bool+f3b e selecionam pose `shock`.
- Não escrevem +8c8 ou +d14, e o argumento de autor usado no ramo mobile
  não é consumido no ramo jewel.
- `43b7a0` testa um círculo. `43af40` amostra uma sequência de círculos até
  Y<0, com X+=arg3 e Y−=passo; arg3=0 usa passo=radius, caso contrário
  q(radius*7,read(e9ba40)). Y inicial é limitado à altura do mundo.

Oráculo executou as duas rotinas e confirmou ausência de dano/transferência
imediata. A inspeção integral de `479ba0`, `4785f0` e `450730` mostra que o
tick de Jewel não consome f38/f40/1164/1388 como resistência:4785f0 alinha
inclinação/superfície e450730 avança EPA; quando a sequência termina o tick
seleciona `normal`. Logo não aplicar por analogia o dano de shock dos mobiles
ao Jewel. Essa conclusão temporal é estática; a matriz não roda o tick
completo e não afirma execução dinâmica do jogo Windows.

Os chamadores exatos estão em q01/*entry-refs.tsv. `43b7a0` é chamado por
`46e5a0` em46f0d4; `43af40` tem chamadores em múltiplas famílias/caminhos, incluindo
435055 e ataques48xxxx/49xxxx/4axxxx. A investigação aqui fecha o consumidor,
sem garantir que todos os48 tiros cheguem a ele: a integração deve preservar
as distinções existentes de minas, terreno, ghosts e efeitos anexos. Qualquer
auxiliar que entre pelo dispatcher450eb0 usa a mesma fórmula Jewel com seu
próprio shell preparado, sem herdar Force/autor por suposição.

## Reprodução e validação

Banco exclusivo `/tmp/gb-jewel-impl-damage`; Ghidra12.2/JDK26.0.1. q01–q03
incluem run.json/manifest/ASM/C/refs/logs; todos `ok=true`, source_unchanged,
sem timeout. VAs internas40d9ba/450f56/46f0d4/435055/478120 foram resolvidas
às entradas existentes, **nenhuma função foi semeada**.478120 está dentro
do destrutor4780e0, não é consumidor de shock.

`tests/tools/jewel_oracle/damage_oracle.py` importa o harness PE existente
`grub_oracle/emu.py`; exige Unicorn2.1.4 instalado fora do projeto. Executa
instruções originais, incluindo helpers de células protegidas e conversor
x87. Stubs: critical sections, RNG determinístico de ofuscação, malloc e
apresentação de número/pose. Não substitui geometria, dano ou autoria por
fórmula Python. A reconstrução Python apenas audita os resultados nativos.

```
/tmp/gb-jewel-damage-oracle-env/bin/python tests/tools/jewel_oracle/damage_oracle.py \
  --pe /Users/guichafy/Workspaces/DemoGame/.tools/mobile-animation-port/GunBound.gme \
  --output /tmp/jewel-damage-regenerated.json
cmp /tmp/jewel-damage-regenerated.json docs/jewel-implementation/damage/damage-fixtures.json
```

No host desta sessão, Unicorn recebe SIGILL no primeiro mem_map dentro do
sandbox (também no teste mínimo sem PE e com Python3.13). A mesma chamada
fora do sandbox, aprovada pela revisão automática, executa normalmente.
Isso não constitui falha da imagem PE nem autoriza substituir os esperados.

Resultados:339 blasts (300 casos com Random seed478 e39 limites/fatores/
material/autoria/drop),16 contatos de hitbox e7 aplicações shock nas duas
rotinas. Todos339 resultados PE coincidem com reconstrução ASM independente.
As fixtures são `damage-fixtures.json`; limites include raio39/40/41,
X−10/X+10 eY−20/Y, dimensões ímpares/zero, aspecto0/negativo, força ímpar,
truncamentos consecutivos, três materiais com triplos distintos, dano nulo,
removed1/2, global block, overkill e autoria0/255.

Limites: não valida vida/morte/respawn do piloto, ordem de todos efeitos do
tick, RNG de spawn, vitória, Gold/XP, som, GPU ou cliente Windows completo.
Não foi executado harness Godot por não haver alteração de runtime nesta
subtarefa. O coordenador integra fixtures/testes e declara adaptações.

## Complemento: porte de queda, vento, apoio, ângulo e clock EPA

Na etapa de implementação autorizada, `damage_tick_oracle.py` executou também
`479ba0`, `4785f0` e `450730` sobre14cenários/355ticks, com stubs apenas de
API de terreno por coluna, atribuição de EPA na apresentação e RNG de escolha
de áudio. Os bytes das LUTs seno/ângulo em memória PE foram comparados aos
assets pinados antes dos cenários. `damage-tick-fixtures.json` substitui a
limitação anterior de ausência de emulação do tick para esses comportamentos;
placar/recompensa no tick e cliente Windows completo continuam fora do oráculo.

- Apoio usa superfície `(x,y−15)`, `y+fall>=surface`, `0<x<width`.
  Fall<5 gravaY=surface e zera velocidade/drift; pose `drop` vira `normal`
  mesmo se a flag de entrada já estiver limpa. Fall>=5 grava
  Y=surface−**velocidade anterior**, reinicia velocidade1 e zera drift.
  Essa primeira batida limpa a flag de entrada quando surface<altura;
  a pose `drop` pode continuar até o apoio lento posterior.
- Sem apoio: se pose era normal, seleciona drop e copia o último autor
  global de terreno. Incrementa velocidade inteira antes de avançarY.
  Somente com flag de entrada ligada, soma `3*trunc(windForce*sin32(angle+90))`
  ao acumulador lateral; X avança por divisão signed/100 e preserva resto
  signed. Vento deixa de deslocar quando essa flag limpa.
- `4785f0` mantém ângulo0 durante entrada. Depois mede superfícies com
  origemY−10 emX,X−10,X+10. O limiar para corrigir abismos laterais é
  center+20. Se ambos lados passam disso, nivela ambos ao centro; se só
  um passa e o outro está abaixo do limiar, reflete em2*center−lado.
  Usa vetor(20,right−left), divide ambos por2 com truncamento até caber
  −127..128, e lê o short exato da LUT; **não** quantiza em3graus.
- `450730` avança EPA após movimento/ângulo. Duração e flag vêm do catálogo
  XFS pinado; todos os estados atuais têm20ticks, normal/drop flag1 e os
  restantes flag0. Loop reinicia quadro0; sequência terminada faz o tick
  selecionar normal/quadro0. Não há prazo arbitrário por nome de pose.

`jewel_rules.gd` aquece as LUTs e o catálogo uma vez em create/warmup,
antes do worker. Estado privado inclui drift, fall, pose_tick, relógio
fracionário, RNG e eventos. `state.wind` é força nativa inteira;
`state.wind_angle` é ângulo nativo emgraus. `state.terrain_owner` é o último
causador da remoção de apoio, default−1. `state.teams` mapeia autores válidos
para times0/1; autores fora desse array, incluindo255, não pontuam.

TDD registrado: primeiro módulo ausente1falha; após núcleo398/0; eventos/
pose_tick RED2falhas→GREEN403/0; fixtures completas de tick RED240falhas→
GREEN758/0. Logs em.tools/jewel-rules-*. O erro ambiental de CA apareceu nos
primeiros processosGodot e sumiu após o import/cache compartilhado; nenhuma
SCRIPT ERROR na suíte dedicada final. O coordenador executa regressão integral
junto da integração, que ainda pode estar sendo modificada em paralelo.
