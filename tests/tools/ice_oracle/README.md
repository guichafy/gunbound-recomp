# Ice — oráculo independente da issue #29

Bootstrap prepara somente os inputs pinados; Unicorn não é dependência do jogo/CI.
Use Python3.12 com Unicorn2.1.4 e Pillow13.0.0:

```sh
python scripts/ci/bootstrap.py --skip-godot --no-legacy-sound --client-source /copia/TestClient
python tests/tools/ice_oracle/generate.py
python scripts/import_ice_effects.py
```

`generate.py` direciona o loaderGrub para o PE que efetivamente valida em
`.tools/gunbound-client/GunBound.gme`. Não consulta JSONs temporários de DAT:
valida SHA256 e descomprime `characterdata.dat` diretamente. O loader é apenas
mapeamentoPE/x86, células e chamadas; nenhuma regraGodot é importada.

- 34casos de45db20 completo: quatrocampos, flags0..15, truncamentos, HP,
  escudo total, valores negativos, limites, zero dano, fora da área,
  alivefalse/bff7/tipo14 e HPletal. O cliente deixa HPnegativo; o porte publica0.
- 16casos adicionais45db20 com dimensões/bottom/flags/vulnerabilidade do
  Bigfoot real, usados pelo testeMatch sem gerar esperados do GDScript.
- 24casos4759b0 executam SS/425ac0 reais. Apenas lookup4206f0 por slot é
  controlado (slot emECX, world na pilha);48de60 e publicaçõesUI são omitidas.
  Cobre distância129/130/131, filtros, negativos, teto20 e redução50→20.
- 48inicializações41da80 executadas, todos16tipos×3armas;6casosIce com
  Attack/Dig assinados. Retorno booleano4065a0 é AL, nãoEAX inteiro.

No dano, hooks45f300/45f5d0 retornam0 para apoio plano e436860 omite somente
número visual. HP/escudo/estado reais são executados. malloc/rand são locais
para ofuscação de células; nunca sorteio de regra. Não há recuperação de
acesso inválido: qualquer unmapped aborta. O JITUnicorn pode exigir execução
fora do sandbox macOS; isso não é execução do clienteWindows inteiro.

`ScanIceFields.java` roda no Ghidra headless readOnly/noanalysis sobre o banco
exclusivo, listando constantesb728/b94c/bb70/bd94/e55ab8. É complemento à
revisão dos loops indiretos, não prova isolada de ausência de outros acessos.
Use o runner da skill para criar/reabrir o banco e consultar40d8e0/458b80/
41da80/45db20/474650/4759b0/425ac0/475e40/461c60. Vtables/ASM e hashes são
preservados em docs/ice-native; Ghidra12.2/JDK26 foram usados nesta sessão.
