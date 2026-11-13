# Evidência JEWEL — issue #46

Contrato e plano: [JEWEL_ISSUE_46.md](../sdd/JEWEL_ISSUE_46.md).
As pastas q01..q14 guardam manifestos/comandos reais, inclusive falhas.
Extratos C/ASM/refs essenciais acompanham cada consulta. Os dois arquivos
ASM de q03 são recortes delimitados do renderer; os demais extratos são
corpos reconhecidos pelo Ghidra. Logs, C e trechos do servidor tiveram
somente espaços finais e linhas vazias finais normalizados para versionamento. Fontes PE/XFS/DAT
não são copiadas ao Git. `sources.json` fixa seus hashes. Listas de refs
duplicadas e listas extensas de chamadores dos helpers genéricos foram
omitidas; não inferir ausência de chamadores dos arquivos selecionados.

O setup definitivo é q12/q14 (`4bb730`, 1500 instruções), após correção de
entrada exploratória interior. q05/q10 não são prova do corpo completo.
`RepairJewelEntry.java` registra a correção no banco privado; um banco novo
deve semear a entrada correta diretamente, sem reproduzir o erro.

Verificação numérica independente, somente leitura:

```sh
python3 docs/jewel-native/verify.py /caminho/local/GunBound.gme
```

A saída deve ser idêntica a `numeric-fixtures.json`; outro SHA é recusado.
Isso confere instruções/imediatos e não executa dano, spawn ou partida.
Os manifestos de Ghidra contêm comandos exatos para a instalação usada;
escolher saídas novas e um banco próprio fora de componentes ocultos ao
repetir. Usar JDK26 para manter compatibilidade do cache desta coleta.

`assets.json` foi obtido com `scripts/gunbound_xfs.py`: `read_toc`,
`read_entry` com checksum por bloco, `frames` e `parse_epa` nas entradas
contendo “jewel” de graphics.xfs/sound.xfs pinados. Não foi aplicado ao
runtime; nomes sem “jewel” como jflame ainda exigem inventário complementar.
`server-excerpts.txt` preserva linhas do commit indicado em `sources.json`;
essa fonte é um emulador, não oráculo do servidor original.
