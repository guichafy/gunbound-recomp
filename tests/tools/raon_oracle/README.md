# Oráculo de terreno das minas Raon

Requer Python3, Unicorn2.1.4 em ambiente isolado e o PE pinado preparado por
`scripts/ci/bootstrap.py`. Não distribui binário nem importa o porteGodot.

```sh
python tests/tools/raon_oracle/generate.py --output /tmp/raon-ground.json
cmp /tmp/raon-ground.json tests/fixtures/raon_ground_native.json
```

`--pe` permite escolher a cópia local: SHA256 divergente é rejeitado antes
de escrever a saída. Em macOS o JIT do Unicorn pode requerer execução fora
do sandbox. A dependência não faz parte do runtime ou do gate de cobertura.

Executa AnimateMine498b60/AnimateSuperMine4921e0 com os helpers protegidos
reais e a sonda4e4340 real sobre uma máscara de bytes. Aborta em499217/492912,
depois de queda e limites e antes de gatilho/movimento/clima. Registra entradas
e retornos de cada sonda, posiçãoY, flag3fb4, velocidade3fb8 e remoção14.
Os stubs são4986a0 (inclinação, ret4),450730 (pose),498070 (alvo, ret4).
Esses stubs não escolhem terreno nem alteram os campos observados. A constante
protegida794bf0 é inicializada em15 como em WinMain40d9d2.

As46fixtures têm duas variantes por cenário, sem contato com atores nem
movimento. O teste Godot compara o ramo `settle` e o limite `outside`;
inclinação/gatilho/agenda/Gold continuam cobertos pelas suítes existentes.
As rotinas do PE são executadas em emulador; não é execução do cliente inteiro.
Contrato e evidência: `docs/sdd/RAON_GROUND_ISSUE_31.md` e
`docs/raon-ground-native/*`.
