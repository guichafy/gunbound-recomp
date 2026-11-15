# Revisão independente do delta Android — safe area, IME e prévias

15/11/2026. Leitura somente, sem executar testes/build/AVD e sem editar
produto. Escopo: Game.fit_platform, PlatformLayout.safe_window, aspect expand,
Settings Android, recortes de prévias e fluxo host android_local. Back estava
em depuração ativa pelo coordenador e foi excluído deste parecer.

## Achados P1/P2

**Nenhum P1/P2 novo confirmado no delta solicitado.** Este resultado não
declara o smoke em andamento aprovado nem substitui o aceite em aparelho.

## Pontos conferidos

### Safe area física / IME

- Game.fit_platform faz a interseção no espaço físico antes da transformação
  inversa: safe display ∩ janela ∩ tela acima da IME, depois retira a origem
  da janela. PlatformLayout.safe_window tem fallback para safe display/tela
  inválidos. A mesma altura da IME não é subtraída novamente de uma janela já
  reduzida por adjustResize.
- Os testes lidos cobrem os dois contratos: tela2400×1080 com IME390 em janela
  completa ou janela2400×690 produz o mesmo retângulo físico útil; ocultar IME
  restaura o display safe. São testes de aritmética, sem declaração sobre
  teclado/OEM físico.
- safe_canvas/dp_scale continuam usando a inversa de get_screen_transform;
  não regressaram à divisão independente de dimensões. O display é convertido
  para coordenadas locais da janela antes de desenhar/hit test.

### Viewport e controles fora do canvas clássico

- project.godot aplica aspect="expand" apenas à feature Android. O viewport
  pode representar as margens em que os controles auxiliares são desenhados;
  o canvas clássico permanece1280×800 com fit uniforme.
- O desenho do touch usa as mesmas regiões de hit test em espaço do viewport,
  transformadas inversamente para o nó de apresentação. O root não tem clipping
  de conteúdo ativado. O matte fica abaixo da UI e cobre somente desenho
  clássico fora de seus limites, sem cortar os controles auxiliares.
- Não observei mudança da resolução do terreno, colisão, CameraRig.VIEW_SIZE
  ou da geometria de tiro como efeito dessa alteração de apresentação.

### Settings / foco

- show_settings deixou de chamar grab_focus no Android; a IME aparece após
  toque deliberado no apelido. Desktop conserva o foco anterior. No Android,
  select_all_on_focus facilita substituir o valor existente sem depender de
  teclado físico. O teste verifica ausência de foco automático e a propriedade.
- IME submit continua usando a transação de salvar já existente. A revisão
  não executou teclado real, acentos, seleção ou serviços de foco do Android.

### Prévias dos mapas

- O builder recorta22quadros544×336 do strip11968×336, sem reamostrar ou alterar
  alpha. A ordem é índice crescente e o catálogo guarda fonte/hash e nomes
  fixos. A forma da fonte é validada antes de criar saídas.
- O ramo Android em ClassicRoomArt.frame usa somente os recortes válidos;
  schema/dimensões/fonte/catálogo aprovado/índices/nomes/presença são checados.
  O fallback de image("room_maps") no Android é o strip nativo pequeno;
  não volta ao atlas HD largo que excede o limite GLES observado.
- Os consumidores da sala usam frame("room_maps", room_frame), preservando
  tamanho lógico136×84. Não observei troca da associação mapa→índice ou
  alteração do mapa da partida. Desktop conserva o caminho anterior.
- O APK exige catálogo e imports das22prévias e confere resolução dos remaps.
  Testes lidos comparam os recortes regenerados ao original pixel a pixel e
  verificam caminhos/ordem/fallback no consumidor. Não rodei esses testes.

### Host macOS

- android_local conserva recusa de telefone/porta inválida, AVD com nome
  reservado e package .ci antes de alterações. O reconnect acrescentado em
  open_apk é wait-for-device somente leitura; taps/Back não são repetidos.
- O helper usa SDK já instalado em leitura, JDK/templates verificados em
  .tools e AVD/user home do worktree. A troca de certificado efêmero remove
  somente o sandbox CI nesse AVD. O contrato de atualização persistente não
  foi misturado ao fluxo local.
- Não encontrei um bloqueio concreto novo no encadeamento prepare/build/
  boot/open/check. Continuam requisitos explícitos Godot4.7.2, import do
  projeto, SDK/imagem apropriados, Python compatível e swiftc/Vision no Mac.

## Limites restantes

A interseção segura é matematicamente coerente para os espaços declarados;
confirmar os valores reais de window position/size, screen size, safe area e
altura IME em runtime permanece necessário, inclusive após resize/rotação.
O teste de aspect por ProjectSettings não demonstra sozinho pixels visíveis
no framebuffer Android. O coordenador conduz essa validação de AVD separada.

Não converter este parecer em aprovação de Back, áudio, multitouch físico,
ARM64 físico, API24 ou atualização de distribuição. As ressalvas de evidência
dos relatórios anteriores permanecem onde não foram substituídas por prova
runtime específica.
