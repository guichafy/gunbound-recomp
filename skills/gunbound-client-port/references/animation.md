# Animação: relógio, geometria e composição

## Separar responsabilidades

| Dado | Responsável |
|---|---|
| Carrier, velocidade, fase, colisão, SS e filhos | Modelo, por projétil |
| Pose/EPA, spawn e áudio | Eventos/timelines, com instantes próprios |
| Histórico e estados anteriores | Amostras publicadas pelo modelo |
| Interpolação, malha, atlas e efeitos | Apresentação, em cópia visual |

Confirmar a ordem nativa: velocidade antes/depois da aceleração muda o
resultado. Somar a onda repetidamente ao carrier causa deriva. Guarda
visual por idade não substitui estado explícito do modelo. Congelar clocks
e endpoints anteriores durante hold/pausa. Dual, Dual+ e filhos têm estado
independente; sinalizador não herda o especial do tiro substituído.

## Rastro e raster

Medir células do atlas, duração/sequência, origem, escala, UV, alpha, blend e
quantidade de amostras. Compartilhar bordas entre seções adjacentes: normais
independentes por quad deixam frestas. Conferir diagonal/UV dos triângulos
no ápice, força mínima e curvas fechadas. Se o original desenha quads cruzados
como dois triângulos, preservar essa topologia; triangulador de polígonos
simples pode rejeitá-los.

**Exemplo específico do Turtle:** WaterEffect usa oito colunas, UV horizontal
1/8 e alpha `(255-16*i)/255`. T1 não recebe cabeça Armor só porque compartilha
o asset base. T2 exige estado inteiro: fase 0/180°, amplitude 1000 centipixels,
avanço 5° por tick; primeiros dez ticks +200/+4, depois −20/−1 com piso zero.
Avançar fase antes de atualizar esse envelope. Colisão usa heading
pré-aceleração; seção ±10 usa o pós. Em voo longo, avanço chega a zero no
contador 55 e amplitude no 160; testar além disso. Esses números não são
padrão para outros mobiles; localizar fontes exatas pelo mapa do projeto.

SS pode trocar EPA, aguardar, gerar filhos e remover o pai sem explosão.
Testar impacto antes/durante/depois da transição; transportar `child` e estado
SS até os efeitos. Não decidir impacto/filhos pelo último frame visível.
Som por grupo evita duplicação por componente; pose Dual pode começar em
instante diferente do spawn.

## Mobile e avatar

Fixar pivôs na janela nativa, aspecto, escala, montagem Body/RiderPivot,
espelhamento e ordem de camadas. Não recalcular juntas pelo centro alpha de
cada quadro. Para equipamentos, preservar compatibilidade, IDs e oclusão do
chassis. Luz aderente à anatomia usa registro da peça base e, quando
comprovado, máscara derivada dela. HD aprovado continua no jogo; fidelidade
de comportamento não exige substituí-lo por arte clássica. Aplicar
gunbound-classic-hd aos detalhes de rig/efeitos quando necessário.

## Validar movimento

Capturar sequência GPU do renderer real com dimensões/FPS/frames medidos.
Conferir dois sentidos, inclinação, ápice/vertical, força mínima/máxima,
voo longo, nascimento/impacto/filhos, pausa e retomada. Exercitar itens e
clima que alteram o caminho, identificando adaptações. Comparar estados em
30/60/120 FPS para independência do render.

Inspecionar continuidade, além de screenshot e contagem de testes. Vídeo
encerrado antes do contador 160 não demonstra visualmente a amplitude zero
do exemplo. Pausa estável pode ser conferida por hashes; retomada também
precisa de inspeção. Áudio afetado exige escuta. Usar perfil isolado e
conferir os recursos importados no PCK se entregar app.
