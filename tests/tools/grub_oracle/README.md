# grub_oracle — as rotinas do PE rodando num emulador x86

Gera os fixtures independentes de `tests/fixtures/grub_{surface,flight,emission}_native.json`
executando o **código do cliente** (GunBound.gme, SHA-256 `4af6283d…c0fcde`) com
[Unicorn](https://pypi.org/project/unicorn/) 2.1.4. Nada daqui roda no jogo nem no `check.sh`;
os testes Godot só leem os JSONs.

- `emu.py` carrega o PE (base 0x400000), FS/SEH, pilha e stubs de `Enter/LeaveCriticalSection`.
- `world.py` monta o mundo mínimo: chaves nulas das células protegidas (0x79376c), constantes
  de WinMain (`consts.py`), linhas do `characterdata.dat` em `ctx+0xf0384`, `rand`/`malloc`.
- `shell.py` cria o projétil pelo spawner real (`0x42bbb0` T2, `0x42de70` SS), coloca o terreno
  num mapa de 1 px e injeta o teste de mobile (`0x450e10`) como caixas.
- `gen_emission.py` (MainAction `0x471fd0`), `gen_normal.py` (`0x4a1740`), `gen_flight.py`
  (`Animate` `0x4a1690` / `0x488780` → tick `0x49fd40` / `0x486ea0`).

Reproduzir (não faz parte das dependências do projeto):

```sh
python3 -m venv /tmp/grub-oracle && /tmp/grub-oracle/bin/pip install unicorn==2.1.4
cd tests/tools/grub_oracle
PYTHONPATH=<site-packages com Pillow> /tmp/grub-oracle/bin/python gen_emission.py   # idem gen_normal / gen_flight
```

Requer `.tools/mobile-animation-port/GunBound.gme`, `.tools/gunbound-client/characterdata.dat` e os
extratos Ghidra em `.tools/battle-re/grub-evidence*/` (ver `docs/sdd/GRUB_CLIENT_FIX.md`).
Os três JSONs gerados aqui foram conferidos byte a byte contra os versionados.

Limites: execução de funções isoladas, não do jogo inteiro. Ficam ocos (retornam 0 ou param): efeitos
visuais/sonoros, registro de objetos no mapa do mundo, objetos especiais (0x4510f0/0x451030/0x4511b0),
rede e atributos do dono (`0x41da80` não foi exercitado com Attack/Dig ≠ 0).
