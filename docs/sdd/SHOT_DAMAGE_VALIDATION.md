# Execução da matriz de combate dos 48 tiros

Registro histórico. O [seguimento](ARMOR_T1_COMBAT.md) corrige contato e dano
do Armor T1 e invalida a conclusão de imunidade do Knight. Os 4.586 casos
abaixo refletem a injeção do tipo do Knight no campo de ação EPA.

Base `0a917667`. Escopo e critérios em [SHOT_DAMAGE_AUDIT.md](SHOT_DAMAGE_AUDIT.md).
Usar o cliente Thor’s Hammer fixado, REA com Ghidra e os oráculos x86 locais.
O disparo real e o snapshot são comparados no Godot. A matriz de comparação
usa cenários de impacto controlado para isolar o cálculo. O voo e os
efeitos que dependem de eventos futuros são medidos em sondas específicas.

1. Repetir o Armor T1 contra Bigfoot e reproduzir tanto os 626 HP quanto os
   valores do consumidor numérico isolado.
2. Cobrir os 48 tiros e os 16 alvos no Godot com Ataque e Defesa assinados,
   escudo, dano calculado e dano efetivamente perdido. Confrontar o
   consumidor comum com o PE.
3. Exercitar as sete categorias de clima, o controle neutro e a cópia do
   estado usado pela previsão. Distinguir efeito observado de mera presença
   em cenário.
4. Classificar cada mecanismo coberto e conferir as suítes associadas.

## Armor T1 contra Bigfoot

| Observação | Posição do impacto | Dano |
|---|---|---:|
| Godot, replay do degrau e snapshot, tick 3 | `(237.435150, 454.472412)` | 626 HP |
| PE `45db20`, entrada de contato do Godot truncada, centro nativo controlado `(250,461)` | `(237,454)` | 155 HP |
| PE `455cc0` e `45db20`, segmento 24.8 do Godot, caixa e chão controlados | `(237,452)` | 149 HP |
| Godot, máscara Miramo Town A e snapshot, tick 3 | `(380.301575, 1375.190430)` | 667 HP |

O caso Miramo usa Armor em `(340,1389)` e Bigfoot em `(388,1373)`, apoiados
em `y=1414` e `y=1398`, com mira de 10°, carga de 25%, vento nulo
e atributos zerados. O teste inicia o confronto pelo modelo normal.
A saída x86 usa o segmento gravado no Godot e um stub de consulta de corpo
com sua caixa controlada. Nenhum valor da tabela estima o resultado de um
voo completo do PE.

O inicializador do PE devolveu 60, 210 e 360 para Ataque −50, 0 e +50.
A vulnerabilidade de Bigfoot foi 140, 100 e 60 para Defesa −50, 0 e +50.
Com Ataque +50, Defesa −50, Force 100 e impacto central, o PE aplicou 756 HP
na sonda controlada. As condições completas importam ao interpretar valores
acima de 600. O caso neutro do Godot continua aberto.

## Evidência e cobertura

| Ensaio | Observações | O que foi comparado |
|---|---:|---|
| Lançamento base | 7.300 vizinhanças de potência, 21.900 células Slice/Drag, 394.200 pares 24.8 | Todos os tiros, duas direções, três inclinações controladas e três ângulos. Esperados usam a LUT e os limites do PE. Os offsets e filhos são avaliados pelas suítes de família. |
| Consumidores x86 | 625 casos de Armor, 79.872 entradas comuns, 9.696 entradas nos eixos assinados | Ataque e Defesa na inicialização, Force acumulado, fronteiras do raio e queda de HP e escudo. A varredura de um atributo por vez passa por todos os inteiros de −50 a +50. |
| Comparação do consumidor compartilhado | 75.286 iguais, 4.586 diferenças | Entradas do PE no consumidor Godot, com corpo e contato controlados. As 4.586 diferenças de valor e estado ficaram no Knight. A varredura adicional com Bigfoot como alvo teve 9.696 iguais. |
| Impactos Godot | 172.032 observações em 6.144 combinações de arma, alvo e clima | Primeiro componente no ponto controlado. Centro, interior, referência de borda e erro distante. Em neutro, Force, Electricity e Thor, cruzamento dos sete valores efetivos de Ataque e Defesa. |
| Voo e clima, sonda dirigida | 1.154 disparos e snapshots, 12.378 verificações | Todas as armas nos dois sentidos, sete climas, controle neutro e vetores adicionais de vento. Inclui controles de Nak SS com alvo elevado. |
| Voo e clima, matriz por alvo | 6.144 disparos e snapshots, 43.776 verificações | Um sentido por arma, alvo e condição. Houve pelo menos um contato direto com mobile em 2.460 voos. Os miss e efeitos de área permanecem identificáveis. |
| Voo em mapas e com itens | 22 voos pelos lados nativos, 1.280 combinações de itens e 10.576 verificações | Armor T1 iniciou nos 22 mapas. Dual, Dual+, Thunder, Teleport e Bunge com T1/T2 dos 16 mobiles, sete climas e neutro. Eclipse bloqueou os itens. Teleport preservou o multiplicador de vento zero. |
| Calendário | 792 turnos em 44 combinações de lado e modo | 22 lados, modos Original e Todos, fronteira 7→0, estado do Thor e 195 criações de colunas dentro das faixas do DAT. |

O oráculo chama `41c360`, `41da80` e `45db20`. As três células de potência
do Armor T1 são 210. Para a matriz comum, a seleção de material é 0 e a
inclinação é fixa. O corpo inicial dos 16 alvos é gerado pelo PE. Os
divisores de inicialização são demonstrados para Armor T1 e os três tiros
do Bigfoot. Os outros 44 estados são amostras controladas com divisor 1.
Os stubs cobrem alocação, seção crítica, inclinação zero, pose e texto de
dano. Os números desta matriz isolam a rotina comum. Para as armas com
feixes, guias, ricochetes, minas e outros eventos tardios, a matriz ainda
precisa do oráculo de seu produtor real e do respectivo relógio.

Na amostra central, 50.960 saídas de impacto Godot têm entradas
comparáveis no PE para Ataque, Defesa e Force acumulado. Destas, 32.884
diferem numericamente. As saídas foram pareadas pelas chaves de entrada. O par pode representar
uma explosão no PE e um guia, uma mina ou um feixe no Godot. O PE nessa
comparação usa 1.500 HP, escudo zero e divisores controlados em 44 armas.
A contagem serve como triagem de estágios e valores, sem atribuir uma
divergência de comportamento a cada par. Os [resultados por arma](shot-damage-validation-results.json) permitem selecionar novas regressões.
O caminho legado de Force altera a potência diretamente, por isso suas
linhas de Force ficam fora da comparação de acumulador igual. Nos
impactos controlados, Moon e Eclipse são estados de fila, Wind é aceleração
inicial e Tornado é aquisição da coluna. Os resultados de turno e voo
desses climas vêm da sonda com `begin_turn` e `Match.fire`.

## Divergências comprovadas e diferenças de escopo

- **Knight.** O consumidor isolado do PE retorna cedo para alvo tipo 14,
  correspondente ao Knight. Todos os 4.992 casos com esse tipo retornaram
  zero. O Godot respondeu com dano positivo em 4.586 deles. Mage T1,
  centro, sem bônus, retornou 0 no PE e 176 no Godot. A conclusão vale
  para `45db20`. Efeitos de outras rotas têm de ser testados separadamente.
- **Potência inicial.** Armor T1 apresentou a diferença de catálogo 280/210.
  Outras cinco diferenças brutas são estados intermediários conhecidos.
  Raon T2/SS guardam a potência na mina e os três tiros do ASate a guardam
  no filho. A potência do guia ou da casca inicial nesses casos está em zero.
- **Dano publicado e perda efetiva.** As 46 trilhas dirigidas com soma
  publicada de pelo menos 600 preservam ticks, contatos, dano e cratera.
  O maior total foi 1.865 no Trico SS com Force, com 300 HP perdidos nessa
  fixture. Na matriz por alvo, 279 trilhas passaram pelo mesmo filtro.
  Trico T2 sob Tornado publicou 2.545 contra Raon com 300 HP perdidos.
  As sondas de voo fixam o alvo em 300 HP antes de cada caso. A ausência
  de perdas de 600 HP nessas sondas decorre desse teto. Os impactos
  controlados usam a vida normal do alvo e podem publicar mais. A matriz
  conserva os valores calculados, escudo consumido, HP perdido e overkill.
- **Clima no voo.** Force, Tornado e Electricity tocaram todos os 96 voos
  de cada categoria na arena dirigida. Moon curou o ator ativo e Eclipse
  bloqueou Dual e limpou ambos os itens em 96 de 96. Os controles elevados
  do Nak SS mostram o raio elétrico e o Thor de clima após contato.
  Aduka T2/SS ativaram o Thor próprio da arma. O vento e os raios observados
  são resultados do modelo de produção sob os estados controlados na sonda.

## Reproduzir

Executar a partir da raiz do checkout importado. `godot` é Godot 4.7.2.
Para o oráculo, usar Python com Unicorn 2.1.4 e Pillow. O diretório local
do cliente deve conter o PE e o DAT fixados. A ferramenta verifica ambos
os hashes. As sondas largas são manuais. O harness registra a suíte curta
`test_shot_damage` e a fixture de Armor junto às suítes existentes.

```sh
set -e
client=/caminho/absoluto/para/cliente
result=/tmp/shot-validation
mkdir -p "$result"
godot --headless --path . --script tests/test_shot_damage.gd
python3 tests/tools/shot_damage_audit/native_matrix.py "$client" --output "$result/native.json"
python3 tests/tools/shot_damage_audit/native_matrix.py "$client" --signed-axes-only --output "$result/axes.json"
python3 tests/tools/shot_damage_audit/native_matrix.py "$client" --armor-contact-only --output "$result/contact.json"
godot --headless --path . --script tests/tools/shot_damage_audit/bridge_probe.gd -- "$result/native.json" "$result/bridge.json"
godot --headless --path . --script tests/tools/shot_damage_audit/bridge_probe.gd -- "$result/axes.json" "$result/axes-bridge.json"
godot --headless --path . --script tests/tools/shot_damage_audit/impact_probe.gd -- "$result/impact.csv"
godot --headless --path . --script tests/tools/shot_damage_audit/launch_probe.gd > "$result/launch.log"
godot --headless --path . --script tests/tools/shot_damage_audit/weather_probe.gd > "$result/weather.log"
godot --headless --path . --script tests/tools/shot_damage_audit/weather_probe.gd -- --all-targets > "$result/weather-targets.log"
godot --headless --path . --script tests/tools/shot_damage_audit/weather_probe.gd -- --maps-items > "$result/weather-auxiliary.log"
python3 tests/tools/shot_damage_audit/summarize.py --native "$result/native.json" --impact "$result/impact.csv" \
    --bridge "$result/bridge.json" --axes "$result/axes-bridge.json" --launch "$result/launch.log" \
    --weather "$result/weather.log" --weather-targets "$result/weather-targets.log" \
    --weather-auxiliary "$result/weather-auxiliary.log" --output "$result/results.json"
```

## Identidade do binário e REA

O PE e o DAT correspondem à [auditoria](SHOT_DAMAGE_AUDIT.md#proveniência-da-auditoria).
O REA 6.7.0 foi chamado explicitamente com `--provider ghidra`. Os cinco
dossiês usaram Ghidra 12.1.4 no mesmo PE x86. Identidades de evidência:

| Endereço | Uso | Evidence ID |
|---|---|---|
| `0x41c360` | Inicialização da Defesa e do corpo | `ev_bc6729f2ba5829d119a06f8bbdef24c267e435cf001c3151bb89d66fba671d4a` |
| `0x41da80` | Inicialização de potência, Ataque e divisor | `ev_af673999ff1788dd7cae3830184d1b10f45b3b3718623381fec3d541a44a53c9` |
| `0x4510f0` | Consulta da coluna Force | `ev_90d43954df0f92b7e7aac553bbd25937a099a0007c4c2f3e07c8449713edf0e0` |
| `0x455cc0` | Consulta de contato do segmento | `ev_ae05d531a4ae6c8d94210ac5ba8cf59d618332e9ae0e2576c22bf0446356e01c` |
| `0x45db20` | Consumidor comum de dano | `ev_7b8d629a5867eb95b25679ef734bd5b5ce94875034440e92726712b04f2ade27` |

## Verificação local antes do PR

O harness CI local completou 92.946 verificações GDScript e as 103
partidas, com 29 regressões de SOLO, 44 de mapas e 30 de JEWEL. A única
falha agregada foi a ausência do XFS e dos DATs de referência no checkout
temporário. Com os insumos locais conectados, a etapa Python do mesmo
harness passou com 262 testes, zero skips e cobertura de 63% em
`scripts/ci`. A suíte dirigida do Armor foi repetida após incluir a
consulta pública de previsão e concluiu 28 verificações sem falhas.

Ruff e `git diff --check` passaram. O pacote local macOS foi exportado,
extraído e verificado pelas rotas de smoke de lobby, sala, loja, 48 tiros,
mapas e JEWEL. Os resultados desktop de outros sistemas dependem dos
runners nativos da CI.

## Limites e retomada

A matriz demonstra diferenças do Armor T1 e do consumidor contra o Knight.
O PR entrega as sondas, a fixture e o registro da execução. A correção
das regras de combate continua aberta. A execução isolada do PE cobre o
cálculo e o segmento do replay. O cliente Windows inteiro continua
pendente. O harness de famílias exercita limiares de Thor, itens, fases
especiais e JEWEL já cobertos pelas suas fixtures. Os cruzamentos de
materiais, fases, modos de jogo, múltiplos modificadores e de mecanismos
especiais com o PE continuam abertos antes de declarar paridade integral.
