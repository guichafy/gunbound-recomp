# Consolidação Dependabot — 28/10/2026

**Requisito:** REQ-52 / ADR-151 (manutenção da automação existente).
**Branch:** `codex/dependabot-security-quality`, base `origin/main` em `044e1b81`.

## Escopo e plano

- [x] Inventariar os PRs abertos, consultar segurança/qualidade e conferir os patches.
- [x] Reunir as sete atualizações abaixo, mantendo actions fixadas por SHA.
- [x] Instalar as versões exatas em Python 3.13 e executar lint e testes existentes.
- [x] Comparar auditoria Python antes/depois e executar o harness com cobertura.
- [x] Revisar o diff e registrar resultados e limites no TASKS/HANDOFF.

| PR | Dependência | Anterior | Consolidada |
| --- | --- | --- | --- |
| [#12](https://github.com/guichafy/gunbound-recomp/pull/12) | actions/checkout | 6.1.0 | 7.0.1 |
| [#13](https://github.com/guichafy/gunbound-recomp/pull/13) | actions/upload-artifact | 6.0.0 | 7.0.2 |
| [#14](https://github.com/guichafy/gunbound-recomp/pull/14) | actions/setup-python | 6.3.0 | 7.1.0 |
| [#15](https://github.com/guichafy/gunbound-recomp/pull/15) | actions/download-artifact | 7.0.0 | 8.0.2 |
| [#16](https://github.com/guichafy/gunbound-recomp/pull/16) | coverage | 7.11.0 | 7.17.0 |
| [#17](https://github.com/guichafy/gunbound-recomp/pull/17) | ruff | 0.14.2 | 0.17.2 |
| [#18](https://github.com/guichafy/gunbound-recomp/pull/18) | Pillow | 12.0.0 | 13.0.0 |

PyYAML 6.0.3 permanece no conjunto. Atualizar todas as ocorrências do workflow,
sem cherry-pick de commits antigos: os patches do Dependabot foram comparados
à main atual, preservando as correções posteriores do PR20.

## Compatibilidade e revisão

Pillow 13 requer Python >=3.11; o workflow continua em 3.13. Conferir os
importadores de PNG/atlas e reprodução dos assets sem regenerar arte versionada.
checkout 7 restringe checkout inseguro em pull_request_target/workflow_run;
o workflow usa pull_request/push e mantém persist-credentials:false.
setup-python 7 migra para ESM; os inputs utilizados permanecem suportados.
Uploads/downloads devem preservar nomes, retenção14dias, extração e gates de
publicação. Conferir quatro checks protegidos, fila main, permissões mínimas,
29 partidas e gate de cobertura Python40% sem reduzir inventário/assertivas.

Referências primárias verificadas:
- https://pillow.readthedocs.io/en/stable/releasenotes/13.0.0.html
- https://github.com/actions/checkout/releases/tag/v7.0.1
- https://github.com/actions/setup-python/releases/tag/v7.1.0
- https://github.com/actions/upload-artifact/releases/tag/v7.0.2
- https://github.com/actions/download-artifact/releases/tag/v8.0.2

## Limites do inventário remoto

Consulta autenticada em28/10: Dependabot alerts retornou403 com mensagem
“Dependabot alerts are disabled for this repository”; metadados confirmam
`dependabot_security_updates.status=disabled`. Code Scanning retornou404
“no analysis found”. Essas respostas não provam ausência de vulnerabilidades.
Nenhuma configuração remota foi alterada. Auditoria local usa pip-audit em
ambiente separado, com versões pinadas e serviço PyPI; não é análise do Godot,
do cliente de referência ou do código JavaScript incorporado em cada action.

## Resultados observados

Python3.13.11 isolado, Godot4.7.2 local. Baseline e final:47 testes de
`test_ci_*.py` passaram; Ruff E9,F63,F7,F82, actionlint e pip check aprovados.
O actionlint mantém a exceção já existente exclusivamente para `concurrency.queue`.
Auditoria pip-audit2.10.1/PyPI: Pillow12.0.0 tinha76registros com58IDs únicos;
Pillow13.0.0 e os outros três pins retornaram zero vulnerabilidades conhecidas.
Resumo com IDs em [dependabot/2026-10-28-audit.json](dependabot/2026-10-28-audit.json).
Isso descreve a consulta feita nesta data, não garantia de ausência de falhas.

Comandos da validação (venv da aplicação separado do auditor):

```sh
.tools/dependabot-venv/bin/python -m pip install -r .github/requirements-ci.txt
.tools/dependabot-venv/bin/python -m pip check
.tools/dependabot-venv/bin/python -m ruff check --select E9,F63,F7,F82 scripts tests
.tools/dependabot-venv/bin/python -m unittest discover -s tests -p 'test_ci_*.py' -v
.tools/audit-venv/bin/pip-audit -r .github/requirements-ci.txt --no-deps --disable-pip --format=json
# Todos os quatro pins não têm dependências de runtime; --no-deps não omite transitivas.
GUNBOUND_SOUND_XFS="$PWD/.tools/gunbound-client/sound.xfs" .tools/dependabot-venv/bin/python scripts/ci/check.py
```

Relatórios brutos: `.tools/dependabot-audit-{before,after}.json`;
logs de instalação/baseline/automação e harness em `.tools/dependabot-*.log`.
Harness completo final: **327 parses,101 suítes Godot/46.117 checks,
29 partidas e152 testes Python,zero falhas/skips,exit0**, em331,137s
(inclui importação inicial do worktree). Cobertura da automação Python:
**62%**, acima do piso40%; XML e HTML gerados. Python3.13.11 e
Godot4.7.2 no macOS; perfil isolado. Nenhum override TLS local neste worktree.
SHA256 de `.tools/dependabot-full-harness.log`:
`4acd508e8b93740f912601984d1719bdff1125b1cc90d3b3a84210a7bd68d4c2`.
Relatório: `.tools/check-logs/report.json`; Python: `.tools/check-logs/python.log`.

Revisão independente somente leitura sem achados acionáveis: workflow
semanticamente idêntico à base após normalizar somente os11pins; manifests
oficiais suportam os inputs atuais. Sem testes concorrentes do revisor.
A execução real das actions, cache, artifacts e build Windows dependem dos
runners GitHub e continuam pendentes. Auditoria não cobre JavaScript das
actions, Godot ou cliente original. Não houve validação visual/GPU nova;
nenhuma arte ou código do jogo mudou.
Nenhum push, merge, encerramento dos PRs, release ou exportação está incluído
neste pedido de branch local. `project.godot` modificado no checkout original
fica preservado; o worktree usa o arquivo versionado da main.
