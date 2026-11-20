# Correção de contato e dano do Armor T1

REQ-04/05/07/08/19/23–26/35–38/44/45/52 e REQ-JEWEL-46. Seguimento da
[execução inicial](SHOT_DAMAGE_VALIDATION.md), commit `7627e37d` do PR #65.

## Resultado dos replays

| Cenário | Contato corrigido | HP perdido no Godot |
|---|---|---:|
| Degrau, Bigfoot, atributos zerados | `(237,452)` | 149, antes 626 |
| Miramo Town A, Bigfoot, atributos zerados | `(390,1375)` | 158, antes 667 |
| Degrau, Bigfoot, Ataque +50, Defesa −50, Force inicial de 20 | `(237,452)` | 392 |
| Degrau, Bigfoot, Ataque −50, Defesa +50, sem Force | `(237,452)` | 25 |
| Degrau, Knight em ação normal, atributos zerados | `(237,452)` | 121 |

As quatro primeiras linhas e a linha de Knight foram conferidas com os
operandos do PE e coincidiram com seus snapshots. A previsão pública do
degrau retorna o mesmo pixel e preserva os atores, o terreno e os eventos
na origem. No trecho neutro do degrau, um tick do PE executado em Unicorn
usou o mesmo segmento, a mesma rotina de seleção de corpo e o mesmo
consumidor de dano. No caso Miramo, a caixa e o trecho gravados foram
transladados na sonda do PE e o centro foi fornecido com a mesma geometria
da ponte Godot. O oráculo assinado injeta Ataque, Defesa e Force no cálculo.
O deslocamento do cano e a trajetória completa continuam sendo do porte.

## Evidência de implementação

| Comportamento | Evidência e integração |
|---|---|
| Emissão | Ação 5 no tick 2 de `44e920` chega a `42bbb0` e `41da80` com tipo 0, arma 0 e divisor 1. As três células de material são iguais no DAT fixado. Potência `210 + 3 × Ataque` e dimensão `68 + trunc(Dig/2)`, aspecto 144 e flags 8. |
| Contato | O construtor `454dc0` publica a vtable `555c34`. O tick `4572b0` usa o segmento 24.8, chama `455cc0` com passo 8 e escreve o pixel de contato antes de remover o projétil. `450e10 → 45d640` testa o corpo. O Godot compartilha a máscara 1 px, a varredura e a atualização do contato entre partida e snapshot. |
| Clima | O sweep consulta Force, Tornado e Eletricidade. O primeiro acúmulo de Force é 20 e o dano usa a metade do acumulador como percentual. O tick dispara `43af40 → 431d90` para Eletricidade, depois `432320` para Thor se o clima atual for o 4, e resolve a cratera e a explosão principal. A sonda x86 confirma a ordem com registros de chamada e stubs para o dano dos anexos. |
| Explosão | `4e4970` dispara a escavação e `450eb0 → 45db20` aplica o falloff inteiro, a vulnerabilidade ajustada pela Defesa e a absorção por escudo. O flag de `450eb0` seleciona a busca de minas do Raon. O Godot reutiliza esses consumidores e entrega a mesma carga à rota de joias. |

REA 6.7.0 com provedor **Ghidra 12.1.4** no mesmo
[PE e DAT fixados](SHOT_DAMAGE_AUDIT.md#proveniência-da-auditoria).

| Rotina | Evidence ID |
|---|---|
| `44e920` | `ev_0b636c9de7b98022ea50f41e95abcfaf216baffbe27d42e8623e2f2e6877d33b` |
| `42bbb0` | `ev_bdb645a9da2dd6f76a0a6268e148953c829e7cc56f266f24a50af49cbaf9ad8f` |
| `454dc0` | `ev_289167e50929d7d3bba12eb0a235c1f6d3336816728158db659e6da4ede391f9` |
| `4572b0` | `ev_9874aa172d9fbb728453e374f18241e205e6bd5d0bdc4dc816b4c34d7c3a7800` |
| `450e10` | `ev_08b54d2fb50a10a8d9dd4323edfd3ee796fa370038d7b8e8d0e27b6de9cfaac6` |
| `45d640` | `ev_4386a6fe7eb139b73f4d0c2b9ba61d06bf812e4edc70bb1660ffdb49fd9c8e25` |
| `450eb0` | `ev_5381353284b559720ee720f85779396d00b5ed300ae58715775bce27b813c88d` |
| `45db20` | `ev_7b8d629a5867eb95b25679ef734bd5b5ce94875034440e92726712b04f2ade27` |

## Knight como alvo

A matriz inicial escreveu o tipo do mobile no offset errado. O construtor
`42b0b0` grava o tipo na célula protegida `+0x1a2c`; `461c60 → 401610` resolve
uma ação do EPA e salva o índice em `+0x24`. A comparação de `45db20` em
`45db69` lê `+0x24`. O índice 14 significa `dead` e o índice 0 significa
`normal` nos 16 EPAs do `graphics.xfs` fixado (SHA-256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`). As 4.586 diferenças da
execução inicial eram um artefato da preparação do Knight como `dead`.

Com os dois campos separados e a busca de corpo nativa, ambos os alvos
colidiram em `(237,452)`. Na mesma geometria controlada, o Bigfoot em
`normal` calculou 149 e o Knight em `normal` calculou 127. No replay Godot
acima, o centro do Knight estava 2 px abaixo do centro desse controle,
resultando nos mesmos 121 calculados pelo PE com esse deslocamento. Ao
forçar apenas a ação `dead`, o PE preservou HP e escudo em ambos, mesmo
mantendo o bit de atividade no teste. No impacto centrado com escudo de 30,
Armor calcula 184 sobre Knight `normal` e o HP cai de 1000 para 846. A
suíte verifica também o dano sobre Knight com Eletricidade e Thor.

| Rotina | Evidence ID |
|---|---|
| `461c60` | `ev_b737914edb56bce37eb3f9bea11ddcdae0a38d6d085f5d267827e42aa35f5711` |
| `401610` | `ev_4e9df7fc6931d0e62f565f8b55f5304c744faf7158b75dee84f4e335f452533a` |
| `4759b0` (Ice SS) | `ev_6c3f88e1484a8e93cfb0c2aef9b2fda6007f719296cdb33fa825c05db8ef406e` |

O teste separado de Ice confirma uma divergência pré-existente do jogo.
O Godot exclui Knight de Ice T2/SS por ID de mobile. No PE, o tipo 14 com
EPA `normal` recebeu dano de Ice T2 e vulnerabilidade `[0,0,5,0]`, e SS
aplicou `[5,5,5,5]`. O gate de `dead` se aplica a qualquer tipo. A supressão
de pose de Ice T2 também lê ações EPA, hoje aproximadas por ID no Godot.
Esses caminhos de Ice ficam para uma correção própria.

## Repetir a matriz

Usar os [comandos de reprodução da execução inicial](SHOT_DAMAGE_VALIDATION.md#reproduzir)
com os scripts desta branch. `--armor-contact-only` inclui Miramo, Knight
com o centro do replay e os casos assinados. A matriz do consumidor comum
usa ação 0 para todo o elenco e registra os controles explícitos de ação 14.

## Matriz repetida

| Ensaio | Resultado |
|---|---:|
| Lançamento, força, Slice e Drag | 423.417 verificações, zero falhas |
| Consumidor comum, 48 armas e 16 alvos | 79.872 resultados iguais no dano calculado, HP e escudo |
| Eixos de Ataque e Defesa de −50 a +50 | 9.696 resultados iguais no dano calculado, HP e escudo |
| Impactos controlados, oito estados de clima | 172.032 observações, 3.584 alterações, todas de Armor T1 |
| Voo dirigido em ambos os sentidos | 1.154 disparos e snapshots, 12.378 verificações |
| Voo de 48 tiros × 16 alvos × oito estados de clima | 6.144 disparos e snapshots, 43.776 verificações. 2.460 voos tocaram um mobile. Os 128 registros alterados são de Armor T1. |
| Voo em mapas e com itens | 22 lados, 1.280 casos com itens e clima, 10.576 verificações |
| Calendário | 792 turnos em 44 combinações de mapa e modo |

As três matrizes de voo terminaram com todos os snapshots iguais à
execução e zero falhas. Os estados de clima incluem sete categorias e
neutro. A matriz de impactos cruzou os sete valores selecionados de
Ataque e Defesa em neutro, Force, Eletricidade e Thor. A comparação de
impactos centrais com entradas de mesmo nome contém 31.615 valores
diferentes em 51.744 pares. Esses pares podem exercitar estágios distintos
em armas especiais, como guia, mina ou feixe, e servem para triagem.
[Resultados por arma e rastros](armor-t1-combat-validation.json).

## Verificação antes do PR

O harness oficial executou 422 verificações de parse, 92.965
assertivas GDScript e 103 partidas completas, com 29 de SOLO, 44 de mapas e
30 de JEWEL. Os 262 testes Python passaram, com cobertura de 63% em
`scripts/ci`. O processo encerrou com `FAILED: []`. A regressão dirigida
terminou com 42 assertivas sem falhas. O pacote local macOS passou nas rotas
de smoke de 48 tiros, mapas e JEWEL. Ruff e `git diff --check` passaram.

## Limites do porte

A ponte offline de itens aplica o percentual de Ataque e de cratera uma
vez. Os objetos especiais e os 44 produtores amostrados com divisor
controlado continuam fora da comparação completa com o PE. A busca comum
herda a conversão de pose/apoio e não recorta partes da caixa de um ator
inclinadas para fora do mapa como `450e10` faz. A explosão elétrica anexada
mantém a ponte de JEWEL dos demais consumidores de Eletricidade, que aplica
a pose do choque em joias sem encaminhar seu blast ao consumidor de joias.
O cliente Windows completo não foi executado.
