# Câmera, vento, clima, Thor e partícula 0.9 — especificação e plano

## Pedido

"Implemente o resto pendentes: clima, Thor, partícula de chão, outros mapas e
câmera rolante." Decisões do usuário (2026-10-11):

- **Outros mapas: não.** Manter apenas Miramo Town A; nenhum HD novo de mapa.
- **Câmera rolante em escala nativa 1:1** (substitui a arena fixa de ADR-042).
- **Vento 2D do original** (força 0–35, ângulo 0–360).
- **Commits locais por fase**, sem push.

Visuais de clima/Thor/partícula usam os sprites e sons originais do OpenBound
(sem GPT Images, pela decisão de não gastar cota em HD novo).

## Requisitos

- **REQ-22 — Câmera rolante.** O mundo do mapa é a imagem inteira do
  `ForegroundA.png` (1800×1800), em coordenadas nativas: spawns, clima e Thor
  do original valem sem conversão. A área visível do mundo é 1280×670 (acima do
  HUD). A câmera segue o mobile ativo na mira, o projétil em voo e o impacto,
  com amortecimento `1/25` por quadro (`Camera.CameraTrackingDampeningFactor`);
  arrastar com mouse/toque desloca a câmera até o próximo turno ou disparo.
  O fundo usa parallax como `LevelScene.UpdateBackgroundParallaxPosition`,
  limitado à faixa coberta pelo fundo HD. Terreno procedural continua 1280×800
  e câmera fixa.
- **REQ-23 — Vento 2D.** `MatchMetadata`: força 0–35 e ângulo 0–360. Por
  rodada, 50% de chance de perturbação (força ±2, ângulo ±3); o clima *Wind*
  sorteia de novo. Aceleração = (cos, sin)·força·1,3 px/s² (35 ≈ 45 px/s², o
  máximo anterior). Adaptação: a partida começa com um sorteio de *Wind*
  (no original começa em zero e raramente muda).
- **REQ-24 — Clima.** Pesos do `WeatherPreset` do Miramo A. Fila de 4
  (ativo + 3 previstos); uma rodada = 2 turnos, ao fim de cada uma entra um novo
  e o mais antigo sai, como `WeatherDisplay`. Colunas de altura total em
  `x = n·largura`, meia-largura 20 (Force/Electricity/Weakness/Mirror), 35
  (Tornado), 40 (Random), escala somada ao fundir colunas sobrepostas do mesmo
  tipo; um tipo ativo diferente apaga os demais. Efeitos aplicados no
  integrador comum (tiro real e previsão):
  Force dano ×1,2+10; Weakness ÷1,2−10 (usa as constantes do Force, como o
  código); Mirror inverte vx e dano ×1,1+5; Electricity dispara raio vertical no
  impacto (cratera 10, choque 30 a até 30 px da linha); Tornado conduz o tiro
  em zigue-zague (3 etapas) e o relança na velocidade inicial; Random ativa uma
  vez e cria Force/Tornado/Electricity/Weakness/Mirror; Protection cura 35;
  Ignorance sem efeito (não há itens).
- **REQ-25 — Thor.** Satélite em x 10–90%, y 10–70% do mapa. Enquanto ativo,
  todo tiro se liga a ele; no impacto, um raio do satélite até o ponto acerta o
  primeiro sólido: raio 25, dano 40+20·nível, XP = dano causado, níveis pela
  tabela 800/1400/2000/2400/3000. Desativa quando outro tipo de clima entra.
- **REQ-26 — Partícula de chão.** Cada explosão que remove terreno emite
  `pixels removidos ÷ 32` partículas do `Particle.png` do mapa (60 quadros
  48×48), com espalhamento, gravidade e vento do `ParticleBuilder`. Só
  apresentação; a pausa congela.

## Opção de clima (ADR-048)

Menu: "original do mapa" (padrão) ou "todos os efeitos" (pesos iguais, Thor
incluído), porque o preset do Miramo A não sorteia Thor.

## Invariantes preservados

`match.gd` decide turno, dano, clima e Thor; `game.gd` apresenta. A previsão
da CPU roda o mesmo laço de voo em cópias (máscara, atores, clima, Thor, vento)
e não altera estado vivo. Mira relativa ao apoio, carga e pausa inalteradas.

## Fases

A. Mundo nativo + câmera (Miramo e procedural). C. Vento 2D, clima e Thor no
modelo. D. Visuais (colunas, satélite, raios, ícones, bússola 2D, partícula).
E. Capturas, export/PCK e documentação. Commit local ao fim de cada fase.

## Limites

Arte de clima/Thor original (baixa resolução). Choque elétrico aproximado pela
distância ao segmento vertical; rodada definida como 2 turnos totais por causa
da iniciativa por atraso; influência de vento igual para todas as armas.
