# CI/CD e releases desktop — implementação

REQ-52/REQ-01/REQ-12, ADR-151. O pedido posterior de 28/10/2026 determina a
implementação; substitui a proposta documental inicial do PR #11.

## Fluxo

`.github/workflows/desktop.yml` roda em PR para main e em push na main:

1. Lint de correção Python (Ruff E9/F63/F7/F82), testes da automação, título
   convencional no PR e actionlint.
2. Versão calculada em checkout com histórico/tags completos. PR usa o título
   (adequado a squash); main valida os commits novos, ignorando merges.
3. Matriz nativa macOS14 ARM e Windows2022 x86_64: dependências Python fixadas,
   Godot4.7.2/templates e TestClient pinados por hash; importação, parse de todos
   os scripts/capturas, todas as suítes do harness e 29 partidas.
4. Python coverage XML/HTML, exportação release, ZIP, extração em pasta
   temporária e smoke do executável nativo sem apoio do projeto-fonte.
5. Ambos os pacotes precisam passar. Somente push main publica release em draft,
   anexa ZIPs, manifestos e checksums e só então publica. Notas de release geradas
   pelo GitHub incluem o SHA e os limites de assinatura/QA.

A fila `concurrency.queue: max` cobre o workflow inteiro: o cálculo de versão só
começa quando a entrega anterior termina. Até100 execuções pendentes, limite
nativo GitHub; acima disso o GitHub rejeita a execução e ela precisa de reexecução.
PRs usam grupo separado por número. Não há cancelamento voluntário de pushes.
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
Dependabot semanal, timeout e retenção de artifacts14dias.

Configuração recomendada no GitHub: proteger main, exigir revisão e checks
`Lint and automation tests`, `Calculate release version` e os dois jobs
`Test, build and smoke`. Habilitar Actions e permitir ao GITHUB_TOKEN criar
releases. Este workflow não altera regras de proteção do repositório.

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
