# Imagens originais do protótipo

Geradas com a ferramenta integrada **GPT Images**. Os PNGs finais foram copiados para `assets/art/` e são consumidos pelo projeto. Os originais não foram sobrescritos. A engine enquadra os veículos por regiões de textura; não houve edição raster dos arquivos.

Na versão 0.2, os mesmos PNGs recebem inclinação, recuo, reação ao dano e
destruição por transformações. Rodas, canhão, carga, bússola, clarão, detritos e
fumaça são desenhados em `scripts/battle_art.gd`. O metal do HUD usa gradientes
em memória. Não foram incorporados sprites, skins, código ou áudio do OpenBound.

## background.png

Prompt: Original 2D side-view artillery game background, wide landscape 1536x1024. Lush floating-island valley panorama in friendly nostalgic early-2000s cartoon game aesthetic, painterly cel-shaded anime videogame environment, aquamarine mist, layered distant floating limestone islands and small waterfalls, soft turquoise sky, warm ivory cumulus clouds, tiny distant red-roof windmill far left, green grass and pink flowers on distant ledges. Main playable ground is rendered separately by game, so NO foreground ground or platform, no characters, no tanks, no text. Keep middle 65 percent airy and uncluttered to read projectile arcs. Crisp decorative detail on distant edges, bright peaceful afternoon, wide composition.

## scarab.png

Prompt: Single ORIGINAL small cobalt-and-teal beetle-inspired artillery rover game sprite, strict 2D side view facing RIGHT. Friendly 2000s cartoon videogame sprite, ivory circular cockpit with tiny goggled pilot, two chunky black rubber wheels along horizontal baseline, rounded blue armor plates, brass rivets, small antenna with teal pennant. Short cannon level pointing right, compact rounded silhouette, vivid colors, crisp dark outlines, hand-painted cel shading. Entire vehicle centered with generous transparent padding. No ground, no shadow backdrop, no text or other items. Suitable for 100px-wide render. Actual transparent background.

## tortoise.png

Prompt: Single ORIGINAL small amber-and-rust tortoise-inspired artillery rover game sprite, strict 2D side view facing RIGHT. Friendly 2000s cartoon videogame sprite matching blue beetle artillery rover, ivory circular cockpit with tiny goggled pilot, two chunky black rubber wheels along horizontal baseline, rounded orange turtle-shell armor plates, brass rivets, tiny red pennant. Short cannon level pointing right, compact rounded silhouette, vivid colors, crisp dark outlines, hand-painted cel shading. Entire vehicle centered with generous transparent padding. No ground, no shadow backdrop, no text or other items. Suitable for 100px-wide render. Actual transparent background.

Terreno, canhão móvel, partículas, mira, barras e menus são desenhados pela engine. Os efeitos sonoros são sintetizados por `scripts/sound.gd`. Não foram reutilizados sprites, áudio ou código do Gunbound ou dos repositórios pesquisados.
