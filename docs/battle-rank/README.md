# Patentes na batalha (issue #43)

Capturas Godot4.7.2/Compatibility, AppleM4Pro. `capture_battle_rank.gd`
renderiza a cena real num SubViewport1920×1080 (canvas1280×800 ×1,35,
margens96px) e1280×800. Não depende do tamanho da janela do host.
Perfil/carteira isolados em `.tools/battle-rank`. Cenário estático: atores
posicionados para conferir ambos os emblemas na mesma imagem, sem simular
uma partida nem alegar contatos/posição natural sobre o chão.

- `battle-rank-gm.png`: GM20/Chick19, jogador primeiro.
- `battle-rank-long-cpu-first.png`: código−4 e nome20caracteres; CPU primeiro.
- `battle-rank-1280.png`: mesmo cenário na escala nativa do mundo.
- `gpu-verification.json`:375pixels opacos por emblema nos anchors nativos,
  comparados ao PNGfonte, zero divergências. Regressão73checks separada.

A fonte e o contorno do texto, as cores, escala da fila e passo16px são
adaptações preservadas do porte; não há alegação de raster integral nativo.
Sem execução do clienteWindows/escuta/input/aceite visual humano nesta tarefa.
Contrato, matriz e resultados: `../sdd/BATTLE_RANK_ISSUE_43.md`.

## Evidência nativa

`native/` conserva extratosASM e manifestos finais Ghidra12.2/JDK26,
`ok=true`/`source_unchanged=true`, PE SHA2564af6283d…fc0fcde.
Banco exclusivo `/tmp/gunbound-issue43-f29c-ghidra` (não versionado).
`assets.json` registra hashes de graphics.xfs/entradas/PNGs e pivôs zero dos
25quadros por atlas. Não contém o PE nem os arquivosXFS.

Comando final (após importação pelo mesmo runner):

```sh
python3 .codex/skills/gunbound-client-port/scripts/run_ghidra.py \
  --ghidra-dir /opt/homebrew/Cellar/ghidra/12.2/libexec \
  --java-home /Library/Java/JavaVirtualMachines/jdk-26.jdk/Contents/Home \
  --binary .tools/mobile-animation-port/GunBound.gme \
  --work-dir /tmp/gunbound-issue43-f29c-ghidra \
  --output .tools/battle-rank/04-final \
  --functions 0x00408180 0x00462900 0x004eb890 0x0040eaa0 0x004ed6a0
```

Consultas iniciais01/02 tiveram `function_not_found` paraVAs interiores de
funções não reconhecidas. O ramo world foi conferido pelo corpo/ASM462900,
com referências de vtable e helper4eb890; consultas03/04 terminaram aprovadas.
O pseudocódigo de462900 omite ramos de nome; são as instruções46342a..463608,
não o C decompilado, que sustentam o contrato portado.
