# Evidência da pesquisa de mapas — issue #45

Pesquisa de 12/11/2026, somente leitura. Não são assets importados nem prova
de execução do cliente Windows. O plano está em
[CLASSIC_MAPS_PLAN.md](../sdd/CLASSIC_MAPS_PLAN.md).

- `inventory.json`: 22 registros não vazios dos 32 slots de `stage.dat`, nomes,
  prefixos, dois campos u16 ainda sem semântica fechada, pesos/ranges de clima,
  existência de IMG/LND/partícula/loading, cabeçalhos de todos os quadros,
  dimensões, pivôs e hashes das entradas extraídas. `auxiliary` contém somente
  sufixos numéricos, sem confundir, por exemplo, `hokb` com animação de `hok`.
- `server-spawns.json`: apenas posições A/B dos 11 mapas do emulador
  [jglim/gunbound-server](https://github.com/jglim/gunbound-server/blob/master/GunBoundServer/map_data.json),
  blob Git `82a95fc61ac56bedd2226e84abed47126b1c4e60`. Fonte auxiliar,
  não comprova o sorteio/apoio do cliente nem paridade do treino 1×1.
- `ghidra/`: consulta final bem-sucedida, com manifesto, comando, logs,
  assembly, pseudocódigo e referências. Análise em banco próprio
  `/tmp/gunbound-map-45-bb36`; Ghidra 12.2/JDK26. Não reutilizou banco concorrente.
- `asm/`: recortes do mesmo PE via LLVM objdump; somente intervalos a partir
  de instruções identificadas. Não são pseudocódigo convertido em regra.

Identidades completas de PE, `graphics.xfs`, `stage.dat`, `sound.xfs` estão em
`inventory.json.sources`. Origem dos arquivos: TestClient de
[jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher/tree/2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1/TestClient).
Arquivos originais lidos do checkout principal, sem modificá-los; nenhum
binário, banco Ghidra ou PNG novo foi incorporado à entrega.
Extratos C/logs versionados têm somente whitespace final normalizado; os
originais sem normalização permanecem na saída local da consulta.

## Reprodução

Com as dependências Python já usadas pelos importadores do projeto:

```sh
python3 docs/maps-issue-45/inventory.py --client /caminho/TestClient --output /tmp/maps-inventory.json
```

O helper verifica os quatro hashes, reutiliza os leitores existentes e
grava apenas JSON. A leitura completa do XFS em Python pode levar minutos.
Não invoca os importadores que escrevem em `assets/`.

O comando Ghidra completo fica em `ghidra/run.json`; os seletores são
`0x00419d90`, `0x004430c0`, `0x004e3c50` e os dados
`0x00557258:8`, `0x00557098:24`, `0x00555504:16`, `0x00557074:24`,
`0x004d4004:64`. Instalação e JDK podem mudar de caminho, preservando o hash
do PE e um diretório de banco próprio sem componentes iniciados por ponto.

## Limites observados

Os três primeiros pedidos exploratórios produziram manifestos parciais
(`function_not_found` em rotinas não reconhecidas pela autoanálise). Não
foram tratados como sucesso nem usados para inventar funções. A quarta
consulta repetiu os três consumidores reconhecidos e dados relevantes com
`ok=true` no manifesto e no resultado do runner. Os parciais permanecem
locais em `/tmp/gunbound-map-45-bb36-evidence-01..03`.

Inventário confirma cabeçalhos/bytes/valores LND, não equivalência pixel a
pixel de todos os alfas IMG com LND, nem disponibilidade efetiva de cada B
na UI do cliente. `land.solid` conta bytes não zero; não é checksum do alpha.
Não se inferem spawns do DAT, nem efeitos animados de nomes de arquivos.
`dragon.lnd` não é referenciado pelos 22 prefixos: permanece recurso órfão,
sem justificativa para criar um décimo segundo mapa selecionável.

## Validação desta entrega

- Regeneração completa por `inventory.py` comparada como JSON: idêntica.
  22 registros,14LND,11partículasA e15load_stage confirmados.
- Cliente com hashes divergentes foi rejeitado antes de decodificar XFS.
- Helper compila com `PYTHONPYCACHEPREFIX=/tmp/maps45-pycache`; o cache
  padrão de Python3.9 fora do workspace foi negado pelo sandbox e não usado.
- Manifesto/runner Ghidra finais `ok=true`; avisos de reflexão Java e
  truststore doSO registrados,109CAsJava carregadas. Não houve erro na consulta.
- Links relativos do plano e evidência conferidos, `git diff --check` sem erros.
- Revisão independente encontrou possível excesso dos headers de partícula
  MetaMine38/41 na célula48. Plano corrigido para medir alpha e dimensionar
  célula/pivô por mapa; não há afirmação de clipping visível sem decode.
- Harness do jogo, GPU, escuta, aplicativo e assinatura não executados nesta
  mudança documental; nenhum resultado histórico foi reutilizado como teste novo.
