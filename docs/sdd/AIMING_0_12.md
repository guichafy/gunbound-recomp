# Modo de mira Drag/Slice 0.12 — especificação e plano

## Pedido

"Aiming mode: vamos implementar (com uma opção para desligar e ligar no menu
configuração). Mouse Speed: vamos deixar desabilitado com um TODO para
implementar. Skins de interface: vamos deixar apenas Skin Blue." (2026-10-11)

## Fonte

O OpenBound declara `AimType` (padrão 1) e o rádio "Aiming Mode: Drag / Slice"
em `PopupGameOptions.cs`, mas nunca implementou o modo ("Pre-release
deactivation"). O comportamento vem do GunBound original, segundo guias de
jogadores:

- StrategyWiki (Gunbound/Controls): o mouse faz "drag style shooting"; o
  Espaço carrega a força "when using slice style shooting".
- GameFAQs ("how to use drag"): segurar o botão esquerdo, arrastar da
  esquerda para a direita e soltar; parar ou voltar faz a barra tremer.

## Requisito

- **REQ-34 — Modo de mira Drag/Slice.**
  - O rádio "Aiming Mode" do popup de opções fica ativo e liga/desliga o
    modo: **Slice** (padrão, como o original) mantém exatamente o
    comportamento atual; **Drag** liga o tiro por arraste do mouse. O valor é
    gravado com as demais opções (`aiming`: 0 Drag, 1 Slice).
  - Drag: no turno do jogador, pressionar o botão esquerdo na área do mundo
    (acima da barra de ação) zera a barra de força e começa o arraste; a força
    é o deslocamento horizontal desde o ponto inicial sobre a largura da barra
    de força na tela (400 × 1,6 = 640 px = 100), limitada a 0–100; voltar o
    cursor reduz a força. Soltar dispara uma vez com a força mostrada.
  - Tremor: enquanto o cursor não avança para a direita, a força oscila
    ±2 a cada 0,04 s (RNG próprio da apresentação, nunca o da partida).
    Amplitude é adaptação: as fontes não dão o valor.
  - Clique sem arraste (força < 1) cancela sem disparar. Soltar fora do mundo
    (sobre a barra do HUD ou fora da janela) também é detectado e dispara com
    a força mostrada, como o original solta o botão. Popup, pausa, ajuda,
    troca de turno, tempo esgotado e recomeçar cancelam o arraste sem
    disparar.
  - Arraste e Espaço são exclusivos: com um ativo, o outro é ignorado (um só
    disparo). O Espaço continua funcionando no modo Drag (teclado, ajuda e o
    botão ● dependem dele).
  - Câmera: no Slice o botão esquerdo continua olhando o mapa; o botão
    direito (ou do meio) olha o mapa nos dois modos. No Drag, durante a mira
    do jogador, o botão esquerdo é tiro.
  - Drag não dispara sozinho ao chegar a 100 (o Slice continua disparando a
    100). Exceção registrada à invariante "carga crescente que dispara a 100%".
- **Mouse Speed:** continua desabilitado, com `TODO` no código; quando for
  implementado deve escalar a distância do arraste do Drag.
- **Interface:** só a skin Blue, por decisão do usuário (rádio desabilitado,
  TH Blue marcado).

## Limites

Com toque emulado como mouse, no modo Drag o próprio turno não permite olhar o
mapa arrastando (só o tiro); use o Slice ou o botão direito. Tiro reverso por
arraste não existe (também não existia segundo os guias).

## Fases

A. Especificação e ADR-056. B. Opção no popup, input Drag, câmera, cancelamentos.
C. Testes de cena (incluindo soltura sobre o HUD via viewport), docs, ajuda,
captura, check.sh, reexportação e commit local.
