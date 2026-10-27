# QA GPU dos assets de batalha —27/10/2026

`tests/capture_client_assets.gd` desenha a cena real em1920×1080, com perfil
isolado e relógio de simulação60Hz. Três casos de120quadros: calendário
adaptado (Bigfoot×Armor), nativo (Mage×Bigfoot) e teleporte disparado por Game.
Contatos Thor/chamas são fixtures visuais controladas, sem alterar dano/colisão.

Cada caso pausa os quadros30..59: os30buffersRGBA foram idênticos por hash;
retomada altera pixels. Confirmação independente dos PNGs30/59/75 também passou.
`capture.json` guarda resultados e hashes. `preview.mp4` tem360quadros,
1920×1080/60Hz/6s; o GIF é prévia800×450/15Hz. O vídeo deriva de JPEG90% da
captura; os PNGs de marcos e a comparação de pausa usam RGBA sem perdas.
`options.png` confere o popup nativo recomposto. Não se mede FPS de performance.

Clima também foi capturado em quatro casos/calendários e dois sentidos:
[360quadros adicionais](../client-weather-assets/gpu-validation.json),
com pausa30e retomada em cada um. Ambos os conjuntos foram refeitos depois
da correção dos dígitos0..7 da fila e das cinco facesSS.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --disable-vsync --always-on-top --script tests/capture_client_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --disable-vsync --always-on-top --script tests/capture_client_weather_assets.gd
```

A inicialização gráfica no sandbox abortou134; execuções finais fora dele
terminaram0, sem erros de script/recurso. Áudio silenciado, sem escuta,
interação humana ou execução do cliente Windows. Composição/layout e lacunas
continuam declarados em [CLIENT_ASSETS_PORT](../sdd/CLIENT_ASSETS_PORT.md).
O menor contraste do ângulo branco sobre o visor claro é uma limitação visual
conhecida deste encaixe; não houve alteração de input ou geometria por isso.
