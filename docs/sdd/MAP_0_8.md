# Mapa Miramo Town 0.8 — especificação e plano

## Pedido

"Devemos implementar um mapa do projeto Gunbound C#, utilize GPT Images para
gerar imagens dos sprites do mapa em alta definição. Utilize a pasta Gunbound
para descobrir as informações de assets e lógica do jogo."

Escolhas do usuário (pergunta única, 2026-10-11):

- Mapa: **Miramo Town, variante A** (terreno de neve contínuo, sem buracos).
- Enquadramento: **arena fixa 1280×800**, sem câmera rolante. HUD, mira,
  CPU e input permanecem iguais.

## Requisito

**REQ-21 — mapa original Miramo Town A.** A arena de treino passa a usar o
terreno e o fundo do mapa Miramo Town A do OpenBound, com visual HD derivado
por GPT Images. A colisão continua vindo de uma máscara única, agora derivada do
alpha original do `ForegroundA.png`, nunca do PNG gerado. Requisitos afetados:
REQ-04 (colisão, crateras), REQ-05 (queda), REQ-08 (CPU usa a mesma máscara),
REQ-11 (direção de arte, já relativizada por REQ-19/20), REQ-12.

## Fonte de verdade no C#

- `Openbound Network Object Library/Entity/Map.cs`: ID20 "Miramo Town", tipo A,
  `WeatherPreset` {2,1,2,1,0,2,0,0,0,1}, 11 spawn points em pixels do
  foreground (148,1439 … 1673,1400), partícula de chão com 60 quadros.
- `GameComponents/Level/Topography.cs`: célula colidível ⇔ `alpha > 0` do
  foreground. `CreateErosion` abre o círculo `radius` e escurece um anel de
  `radius + BlastBlackmaskRadius(3)` multiplicando a cor por 0,4.
- `GameComponents/Level/Scene/LevelScene.cs`: `Background.png` com parallax e
  `Foreground{tipo}.png` como área jogável. Miramo Town não declara flipbooks
  (`BackgroundAnimation*.png` não são usados nem no original).
- `RoomMetadata.cs`: cada jogador recebe um spawn sorteado da lista, sem repetição.

## Desenho

- Recorte: bbox do alpha original x17–1783, y1344–1800 (1766×456 px). Escala
  única `k = 1280/1766` para o mundo: o terreno ocupa x0–1280 e
  y420–≈750,5; a colisão termina em y670, onde começa o HUD: abaixo é abismo, para nenhum mobile ou impacto ficar escondido.
- Colisão: o recorte é reamostrado (vizinho mais próximo) para a grade atual de
  640×400 células de 2 px; linhas 210–375. `cells` derivada uma vez e copiada
  por partida. `generate()` procedural continua disponível (`map_id` vazio).
- Visual: `assets/hd/maps/miramo_town/foreground_a.png`, 2560×661 (2× mundo),
  alpha = máscara original ampliada. Crateras apagam essa imagem na mesma
  transformação e escurecem o anel ×0,4 como o `CreateErosion` original; a
  borda de cor fixa e os tufos de grama procedurais não são usados no mapa.
- Fundo: `background.png` HD (ou o `Background.png` original como fallback),
  recorte com largura total, alinhado à base como a câmera original no chão.
- Spawns: 1×1 sorteia, com o `rng` da partida, um spawn da metade esquerda para
  o jogador e outro da metade direita para a CPU, convertidos por `k`.
  Lado fixo preserva orientação inicial e a UI existente.
- Clima/Thor, partícula de chão e miniaturas ficam fora deste corte.

## GPT Images

Codex CLI `image_gen` (`gpt-5.6-sol`), mesmo pipeline de 0.6. O foreground
tem proporção 3,9:1, então foi gerado em três blocos 3:2 sobrepostos
(684×456 → 1536×1024 cada); o fundo, em dois blocos 2:3. Blocos brutos ficam
intactos em `assets/hd/maps/miramo_town/source/` (`.gdignore`, fora do pacote).
`scripts/build_map_hd.py` costura com feather linear, aplica a máscara original
e grava `manifest.json` com SHA-256. Prompts em `assets/hd/MAP_PROMPTS.md`.

## Critérios de aceite

1. Partida inicia no Miramo Town A; jogador à esquerda e CPU à direita, sobre
   chão sólido e dentro da arena.
2. Toda célula sólida corresponde ao alpha original na posição transformada;
   visual e colisão concordam (amostragem da imagem HD).
3. Cratera remove células e pixels visuais; `collision_copy` independente.
4. Previsão da CPU e disparo real seguem usando a mesma máscara.
5. Suites existentes e dez partidas completas passam; fixtures que dependem da
   geometria procedural pedem o terreno procedural explicitamente.
6. Captura real 1920×1080 da arena com o mapa.

## Limites

Adaptação HD, não restauração quadro a quadro. Arena fixa reduz o mapa
(1766 px → 1280 unidades); não há rolagem, parallax nem queda pelas bordas
como no original. "Gunbound"/OpenBound são de terceiros; uso local.
