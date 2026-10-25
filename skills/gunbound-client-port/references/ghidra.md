# Ghidra headless: evidência para o porte

## Preparar e executar

Usar instalação existente, JDK exigido por `Ghidra/application.properties` e
cópia local do cliente. Scripts desta skill usam Python3 padrão e Java do
Ghidra; não requerem REA, GUI, instalação de pacotes ou execução do jogo.
O runner usa launcher/grupos de processos Unix (macOS/Linux); esta validação
foi em macOS arm64. Isso não restringe os alvos de exportação do jogo Godot.
Resolver `SKILL_ROOT` para a pasta desta skill. A raiz do Ghidra deve conter
`support/analyzeHeadless`; o runner também aceita o prefixo Homebrew contendo
`libexec`. Escolher diretório de trabalho persistente **sem componentes
iniciados por ponto**. Saída de evidência deve ser nova a cada execução.

```sh
python3 "$SKILL_ROOT/scripts/run_ghidra.py" \
  --ghidra-dir "$GHIDRA_INSTALL_DIR" --java-home "$JAVA_HOME" \
  --binary "$CLIENT_PE" --work-dir "$GHIDRA_WORK" --output "$EVIDENCE_OUT" \
  --functions 0x004a6200 --data 0x005564f0:32 0x0055806c:4
```

Endereços acima são exemplo da build fixada no mapa do projeto: confirmar
SHA-256 antes de usá-los. `--help` descreve os argumentos. O runner importa
na primeira execução e reabre o mesmo programa nas seguintes; confere hash
do banco/PE e recusa outra identidade. Hash idêntico permite mover a cópia
do PE, mantendo o mesmo nome. Não reutilizar banco de outra build.

Perfil, cache e temporários Java ficam dentro de `--work-dir`, por ambiente
do subprocesso. Isso evita `java_home.save` no perfil real e cache padrão
em `/var/tmp`. `application.tempdir` sozinho não redireciona o cache;
`application.cachedir` é necessário. Não alterar `$HOME`, a instalação nem
configuração global para contornar esse problema.

## Entradas e cobertura

Uma VA pode estar no interior de outra função: usar `entry_va` do manifesto
e preservar a VA solicitada. Se retornar `function_not_found`, consultar
referências e tabela de despacho; código indireto pode não virar função na
autoanálise. Confirmar bytes/prólogo/ponteiro no mesmo PE antes de repetir
com `--seed-known-entries`. Essa opção cria entradas ausentes apenas no
banco de análise; não divide uma função já reconhecida nem altera o PE.
Não criar funções em todo valor parecido com endereço.

Sem seeding, reabertura usa `-readOnly -noanalysis`. Com seeding, alterações
de análise são salvas para a próxima consulta. Não processar o mesmo projeto
simultaneamente em GUI/headless ou em dois agentes; usar work-dirs distintos.
Projeto temporário pode desaparecer; reconstruir a partir do PE e dos
recursos versionados da skill, sem depender de scripts de sessão anteriores.

## Ler os resultados

| Arquivo/campo | Uso |
|---|---|
| `run.json` | Comando exato, instalação/Java, hash, importação/reabertura e resultado |
| `manifest.json` | Identidade, image base, linguagem, VA solicitada/entrada e estado de cada pedido |
| `0x*.asm` | Endereços, bytes das instruções e assembly do corpo reconhecido |
| `0x*.c` | Pseudocódigo decompilado; orientação, não código-fonte original |
| `*.requested-refs.tsv` / `*.entry-refs.tsv` | Referências exatas à VA e à entrada, incluindo DATA/vtable |
| `*.outgoing-refs.tsv` | Chamadas, acessos a dados e fluxos das instruções do corpo |
| `data[].hex` / `*.data-refs.tsv` | Bytes de LUT/constante/vtable e referências à base pedida |
| `console.log`, `analysis.log`, `scripts.log` | Avisos, timeout, compilação do script e cobertura real |

Exigir `ok=true` em ambos os manifestos e inspecionar logs. Função ausente,
decompilação falha, dado ilegível, hash divergente ou timeout não são sucesso,
mesmo que o launcher termine com exit0. Um manifesto parcial continua útil
como evidência da lacuna. `refs` não resolve todos os saltos indiretos; ausência
de referência exata não prova ausência de consumidor. Bytes são os da imagem
carregada, sujeitos aos fixups do loader; não rotular VA como offset de arquivo.

## Do extrato ao GDScript

1. Seguir os ponteiros da vtable até construtor/fábrica, atualização,
   colisão e render. Relacionar campos por offset e largura, não pelo nome
   inventado do decompilador. Pedir outros VAs/dados com o mesmo runner.
2. Confirmar constantes nos bytes little-endian e instruções que as leem.
   Reconstruir ABI/custom helpers, LUT, sinais, FPU e ordem de truncamento.
   `unaff_*`, parâmetros ausentes e aritmética com ponteiro de critical
   section marcam lacuna, mesmo com `decompileCompleted=true`.
   Conferir a convenção dos eixos e as amostras da LUT: Y positivo pode ser
   para baixo, e uma entrada179 pode virar180 após quantização. Não gerar
   esperados com `atan2` ideal ou simetria presumida.
3. Escrever contrato em unidades e ticks nativos; produzir fixtures
   independentes. Usar [registro](evidence.md) e [animação](animation.md).
4. Só então alterar o Godot: estado por shell/ator, real/previsão comuns,
   cópia profunda para CPU e interpolação só visual. Conferir as fixtures no
   código executado e fazer regressões proporcionais ao delta.

Isso valida o caminho de análise estática. Paridade visual requer sequência
GPU e aceite; paridade dinâmica do cliente exige executá-lo em ambiente
adequado. Ghidra não converte automaticamente o cliente em um projeto Godot.

## MCP e alternativas

Conferir versão e disponibilidade reais do provedor antes de abrir o alvo.
Na avaliação do projeto, Ghidra12.2/JDK25 direto funcionou, enquanto REA6.7.0
aceita somente12.1.x (verificada12.1.4). Usar CLI direta nesse caso; não editar
a política de versão para forçar compatibilidade. Hopper permanece segunda
fonte para comparar extratos existentes, com endereços/hash da mesma build.
