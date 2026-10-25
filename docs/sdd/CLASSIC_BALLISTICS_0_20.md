# Desenho fechado — física comum original e Boomer (24/10/2026)

Análise somente leitura do produto e do cliente, sem executar GME/EXE. Nenhuma
alteração em `scripts/`, `tests/` ou `docs/sdd`. REQ-03/04/08/28/34/44/45;
autorização de física/carga/mínimo já consta em ADR-084. Esta é a proposta de
contrato antes de código, para implementar tarefas 5 e 6 no laço compartilhado.

## Fonte e material independente para testes

`/Users/guichafy/Workspaces/GunboundClassic/gunbound-launcher/TestClient/GunBound.gme`
SHA256 **4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde**.
Conferidos ASM recuperado e novas desmontagens diretas com `/usr/bin/objdump`.
`graphics.xfs` foi apenas lido pelo parser do repositório.

Gerador independente (não importa Match/Combat/Godot):
`.tools/battle-execution/physics-reference/reference.py`; executado com Python.
Saídas ao lado: `fixtures.json`, `native-sine-f32.bin`, `native-angle-i16.bin`.
O gerador só lê o PE e calcula aritmética; **não é uma captura executada do
cliente**. As fixtures provam a tradução das operações estáticas, e não paridade
de colisão/partida inteira. O gerador inclui mundo vazio e nenhum clima de coluna.

- Seno: VA `0x54c240`, 360 float32, 1440 B, SHA256
  `6e40fa45f367eda31c6b03f9cf76af99ab1cf97bace9c856eca44357416dfa7a`.
- Ângulo: ponteiro central `0x598e7e`, primeiro byte `0x588f80`, 65536 int16 LE,
  131072 B, SHA256 `41734b41c43ff4e760a3a11a830c208493446dd1aef3a72f2a760e9b0bce3ffb`.
  Layout linear: `index=(x+127)+256*(y+127)`, ambos em [-127,128].
- Identidades corrigidas: tipos 13/14/15 = **Dragon/Knight/Aduka**. Desconsiderar
  rótulos Aduka/Kalsiddon/JFrog nos cabeçalhos históricos.

## Aritmética comprovada e API isolada proposta

`ClassicBallistics` é RefCounted puro: sem terrain, atores, RNG, nós, desenho,
relógio global ou leitura do vento vivo. A posição, velocidade e aceleração de
cada projétil são inteiros com 8 bits fracionários. `STEP=0.05` (20 Hz).
`GameTick 0x413160` divide tempo por 0x32 e chama atualização de batalha uma vez.
Godot `Vector2i` pode guardar os pares; `int` de 64 bits evita overflow acidental.

Contrato sugerido (nomes adaptáveis, responsabilidades não):

```gdscript
static func native_power(percent: float, force_max: int) -> int
static func power_percent(power: int, force_max: int) -> float
static func launch_velocity_fp(theta: int, power: int) -> Vector2i
static func acceleration_fp(gravity: int, wind_force: int, wind_angle: int) -> Vector2i
static func seed(shell: Dictionary, position_fp: Vector2i, velocity_fp: Vector2i, acceleration_fp: Vector2i) -> void
static func move(shell: Dictionary) -> Dictionary # {from_fp,to_fp}; não acelera
static func finish_tick(shell: Dictionary, accelerate: bool = true) -> void
static func mirror_x(shell: Dictionary) -> void
static func set_position_fp(shell: Dictionary, value: Vector2i) -> void
static func set_velocity_fp(shell: Dictionary, value: Vector2i) -> void
static func import_external_motion(shell: Dictionary, position: Vector2, velocity_px_s: Vector2) -> void
static func publish_motion(shell: Dictionary) -> void # pos px / velocity px/s; derivados
static func integer_position(shell: Dictionary) -> Vector2i # aritmético >>8
static func outside(position_fp: Vector2i, world_size: Vector2i) -> bool
static func velocity_angle(v_fp: Vector2i) -> int # LUT +3° do original
```

`native_power` deve fazer `clampi(int(clampf(percent,0,100)*force_max/10.0),1,10*force_max)`;
percentual é apenas adaptador da UI existente, **P inteiro é a unidade de regra**.
Não arredondar os componentes trigonométricos, não aplicar sin/cos matemáticos
novos, não fazer clamp genérico da mira dentro deste módulo. `Match.shot_velocity`
limita mira pelos dados do mobile, converte inclinação/direção, passa theta inteiro.

Guardar na fábrica ShellState: `fp_pos`, `fp_velocity`, `fp_acceleration`, `fp_ready`,
`flight_ticks` (com seus nomes definitivos); `pos`/`velocity` ficam só projeções.
Copiar tudo por Dictionary.duplicate(true), como o snapshot já faz. Nenhum caminho
paralelo para CPU: `predict_shot` continua armando snapshot e chamando
`advance_projectiles` a STEP, exatamente como a partida.

Pseudocódigo nativo, comprovado no spawn `0x42cc97–0x42cff6`:

```text
q(n,d) = divisão inteira assinada com truncamento para zero (x86 idiv)
T(x) = truncamento para zero (_ftol 0x53753c)
S[a] = tabela float32 lida do PE; a normalizado em [0,359]
vx = q(T(S[theta+90] * P) << 8, 10)
vy = -q(T(S[theta] * P) << 8, 10)
ax = q(T(W*S[phi+90]) << 8, 100)
ay = q((G-T(W*S[phi])) << 8, 100)
```

`S[45]=0.7071099877357483`, não sin(π/4); `S[1]=0.01744999922811985`,
`S[30]=0.5`, `S[90]=1`, `S[180]=0`. Extrair tabela como asset de dados ou
constantes float32 exatas. Os produtos por inteiros pequenos são representáveis
exatamente em float64; não exigir emulação de x87 para estes valores. O `_ftol`
original corrige o resultado de FISTP para truncar: não usar round().

Entrega runtime das duas tabelas: copiar os arquivos validados para
`assets/openbound/physics/` mantendo estas fontes scratch como evidência, registrar
origem/VA/hash em um JSON, e incluir explicitamente bin/JSON no preset de export.
Usar preload/cache estático já aquecido na thread principal **antes** de iniciar
WorkerThreadPool; a busca recebe dados prontos e nunca faz load/FileAccess/JSON
durante o planejamento. Pode armazenar seno como constantes exatas para dispensar
leitura runtime, mas a LUT de ângulo deve ser a mesma e validada pelo hash.

Apresentação20Hz: guardar `previous_draw_pos`/`previous_hit_pos` e valor novo a cada
passo (ou fazer um sampler visual equivalente), renderizar lerp pelos resíduos do
acumulador/STEP. No spawn primeiro/anterior são iguais; impacto/burrow/teleport e
entrada/saída de transformação devem fixar endpoints apropriados para não criar
um quadro atravessando o chão. O `hit_pos`, estadoFP, trace e CPU nunca usam lerp.
O estado de animaçãoSS é do modelo; o renderer pode suavizar posição, mas não
inferir normal/change/cnormal por idade. Nenhum relógio/render na worker.

**Ordem obrigatória** (comum `0x4572b0`, chamada Simulate `0x45734e`):
1. Boomer ajusta velocidade antes do deslocamento; comum não.
2. `fp_pos += fp_velocity`.
3. Colisão varre segmento anterior→novo (original Simulate(8)).
4. Só se não houve impacto: publicar coordenadas inteiras e `v += a`, salvo clima.
5. Pós-passo do Boomer; bounds nativos após integração.

Não retornar de uma função monolítica com `velocity+a` antes de a colisão decidir:
isso altera a velocidade de impacto usada pelos efeitos. Um par move/finish_tick
torna essa ordem explícita. O modelo pode usar um resultado candidato e só
finalizar no ramo sem colisão, desde que nunca aplique aceleração duas vezes.

## Integração com WeatherContact e filhos (sem fontes duplas)

`WeatherContact.interact` atualmente altera `projectile.velocity` ao espelhar;
`tornado_step` retorna posição/velocidade float. Eles precisam de ponte explícita.

- **Lançamento real:** depois de todas as modificações do item/offsets/filhos e
  antes do primeiro passo, seed usa a velocidade final e captura ax/ay **uma vez**
  com W/phi/G daquele lançamento. Um projétil atrasado só é semeado ao lançar;
  jamais re-seed a cada tick. `launch_speed` deriva dessa velocidade inicial.
- Espelho: `ClassicBallistics.mirror_x` nega somente `fp_velocity.x` e publica a
  projeção float no mesmo ato; **não recalcula** ax/ay nem modo inicial do Boomer.
- Tornado C# preservado enquanto não portado: aplica o percurso externo, depois
  `import_external_motion` **uma única vez** naquele tick, mantendo fp_acceleration.
  Não usar o estado fixo anterior no tick seguinte. Durante a coluna, suprima
  sustentação/curva e aceleração comum quando o ramo de clima exigir. Ao sair,
  importa velocidade de saída e retoma o acelerador congelado no próximo passo.
- Filhos (Turtle/Dragon/cristal/itens): todos saem de ShellState; se duplicam pai,
  limpar fp_ready e campos de curva/transformação antes de lançar. Seed após
  sobrescrever pos/velocity, antes da primeira integração. Filhos com nascimento
  no impacto não podem herdar posição/velocidade fixas antigas do pai.
- Nak ao entrar no solo: escrever posição de impacto e vy/2 por setter fixo;
  aceleração subterrânea própria; não deixar float e inteiro divergirem.
- Ponte float externa é adaptação do C# atual, **não fidelidade nativa**. Escolher
  e documentar quantização (recomendação truncar px*256 / px/s*256/20 para zero)
  só no ponto da mutação. Nunca reconverter os derivados float a cada tick.

`apply_weather_contact` deve ler posição de colisão derivada do estado inteiro;
desenho/interpolação não entra. Vento de turno modificado durante voo não muda
fp_acceleration dos projéteis já lançados. A API de avanço nem aceita vento.

Limitação comprovada: o tornado atual é C# e não reproduz o ramo original
(piso nativo |vx|200/256 e até dois rebates, supressão de a). Não declarar tornado
original só porque a balística fora da coluna ficou original. Mesmo tratamento
para helix/orbit C# e beacon com fator1,4: adaptações nomeadas, não multiplicador
de vento comum por mobile.

## Dados, mínimo, carga e inclinação

| Mobile/tipo | f25 | P máximo | f40 |
|---|---:|---:|---:|
| Armor0 |46|460|98|
| Mage1 |45|450|90|
| Nak2 |41|410|98|
| Trico3 |43|430|98|
| Bigfoot4 |42|420|98|
| Boomer5 |35|350|98|
| Raon6 |44|440|98|
| Lightning7 |47|470|90|
| JD8 |50|500|98|
| ASate9 |45|450|98|
| Ice10 |50|500|98|
| Turtle11 |46|460|98|
| Grub12 |50|500|98|
| Dragon13 |50|500|90|
| Knight14 |48|480|98|
| Aduka15 |48|480|94|

**Mínimo físico P=1, não 1%**. Mouse Drag em `0x4c1879–0x4c191c` incrementa
com trunc(deltaMouseX/2), ou tremor, e faz clamp>=1. Release mouse em
`0x4baeda–0x4baf53` só aplica teto 10*f25. Teclado no modo temporal faz clamp1
em `0x461765–0x4617b7`. Por isso mínimos percentuais são `10/f25`: Mage
0,222222%, Bigfoot0,238095%, Boomer0,285714%; físico horizontal P1 dá vx25,
diagonal45° P1 dá vx=vy=0 devido ao truncamento antes do shift.

**Não confundir clamp mínimo com o primeiro incremento de carga.** O modo
teclado por ticks começa P=floor(f25/6) (`0x4615a8–0x4615de`) e soma esse
inteiro em `0x4616e6–0x461722`. Portanto f25 não divisível por6 não enche
exatamente em60ticks (Boomer floor35/6=5:70incrementos). O modo temporal usa
max(1,floor(10*f25*elapsed_ms/3000)), porém há ramo de release que acrescenta10
(`0x460db5–0x460dee`) e ramo inicial com tempo +50ms (`0x46153c`). **Carga
uniforme de3s é decisão aprovada do porte**; não afirmar que reproduz todos os
modos legados. Recomenda-se acumular tempo e converter diretamente P com teto
no instante3s; usar a mesma função no HUD/Drag/CPU, e preservar cancelamento e
disparo único. Não introduzir piso percentual15 ou1.

Inclinação: `AlignMobileToTerrain 0x45ba50`; soma mira+ângulo do apoio em
`0x45c303–0x45c33f`; se facing nativo0: `180−(mira+apoio)` em
`0x45c395–0x45c3ea`. O ângulo absoluto vai a mobile+0x4d90 e ao spawner.
No Godot, apoio é rotação de tela: direita theta=aim−rad_to_deg(rotation),
esquerda theta=180−aim−rad_to_deg(rotation), pois o valor nativo do apoio
é orientado pela direção do mobile. **Esta última conversão é mapeamento do
contrato Godot**, não alegação de reanálise do algoritmo do solo completo.
Testar aim45 com rotation±10° nos dois lados, theta35/55 e125/145.
Manter uma só conversão em Match usada pelo muzzle/CPU/HUD; extrair theta inteiro
sem rotações trigonométricas extras sobre a velocidade já quantizada.

## Limites nativos e tempo máximo do porte

Comprovado em Boomer `0x452983–0x452a08` e SS `0x453d2a–0x453d52`:
miss se `x_int<0 || x_int>=width || y_int>=height || y_int<−1000`.
Helpers `0x40b300` é >= e `0x40b330` é <, conferidos nos bytes novos.
`x_int/y_int` vêm do shift aritmético>>8, não divisão truncante: fp−1 vira pixel−1.
Coordenadas nos limites: x0 válido, xwidth inválido, y−1000 válido, y−1001
inválido, yheight inválido. Sem margem lateral150 ou fundo20.
O limite12s atual é proteção do porte; não foi encontrado como regra original
nestes trechos. Preservá-lo explicitamente como proteção compartilhada CPU/real,
ou justificar mudança; não atribuir12s ao cliente.

## Boomer: sinais, ordem e relógio do SS comprovados

Spawn S1/S2 `0x42d50e–0x42d667`; SS `0x42ef64` aplica mesma decisão.
`curve = vx != 0 && !((ax<=0 && vx<0) || (ax>=0 && vx>0))`.
O sinal é do **ax já quantizado**, logo W1 diagonal pode virar ax0 e não curvar.
Flag é fixada no spawn; espelho/tornado não a recalculam.

No início de tick Boomer `0x4513b0–0x4516ab`, SS `0x453242…`:

```text
se curve e primeiro_tick:
    a=velocity_angle(v)
    direction = +1 se a<90 senão -1
se curve e direction==0: a=velocity_angle(v)
se !curve: a=0
dvx = q(T(256*k*S[a+180]),100)
dvy = -q(T(256*k*S[a+90]),100)
se dvy>0: dvx=-dvx; dvy=-dvy
se não dentro_de_objeto: v += (dvx,dvy)
pos += v
colisão; se livre e fora_objeto: v += a_congelada
se vy>0: direction=0
se curve:
    a += direction
    se direction=+1 e a>=90 ou direction=-1 e a<=90:
        direction=0; vy=0
```

k=[53]/[66]/[79]=50 em S1/S2/SS. Sem vento/vento a favor, dv=(0,−128):
250−128=122 unidades de aceleração líquida vertical por tick, sustentação real
antes de mover. Não usar200px/s² com integraçãofloat nem trocar50 por ajuste ao C#.
O ponto de zerar direção se descendo é **depois** de v+=a; provas
`0x4528a7–0x452977`. Na coluna, o reset por descida é pulado no ramo original.

`velocity_angle` nativo `0x4585e0–0x458685` NÃO é atan2 arredondado:
1. x=q(vx,100), y=q(vy,100).
2. `0x4f1f10`: enquanto qualquer componente fora de[-127,128], dividir AMBOS
   por2 truncando para zero; consultar int16[center+x+256*y].
3. a=3*q(raw+1,3). LUT às vezes retorna44 para diagonal,89 para cima; +1 antes
   da divisão corrige isso. v=(99,−99) dá a=0, não45.
Usar LUT fornecida; testes de simetria devem tolerar a assimetria real da tabela
após a fase inicial (o gerador mostra diferença abaixo de1px em certos ticks).
O fato de curve=true não garante que todos os ângulos/forças retornem ao atirador;
não impor um comportamento maior que o demonstrado pela integração.

SS: construtor `0x452c80` zera contador; tick `0x452ce8–0x452d14` incrementa e
entra **change no início do tick36**. Setter de estado `0x461c60` zera relógio,
flag done e índice. Em estado1(change), `0x453238` salta ao fim **sem mover,
sem colisão, sem aceleração ou curva**. EPA original bullet6p tem normal20frames
loop, change10frames duração1 sem loop, cnormal20frames loop. AnimateSS
`0x4541c4–0x4541cd` chama física antes de `AdvanceAnimation0x450730`.

- Tick35: último deslocamento de normal.
- Ticks36..45: posição e velocidade congeladas, animação muda a cada tick.
- Fim tick45: animação termina (`0x450792–0x4507b7`).
- Tick46: `0x452d14–0x452d3d` detecta done+estado1, entra cnormal; multiplica
  três poderes por[81]/100 e três diâmetros por[82]/100 **com idiv inteiro**;
  integra no mesmo tick. Para dados crus:350→700 e46→55.
- Transformação ocorre uma vez. Armazenar state e state_tick no modelo;
  renderer só consome esse estado. Nunca disparar por idade visual.

Godot usa radius23 derivado de diâmetro46. Transformar **diâmetro cru46→55
primeiro**, depois converter ao raio do porte27,5; não radius23*1,2=27,6.
O dano original usa outro alcance `q(diametro,2)+10` (55→37); portar essa fórmula
de dano inteira está além desta tarefa de física e não foi comprovado pelo teste
daqui. Não dizer que mudar o raio sozinho implementa dano nativo integral.

Emissão S1/SS tick8; S2 ticks8,10,12,14. Switch/tabela em `0x454499` e
`0x454da0`: índices0,2,4,6 apontam cada bloco real. Todas as emissões usam
mesma mira/força/boca, sem spread artificial. Som62fire por spawn comprovado
em `0x4545fb–0x45460b`, `0x454752–0x45475f` e blocos seguintes: quatro sons
no S2 são quatro chamadas originais, não duplicação acidental.

## Fixtures numéricas mínimas antes de implementar

Todas posições iniciam em fp(0,0), mundo vazio; valores de v são **após** tick.
As fixtures completas de9cenários estão em physics-reference/fixtures.json.

| Caso | v inicial FP | a FP | tick1 p / v | tick2 p / v |
|---|---|---|---|---|
| Bigfoot P420 θ45 W0 G98 |7577,−7577|0,250|7577,−7577 /7577,−7327|15154,−14904 /7577,−7077|
| Mage P225 θ30 W26 φ45 G90 |4966,−2867|46,184|4966,−2867 /5012,−2683|9978,−5550 /5058,−2499|
| Boomer P350 θ45 W0 |6323,−6323|0,250|6323,−6451 /6323,−6201|12646,−12780 /6323,−6079|
| Boomer P350 θ45 W26 φ180 |6323,−6323|−66,250|6233,−6413 /6167,−6163|12308,−12664 /6009,−6001|
| Boomer P350 θ135 W26 φ0 |−6323,−6323|66,250|−6233,−6413 /−6167,−6163|−12308,−12664 /−6009,−6001|

Vento G98 (ax,ay): W26 φ0=(66,250); φ90=(0,184); φ180=(−66,250);
φ270=(0,317); φ45=(46,204); φ225=(−46,296). W1 φ45=(0,250).
Notar **gravidade quantizada250/256×400=390,625px/s²**, não392 exato;
G90 vira230/256×400=359,375; G94 vira240/256×400=375. 4G é escala nominal.

SS Boomer W0: fim tick35 p=(221305,−153195),v=(6323,−2053); ticks36..45
idênticos; tick46 p=(227628,−155376),v=(6323,−1931),damage700,diameter55.

Testes adicionais obrigatórios de integração (não só reaplicar fórmulas):

1. Comparar ticks contra valores literais do JSON, sinais e faixas de vento.
2. Capturar shell já lançado, mudar W/phi do Match, continuar: mesmo estadoFP.
3. Espelho no primeiro contato: vxFP nega exatamente; tick seguinte continua
   desse valor com ax original. Tornado e retorno sincronizam FP/float.
4. Filho com pos/velocity sobrescritas usa ambas na primeira integração;
   dual/dual+ têm relógios/transformações independentes.
5. Impacto no primeiro segmento encerra sem aplicar aceleração; posição não vem
   do renderer. P1 θ45=velocidade0 é aceito e cai pela gravidade.
6. Bounds nos quatro limiares e FP−1→pixel−1; altura−1000 ainda válida.
7. Carga3s com delta fragmentado/pausa, soltar Drag P1, nenhuma carga duplicada;
   CPU percorre1..10*f25 ou percentuais convertidos pela mesma função.
8. SS nos ticks35/36/45/46 independente de frame rate e chamadas de desenho.
9. Partida/predict com Boomer/itens/vento: igualdade de impacto, dano, miss,
   crateras e autoria. CPU usa mesma idade/limites/tick.

## Fronteiras que não foram resolvidas por esta RE

- Refino exato da colisão do cliente (Simulate8 + helpers458920/458a00),
  caixas e origem da boca nativas de cada arma: manter raycast/caixa já existente,
  documentar a adaptação. Não prometer emulação pixel por pixel.
- Voo especial completo de ASate/Knight/filhos/itens, colisões de clima original,
  dano em ponto fixo e refinamento Nak fora do trecho específico: não inventar.
- RNG de host original e calendário integral: relatório recuperado prova força
  inicial0..25, evento0..26 e oscilação[-1,0,1,0,1,0,−1,0] por turno, mas esta
  análise não validou todas as oito categorias contra weather.gd atual.
- Native elapsed/input mode1 tem diferenças históricas citadas acima; decisão
  de carga3s não deve ser descrita como clone exato de todo modo original.

O módulo comum e o estado Boomer já têm evidência suficiente para implementação.
Preservar baseline anterior; sem novos commits/push/build nesta sessão.
