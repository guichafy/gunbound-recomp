# Aprender com o protótipo pronto

## O caminho de um disparo

1. `game.gd` recebe o teclado ou o clique. Ajusta a mira e pede a `match.gd` para disparar.
2. `match.gd` confere se é o turno correto e se a arma está disponível. Cria um ou três projéteis e muda de **aim** para **flight**.
3. `match.gd.shot_velocity` combina ângulo local, direção e inclinação do apoio; `combat.gd` calcula a velocidade e avança a física em passos de **1/120 de segundo**.
4. Antes de aceitar a nova posição, o código verifica o segmento inteiro percorrido, procurando a primeira colisão com um veículo ou com o terreno.
5. No impacto, `terrain.gd` abre a cratera; `match.gd` aplica dano e emite eventos.
6. `game.gd` transforma eventos em som/texto e delega a `battle_art.gd` o recuo, reação ao dano, rodas, carga, destruição e efeitos de impacto.
7. Ao terminar todos os projéteis, os veículos descem até a superfície que restou. O jogo verifica queda, dano e vitória antes de escolher o próximo turno.

Essa separação permite testar combate sem abrir uma janela. Também deixa uma base mais clara para discutir multiplayer depois: a interface não decide quem ganhou nem quanto dano ocorreu.

## Estado da partida

`menu → aim → flight → settle → aim` é o ciclo normal. A eliminação muda para `finished`. Pausa é uma condição da apresentação que interrompe a atualização do modelo, preservando o estado atual.

Esse controle evita erros como dois tiros ao mesmo tempo, movimentação durante um impacto ou uma ação antiga da máquina entrando em uma revanche. Reiniciar cria a arena e os atores novamente e descarta planos/projéteis da partida anterior.

## Física: por que ângulo, força e vento importam

A força determina a velocidade inicial. O ângulo divide essa velocidade entre os eixos horizontal e vertical. A gravidade acelera o projétil para baixo; o vento acrescenta aceleração lateral.

O integrador calcula `posição + velocidade × tempo + aceleração × tempo² / 2`, depois atualiza a velocidade. Essa equação é exata para a aceleração constante usada neste protótipo. O passo fixo mantém o mesmo comportamento quando a taxa de desenho varia.

Para experimentar, mude `GRAVITY` e os limites de velocidade em `combat.gd`; os dados das armas ficam em `bigfoot_attacks.gd` e `match.gd.MAGE_WEAPONS`. Aumentar gravidade encurta o alcance; aumentar velocidade alonga o arco. Não é necessário alterar o desenho do projétil para mudar suas regras.

## Terreno destrutível

`terrain.gd` mantém uma máscara: cada célula é chão ou vazio. Cada célula corresponde a dois pixels do mundo. A textura usa a mesma máscara. Explodir remove as células dentro de um círculo e atualiza a imagem.

Para colisão, uma travessia de grade visita cada célula cruzada pelo segmento do projétil. Verificar apenas a posição final permitiria atravessar uma parede fina; amostrar pontos espaçados também pode perder um canto. Um teste de regressão demonstra esse caso.

Os veículos procuram o primeiro chão abaixo deles depois de uma explosão. Não usamos corpos rígidos para decidir trajetória, vida ou turnos: essas regras ficam explícitas em GDScript.

## Como a máquina mira

A máquina experimenta combinações de ângulo e força. Cada candidata é simulada por `Match.predict_shot` em uma cópia da partida e da máscara, com o mesmo avanço de salvas, usando o mesmo passo, gravidade, vento e colisão do disparo real. Ela escolhe o impacto mais próximo do adversário e aplica um erro conforme a dificuldade.

Assim a dificuldade tem uma causa compreensível: mira menos precisa. A máquina não recebe um projétil que teletransporta para o jogador nem aumenta seu dano escondido. Nesta versão ela não planeja deslocamento; esse é um caminho de melhoria separado.

## Turnos por atraso

Cada ator tem uma disponibilidade acumulada, chamada `ready`. Disparar soma o atraso da arma e do veículo. Quem tem o menor valor joga em seguida; o relógio da fila avança para essa disponibilidade. O atraso mostrado na tela é a diferença para esse relógio.

Isso cria uma decisão tática: causar mais dano agora ou recuperar o turno mais rápido. Os testes verificam tanto a troca de ator quanto a possibilidade de o mesmo ator manter a iniciativa.

## Persistência

`profile.gd` guarda dados pequenos em JSON. O carregamento valida tipos e valores, e recupera padrões quando o arquivo está corrompido. O salvamento escreve um arquivo temporário antes de substituir o definitivo.

Cada partida tem um identificador. A recompensa registra esse identificador para impedir que abrir a tela de resultado duas vezes some XP duas vezes. Os testes fazem isso com um perfil separado do seu perfil real.

## Onde alterar cada coisa

| Experimento | Arquivo |
|---|---|
| Dano, cratera e atraso das armas | `scripts/bigfoot_attacks.gd`, `scripts/match.gd.MAGE_WEAPONS` |
| Velocidade/gravidade/colisão compartilhadas | `scripts/combat.gd` |
| Vida e mobilidade dos veículos | `scripts/match.gd` |
| Formato e aparência do chão | `scripts/terrain.gd` |
| XP e nível | `scripts/profile.gd` |
| HUD, teclado, efeitos, menus | `scripts/game.gd` |
| Animações de veículo, canhão, bússola, explosão | `scripts/battle_art.gd` |
| Cores, fontes e aparência dos controles | `scripts/ui.gd` |
| Efeitos sonoros | `scripts/sound.gd` |

Mude um comportamento por vez e rode os testes antes de jogar. Use os testes como exemplos das regras, não como reprodução linha a linha da implementação. Depois valide visualmente: um teste de física não detecta um texto cobrindo o canhão.

## O que a versão 0.2 ensina

O ângulo inferior é local ao veículo. Dois apoios laterais fornecem a inclinação,
limitada a ±30° e descartada se o apoio estiver distante ou ausente. A direção
local é girada por esse ângulo antes de virar velocidade. `muzzle`, canhão e
previsão usam a mesma conversão. Espelhar o PNG apenas muda a aparência; mudar
`facing` no modelo também muda o tiro.

A fila visível é uma previsão: calcula o custo sem alterar `ready`, `clock` ou
RNG. Não deve inventar uma arma para a CPU ainda indecisa. Animação também é uma
projeção: interpola a posição visual, mas colisão continua usando a posição real.

Carga é uma pequena máquina de estados na entrada: apertar → carregar → soltar
ou completar → disparar uma vez. Pausar/expirar/reiniciar cancelam a carga antiga.
Uma soltura atrasada após auto-disparo não cria outro projétil. Os testes usam
os handlers de teclado reais para proteger essas transições.

O HUD metálico usa texturas de gradiente geradas por código e compartilhadas,
sem downloads de skins. Textura/estilo não é recriado a cada quadro. Na revisão,
um cenário de cratera revelou que o painel lateral podia esconder vida; uma
regressão reproduziu isso antes de adaptar sua posição.

## IDs e peças do mobile

O roster atual só tem Mage(ID1) e Bigfoot(ID2). O slot do botão não é o ID;
UI consulta PLAYABLE_VEHICLES e o modelo escolhe o outro como CPU. ID0 foi
removido; entradas antigas/inválidas normalizam para Bigfoot.

mobile_rig.gd articula peças constantes e piloto inteiro em perfil. A perna
invisível é ocultada no próprio PNG, pois trocar a ordem de uma imagem inteira
não muda a sobreposição dentro dela. O catálogo conserva o espaço transparente
para manter mãos e assento na posição aprovada. Física não usa essas imagens.

## Loja local, composição e atributos

O catálogo preserva a chave gênero/categoria/ID: Basic0 masculino e feminino
não são o mesmo item. A interface seleciona uma chave; o perfil resolve preço
e valida saldo/propriedade, grava débito e posse juntos e restaura a cópia
anterior se falhar. Experimentação vive no modelo da loja, não no perfil.

O rider junta quatro camadas usando pivôs da fonte. Atlas têm grades diferentes;
o quadro é convertido em coluna/linha, sem recentrar o recorte a cada frame.
O rig do mobile aplica transformação conjunta e não modifica colisão.

A partida copia atributos; dano e Dig são aplicados no laço comum ao tiro e à
previsão. AttackDelay converte o inteiro original antes de dividir por7,5.
Gold/Popularity ficam no modelo, e a concessão final usa o mesmo ID idempotente
de XP. O fluxo C# multiplica Gold acumulado por tiro, usa4/1 Gold no resultado
e tem a condição2000 inalcançável: peculiaridades preservadas e testadas.
