# Prompts GPT Images — mapa Miramo Town 0.8

Gerados com o Codex CLI (`codex exec -m gpt-5.6-sol --sandbox read-only -i <bloco>`),
ferramenta integrada `image_gen`, uma edição por bloco. Cada referência é uma
janela do original em `assets/openbound/maps/miramo_town/`:

| Bloco | Janela original (x0,y0,x1,y1) | Saída |
|---|---|---|
| fg_tile0 | 17,1344,701,1800 de ForegroundA | 1536×1024 RGBA |
| fg_tile1 | 558,1344,1242,1800 | 1536×1024 RGBA |
| fg_tile2 | 1099,1344,1783,1800 | 1536×1024 RGBA |
| bg_tile0 | 0,260,693,1300 de Background | 1024×1536 RGB |
| bg_tile1 | 607,260,1300,1300 | 1024×1536 RGB |

Origens `exec-*.png` em `GENERATION.json`. `scripts/build_map_hd.py` costura,
aplica a máscara original e registra SHA-256 em `maps/miramo_town/manifest.json`.

## Foreground (três blocos)

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: style-transfer / upscale remaster. The attached image is one horizontal section of the classic Gunbound "Miramo Town" battlefield terrain (a destructible foreground strip). Remaster this EXACT section into clean high resolution hand-painted 2D game artwork for a Full HD game. Output a landscape 3:2 PNG, ideally 1536x1024, where the terrain fills the WHOLE canvas exactly like the reference fills its frame: same framing, same scale, same position of every element, NO zoom, NO crop, NO added margin. Preserve the EXACT silhouette: the wavy snow-cap top outline with its bumps and dips must stay at the same pixel positions relative to the frame; left/right/bottom edges continue to the borders exactly as in the reference. Keep the identical content: thick glossy white-blue snow layer on top with small blue pebbles, a band of faceted icy blue and lavender crystal shards hanging below the snow, pale frosted blue ice rock body with dark navy outlines, carved ice creature faces and round dots exactly where they appear, any arched ice door exactly where it appears. Same cool palette (white, ice blue, periwinkle, lavender, navy outlines). Improve only fidelity: crisper facet edges, finer frost texture, cleaner snow highlights and soft shading, nostalgic painted cartoon look of the original game. Do not redesign, do not add new objects, buildings, characters, text, sky, background scenery or ground shadow. Where the reference is transparent (the area above the snow outline), keep it genuinely transparent.
```

## Background (dois blocos)

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: style-transfer / upscale remaster. The attached image is one vertical section of the classic Gunbound "Miramo Town" battle background: a snowy fantasy town on two cliffs under a lavender sky, with white towers, a woolly mammoth on a round tower, pipes, snowy pine trees, colourful cottages, a teddy bear snow statue, wooden ladders on rope, cloud sea in the canyon, grey rocky mountains and ice crystal spires. Remaster this EXACT section into a clean, crisp, high resolution painted 2D game background for a Full HD game. Output portrait 2:3, ideally 1024x1536, fully opaque. The image must fill the whole canvas with exactly the same framing as the reference: same scale, same position of every building, tree, cloud, cliff edge and horizon, NO zoom, NO crop, NO added border, NO new objects. Content touching the left or right edge must continue to that edge exactly as in the reference, because this section will be stitched to its neighbour. Keep the same palette (lavender sky, white-blue snow, slate rock, warm red/yellow/teal cottages) and the nostalgic soft rendered cartoon look of the original game. Improve only fidelity: sharper edges, cleaner snow and rock texture, clearer windows, roof tiles, trees and clouds. No text, no logos, no characters, no vehicles.
```
