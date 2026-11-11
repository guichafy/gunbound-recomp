# Evidência Raon — sondagem de minas (#31)

Os manifests identificam o PE, linguagem, VAs e cobertura das duas consultas
Ghidra12.2/JDK26 desta sessão. ASM contém os ramos de terreno/queda/limites
de498b60/4921e0, a sonda completa4e4340 e SUB40a6e0. Não é código-fonte do
porte. Logs completos locais: `.tools/issue31/evidence-{ground,init}`.
Resumo de contratos/limites: `../sdd/RAON_GROUND_ISSUE_31.md`.

`frame-*.png` e `mines.mp4`: capturaGodot1920×1080,330quadros a passo manual
1/60s (110PNGs a20Hz), dois tipos/sentidos, rampa, plataforma fina, enterramento
e cratera. Quadros90..119 pausados, RGBA idêntico;120 retoma. MP4H264 é
apenas prévia; PNG/bytes e o estado são a evidência da pausa. Não medeFPS real.

Comando: Godot `--path . --script tests/capture_raon_mines.gd --resolution
1920x1080 --disable-vsync --always-on-top -- .tools/issue31/frames 330`.
Sem clienteWindows inteiro/escuta/interação humana; nenhuma alegação de
paridade integral de Raon. Originais/rig/arte preservados.
