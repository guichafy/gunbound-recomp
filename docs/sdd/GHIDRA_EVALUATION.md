# Avaliação do Ghidra 12.2 para o porte do cliente

24/10/2026, America/Sao_Paulo. REQ-12/19/44/45; investigação de ferramentas,
sem alteração de comportamento, assets, perfil ou versão do aplicativo.

## Resultado

Ghidra **12.2 funciona diretamente em modo headless** neste Mac arm64 e é
uma alternativa viável para continuar a investigação de tiros/animações.
Importou o PE x86, analisou o programa e exportou pseudocódigo, assembly e
referências sem interação com a GUI. O reconhecimento automático de funções
foi incompleto: quatro das oito rotinas da amostra exigiram fornecer seus
endereços já comprovados. Não anunciar superioridade geral sobre o Hopper,
nem afirmar que seu pseudocódigo dispensa confirmação em assembly.

O **REA 6.7.0 instalado não aceita Ghidra 12.2**: sua política verifica
12.1.4 e aceita somente a linha 12.1.x. Além disso, o MCP atual estava sem
`GHIDRA_INSTALL_DIR`. Não houve edição da configuração global, troca de
versão, modificação do conector ou remoção do Hopper. Para esta instalação,
usar `analyzeHeadless` diretamente; para MCP, é necessário um conector que
aceite 12.2 ou uma instalação 12.1.x compatível com o REA existente.

## Ambiente e fonte

- Launcher informado: `/opt/homebrew/Cellar/ghidra/12.2/bin/ghidraRun`.
  É um wrapper para `libexec/ghidraRun`, com Java 25 do Homebrew como padrão.
- Ferramenta efetivamente executada:
  `/opt/homebrew/Cellar/ghidra/12.2/libexec/support/analyzeHeadless`.
- JDK: `/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home`,
  OpenJDK 25.0.5.0.2, arm64. Decompilador nativo `mac_arm_64` disponível.
- Binário existente: `.tools/mobile-animation-port/GunBound.gme`, SHA-256
  `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
  Loader PE, `x86:LE:32:default`, compiler `windows`, image base `0x400000`.
- Projeto de análise: `/tmp/gunbound-ghidra-evaluation-20261024/GunboundEvaluation.gpr`.
  Banco de análise separado; hash do binário conferido novamente ao final.
- Extratos anteriores do Hopper: `.tools/mobile-animation-port/0x*.asm` e `.c`.
  Não foi executado novo benchmark do Hopper, nem reproduzido seu problema
  de interface/aprovação. As comparações usam os extratos já existentes.

## Experimentos observados

| Etapa | Resultado |
|---|---|
| Autoanálise padrão, limite 240 s, duas CPUs | Concluída em 26 s; 2408 funções; 4/8 rotinas da amostra reconhecidas |
| Indicação de quatro entradas conhecidas, disassembly/createFunction e analyzeChanges | 8/8 decompiladas; 2413 funções após análise incremental |
| Reabertura do projeto com `-process -noanalysis -readOnly` | 8/8 decompiladas; 24 arquivos C/ASM/referências byte-idênticos |
| Decompilação individual após indicar entradas | 5–1495 ms; na reabertura 6–1599 ms; tempos não incluem startup/importação |
| Logs das três rodadas concluídas | Zero linhas ERROR; avisos ambientais e de nomes preservados |
| Política real do REA para application.version=12.2 | `status=unsupported`, `accepted=false`; build verificada 12.1.4 |

| VA solicitada | Uso na investigação | Reconhecimento inicial | Instruções Ghidra |
|---|---|---|---:|
| `0x0047ebc0` | Mage T1 Animate | Entrada indicada posteriormente | 408 |
| `0x0047f1c0` | Mage T1 Publish | Entrada indicada posteriormente | 64 |
| `0x004a46f0` | Mage T2 construtor | Automático | 71 |
| `0x004a4950` | Mage T2 Detonate | Automático | 1662 |
| `0x004a6200` | Mage T2 Animate | Entrada indicada posteriormente | 424 |
| `0x004a6840` | Mage T2 Publish | Entrada indicada posteriormente | 65 |
| `0x0048d8e0` | Mage SS impacto | Automático | 193 |
| `0x004c480c` | Interior do renderer, entrada real `0x004c3020` | Função contendo o endereço | 5946 |

As quatro rotinas inicialmente ausentes têm referências DATA nas tabelas
do cliente; por exemplo, `0x005560d8 → 0x0047ebc0` e
`0x005564f8 → 0x004a6200`. As referências já eram dados úteis; não interpretar
ausência de função automática como ausência de código nativo.

Nas seis rotinas com ASM anterior disponível, todos os endereços de
instrução dos extratos Hopper aparecem no Ghidra. As diferenças de mnemônico
observadas são aliases (`je/jz`, `jne/jnz`, `sete/setz`, `setne/setnz`) e
formatação de `rep movsd`. O Ghidra enumera 36 instruções adicionais em
Detonate e 180 no renderer: isso mede cobertura dos extratos, não prova que
o Hopper deixou de analisar essas instruções nem equivalência semântica
integral dos decompiladores.

O pseudocódigo facilita a leitura de imports como `EnterCriticalSection` e
`LeaveCriticalSection`, que o extrato Hopper apresentava como ponteiros.
Ainda há `undefined`, assinaturas inferidas e registradores não resolvidos
(por exemplo `unaff_EBP`); manter conferência de ABI, operandos e ordem em ASM.

## Ajustes locais necessários e reprodução

O cache padrão tentou gravar em `/var/tmp/guichafy-ghidra`, fora da área
permitida. Definir `application.cachedir` resolveu esse bloqueio;
`application.tempdir` sozinho não muda o cache. A localização de projeto
também recusou o componente `.tools` com `Path element starting with '.' is
not permitted`; o projeto foi criado em `/tmp`, sem componente oculto.

Script do experimento: `.tools/ghidra-evaluation/scripts/EvaluateGunbound.java`.
Para reproduzir, a partir da raiz do checkout:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home
export JAVA_TOOL_OPTIONS="-Duser.home=$PWD/.tools/ghidra-evaluation/home -Dapplication.cachedir=$PWD/.tools/ghidra-evaluation/cache -Dapplication.tempdir=$PWD/.tools/ghidra-evaluation/tmp -Djava.io.tmpdir=$PWD/.tools/ghidra-evaluation/tmp"

# Projeto já importado; 'seed' cria somente as funções que ainda faltarem.
/opt/homebrew/Cellar/ghidra/12.2/libexec/support/analyzeHeadless \
  /tmp/gunbound-ghidra-evaluation-20261024 GunboundEvaluation \
  -process GunBound.gme -noanalysis -max-cpu 2 \
  -scriptPath "$PWD/.tools/ghidra-evaluation/scripts" \
  -postScript EvaluateGunbound.java "$PWD/.tools/ghidra-evaluation/new-results" seed
```

Em projeto novo, trocar `-process GunBound.gme -noanalysis` por
`-import "$PWD/.tools/mobile-animation-port/GunBound.gme" -analysisTimeoutPerFile 240`.
O diretório do projeto deve existir. Não abrir o mesmo projeto na GUI enquanto
o headless o processa. A documentação oficial descreve importação, processamento
e scripts sem GUI:
[Headless Analyzer](https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/RuntimeScripts/support/analyzeHeadlessREADME.md).

## Evidência e limites

Evidência local em `.tools/ghidra-evaluation/`: `console.log`,
`seeded-console.log`, `reopened-console.log`, respectivos logs de análise e
scripts, `results/`, `seeded-results/`, `reopened-results/`,
`repeat-verification.json`, `assembly-comparison.json` e `rea-version-policy.json`.

O MCP `binary_session` confirmou a ausência de configuração. `rea doctor`
pela CLI parou antes de verificar a instalação, durante preparação de um
helper Swift que tenta usar cache fora da sandbox; o diagnóstico de versão
foi obtido separadamente chamando a política instalada do próprio REA e lendo
`application.version`. Não descrever o doctor como aprovado.

Os logs concluídos mantêm aviso de truststore do macOS, com fallback para
110 CAs do JDK; a primeira rodada também avisa sobre dois nomes no-return.
DLLs Windows não foram carregadas no Mac; não há PDB/DWARF do cliente.
Não houve execução do Gunbound, validação da GUI `ghidraRun`, medida comparativa
de latência do Hopper, validação GPU/áudio/input ou nova execução do harness
Godot. A avaliação não conclui nem valida a implementação parcial 0.20.4
que já estava no workspace. Nenhum commit/push ou novo aplicativo.
