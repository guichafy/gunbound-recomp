# Registro e movimento sem troca de anatomia

Este fluxo trata correções de rig HD existente ou adaptação de animação
explicitamente solicitada. Para restauração fiel de atlas, conserve os quadros,
poses e janelas da fonte; não os substitua por transformações de um mestre.

## Bbox não é pivô

Gerar quadros bonitos separadamente pode variar rosto, roupa e silhueta.
Mesmo um único desenho HD treme se for deslocado pelo centro alpha de cada
quadro antigo. Cabelo, olhos e cone de luz alteram o recorte; não indicam
movimento anatômico. A interpolação desses centros apenas suaviza uma deriva
incorreta. Preserve uma caixa e um pivô de referência por peça constante.

Para conter uma região gerada com aspecto preservado na janela nativa:

```text
p = pivô nativo
b = bounding box da referência nativa (uma vez)
s = tamanho do recorte opaco da arte HD
r = (p - b.position) / b.size          # localização normalizada do pivô
d = s * min(b.size.x/s.x, b.size.y/s.y)
target = Rect2(anchor - d*r, d)         # coordenadas locais do conjunto
```

`anchor` é o ponto onde a peça se conecta ao Body. Não substitua esse ponto
pelo centro da figura gerada. As janelas de catálogo podem ser diferentes
entre peças, mas não entre quadros da mesma peça constante. Fallback nativo
conserva seu próprio calendário e geometria original.

## Montagem de Body no mobile

Defina os espaços antes de calcular: origem do ator, apoio/chão, pivô do
atlas, Body e quadris do piloto inteiro são pontos distintos.

No OpenBound, RiderPivot registra **Body**, não o quadril do mestre HD.
Na base visual do apoio, sejam `R` RiderPivot idle, `c=contact_y-pivot_y`,
`H` largura nativa do hull e `W` largura do hull nessa base:

```text
escala_avatar = W/H
origem_body = (R - Vector2(0,c)) * escala_avatar
mount = Transform2D(0, Vector2.ONE*escala_avatar, 0, origem_body)
avatar = support * chassis_pose * mount * pilot_sway
```

`support` já contém posição, direção, inclinação e contato de chão do render.
Não aplique o contato duas vezes. No rig atual W=60: Bigfoot R=(3,5), c=31,
H=49 dá origem local(3,−26)×60/49, aproximadamente(3,673,−31,837).
Mage R=(5,6), c=32, H=46 dá(5,−26)×60/46. São medidas desta fonte,
não posições universais. Para outros mobiles, leia seus metadados.

Âncoras relativas ao Body no catálogo atual: cabeça(7,−17), óculos(9,−17),
bandeira(11,−17), corpo(0,0). Use pivôs de cada peça; não centralize tudo.
Espelhe e incline o conjunto pela mesma base. Proporção precisa ser verificada
contra a fonte, não apenas contra o PNG novo. Chassis/arma/rodas ocultam a
parte inferior do avatar equipado; conserve a ordem de camadas apropriada
ao piloto monolítico quando esse for outro caminho do render.

## Movimento contínuo e pausável

- Rig usa as mesmas peças no idle, movimento, carga, recuo, dano e morte.
  Clarão/aura não pertencem ao tamanho do chassis; corpo não encolhe quando
  uma explosão aparece. Na morte, colapso/fade podem conservar o mestre.
- Respiração tem relógio contínuo pausável, separado de `pose_age`. Reiniciar
  `pose_age` para recuo/mudança de arma não reinicia fase respiratória.
- Use transform suave e pequeno em torno do Body/assento, compartilhado por
  cabeça/corpo/acessórios. Para piloto inteiro, mantenha anatomia unida.
- Guarde histórico de apresentação **por ator**. Ao mudar pose ou reiniciar
  ação, capture a geometria atualmente exibida; interpole dela até a pose
  atual. Interromper uma interpolação parte do resultado misturado, não de
  um quadro antigo. Nunca guardar histórico único num renderer compartilhado.
- Referência validada: `t=smoothstep(0,0.14,transition_age)`; misturar offsets
  por lerp e ângulos por lerp_angle. Ajuste a janela à ação; mantenha o tempo
  real de tiro/dano/morte. Um crossfade de desenhos com anatomia diferente
  cria contorno duplo e não substitui o rig.
- Rodas usam fase acumulada por deslocamento; parar não zera sua orientação.
  Posição/inclinação visual podem interpolar snapshots físicos, mas colisão,
  muzzle, dano e decisão de turno continuam usando estado físico.

## Projéteis e efeitos

Mantenha cabeça do projétil em registro/aspecto fixos. Separe chama, rastro,
brilho e impacto. Oriente pelo sentido real da arte: uma cabeça que aponta
à direita não recebe PI adicional. Mage usa rastro contínuo, não sequência
de cabeças repetidas. Impactos podem misturar fases com centro fixo; preserve
duração e semântica física. Fase gráfica não muda hit_pos, colisão ou EMP.

## Critérios observáveis

Teste geometria sem precisar da GPU: registro/dimensão invariantes, origem
correta, continuidade antes/depois da fronteira do ciclo, moving→idle,
carga→recuo→dano, recuo repetido e interrupção durante mistura. Pause no meio
da transição; relógio e geometria devem ficar iguais. Verifique atores
independentes, inclinações e espelhamento.

Na GPU, capture sequência a60fps e compare quadros adjacentes nas transições.
Além da sequência, entregue composição1920×1080 em framebuffer real, com
aspecto preservado. Uma imagem estática pode provar encaixe e nitidez;
não prova movimento suave. Reporte a dimensão real se a captura tiver outro
tamanho. Fallback ausente/inválido deve retornar arte original coerente,
sem personagem parcialmente desmontado por recursos obrigatórios faltantes.
