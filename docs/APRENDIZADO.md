# Aprender com o protótipo pronto

## O caminho de um disparo

1. `game.gd` recebe o teclado ou o clique. Ajusta a mira e pede a `match.gd` para disparar.
2. `match.gd` confere se é o turno correto e se a arma está disponível. Cria um ou três projéteis e muda de **aim** para **flight**.
3. `combat.gd` calcula velocidade inicial usando ângulo, força e direção. A física avança em passos de **1/120 de segundo**.
4. Antes de aceitar a nova posição, o código verifica o segmento inteiro percorrido, procurando a primeira colisão com um veículo ou com o terreno.
5. No impacto, `terrain.gd` abre a cratera; `match.gd` aplica dano e emite eventos.
6. `game.gd` transforma os eventos em som, explosão, partículas e números de dano.
7. Ao terminar todos os projéteis, os veículos descem até a superfície que restou. O jogo verifica queda, dano e vitória antes de escolher o próximo turno.

Essa separação permite testar combate sem abrir uma janela. Também deixa uma base mais clara para discutir multiplayer depois: a interface não decide quem ganhou nem quanto dano ocorreu.

## Estado da partida

`menu → aim → flight → settle → aim` é o ciclo normal. A eliminação muda para `finished`. Pausa é uma condição da apresentação que interrompe a atualização do modelo, preservando o estado atual.

Esse controle evita erros como dois tiros ao mesmo tempo, movimentação durante um impacto ou uma ação antiga da máquina entrando em uma revanche. Reiniciar cria a arena e os atores novamente e descarta planos/projéteis da partida anterior.

## Física: por que ângulo, força e vento importam

A força determina a velocidade inicial. O ângulo divide essa velocidade entre os eixos horizontal e vertical. A gravidade acelera o projétil para baixo; o vento acrescenta aceleração lateral.

O integrador calcula `posição + velocidade × tempo + aceleração × tempo² / 2`, depois atualiza a velocidade. Essa equação é exata para a aceleração constante usada neste protótipo. O passo fixo mantém o mesmo comportamento quando a taxa de desenho varia.

Para experimentar, mude `GRAVITY` e os dados de `WEAPONS` em `combat.gd`. Aumentar gravidade encurta o alcance; aumentar velocidade alonga o arco. Não é necessário alterar o desenho do projétil para mudar suas regras.

## Terreno destrutível

`terrain.gd` mantém uma máscara: cada célula é chão ou vazio. Cada célula corresponde a dois pixels do mundo. A textura usa a mesma máscara. Explodir remove as células dentro de um círculo e atualiza a imagem.

Para colisão, uma travessia de grade visita cada célula cruzada pelo segmento do projétil. Verificar apenas a posição final permitiria atravessar uma parede fina; amostrar pontos espaçados também pode perder um canto. Um teste de regressão demonstra esse caso.

Os veículos procuram o primeiro chão abaixo deles depois de uma explosão. Não usamos corpos rígidos para decidir trajetória, vida ou turnos: essas regras ficam explícitas em GDScript.

## Como a máquina mira

A máquina experimenta combinações de ângulo e força. Cada candidata é simulada por `Combat.predict`, usando o mesmo passo, gravidade, vento e colisão do disparo real. Ela escolhe o impacto mais próximo do adversário e aplica um erro conforme a dificuldade.

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
| Dano, cratera, velocidade, atraso de armas | `scripts/combat.gd` |
| Vida e mobilidade dos veículos | `scripts/match.gd` |
| Formato e aparência do chão | `scripts/terrain.gd` |
| XP e nível | `scripts/profile.gd` |
| HUD, teclado, efeitos, menus | `scripts/game.gd` |
| Cores, fontes e aparência dos controles | `scripts/ui.gd` |
| Efeitos sonoros | `scripts/sound.gd` |

Mude um comportamento por vez e rode os testes antes de jogar. Use os testes como exemplos das regras, não como reprodução linha a linha da implementação. Depois valide visualmente: um teste de física não detecta um texto cobrindo o canhão.
