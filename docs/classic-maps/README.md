# Evidência e QA dos mapas clássicos

Contrato: [CLASSIC_MAPS_IMPLEMENTATION.md](../sdd/CLASSIC_MAPS_IMPLEMENTATION.md).
Ghidra12.2/JDK26, banco próprio; PE/XFS/DAT identificados no contrato e manifestos.
`ghidra/g02,g03,g05,g06,g07,g08` preservam consultas finais com ASM/dados/refs.
Nenhum binário bruto ou banco de análise foi adicionado ao Git.

`gpu-proof.json` registra22lados, resolução1920×1080, hashes de30quadros de
pausa e retomada. PNGs por lado mostram sala/loading/arena/tiro pausado.
O viewport virtual1280×800 é renderizado pelaGPU em1728×1080, centralizado
em1920×1080, sem reamostragem posterior. Capturas anteriores foram substituídas.
Áudio silenciado, perfil isolado em.tools; sem aceite visual humano ou execução
do clienteWindows original. Não alegar paridade integral por estas capturas.

Reproduzir captura: `Godot --path . --resolution 1280x800 --disable-vsync
--always-on-top --script tests/capture_classic_maps.gd`. Harness completo:
`python scripts/ci/check.py --godot /Applications/Godot.app/Contents/MacOS/Godot --workers 4`.
