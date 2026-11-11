# Luz dos projéteis — issue #32

Grade Full HD: linhas Armor/Bigfoot/Trico/JD/ASate/Ice. Cada dupla mostra
legado à esquerda e alpha+add à direita; T1/T2/SS primeiro para direita,
depois esquerda. Atlas, pivôs, EPA e física idênticos. Os vídeos são
sequências GPU de passo manual1/60s, não um benchmark de performance.

- [Claro](light.mp4) e [escuro](dark.mp4):361frames cada, pausa65..94.
- `capture-*.json`:100impactos por fundo,36modelos,zero tiros restantes.
- `verification.json`:oráculoRGB,60buffers de pausa,retomada,72pares finais
  vazios e12pares de armas sem luz no MESMO local da viewport.
- `probe-*`/`empty-*`:corpoRGBA(102,51,26,128),luz(26,77,128,64), alfa1/0,5.
  Esperado independente: corpo×alfa+fundo×(1−alfa), depois luz×alfa.
- `unlit-*`:ArmorSS/BigfootT2/ASateSS comparados na mesma posição com
  RGBAexato. Painéis transladados podem diferir numa borda de textura
  filtrada4×; por isso não servem para alegar raster idêntico.
- `evidence/`:ASM focalizado,manifestos e hashes do PE; sem binário.

Reproduzir captura com Godot4.7.2:

```sh
Godot --path . --disable-vsync --always-on-top --script tests/capture_projectile_light.gd
Godot --path . --disable-vsync --always-on-top --script tests/capture_projectile_light.gd -- dark
python3 tests/tools/projectile_light/verify_capture.py
python3 tests/tools/projectile_light/evidence.py --output /tmp/projectile-light.json
```

A captura salva todos os frames em `.tools/projectile-light/frames-*`,
ignorado pelo Git. PNGs selecionados e vídeos ficam neste registro.
Sem execução do cliente Windows inteiro, som/input ou aceite humano.
Contrato e plano: [ADR-165](../sdd/PROJECTILE_LIGHT_ISSUE_32.md).

Reconfirmar no Ghidra (caminhos de instalação locais; banco novo próprio):

```sh
python3 .codex/skills/gunbound-client-port/scripts/run_ghidra.py \
  --ghidra-dir /opt/homebrew/opt/ghidra/libexec \
  --java-home /Library/Java/JavaVirtualMachines/jdk-26.jdk/Contents/Home \
  --binary .tools/gunbound-client/GunBound.gme \
  --work-dir /private/tmp/gunbound-light-reproduce \
  --output /private/tmp/gunbound-light-reproduce/audit \
  --functions 0x4c3020 0x458690 0x4ae1a0 0x4c1d30 0x42bbb0 0x42de70 0x43f0e0 \
  --data 0x555c34:32 0x555dac:32 0x55631c:32 0x5564d0:32 0x5565f8:32 \
         0x555e88:32 0x555d14:32 0x556360:32 0x556160:32 0x555f38:32 0x555f58:32 \
  --seed-known-entries
```
