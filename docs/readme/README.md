# Capturas do README

Capturas GPU do jogo atual, feitas por `tests/capture_readme.gd` com perfil isolado
(o perfil real não é tocado). Mostram lobby, sala, Avatar Shop e um T1 real do Bigfoot
contra o Mage no Miramo Town A, com o avatar vestido pelos quadros originais (ADR-130/131).

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --disable-vsync --always-on-top --script tests/capture_readme.gd
```

```bash
ffmpeg -y -framerate 30 -i .tools/readme-frames/%03d.png -vf "fps=15,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" docs/readme/shot.gif
```

```bash
ffmpeg -y -framerate 30 -i .tools/readme-frames/%03d.png -vf "scale=1920:-2" -c:v libx264 -pix_fmt yuv420p -crf 22 docs/readme/shot.mp4
```

Limites: o cenário do Miramo e o HUD ainda usam os derivados HD e os assets herdados de
fase anterior; mobiles, tiros, avatares, lobby, sala e loja usam os originais. Áudio
mudo, sem escuta. É uma captura do Godot, não do cliente original.
