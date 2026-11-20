# Ice T2 e SS contra Knight

REQ-04/05/07/08/09/19/20/38/44/45/52. Seguimento de
[ARMOR_T1_COMBAT.md](ARMOR_T1_COMBAT.md#knight-como-alvo) e emenda à ADR-162.

1. Separar o tipo protegido `+0x1a2c` da ação EPA `+0x24` no oráculo.
   Comparar Knight normal, disparando, morto e intangível no PE fixado.
2. Aplicar dano e vulnerabilidade aos alvos vivos elegíveis. Usar a reação
   de disparo corrente para o filtro visual de T2 e do blast comum de SS.
   Preservar a ação de gelo da área própria de SS durante o disparo.
3. Conferir o passo comum da partida e previsão, os limites de escudo, HP
   e área e a matriz dos 48 tiros com clima, Ataque e Defesa antes do PR.

## Regras confirmadas

| Estado do Knight | T2 | SS |
|---|---|---|
| Ação `normal`, impacto no centro, HP 1000 e escudo 30 | Dano 260, HP 770, escudo 0. Vulnerabilidade `[0,0,5,0]` e uma ação `ice`. | Dano 294, HP 736, escudo 0. Área aplica `[5,5,5,5]` e `ice`. |
| Ações EPA 5, 6, 8 ou 10 | O mesmo dano e a mesma vulnerabilidade. A pose de disparo continua. | A explosão preserva a pose de disparo. A área emite `ice` e aplica a vulnerabilidade. |
| Ação EPA 14 (`dead`), inativo ou intangível | Sem dano, vulnerabilidade ou pose. | Sem dano, vulnerabilidade ou pose. |

Todos os 16 EPAs usam `normal=0`, `fire1=5`, `fire2=6`, `ifire=8`,
`sfire=10` e `dead=14`. A construção grava o tipo em `+0x1a2c`.
`461c60 → 401610` grava a ação em `+0x24`. O oráculo antigo usava o tipo
como índice de ação e acabava colocando o Knight no estado `dead`.

`474650` entrega `[0,0,5,0]` a `450eb0 → 45db20`. O vetor entra antes da
aplicação a HP/escudo, mesmo quando todo o dano vai para o escudo.
`45e7d7` escolhe `ice` como a única reação do T2. O filtro compartilhado
`45e883` suprime a reação durante as ações de disparo. No SS, `4759b0`
chama o blast `48de60` primeiro. A área estrita de `425ac0` é centrada no
hotspot menos 10 no Y. Em 129 px funciona mesmo sem dano, em 130 px já
fica fora. O blast usa a vulnerabilidade anterior. Depois a área pode
reduzir cada campo ao teto 20. No caso combinado de Knight sem inclinação e com
`[20,21,49,50]`, a sonda mediu 414 de dano antes de chegar a `[20,20,20,20]`.
A validade de vivo é mantida entre o blast letal e o efeito de área no
mesmo impacto. Em JEWEL, o T2 modifica o estado, com HP e escudo intactos.

REA 6.7.0, provedor Ghidra 12.1.4, no
[PE, DAT e XFS fixados](ARMOR_T1_COMBAT.md#evidência-de-implementação).

| Rotina | Evidence ID |
|---|---|
| `474650` (T2) | `ev_7ebdf07e99bc5fc4a6dbb0bfa995b821adea7f3d24f7103d1bdf76ad1ead79b0` |
| `45db20` (dano, estado e reação) | `ev_7b8d629a5867eb95b25679ef734bd5b5ce94875034440e92726712b04f2ade27` |
| `4759b0` (SS) | `ev_6c3f88e1484a8e93cfb0c2aef9b2fda6007f719296cdb33fa825c05db8ef406e` |
| `48de60` (blast inicial do SS) | `ev_ab19fb63fd2813d8d3c5764a3f03c14c050725e013475d9ab62df60544630d33` |
| `425ac0` (raio de área) | `ev_f9a5ac294c606c0007c61832a375450797a26f56b7aaeda6eea429db470c58b5` |
| `461c60` (ação EPA) | `ev_b737914edb56bce37eb3f9bea11ddcdae0a38d6d085f5d267827e42aa35f5711` |

## Integração no Godot

`IceEffects.eligible` usa vida estampada e invulnerabilidade. O tipo do
mobile só identifica a geometria, vulnerabilidade e recursos. `Match`
resolve escudo, HP e campos tipados para partida e snapshot. O T2 emite uma
solicitação de gelo e os eventos de dano continuam disponíveis para HUD e
Gold sem gerar uma segunda reação de ferimento. `BattleArt` conserva o
recoil ativo no T2 e no blast comum do SS. A reação de área do SS pode
interromper o recoil.

O relógio de apresentação existente representa `fire1`, `fire2` e `sfire`
por `recoil`, sem faixa própria de item-fire (`ifire`) e com entrega de
eventos no quadro visual. A sonda x86 cobre `ifire`. O porte não recalcula
um relógio EPA dentro da simulação. A apresentação da explosão comum de SS
mantém os eventos usuais de dano e escudo. A balística e a ponte de clima
existente de Ice permanecem no escopo medido, sem alegação de paridade dos
produtores especiais ou de execução do cliente Windows completo.

## Reproduzir

Regenerar a fixture com o PE e DAT locais fixados e Unicorn 2.1.4.

```sh
set -e
python3 tests/tools/ice_oracle/generate.py
godot --headless --path . --script tests/test_ice_effects.gd
```

Repetir os [comandos da matriz](SHOT_DAMAGE_VALIDATION.md#reproduzir).
A matriz gera os resultados por tiro, alvo, clima e atributos. A fixture
separa o tipo e a ação no estado x86 e registra as invocações de pose.

## Matriz repetida antes do PR

Base `9f042861` em `main`. A matriz usa 48 tiros, 16 alvos, sete climas e
neutro. Ataque e Defesa são cruzados em sete valores nos impactos com
neutro, Force, Eletricidade e Thor. A varredura adicional cobre todos os
inteiros assinados de −50 a +50 em cada eixo. O oráculo comum usa uma
ação EPA normal para todo o elenco.

| Ensaio | Resultado |
|---|---:|
| Lançamento, potência, Slice e Drag | 423.417 verificações sem falhas |
| Consumidor comum x86 | 79.872 comparações iguais em dano, HP e escudo |
| Eixos assinados adicionais | 9.696 comparações iguais em dano, HP e escudo |
| Impactos controlados | 172.032 observações. 208 mudanças em Ice T2 e 209 em Ice SS, todas contra Knight. |
| Voo dirigido, ambos os sentidos | 1.154 voos, 12.378 verificações |
| Voo dos 48 tiros contra todos os alvos e climas | 6.144 voos, 43.776 verificações e 2.460 voos com contato direto. Um registro mudou, Ice T2 contra Knight. |
| Voo em mapas e com itens | 22 lados, 1.280 combinações de itens e clima, 10.576 verificações |
| Calendário | 792 turnos em 44 combinações de lado e modo |

Os voos coincidiram com os snapshots e terminaram sem falhas. No
levantamento comparativo de impactos centrais, 31.517 dos 51.744 pares
usam resultados numéricos diferentes. Esses pares ainda podem comparar
diferentes estágios de armas especiais. O cruzamento serve para triagem.
[Resultados por tiro](ice-knight-epa-validation.json).

A verificação dirigida terminou com 363 assertivas sem falhas. A fixture
x86 foi regenerada com bytes idênticos após passar a ler o registro de
Defesa do Knight do DAT. A captura GPU verificou T2 contra Knight parado
e disparando e SS contra Knight disparando, nos dois sentidos. Foram 105
quadros em 1920×1080, com 30 quadros pausados idênticos. O smoke do pacote
macOS extraído cobriu os 48 tiros, mapas e JEWEL. Ruff e `git diff --check`
passaram.

O harness executou 422 parses, 93.028 verificações GDScript e 103
partidas completas, com 29 de SOLO, 44 de mapas e 30 de JEWEL. Passaram
os 262 testes Python, com cobertura de 63% em `scripts/ci`. O agregado
registrou uma falha de fixture em `test_ice_effects`: a posição estava
correta, mas a inclinação do terreno procedimental diferia do controle
x86 de inclinação zero. A suíte corrigida passou com as 363 assertivas no
mesmo runner e em perfil isolado. As outras verificações e as partidas
executaram o runtime final.
