# Ghidra na skill de porte — plano e validação

REQ-12/19/44/45. Pedido: adotar Ghidra na skill existente e demonstrar que
serve à análise do cliente e à reescrita delimitada em Godot. Nenhuma mudança
de combate, arte, perfil ou versão do jogo faz parte desta tarefa.

## Plano

1. Exercitar a skill anterior em contexto independente, usando só o PE local,
   para registrar lacunas operacionais antes de editar as instruções.
2. Incorporar Ghidra headless como caminho preferencial, com scripts
   reutilizáveis na própria skill. Python3 conduz importação/reabertura;
   Java exporta funções, bytes, referências e metadados pelo Ghidra.
3. Isolar perfil/cache/projeto, conferir hash do PE e recusar reutilização de
   projeto de outra origem. Entradas de função só são criadas por opção
   explícita e com endereços comprovados; ausências/falhas permanecem visíveis.
4. Validar importação nova, vtable/dados, funções ausentes, reabertura e
   resultados exportados. Derivar um contrato numérico da ASM nova e exercitar
   a integração GDScript existente com perfil isolado.
5. Repetir a aplicação em contexto independente, conferir links/frontmatter,
   atualizar HANDOFF/TASKS e tentar versionar somente esta mudança local.

Arquivos: `skills/gunbound-client-port/SKILL.md`, `references/ghidra.md`,
`references/reverse-engineering.md`, `references/evidence.md`,
`references/project.md`, `agents/openai.yaml`,
`scripts/run_ghidra.py` e `scripts/ExportClientEvidence.java`.
Testes de interface do runner em `tests/test_ghidra_skill.py`.

## Critérios

- Novo checkout consegue executar os recursos da skill sem depender de scripts
  descartáveis em `.tools` ou configuração global do REA.
- `--help` funciona; caminho de projeto oculto é recusado antes de abrir Java.
- Ghidra12.2 direto e compatibilidade do MCP são tratados separadamente.
- O export registra VA/entrada real, SHA-256, arquitetura, image base, bytes,
  referências e estado de cada pedido, inclusive função não encontrada.
- Reabrir projeto preserva extratos; outra identidade não reutiliza o banco.
- O contrato Godot deriva de instruções/dados, sem transformar pseudocódigo
  em fonte original nem anunciar validação visual/dinâmica inexistente.

## Resultados

24/10/2026, America/Sao_Paulo. Skill atualizada e caminho estático→Godot
funcional para um contrato delimitado. Scripts fazem parte da skill, com
parâmetros para outros VAs/dados; não dependem de código perdido em `/tmp`.

### Aplicação independente antes/depois

Baseline sem a nova referência/runner: agente com contexto mínimo extraiu a
rotina0x004a6200, mas precisou inventar script Java/comando e contornar falha
do launcher ao gravar `java_home.save` no perfil global. Importação31s,
exit0. Evidência: `.tools/ghidra-skill-baseline/REPORT.md` e extrato completo.
O baseline já respeitava os limites de paridade; a lacuna comprovada era
operacional, não uma falha universal de julgamento.

Após atualização, outro agente sem contexto herdado usou exclusivamente a
skill/binário, sem consultar os relatórios anteriores. Importação nova26s;
função ausente produziu `ok=false` apesar do exit0. Investigou bytes de
prólogo/vtable antes de usar seeding explícito; extraiu424instruções,
referênciaDATA0x005564f8→0x004a6200 e constante float8.0. Reabertura final
readOnly na revisão estável passou; extratos preservados. Não inventou
significado para os casts/registradores do pseudocódigo.

Essa aplicação achou uma falha real no timeout do runner intermediário:
após SIGTERM, o shell podia sair antes de um descendente que ignorasse TERM,
deixando-o vivo. Sonda isolada criou marcador depois do retorno (RED).
Correção envia SIGKILL ao grupo mesmo quando o líder já terminou. Repetição
não criou marcador (GREEN); teste permanente cobre esse caso. São processos
de fixture, não execução do Gunbound. Revisão estável do runner na sonda e
na última reabertura: SHA-256
`707b5f5bd1673944979c74b38385bd5c76494e2547ec5f237dc145b3e71b58ff`.

### Execuções principais

| Execução | Resultado |
|---|---|
| `python3 -m unittest discover -s tests -p test_ghidra_skill.py -v` | 5/5: ajuda, projeto oculto, saída preservada, outra identidade e timeout com descendente resistente |
| Importação nova pelo runner,4funções+2ranges | `run.ok`/`manifest.ok=true`;25s de autoanálise; três entradas indicadas e renderer resolvido ao início real0x004c3020 |
| Reabertura sem seeding | readOnly;22extratos C/ASM/referências byte-idênticos |
| VA0x00700000 sem função | manifesto `function_not_found`,runner exit1,launcher exit0; falha explícita |
| Helpers/LUTs adicionais | _ftol0x0053753c, ângulo0x004585e0 e redução0x004f1f10 exportados; dados legíveis |
| Teste independente da ponte Godot | 8checks de ângulo/seção, zero falhas |
| `check.sh test_mage_client_animation test_classic_ballistics test_classic_shot_timing test_classic_shot_timing_scene` | 115+1077+158+18=1368checks, zero falhas; harness exit0 |
| Estrutura da skill | quick_validate aprovado (annotations adiadas para Python3.9); links Markdown, UI e alias Claude conferidos |

A política do REA continua separada: 6.7.0 aceita12.1.x, não12.2. Não houve
troca de versão ou alteração global. O fluxo validado é Ghidra12.2 direto,
JDK25 Homebrew, macOS arm64. Runner usa processos Unix; Windows não testado.

### Contrato extraído e exercitado no Godot

PE preservado, SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Exportador Java SHA-256
`73dbfe9723bc19525fe086bb5fc3e3532306c54cc4e19a219a2a3450ff6fd090`.

O manifesto novo contém bytes `00000041` em VA0x0055806c: float32LE8.0.
ASM0x004a63ff/0x004a6425 faz FMUL dessa constante após leitura de seno em
0x0054c240. A vtable0x005564f0 contém0x004a6200 no deslocamento8.
Amostras da LUT de ângulo, lidas também pelo Ghidra, dão os esperados abaixo;
ASM0x0045865a–0x0045866b aplica3*trunc((raw+1)/3).

| Velocidade24.8 de entrada | VA da amostra | raw | Ângulo quantizado | Seção esperada |
|---|---|---:|---:|---|
| (25600,0) | 0x00598f7e | 0 | 0 | (0,−8) |
| (0,25600) | 0x005a8e7e | 270 | 270 | (8,0) |
| (−25600,0) | 0x00598dfe | 179 | 180 | (0,8) |
| (0,−25600) | 0x00590e7e | 89 | 90 | (−8,0) |

O gerador de esperados usou bytes exportados e aritmética independente em
Python, sem importar código Godot. O probe GDScript executou
`ClassicBallistics.velocity_angle` e `MageFlight.section_side` e comparou as
oito saídas com os valores fixados. Primeiro probe continha uma hipótese
errada sobre o sinal de Y e falhou2/4; ler a LUT nativa corrigiu a fixture,
sem alterar o produto. Logs de RED e derivação final foram preservados.
Isso comprova largura/ângulos/seções destes casos; não toda a hélice/colisão.

### Evidência e limites

Principal: `.tools/ghidra-skill-validation/`: `fresh/`, `reopened/`,
`helpers/`, `angles/`, `missing/`, `repeat.json`, `runner-tests-final.log`,
`bridge-fixtures.json`, `bridge.gd`, `bridge-final.log`, `godot-directed.log`.
Validação independente: `.tools/ghidra-skill-forward/`, manifestos,
comparações e `timeout-ignore-probe{,-green}.json`; baseline em pasta própria.

Avisos de truststore macOS com fallback JDK e DLL/PDB ausentes continuam
explícitos. Godot dirigido usou a configuração local já existente; não
exportamos o override. O primeiro probe sem log-file explícito teve erro de
gravação no perfil real, corrigido no comando final pelo log local; não
houve gravação de perfil. Não executamos o cliente original nem GUI Ghidra,
QA GPU/escuta/mouse, partidas completas ou exportação do app. Não houve
mudança de runtime nesta tarefa e o trabalho0.20.4 preexistente não está
validado integralmente por estas suites dirigidas.

`git add` apenas da skill/teste/registro falhou com `.git/index.lock:
Operation not permitted`. Não foi criado commit por esta sessão nem push.
Durante a execução, HEAD avançou externamente de322cb15 para b9fd589 e
incluiu alguns arquivos intermediários desta tarefa; a versão final da skill
e as correções posteriores continuam como delta local. Não reverter nem
atribuir esse commit externo a esta validação.

### Revisão para versionamento após o pull

Autorizada posteriormente pelo usuário. Os cinco testes de
`python3 tests/test_ghidra_skill.py` passaram novamente após o merge.
Delta revisado para commit local; sem nova execução Ghidra/Godot ou build.
`override.cfg` contém somente o caminho local de certificados e permanece
fora do versionamento. Os bloqueios descritos acima são históricos.
