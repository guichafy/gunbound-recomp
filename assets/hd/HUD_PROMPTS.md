# Prompts GPT Images — HUD de batalha 0.10

Gerados com o Codex CLI (`codex exec -m gpt-5.6-sol --sandbox read-only -i ref_<folha>.png`),
ferramenta integrada `image_gen`, uma edição por folha. `scripts/build_hud_hd.py refs`
monta as folhas de referência (layout fixo sobre fundo #161E2E); a imagem gerada
é salva como `hud/source/gen_<folha>.png` e `build_hud_hd.py` recorta cada sprite,
redimensiona para 3× o original e aplica o alfa original. Origens `exec-*.png` em
`GENERATION.json`; SHA-256 em `hud/manifest.json`.

## Folha `bar`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI. The attached image shows three horizontal slices of the classic Gunbound blue in-game action bar (the bottom HUD console), stacked vertically with dark gaps. The slices overlap: they will be stitched back side by side, so content at the left/right edges of each slice must continue to the edge exactly as in the reference. Preserve: steel-blue metallic frame panels with bevels and rivets, the dark "WEAPON" panel at the left with the white italic WEAPON title, the black rounded "LAST" angle window with its small yellow dot, the long dark item slot panel with tiny "F1" and "F6" labels, the white glossy weather window, the four-cell dark weather/status strip, the long dark power meter channel and movement channel, the gold coin icon and the orange "G" in the right gold window. Same colors (steel blue, navy, white highlights, black windows). Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `buttons`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI buttons. The attached image is a sheet of the classic Gunbound blue HUD buttons, each drawn in a separate cell on a dark background: row 1 five states of the weapon "1" button (normal, hover, pressed, disabled grey, active); row 2 the same five states of the weapon "2" button; row 3 the five states of the orange "SS" special button followed by a small yellow-and-red power marker; row 4 four states of the red "ESC" options button with a grey wrench/hammer icon; row 5 four states of the blue "F8 PASS" skip-turn button with a crossed-out blue character icon. Preserve every button shape, the folder-tab top with its colored highlight strip (brown, beige, yellow, grey, yellow), the digit and SS lettering, the ESC / F8 PASS lettering in the same pixel-style white and yellow text, and every icon. Each state must keep its own color difference exactly as in the reference. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `fonts`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game number fonts. The attached image is a sheet of classic Gunbound HUD digit sprite-fonts, one font per row, each row is a strip of glyphs 0 1 2 3 4 5 6 7 8 9 and sometimes a minus sign, in exact equal-width cells: row 1 gold yellow bold italic digits on black squares; row 2 gold-orange italic digits on dark blue-grey squares; row 3 big red blocky digits with the minus sign first; row 4 two lines of small white digits with black outline; row 5 thin pale beige LCD-style digits; row 6 white digits on light-blue square badges; row 7 white digits on orange square badges; row 8 small pale-blue italic digits, then small white digits with black outline. Each glyph must stay EXACTLY in its cell, same glyph shapes and same digit order, same width and height, same colors and outlines. Make edges sharper and smoother (vector-clean anti-aliased digits) without changing their design. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `timer`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of a game timer font. The attached image shows the classic Gunbound turn timer digit sprite-sheet: the digits 0 1 2 3 4 on the top row and 5 6 7 8 9 on the bottom row, each a big glossy red brush-stroke digit with dark red outline, in equal cells. Preserve each digit exactly in its cell, same shape, same slant, same size, same red gradient and dark outline. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `misc`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI sprites. The attached image is a sheet of classic Gunbound HUD sprites on a dark background: row 1 the round dark wind compass dial with orange tick marks, the purple translucent compass glass ring, a white arrow, a yellow arrow, a red arrow (arrows are faint and translucent), and the grey ring-shaped crosshair frame with an opening at the bottom right; row 2 the turn-counter balloon sheet (21 small rounded badges with numbers 20 down to 0, blue then yellow then red, each with a small pointer at the bottom) and a small orange square frame; row 3 the weather icon strip (colored icons on top, the same icons in greyscale below). Preserve every element shape, color, translucency, and numbers exactly. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `options` (0.11 — PopupGameOptions)

Gerada com `codex exec -m gpt-5.6-sol --sandbox read-only -i ref_options.png` e o
prompt pela entrada padrão (com `-i` antes do prompt posicional, o Codex trata o
prompt como outra imagem).

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI. The attached image is a sheet of the classic Gunbound blue in-game OPTIONS popup window on a dark background: at the top a large window with a dark navy title bar on the left carrying the white bold "OPTIONS" title with a dark outline, a lighter blue stepped tab on the right of the title bar, a pale lavender-to-steel-blue gradient metallic frame with a thin white inner highlight and a black outer border, a big flat dark slate-blue inner panel with a small grey wrench icon in its top-left corner, and a plain steel-blue bottom strip; below the window, four states of a blue check-mark "accept" button (normal, hover, pressed, disabled grey-blue) and two tiny radio button states (dark empty circle, glowing yellow selected circle). Preserve every element shape, the OPTIONS lettering, the wrench icon and all colors. The inner dark panel and the bottom strip must stay plain and flat (no texture, no text, no new icons). Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```
