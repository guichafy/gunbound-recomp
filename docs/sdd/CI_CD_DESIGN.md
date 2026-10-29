# CI/CD e releases desktop — implementação

REQ-52/REQ-01/REQ-12, ADR-151. O pedido posterior de 28/10/2026 determina a
implementação; substitui a proposta documental inicial do PR #11.

## Fluxo

`.github/workflows/desktop.yml` roda em PR para main e em push na main:

1. Lint de correção Python (Ruff E9/F63/F7/F82), testes da automação, título
   convencional no PR e actionlint.
2. Versão calculada em checkout com histórico/tags completos. PR e main validam
   os commits novos, ignorando merges. PR também exige título convencional;
   o cálculo usa as mensagens reais preservadas pelo Rebase and merge.
3. Matriz nativa macOS14 ARM e Windows2022 x86_64: dependências Python fixadas,
   Godot4.7.2/templates e TestClient pinados por hash; importação, parse de todos
   os scripts/capturas, todas as suítes do harness e 29 partidas.
4. Python coverage XML/HTML, exportação release, ZIP, extração em pasta
   temporária e smoke do executável nativo sem apoio do projeto-fonte.
5. Ambos os pacotes precisam passar. Somente push main publica release em draft,
   valida manifestos, anexa dois ZIPs e SHA256SUMS e só então publica. Notas geradas
   pelo GitHub incluem o SHA e os limites de assinatura/QA.

A fila `concurrency.queue: max` cobre o workflow inteiro: o cálculo de versão só
começa quando a entrega anterior termina. Até100 execuções pendentes, limite
nativo GitHub; acima disso o GitHub rejeita a execução e ela precisa de reexecução.
Main mantém grupo fixo; PRs usam grupo de workflow por run_id e grupos de
jobs lint/versão/desktop por PR/etapa/plataforma com fila single padrão e
cancelamento só em PR. Ao alcançar uma etapa, a execução nova substitui o
job correspondente antigo. Lint novo falhando pode deixar builds antigos
terminarem. Não há cancelamento voluntário de pushes. `queue` é literal;
não pode ser expressão nem combinar max com cancel-in-progress:true.
Actionlint1.7.12 ainda rejeita a chave oficial `queue`; ignora-se somente esse
alerta, e `test_ci_workflow.py` valida queue/max, não cancelamento, SHAs e gates.

## SemVer e reexecução

`feat` sobe minor; `!`/`BREAKING CHANGE` sobe major, inclusive antes de1.0;
`fix`, `perf` e manutenção sobem patch (extensão explícita para release por push).
O maior incremento desde a última tag aplicável prevalece. `.github/release.json`
fixa baseline0.20.5 e revisão anterior à implantação: tags antigas menores e
commits anteriores não são reinterpretados. Baseline divergente falha, sem
inferir versão de um histórico reescrito. Mensagem inválida na main bloqueia.

O checkout recebe a versão em `application/config/version` antes dos testes e
exports. Não há commit de versão gerado pelo bot nem loop de push. A versão do
arquivo na branch é a base de desenvolvimento; a tag e os manifestos identificam
a entrega. A tag exata no mesmo SHA é reutilizada em retry. Release publicada
não é sobrescrita. Draft é localizado inclusive antes de existir tag Git e
retomado apenas para o SHA validado; upload parcial nunca é publicado. Depois
dos dois pacotes aprovados e antes do draft, o publisher cria uma tag lightweight
como reserva durável. Mesmo se o upload falhar, o próximo push vê a reserva
com contents/read e calcula a próxima versão. Retry no SHA reservado reutiliza-a.
A presença da tag, sozinha, não anuncia uma release concluída.

## Qualidade e cobertura

`scripts/ci/check.py` preserva a lista de suítes de `scripts/check.sh`, com
processos e timeout multiplataforma. Parse, erro de script, exit não zero,
ausência de resumo e testes Python pulados bloqueiam a entrega. Logs e relatório
JSON são artifacts mesmo em falha. Fixtures de cena preparam apenas os diretórios
necessários; caminhos propositalmente ausentes dos testes de rollback continuam
ausentes. Perfis de testes usam `.tools` ou pasta temporária.

Otimização PR20: após importação única, um pool de no máximo4 tarefas por
padrão (também limitado por os.cpu_count) roda a faixa parse/suítes comuns,
Python/cobertura e grupos determinísticos das13+16 partidas. `--workers N`
permite ajuste e1 executa sequencialmente. Cada grupo tem perfil/log de engine
próprio; cenas mantêm a ordem e as fixtures anteriores. A união das partidas
é conferida por seed/ID e contagem no log, sem aceitar ausência/duplicação.
Qualquer erro/timeout/exceção bloqueia o job, coletando os demais resultados.
XML/HTML usam dados de cobertura novos e separados por execução. `report.json`
inclui duração por comando/total e partidas; `python-times.json` registra
tempos de cada teste e os15 maiores aparecem no log do Actions. Esses tempos
não incluem o setUpClass como teste individual; o tempo total Python inclui-o.

A cobertura de linhas/branches mede **Python**, com relatório completo em
`.tools/coverage.xml` e `.tools/coverage-html/`. O gate inicial de40% aplica-se
somente a `scripts/ci/*`, não ao jogo. O restante Python aparece no relatório
sem piso global artificial. O inventário e os checks Godot são publicados
separadamente em `report.json`; não representam cobertura de linhas GDScript.
Instrumentação de linhas GDScript ainda é uma limitação desta entrega.

Dependências dos testes de fidelidade são preparadas a partir do TestClient
Thor's Hammer fixado por revisão e SHA256. Avatares/DAT de referência são
extraídos para a pasta ignorada `assets/xfs/reference`, excluída do PCK. Caminhos
absolutos do áudio foram trocados por `.tools/gunbound-client/sound.xfs`.
Não se consulta OpenBound nem se baixa qualquer versão posterior como fonte.

## Pacotes e smoke

`package.py --platform macos|windows` produz em `builds/dist`:

- `Gunbound-Recomp-VERSION-macOS.zip` (universal Intel/Apple Silicon).
- `Gunbound-Recomp-VERSION-Windows-x86_64.zip` (exe e PCK separados).
- Um `.json` e um `.zip.sha256` por ZIP, com SHA do commit, versão Godot,
  tamanho/hash, plataforma, arquitetura, smoke e estado de assinatura.

Os seis arquivos permanecem nos artifacts `desktop-macos`/`desktop-windows`
(retenção14dias). O publisher valida todos antes de qualquer escrita remota;
próximas releases públicas recebem somente os dois ZIPs e `SHA256SUMS`, contendo
duas linhas UTF-8/LF compatíveis com `sha256sum -c SHA256SUMS` ou
`shasum -a 256 -c SHA256SUMS`. Os JSONs são metadados operacionais da CI,
não downloads necessários para jogar. O consolidado é temporário e não altera
os inputs, permitindo retry local sem limpeza. Falha de upload mantém draft;
releases publicadas com seis anexos (como0.21.0) não são modificadas em retry.
GitHub acrescenta automaticamente Source code.zip/tar.gz como snapshots da tag;
eles não são os aplicativos prontos. Serão cinco itens visíveis nas próximas
releases: três arquivos da pipeline e esses dois arquivos automáticos.

Ambos incluem licenças e atribuições. Override de certificados, credenciais,
fontes de pesquisa, testes e configurações CI são excluídos e auditados.
macOS preserva assinatura ad-hoc e verificação codesign, sem notarização;
Windows fica sem Authenticode. Assinatura comercial depende de certificados
que não foram fornecidos; não é alegada nesta entrega.

O template release ignora opções de editor como `--script`; por isso o
smoke usa `-- --ci-smoke`. O hook no começo de `Game._ready` injeta um perfil
absoluto temporário antes do perfil padrão. Sem flag, esse script não é
carregado. Testa versão, recursos, catálogos, lobby/sala/loja e persistência
isolada. O pacote só ganha manifesto após `PACKAGED SMOKE: PASS`, exit0 e
logs sem erros. Smoke headless não comprova GPU, áudio ou input humanos.

## Segurança e operação

Permissão padrão contents/read; só a publicação recebe contents/write. PRs
não publicam nem recebem token de escrita; sem pull_request_target, PAT ou
segredos de assinatura. Actions fixadas por SHA, dependências por versão,
Dependabot semanal, timeout e retenção de artifacts14dias. Checkouts esparsos
evitam materializar os1,4GB de galerias históricas; os runners mantêm assets, cenas,
scripts, testes, evidências SDD, referência do botão Exit e avisos legais.

## Proteção aplicada na main

`.github/main-protection.json` e `.github/merge-settings.json` registram a
configuração aplicada em28/10/2026, fora do workflow. Exigir PR (zero aprovações
de terceiros no repositório individual), atualização com main e estes checks,
obrigatoriamente emitidos pelo GitHub Actions (app15368):

- `Lint and automation tests`.
- `Calculate release version`.
- `Test, build and smoke (macos)`.
- `Test, build and smoke (windows)`.

Administradores também cumprem as regras; histórico linear obrigatório, force
push e exclusão bloqueados. Somente Rebase and merge é permitido no repositório.
Não exigir o job de publicação: ele só roda após push main. Alterações em nomes
dos jobs precisam atualizar a configuração remota para não bloquear os PRs.

Reaplicação administrativa explícita (não executada pela CI):

```bash
gh api --method PATCH repos/guichafy/gunbound-recomp --input .github/merge-settings.json
gh api --method PUT repos/guichafy/gunbound-recomp/branches/main/protection --input .github/main-protection.json
```

Actions usa contents/write somente para tags/releases; não recebe permissão de
administrar proteções. Os JSONs versionados documentam a política; editá-los no
PR não muda a configuração remota automaticamente.

Repetição local (Python3.13):

```bash
python -m pip install -r .github/requirements-ci.txt
python scripts/ci/bootstrap.py --no-legacy-sound
python scripts/ci/check.py
python scripts/ci/package.py --platform windows  # no Windows; macos no Mac
```

Com editor já instalado, `bootstrap.py --skip-godot --no-legacy-sound` prepara
somente as fontes. Definir `GODOT` para o binário do editor. Bootstrap normal
confere os hashes do editor/template e publica GODOT em GITHUB_ENV no Actions.
Publicação é exclusiva da main após aprovação dos gates, não ao enviar o PR.

Referências: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/),
[concorrência GitHub](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency),
[segurança GitHub](https://docs.github.com/en/actions/reference/security/secure-use),
[export Windows](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html).
