# Capturas do README

Capturas GPU de27/10/2026 do jogo atual, feitas por `tests/capture_readme.gd` com perfil isolado
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

Conferência desta entrega: lobby/sala/loja/batalha e86quadros do disparo em
**1920×1080** reais; MP4 com86quadros/30Hz (2,867s), GIF640×360/15Hz.
O script desliga o stretch automático somente na captura e encaixa o canvas
1280×800 em1728×1080, centrado na janela física1920×1080. A loja conserva seu
próprio ajuste nativo. Cada imagem tem assertiva de dimensão; os PNGs não são
esticados depois. Isso corrige a captura anterior de área útil1728×1080,
cujo vídeo convertido acabava1920×1200.

Miramo, os componentes de HUD disponíveis, clima/Thor, ícones/teleporte e
música usam agora recursos do cliente Thor's Hammer (ADR-133/REQ-48).
Cronômetro de segundos/décimos e anel laranja/WIND vêm de numfont/moon.xtf.
Header/footer agora seguem as faixas nativas separadas (ADR-134), com Gold
no topo e carga/tiros na base. O miolo mais curto e famílias de comportamento
continuam adaptados onde declarado; faltas de equivalente preservam os recursos herdados1×.
O detalhe por consumidor está em [CLIENT_ASSETS_PORT](../sdd/CLIENT_ASSETS_PORT.md).

Correção atual do HUD: [capturas e pausa](../battle-hud-layout/README.md),
960quadrosGPU (Slice/Drag/Move+4ventos/calmaria),8×30quadros idênticos e
retomada, cliques reais testados no viewport. README recapturado após os
ajustes finais de cronômetro/vento.

A sequência anterior de assets com pausa fica em [docs/client-assets](../client-assets/README.md)
e [docs/client-weather-assets](../client-weather-assets/gpu-validation.json):
720quadros GPU, sete casos com30quadros pausados idênticos e retomada.
Áudio mudo, sem escuta. É captura do Godot; o cliente Windows não foi executado.

MOVE: correção posterior da posição em [docs/move-bar](../move-bar/README.md),
ADR-135. A sequência de T1 destas capturas não aciona movimento; os seus
arquivos permanecem válidos para esse cenário. Captura específica cobre
abertura/expansão/soltura nos dois sentidos e pausa na nova posição.

Fundo do footer corrigido após a ADR-135 (ADR-136): as quatro telas e os86
quadros T1 foram regenerados por `capture_readme.gd`; GIF e MP4 recompostos.
O importador preserva preto opaco do RGB565. Ver [QA do fundo](../footer-background/README.md):
480 quadros FullHD, pausa e probe de35.200 pixels, sem vazamento do cenário.
