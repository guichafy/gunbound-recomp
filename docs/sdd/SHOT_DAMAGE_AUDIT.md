# Auditoria de força e dano dos 48 tiros

**Data** 19/11/2026. **Base auditada** `69079683`. **Escopo** Thor’s Hammer e treino offline,
com requisitos REQ-04/05/07/08/19/23–26/35–38/44/45/52 e REQ-JEWEL-46.
Esta entrega registra a auditoria e o plano. As correções e os gates de paridade ficam no plano de execução abaixo.

## Achado reproduzido no Armor T1

Um único Armor T1 atingiu Bigfoot por **626 HP** no tick 3 (50 ms por tick),
sem escudo, vento, clima de dano, item, Attack, Defense ou bônus de equipamento.
O impacto foi `(237.435150, 454.472412)`. O disparo real por `Match.fire` e a
proposta armada via `FlightSnapshot.arm` produziram o mesmo impacto, evento
e perda de HP. Isso localiza a discrepância no caminho compartilhado.

Para repetir no Godot 4.7.2, criar um `Match` com Armor (ID 4) e Bigfoot
(ID 2), semente 42, mapa procedural, jogador no primeiro turno e modo SOLO.
Preencher ambas as máscaras com chão em `y >= 500` e um degrau em
`x >= 232 && y >= 478`, com `first_solid_y = 478`. Colocar o Armor em
`(200,475)` virado para a direita e o Bigfoot em `(250,453)`. Limpar colunas
e eventos, desligar Thor e fixar `wind = Vector2.ZERO`. Chamar
`fire(10.0, 25.0, 0)` e avançar `advance_projectiles(0.05)` até sair de voo.
O alvo começa com 1100 HP e perde 626 no único evento `damage`. O degrau
e a cratera fazem parte da reprodução. O cenário relatado originalmente
pelo jogador fica sem identificação de mobile, mapa ou replay.

| Divergência | Evidência comparável |
|---|---|
| Potência base do Armor T1 | `characterdata.dat`, type 0, contém 210 nas três células de potência T1. O ramo de `44e920` chama `42bbb0` em `44eac5`, que leva ao inicializador `41da80`. O catálogo atual de `classic_mobiles.gd` inicia T1 com **280**, valor base do SS. |
| Atenuação com a distância | `Damage.blast` chama `Combat.blast_damage`, que calcula `int(base * raio / max(distância_ao_centro, 1))`. Com raio 34, o divisor pequeno amplia a potência. No PE, a explosão comum chega a `450eb0 → 45db20`. O gate geométrico estrito e o falloff de até 1000‰ produzem potência integral no centro, decaindo até a borda. No ramo de material 0, `45e352–45e37d` e `45e3d6–45e404` mostram raiz, diferença para o raio e divisão por 1000. |
| Atributos e clima no ramo compartilhado | O caminho legado aplica `Attack − Defense` como percentual, além do Force de entrada `1,2 × dano + 10` em `WeatherContact`. Em caminhos que usam a rotina nativa, o consumidor recebe potência preparada por componente, área elíptica e Force como campo separado. `45e4bc–45e519` aplica o acumulador pela metade com bônus e divisão inteira. `45e53c–45e644` usa a vulnerabilidade do alvo, seu flag condicional e as interações de tipo. `45e648–45e750` encadeia os campos de Ice. |
| O valor mostrado pode diferir da perda efetiva | `Damage.deal_damage` limita HP a zero, mas publica o restante depois do escudo no evento `damage`, mesmo acima do HP disponível. Gold também lê eventos. A reprodução do Armor fica abaixo do HP do Bigfoot e os 626 correspondem à perda real. |

O oráculo Unicorn 2.1.4 executou `41da80` e `45db20` no próprio PE em
11 testes isolados, com Bigfoot tipo 4 e geometria plana controlada. Confirmou
210 no centro para os três materiais, 147 a 20 px horizontais, 105 com
deslocamento (23,16), 4 a 63 px horizontais e zero a 64 px. Com Attack 50,
confirmou potência 360 e, ao injetar Force 100, 540 no centro sob
vulnerabilidade 100. Vulnerabilidade 60 com o mesmo Attack e Force zero
resultou em 216. O oráculo fixa a geometria e o estado de combate e substitui
os auxiliares de inclinação e a publicação visual. Os números validam os
consumidores isolados. A posição nativa do contato para o replay inteiro
de 626 ainda requer validação. No ponto observado o centro legado era
`(250, 463)` antes da cratera. Com a mesma geometria e a mesma equação,
trocar apenas 280 por 210 produziria 470 HP. Essa simulação aritmética
confirma que o desvio na fórmula deve ser tratado junto com o catálogo.

**Prioridade.** O primeiro caso de regressão é Armor T1 em SOLO. O mesmo
consumidor legado atende outros tiros e efeitos. A classificação de um
total acima de 600 depende da decomposição por componente, clima, itens,
escudo e overkill. O plano usa 600 como filtro de investigação e exige
comparação com o oráculo para julgar cada resultado.

## Inventário observado dos 48 tiros

`Fmax` e gravidade (`g`) das 16 linhas do DAT coincidem com as tabelas
de lançamento do porte. A prova cobre cada par de células `[25]/[40]`.
A carga em percentual gera a potência de lançamento. As células de dano
`[44]/[57]/[70]` são de outro domínio. A smoke do Godot percorreu os 48 tiros
com 50% de carga, ponto médio da mira e clima neutro. Todos encerraram o
voo no cenário. O alvo foi Armor em todas as sondas de inventário.
Aduka T2 e SS tiraram 26 HP cada nesse cenário e os outros 46 tiros não
tiraram HP do alvo. Os valores abaixo são do shell **na criação**, antes de
transições, filhos e efeitos. A coluna do PE usa a primeira célula de
potência de cada arma. `41da80` inicializa as três células e `45db20`
seleciona a correspondente na resolução por material.
A coluna de revisão aponta o primeiro consumidor de dano e os efeitos que
precisam de comparação adicional. Fontes por MainAction, spawn e classe
estão na [matriz histórica dos 48 tiros](BATTLE_SHOT_MATRIX.md).

| Mobile (ID/type) | Fmax / g | Potência DAT T1 / T2 / SS | Shell Godot T1 / T2 / SS | Consumidores e lacunas por arma |
|---|---:|---|---|---|
| Mage (1/1) | 45 / 90 | 200 / 186 / 380 | 200 / 186×2 / 380 | Dano comum via MageCombat. T2 dois lasers com composição adaptada. SS EMP e blast em ordem. |
| Bigfoot (2/4) | 42 / 98 | 86 / 70 / 92 | 86×4 / 70×6 / 92×8 | Dano via BigfootCombat e rotina compartilhada. Conferir grupo, divisores de atributo, clima e mina. |
| Nak (3/2) | 41 / 98 | 200 / 350 / 360 | 200 / 350 / 360 | Blast legado nas três armas. Validar saída do solo do T2 e contato só com mobile no SS. |
| Armor (4/0) | 46 / 98 | **210** / 236 / 280 | **280** / 236 / 280 | Blast legado. T2 tem duas fases nativas de contato com redução entre elas. SS tem transformação de voo ainda a confrontar. |
| Trico (5/3) | 43 / 98 | 200 / 150 / 256 | 200 / 150×3 / 256 | Blast legado no T1 e nos impactos do T2 e SS. T2 separa dois orbitais e o terceiro comum. SS tem oito ações. |
| Boomer (6/5) | 35 / 98 | 254 / 118 / 350 | 254 / 118×4 / 350 | Rotina compartilhada. T1/2 curva e sinal do vento. SS muda potência e raio após transformação. |
| Raon (7/6) | 44 / 98 | 90 / 200 / 400 | 90×3 / 0×2 / 0 | T1 orbital com blast legado. T2/SS transferem dano a minas, incluindo gatilho tardio e autoria. |
| Lightning (8/7) | 47 / 90 | 230 / 240 / 230 | 230 / 240 / 230 | LightningCombat. Conferir explosões de feixe, choques e cadeia na ordem do tick. |
| JD (9/8) | 50 / 98 | 180 / 240 / 0 | 180 / 240 / 0 | Blast legado. T2 tem dano e cristal. SS exige validar repulsão e consequências, inclusive queda. |
| ASate (10/9) | 45 / 98 | 190 / 160 / 140 | 0 / 0 / 0 | Guia sem blast. Filhos 1/3/6 com esses valores como base. Conferir a autoria e os efeitos aplicados ao guia. |
| Ice (11/10) | 50 / 98 | 220 / 310 / 350 | 220 / 310 / 350 | T1 usa blast legado. T2/SS usam IceEffects e consumidor nativo. Conferir raios, ordem, teto e persistência dos quatro campos. |
| Turtle (12/11) | 46 / 98 | 230 / 224 / 300 | 230 / 224×2 / 300 | Blast legado. T2 fase 0/180 e contato. SS antes da abertura e após expulsar seis filhos. |
| Grub (13/12) | 50 / 98 | 190 / 94 / 26 | 190 / 94×4 / 26 | GrubCombat. T1 comum, T2 ricochete, SS dano por quadro, Moon e bordas de contato. |
| Dragon (14/13) | 50 / 90 | 290 / 200 / 160 | 290 / 200×4 / 160 | Blast legado; T1/T2 deslocamentos de carga/ângulo. SS pai e leque de cinco filhos. |
| Knight (15/14) | 48 / 98 | 136 / 128 / 126 | 136 / 128 / 126 | Guia e Ion em T1/T2/SS com leques 3/5 e chuva 8. Conferir filhos, dano atribuído e imunidades. |
| Aduka (16/15) | 48 / 94 | 152 / 0 / 0 | 152 / 0×3 / 0×3 | T1 usa consumidor nativo. T2 mantém três criaturas por decisão do projeto. O PE emite duas. SS encadeia Thor. Conferir valores por nível e agregação. |

## Plano de validação e correção

**Resultado esperado.** Uma matriz rastreável por arma, fase, alvo e
variação de clima, com comparação independente no nível da potência, do
contato e do dano. A implementação futura conserva os contratos de treino
e explicita cada adaptação autorizada. `Match` e `FlightSnapshot` continuam
a usar o mesmo passo e o mesmo resolvedor.

### 1. Transformar a auditoria em casos repetíveis

- [ ] Criar `tests/test_shot_damage.gd` e uma fixture independente em
  `tests/fixtures/shot_damage_native.json`. Reproduzir Armor/Bigfoot 626 pela
  API de disparo e no snapshot. Registrar posição, inclinação, precisão e
  relógio no contato. Fixar a fixture de `45db20` com e sem colisão
  controlada e acrescentar um mapa nativo com geometria semelhante.
- [ ] Estender o oráculo isolado em `tests/tools/` a partir dos de Bigfoot,
  Armor e Ice. Fixar PE, DAT, Ghidra/REA, RNG, largura/sinais, VA e ABI.
  Usar o PE para produzir esperados, guardar entrantes/resultados e listar
  explicitamente cada stub. Integração em Godot lê fixture sem PE, REA ou
  Unicorn na CI. Versionar resultados e hashes, com o binário de referência
  restrito à ferramenta local.
- [ ] Instrumentar, só para testes, cada caminho de evento com ID de tiro,
  mobile/arma, componente/rajada/filho, estágio, tick, pixel/subpixel, clima,
  HP e escudo antes/depois, dano calculado, aplicado e overkill. Capturar
  cratera, status, autoria e eventos de mina/feixe. Comparar ordem e estado
  final no disparo e na previsão, incluindo Gold e o objetivo JEWEL
  conforme o contrato de cada caminho.

### 2. Fechar a matriz numérica

| Camada | Cobertura obrigatória | Critério |
|---|---|---|
| Carga e lançamento | 48 armas × ambos os sentidos × extremos/miolo da mira, inclinação positiva/zero/negativa, Slice e Drag, cada degrau inteiro de P e vizinhos no adaptador de percentual. Incluir saturação e os offsets pós-quantização, inclusive valores assinados, com vento congelado por disparo. | Concordância exata de θ, P, vx/vy, aceleração e tick de cada emissão com os casos PE demonstrados. Mesmo P quantizado deve dar os mesmos inteiros pelos dois modos de mira. |
| Dano e defesa | **48 × 16 alvos × 7 categorias nativas = 5.376 células** de cobertura básica, mais um controle neutro por par (768). Em cada célula validar centro, contato real ou equivalente do efeito, borda estrita e erro completo. Cobrir corpo, inclinação e material do mapa. | Dano, queda e estado estruturados por componente. Um miss não satisfaz o caso de dano, e uma célula sem produtor de dano precisa de prova da imunidade, efeito ou filho pertinente. |
| Ataque e Defesa | Em cada par arma/alvo, cruzar efetivos `−50, −1, 0, 1, 25, 49, 50` em neutro e nas categorias com efeito direto. Para cada família aritmética, percorrer os 101 inteiros de cada eixo em separado e adicionar os pares em que o arredondamento muda. Exercitar equipamento assinado, sem avatar, soma saturada e orçamento de perfil. Separar Attack de Dig, HP e Regen. | Igualdade de inteiros em cada estágio demonstrado. Avaliar resistência por tipo, bits 8/4/2/1, teto de Ice, Defense efetiva e vulnerabilidade base observados separadamente. Demonstrar a origem de cada campo do alvo antes de trocar a ponte offline. |
| Limites do alvo | Em cada família, cobrir HP 1/normal, escudo 0/menor/igual/maior que o dano, EMP puro e EMP+blast, invulnerável, morto, dano de retorno no autor, queda e duplo KO, estado de Ice antes e depois, com e sem JEWEL. | Distinguir soma calculada, escudo consumido, HP perdido e overkill. Assegurar autoria/Gold/Thor XP e efeito JEWEL uma vez e preservar previsão sem escrita no jogo vivo. |

O rastreamento por arma precisa incluir os stubs e as fronteiras que o
smoke não exercitou. Para cada transformação, nova emissão ou consumo de
efeito, verificar o tick anterior, o exato e o posterior. Começar pelo Armor T1 e blast comum,
depois passar por T2 de múltiplos impactos e efeitos especiais da tabela.
Usar `Damage.blast`, `AdukaCombat.amount`, `Match.explode` e os consumidores
por família apenas nos caminhos cujo produtor esteja comprovado. Teste
vermelho com oráculo primeiro. Depois corrigir a potência de catálogo e a
rota de dano desse tiro em deltas isoláveis, com regressão de T2/SS e
dos auxiliares que também usam blast. Evitar substituição global da função
antes de mapear mina, choque, cristal, Thor, JEWEL e os filhos.

### 3. Cruzar clima com trajetória, dano e turnos

| Clima/entrada | Casos obrigatórios |
|---|---|
| Force | Borda ±1 px, entrada/saída/reentrada, coluna atravessada num passo, duas colunas, várias amostras no mesmo tick, primeiro ganho, teto e ticks intermediários. Comparar contato nativo com a ponte de entrada legada. |
| Tornado | Entrada pelos dois lados e de cima, vx abaixo/igual/acima da magnitude mínima, ambas as direções, três bordas, congelamento e retomada da aceleração, contato ou saída de mundo dentro da coluna, caminho de gatilho pelo ponto da onda. |
| Electricity | Toque e miss, impacto em ar/chão/mobile, raio bloqueado pelo primeiro terreno, divisão de rajada, choque, cadeia, tick em que o alvo já morreu, interação com crateras e guia/filhos. |
| Wind | Calmo e força mínima/intermediária/máxima de cada faixa. Incluir quadrantes, pontos angulares na fronteira, mesmo/favorável/contrário ao facing, vento congelado e retorno após Tornado. Cruzar vento persistente com Force, Tornado, Electricity e Thor em transições e durante o voo. |
| Thor | Cada nível e XP imediatamente antes/no/depois do limiar, ativação/saída do período, altura e primeiro corpo/obstáculo, ordem com Electricity, divisor do grupo, T2/SS Aduka e atribuição do XP. |
| Moon | Flag bionic e demais alvos, cura 3%/8% no ator ativo, limite de HP, morto/ausente, fase do turno, com escudo e regen. Auditar o flag de proteção no PE em caso isolado e checar a transição de Moon em separado. Hoje `AdukaCombat.amount` lê `native_protection` e `MageWeather.moon_heal` aplica a cura sem produzir esse campo. |
| Eclipse | Fronteira de período e fila de itens, esvaziamento de Dual/Dual+ e conservação de slots, escolha de arma/SS, disparo imediatamente após início/fim e controle para dano/força com mesmos estados. |
| Transições e mapa | 22 lados, original e todos, cada peso/range aplicável, slot 7→0, N−1/N/N+1 da troca e RNG reprodutível. Cobrir persistência alcançável e ordem Force/Tornado/Electricity/Thor. As entradas artificiais ficam marcadas como sondas. Weakness/Mirror/Random ficam em controle legado separado conforme ADR-159. |

Executar condições-base em mapa controlado. Usar todos os lados para
calendário e ranges, cobrindo ao menos uma trajetória comparada por
família de mundo, ambos os lados quando seus dados diferirem e as
geometrias-limite de cada consumidor. Repetir os casos com item de dano,
Dual/Dual+, Thunder, Teleport e Bunge onde forem aplicáveis, com item
inativo, permitido e bloqueado como controles.

### 4. Critérios para aceitar a paridade

- [ ] Identificar cada célula como comprovada pelo PE, derivada, adaptação
  documentada ou pendente. Aprovação exige igualdade numérica
  para cada mecanismo reivindicado e nenhum caso pulado sem motivo
  registrado. Uma adaptação acordada tem comparação e contrato próprios.
- [ ] Para qualquer resultado ≥600, emitir trilha auditável do cálculo,
  identificar o primeiro estágio divergente e repetir o caso com e sem
  cada modificador. Incluir um total legitimamente alto no oráculo para
  proteger rajadas e combinações válidas contra um teto artificial.
- [ ] Comparar pelo menos um contato regular e um caso-limite por arma em
  ambiente Windows com o cliente fixado quando disponível, preservando a
  trilha de eventos. Registrar se só houve execução isolada do PE.
- [ ] Integrar fixtures rápidas ao harness, rodar `./scripts/check.sh` com
  partidas completas, confirmar todas as regras protegidas no PR da
  implementação e testar smoke do pacote nos alvos da CI. Anexar resultados
  de execução/previsão, lista de adaptações e dúvidas por família.

## Repetir as sondas

O [probe Godot](../../tests/tools/shot_damage_audit/probe.gd) gera 48
linhas `ROSTER` e uma linha `REPRO` com o mesmo cenário em disparo e
snapshot. Ele fixa o resultado histórico de 626 nesta base, sendo executado
manualmente para diagnóstico. O [oráculo Armor](../../tests/tools/shot_damage_audit/armor_oracle.py)
gera os 11 vetores a partir do PE e do DAT locais. Requer Unicorn 2.1.4 e
Pillow no ambiente Python. Após importar o projeto com Godot 4.7.2, rodar
os dois comandos a partir da raiz do checkout.

```sh
godot --headless --path . --script tests/tools/shot_damage_audit/probe.gd
python3 tests/tools/shot_damage_audit/armor_oracle.py /caminho/absoluto/para/cliente
```

O segundo comando verifica os hashes do PE e do DAT. A execução passa se
todos os voos terminarem, a linha `REPRO` mostrar paridade e 626 HP perdidos
e o JSON nativo publicar, na ordem, 210, 210, 210, 210, 147, 105, 4, 0,
360, 216 e 540. O PE e os DAT ficam no ambiente local.

## Proveniência da auditoria

PE x86-32 `GunBound.gme`, SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
`characterdata.dat` SHA-256
`b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf`,
redecodificado em 16 registros de 83 inteiros. `stage.dat` SHA-256
`103c2b488977e1721becf8cb90496f95477302ec24141f94116d5214a3e6cfca`.

Ghidra Headless 12.2 exportou 33 consultas de função com sucesso, incluindo
os 16 MainAction, spawners `42bbb0/42de70`, inicializador `41da80`, dano
`450eb0/45db20`, contato `455cc0`, clima `4510f0/451030/4511b0` e
Thor `4ccd10/4ac180`. Os endereços são VAs com image base `00400000`.
REA 6.7.0, com provedor Ghidra 12.1.4, confirmou a função de dano no
mesmo PE. Evidence ID
`ev_7b8d629a5867eb95b25679ef734bd5b5ce94875034440e92726712b04f2ade27`.
A validação local passou em 13 suítes Godot de combate/clima
(10.464 checks) e no teste Python de materiais de JEWEL. O smoke de 48
armas e a reprodução de Armor terminaram com zero erros Godot no passe
final. O passe local de suítes foi dirigido, pois o delta é documental.

A análise estática e as observações no Godot cobrem os níveis registrados
acima. A matriz de paridade por alvo e clima e a sessão Windows inteira
seguem como tarefas abertas.
