# Prompts GPT Images — itens 0.13

Gerados com o Codex CLI (`codex exec -m gpt-5.6-sol --sandbox read-only -i ref_<folha>.png`,
prompt pela entrada padrão), ferramenta integrada `image_gen`, uma edição por folha.
`scripts/build_items_hd.py refs` monta as referências; a imagem gerada vira
`items/source/gen_<folha>.png` e `build_items_hd.py` recorta, redimensiona e aplica o
alfa original. Origens `exec-*.png` em `GENERATION.json` (`items_0_13`); SHA-256 em
`items/manifest.json`.

## Folha `items2`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI item buttons. The attached image is a sheet of the classic Gunbound in-game item buttons, six rows, each row shows the four states of one item button side by side (normal, hover, pressed/darker, disabled greyscale), each button is a wide square-cornered tile with a colored bevel frame and an icon: row 1 the red-framed DUAL item with two grinning red cartoon bombs on a light green burst; row 2 the red-framed DUAL+ item with a red bomb and a white bomb; row 3 the red-framed THUNDER item with a yellow lightning bolt; row 4 the green-framed ENERGY UP 2 item with two medical bandage plasters; row 5 the purple-framed TEAM TELEPORT item; row 6 the purple-framed TELEPORT item. Preserve every icon, every frame color, the exact state differences (the 4th button of each row stays greyscale), and the thin black outline of each tile. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `items1`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI item buttons. The attached image is a sheet of classic Gunbound in-game UI sprites on a dark background: rows 1 to 5 show the four states (normal, hover, pressed/darker, disabled greyscale) of five small square item buttons: red-framed BLOOD item with a grinning red bomb, red-framed BUNGE SHOT item with a grey shovel, red-framed POWER UP item with a blue armored creature with a golden crown, blue-framed CHANGE WIND item with a blue-and-white pinwheel on a red circle, green-framed ENERGY UP 1 item with one medical bandage plaster; row 6 two flat blue folder tab shapes (a dark blue tab and a lighter lavender tab); row 7 a green LCD panel inside a blue metal frame showing the black dotted pixel text ITEM LOCKED. Preserve every icon, frame color, state difference (the 4th button stays greyscale), the tab shapes, and the exact dotted LCD lettering ITEM LOCKED (same letters, same dot-matrix style, same position). Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `popup`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of game UI. The attached image is the classic Gunbound blue SELECT ITEM popup window: a dark navy title bar at the top left carrying the white bold outlined title SELECT ITEM, a lighter blue stepped tab shape on the right of the title bar, a pale lavender-to-steel-blue gradient metallic window frame with a thin white inner highlight and a dark outer border, a large flat indigo inner panel with a dark border, below it a flat grey-blue description panel, and at the bottom six dark slate square slots in a row. Preserve every element shape, the SELECT ITEM lettering and all colors. The inner panels and the slots must stay plain and flat (no texture, no text, no icons). Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the flat dark navy background (#161E2E) around the elements exactly flat and plain. Improve only fidelity: crisp clean edges, smooth gradients, glossy bevels and clean highlights, in the nostalgic Gunbound 2004 game UI style, suitable for a Full HD game. Do not redesign.
```

## Folha `beacon`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of a game projectile animation. The attached image is a 4 by 3 grid of the twelve frames of the classic Gunbound teleportation beacon projectile, each frame a small glowing cyan/aqua energy ball with a bright white-cyan core and a soft sparkly cyan halo of tiny particles trailing to the left, slightly different in each frame (a spinning animation). Preserve each frame exactly in its cell with the same shape, size, orientation and cyan color. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the pure black background around the effects exactly flat and black (it is used as transparency). Improve only fidelity: smooth soft glows, crisp sparks and clean particles, in the nostalgic Gunbound 2004 game effects style, suitable for a Full HD game. Do not redesign, do not change the size or brightness of any frame.
```

## Folha `flame`

```text
Use your built-in image generation tool (GPT Images) exactly once to edit the attached image. Do not write code, do not run shell commands. After generating, reply only with the absolute path of the saved generated image file.

Image prompt:
Use case: upscale remaster of a game special effect animation. The attached image is a 4 by 2 grid of eight keyframes of the classic Gunbound teleport flame effect, in time order left to right then top row to bottom row: a tiny red-orange spark, a big bright yellow-white fireball with an orange glow, a white glowing core with yellow flame bursts and sparks, a translucent white energy sphere with orange sparks, a large translucent white ring sphere with sparks, a fading ring with scattered orange sparks, scattered dissolving orange particles, and a faint dusty remnant. Preserve each keyframe exactly in its cell with the same shape, size, brightness, colors and particle positions. Keep EXACTLY the same canvas framing and layout: every element must stay at the same position, same size and same spacing as in the reference, NO zoom, NO crop, NO added margin, NO re-arrangement, NO new elements, NO labels, NO text other than the text already printed on the elements. Keep the pure black background around the effects exactly flat and black (it is used as transparency). Improve only fidelity: smooth soft glows, crisp sparks and clean particles, in the nostalgic Gunbound 2004 game effects style, suitable for a Full HD game. Do not redesign, do not change the size or brightness of any frame.
```
