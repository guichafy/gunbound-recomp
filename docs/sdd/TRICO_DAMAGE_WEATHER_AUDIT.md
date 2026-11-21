# Auditoria do dano do Trico T2 com Tornado e do SS com Force

Base de execução `a47b715709203598b7a01173d2672c4d62a5368b`, Godot 4.7.2.
Requisitos relacionados REQ-04, REQ-05, REQ-07, REQ-08, REQ-44 e REQ-45.
A [ADR-163](TRICO_SPECIALS_ISSUE_30.md) documenta o porte da órbita do T2
e da sequência do SS e as adaptações de dano, cratera e clima. Este
relatório registra os resultados da investigação.

## Reprodução no Godot

As sondas usam `Match.fire` e conferem, por tick, eventos, projéteis,
atores e terreno contra um `FlightSnapshot` armado separadamente.
Os dez replays terminaram com as duas rotas idênticas. A tabela registra
o evento bruto e a redução efetiva de HP do alvo, que começou sem escudo.

| Tiro e alvo | Clima | Ataque / Defesa | HP inicial | Dano publicado | HP perdido |
|---|---|---:|---:|---:|---:|
| T2 → Raon | Tornado | 0 / 0 | 300 | 2.545 | 300 |
| T2 → Raon | Tornado | 0 / 0 | 1.050 | 2.545 | 1.050 |
| T2 → Raon | Só vento | 0 / 0 | 1.050 | 256 | 256 |
| T2 → Raon | Tornado | +50 / −50 | 1.050 | 5.090 | 1.050 |
| T2 → Raon | Tornado | −50 / +50 | 1.050 | 0 | 0 |
| SS → Armor | Force | 0 / 0 | 300 | 1.865 | 300 |
| SS → Armor | Force | 0 / 0 | 1.000 | 1.865 | 1.000 |
| SS → Armor | Só vento | 0 / 0 | 1.000 | 1.506 | 1.000 |
| SS → Armor | Force | +50 / −50 | 1.000 | 3.730 | 1.000 |
| SS → Armor | Force | −50 / +50 | 1.000 | 0 | 0 |

Reprodução a partir de `tests/tools/shot_damage_audit/weather_probe.gd` e
`probe.gd`. Use o terreno plano com chão em Y=500, seed 42, carga de 35%,
vento 13 a 60° e atributos neutros. No T2, mire a 10° para a direita, use
Trico em X=200, Raon em X=500 e coluna Tornado de largura nativa 97
em X=244. No SS, mire a 20° para a esquerda, com Trico em X=1.080, Armor
em X=780 e a coluna Force de largura nativa 97 em X=1.037. Os controles
preservam o vento e retiram a coluna. Os casos com HP integral restauram
`max_hp` antes do disparo.

### T2 com Tornado

Os três componentes entram no Tornado no tick 7 do Godot. O único dano
sai do componente 1 no tick 31, em (499, 479), a √2 pixels do centro da
caixa legada do Raon, (500, 480). O caminho em
`Match.explode → Damage.blast → Combat.blast_damage` publica
`int(150 × 24 / √2) = 2.545`. Os outros impactos, em (539, 500) e
(601, 500), ocorreram após o alvo chegar a zero HP. No controle só com vento, o
componente 1 cai em (486, 479) e publica 256, com a mesma potência 150.

O inicializador x86 `0x41da80` dá potência 150, dimensão 48 e aspecto
134 a cada componente neutro, com divisor 3. Com Ataque −50 / 0 / +50,
as potências isoladas são 100 / 150 / 200. A execução do consumidor
`0x45db20` nos três pontos do replay, com o corpo nativo de Raon,
retorna 85 / 0 / 0 no neutro. A sonda fixa a origem do alvo em
(500, 480) e calcula o centro de dano nativo em (500, 468). O controle
exatamente no centro retorna 127. Mantido
o primeiro ponto, os nove cruzamentos dos três níveis de Ataque e Defesa
dão de 30 a 168. O neutro deu 85 em cada um dos três materiais exercitados.

A rota do Tornado também altera o ponto que chega ao cálculo de dano.
No cliente, `0x4a2ce0` usa `0x455cc0` para amostrar a varredura do
ponto publicado. A saída dos orbitais usa o X publicado. O caminho do
Trico em `Match.advance_projectiles` passa um dicionário vazio à
consulta de contato e consulta o clima antes do movimento pelo centro
do projétil. A saída do Tornado em `AdukaWeather.finish` também usa
o centro para o Trico. Em uma segunda sonda, sem terreno nem atores,
os estados iniciais foram iguais no PE e no Godot. Posição inicial
(215, 350), velocidade (1.800, −400) e aceleração (15, 222) em 24.8
para os vetores, fase inicial 45°/225° nos orbitais, passo −8°,
raio inicial 2 e coluna em X=244 com largura 97. No neutro, os 48
registros dos três componentes em 16 ticks coincidiram em posição
central, publicada e velocidade. Com Tornado, os 48 estados diferiram.
O PE aplicou a coluna no tick 1, com primeira reversão nos ticks 6, 1
e 8 para os componentes 0, 1 e 2. O Godot aplicou a coluna nos três no
tick 2 e reverteu os três pela primeira vez no tick 8.

### SS com Force

A coluna eleva a potência legada do portador de 256 para 317
(`int(256 × 1,2 + 10)`). O contato inicial em (794, 500) no tick 25
arma o SS. O Godot clona o dicionário do portador para cada filho,
incluindo a potência 317. O primeiro filho explode no tick 27 em
(782, 475), a √104 pixels do centro legado do Armor, (780, 485).
O raio 60 produz `int(317 × 60 / √104) = 1.865`. Os oito pontos
coincidem com os do controle só com vento. Nessa rodada, o primeiro
filho tem potência 256 e publica 1.506. Os dois casos já esgotam a
vida do Armor no primeiro impacto.

No PE, `0x4ad230` arma a ação retardada, `0x4acd10` chama a fábrica
`0x431d90` e a fábrica inicializa cada filho novo com `0x41da80`.
O argumento copiado de `+0x17e4` é o percentual de base/item.
O acumulador Force em `+0x15c0` é um campo distinto. Na execução
x86, 16 combinações deram 128 filhos com Force 0, inclusive com o
portador em Force 20 e 100. Percentuais de base 100 e 125 chegaram
aos filhos. Com Ataque 0, cada filho tem potência 128, dimensão 60 e
aspecto 120. Uma sonda separada de contato (`0x455cc0 → 0x4510f0`)
confirmou que o portador pode acumular Force. Na coluna do cenário, as
amostras aceitas vão de X=1.014 a 1.060. Na varredura controlada de
passo 8, o acumulador começou em 20, subiu de 8 em 8 e saturou em 100.
O percentual de base do portador ficou em 100.

Armado no mesmo impacto inicial, o PE reproduziu os oito pontos do
Godot na ordem observada, (782, 475), (770, 524), (809, 476),
(802, 477), (805, 497), (813, 509), (783, 514) e (770, 512).
Com Armor neutro, material 0 e alvo reposto antes de cada consulta,
a sonda fornece (780, 475) como origem do alvo ao PE. O corpo
nativo de altura 24 posiciona seu centro de dano em (780, 463).
O consumidor de dano deu **74, 0, 33, 45, 0, 0, 0, 0**, iguais com
Force 0, 20 e 100 no portador. No primeiro ponto, Ataque/Defesa de
50/0, 0/50 e 50/50 deram 118, 39 e 62. Dois controles confirmaram
que os campos têm efeito próprio. Com base 125 e Force 100 no
portador, o primeiro dano foi 93. Com base 100 e Force 100
injetado diretamente no filho, foi 111.

## Classificação

| Comportamento | Status | Evidência e localização |
|---|---|---|
| Base neutra do T2 e movimento sem coluna no estado controlado | **Fiel** | O PE `0x41da80` e os três componentes em `Match.shot_shells` começam com 150. O passo de `TricoFlight` reproduziu os 48 estados sem coluna. |
| Contato com Tornado e atenuação do T2 | **Adaptação** | A ADR-163 preservou clima e dano legados. O segmento publicado de `0x4a2ce0 → 0x455cc0` diverge da rota de `Match.advance_projectiles → AdukaWeather.finish`. Em (499, 479), `0x45db20` deu 85 e a rota legada via `Combat.blast_damage` publicou 2.545. |
| Calendário e pontos dos oito filhos do SS | **Fiel** | `0x4ad230 → 0x4acd10` e `TricoFlight.tick_ss` produziram os mesmos pontos a partir do impacto controlado, nos ticks relativos 2, 4, 6, 8, 10, 12, 14 e 16. |
| Potência e atenuação dos filhos do SS | **Adaptação** | O filho inicializado por `0x431d90 → 0x41da80` tem potência neutra 128. `Match.advance_projectiles` duplica o portador de potência 256 no controle sem coluna e calcula a atenuação legada. |
| Cópia do bônus de Force para cada filho do SS | **Divergência comprovada** | `0x4acd10 → 0x431d90` cria filhos com Force 0. No Godot, `WeatherContact.apply` altera a potência do portador e `Match.advance_projectiles` duplica essa potência para todos os filhos. Com o mesmo vento e os mesmos pontos, a coluna eleva o primeiro dano publicado de 1.506 para 1.865. |
| Trajetória completa e dano acumulado da partida no cliente Windows | **Falta comprovar** | Os testes do PE isolaram inicialização, clima, ação retardada e dano. A sequência de dano do SS usa o Armor restaurado a cada consulta. |

## Proveniência nativa

REA 6.7.0 com `--provider ghidra`, Ghidra 12.1.4. A execução isolada
usou o PE x86 de Thor's Hammer e Unicorn 2.1.4. Os endereços são VAs.
Os extratos Ghidra identificam campos e chamadas. As comparações
numéricas, os estados do Tornado e a construção dos filhos foram
observados executando instruções do PE. As sondas de rotina substituem
serviços externos, como terreno ausente no teste de voo e apresentação
no teste de dano.

| Artefato | SHA-256 |
|---|---|
| `GunBound.gme` | `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde` |
| `characterdata.dat` | `b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf` |

| VA | Evidence ID do REA |
|---|---|
| `0x4a2ce0` | `ev_501439c75806d155eff4d6384be5d8bbc130be983eab7ce03304b9c375e2dfe2` |
| `0x4ad230` | `ev_cbe788bf0f2955727acd75a6455a8152b33b90f1e15c2d8c4a1d6e3c45364794` |
| `0x4acd10` | `ev_d80074767656acff1c9823aa0aaa7c5d085cf6792d0f05508201f27cd5487599` |
| `0x431d90` | `ev_047c10037064bff8bd959222ddbfe4c23f1e792152316b077bc6fae38630b482` |
| `0x451030` | `ev_e03af1fecf072e8f234238543c3193fb8c76db5cb900ac6e3bf5fa6723945599` |
| `0x4510f0` | `ev_90d43954df0f92b7e7aac553bbd25937a099a0007c4c2f3e07c8449713edf0e0` |
| `0x455cc0` | `ev_ae05d531a4ae6c8d94210ac5ba8cf59d618332e9ae0e2576c22bf0446356e01c` |
| `0x45db20` | `ev_7b8d629a5867eb95b25679ef734bd5b5ce94875034440e92726712b04f2ade27` |

## Matriz dos 48 tiros

Nova execução das [sondas de validação](SHOT_DAMAGE_VALIDATION.md#reproduzir)
a partir da base acima, antes da abertura do PR. A matriz de voo cruzou
16 mobiles × T1/T2/SS × 16 alvos × oito condições. As condições foram
neutro, Force, Tornado, Electricity, Wind, Thor, Protection e Ignorance.
As sondas dirigidas também variaram o lado do disparo e o vento.

| Etapa | Resultado observado |
|---|---|
| Lançamento | 423.417 verificações sem falhas, incluindo 394.200 pares de velocidade. |
| Impactos controlados no Godot | 172.032 observações em 6.144 combinações de tiro, alvo e clima. Neutro, Force, Electricity e Thor cruzaram Ataque e Defesa em −50, −1, 0, 1, 25, 49 e 50. |
| Voo com todos os alvos | 6.144 cenários e 43.776 verificações sem falhas. Execução e previsão coincidiram em todos os cenários. |
| Voo dirigido e calendário | 1.154 cenários, 12.378 verificações e 792 turnos de calendário sem falhas. |
| Mapas e itens | 1.302 cenários e 10.576 verificações sem falhas, com 22 lados de mapa e 1.280 casos de itens. |
| Consumidor comum isolado | 79.872 comparações PE/Godot sem diferença de dano, HP ou escudo. Mais 9.696 comparações sem diferença, variando um atributo por vez de −50 a +50. |
| Controles do Armor no PE | 625 casos isolados de dano e sete segmentos de contato. |
| Regressões focais do Godot | Trico T2 4.043/0, Trico SS 394/0, replay de dano 42/0, em verificações/falhas. |

O comparador do consumidor comum fornece os mesmos dados de entrada aos
dois cálculos. Ao comparar o ponto central no fluxo atual do jogo com
esse oráculo, o resumidor encontrou 31.517 diferenças em 51.744
observações comparáveis. A grade do Trico T2 incluiu 768 diferenças em
784 comparações de centro, e a do SS, 784 em 784. A matriz ampla usa
divisores controlados para famílias sem emissão nativa exercitada
nessa sonda. Para o Trico, as sondas dirigidas acima exercitam o divisor
real do T2 e a fábrica real dos filhos do SS.
