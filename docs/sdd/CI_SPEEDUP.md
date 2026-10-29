# CI mais rápido — plano e validação (PR20)

REQ-52/REQ-01/REQ-12; emenda da ADR-151. Pedido do usuário: implementar na
branch fix/grub-weather-room, preservando testes e cobertura.

## Evidência inicial

Run40783414221: Windows35min25s; partidas13=8min26s e16=6min53s;
Python/cobertura~7min50s; pacote32s. macOS esperou10min04s por runner,
testes27min12s e pacote47s. Não prometer redução da fila hospedada.

## Plano de implementação

- [x] Testar e implementar partição determinística das13+16 partidas,
  argumentos inválidos bloqueantes e execução sem filtros preservada.
  Arquivos: tests/support/match_partition.gd, tests/test_match_partition.gd,
  tests/test_matches.gd, tests/test_classic_matches.gd, scripts/check.sh.
- [x] Testar e implementar pool limitado em scripts/ci/check.py: faixa de
  parse/suítes comuns sequencial, Python paralelo e partidas em grupos;
  perfis/logs próprios, todos os resultados coletados mesmo em falha,
  contagem integral de partidas e tempos em report.json. Testes do runner
  devem exercitar concorrência real, propagação de falha e inventário.
- [x] Medir cada teste Python e manter source=scripts, branches, XML/HTML e
  gate include=scripts/ci/* / fail-under=40. Conferir os testes mais lentos
  antes de otimizar processamento repetido; não alterar leitores nativos
  sem evidência. Testes de assets só escrevem em TemporaryDirectory; a
  faixa Python é processo separado e só lê assets do projeto.
- [x] Ajustar workflow e testes: main max/sem cancelamento; PR com grupo de
  workflow por run_id e grupos de jobs por PR/etapa/plataforma, single padrão
  e cancelamento condicional. Substituição ocorre quando a nova etapa começa,
  não antes; lint novo falhando pode deixar build antigo concluir. Preservar
  quatro checks, ambos pacotes/smokes e release gate.
- [x] Rodar automação/lint/parse e harness completo com fontes preparadas;
  comparar inventário29 e cobertura, revisar, registrar resultados em
  TASKS/HANDOFF/DECISIONS. Medida hospedada posterior é o aceite de desempenho.

## Riscos a revisar

Omissão/duplicação de seed; shard vazio ou malformado aparentando sucesso;
perfil/log compartilhado; erro numa faixa escondido por outra; cobertura de
run anterior; alteração da política main ou dos nomes protegidos; saturação
de núcleos. O pool deve ser configurável (inclusive1) e limitado por padrão.

## Resultados

TDD: teste de partição falhou por helper ausente, depois153/0. Cinco testes
novos do runner falharam antes de duração/inventário/pool/tempos; depois
passaram. Integração com subprocessos reais, engine substituída e coverage
real detectou cwd incorreto antes da correção; depois passou, mantendo falha
de cena no status e29 partidas no relatório. Automação46/0, Ruff e actionlint
aprovados; revisão independente encontrou queue não literal, corrigido com
novo RED→GREEN. Nenhum outro achado acionável.

Primeiro harness completo:327 parses,101 suítes Godot,46.116 checks,
29partidas e150 testes Python/zero skips, exit0,275,262s. Rodada intermediária
durante a implementação; não substitui a validação final. Python coberto
186,399s; sem cobertura46,850s. Maiores custos: comparações nativas de pixels
Mage/Bigfoot, Mage, Grub e Aduka; preservadas integralmente, sem cache de
oráculos nem exclusão de linhas da cobertura.

Validação final:327 parses,101 suítes Godot/46.116 checks,29partidas e
151 testes Python/zero skips, zero falhas/exit0 em270,535s (4min30s). Cobertura
da automação62%, piso40% preservado e acima dos54% observados no Windows
do run anterior. Ruff/actionlint/diff--check aprovados. Log
`.tools/ci-speed-final.log`, relatório `.tools/check-logs/report.json` e
tempos `.tools/check-logs/python-times.json`. Log SHA256:
`1972cf1d2753f76d6bd2a77c2710300625f67e4dbe11b02ec6140637445c7c2f`.
Execução adicional das13+16 partidas **sem argumentos de partição**:29/29
linhas idênticas aos grupos (opener, shots, winner, remaining_hp); sem falhas,
187,410s+151,993s. Evidência `.tools/ci-speed-match-parity.json` e
`.tools/ci-speed-serial-test_{matches,classic_matches}.log`. Medida hospedada
pendente. A importação no sandbox falhou
no acesso aos certificados macOS; fora do sandbox passou. Dependências
fixadas instaladas em venv local (Python3.12; runners continuam3.13).
Override local preexistente permanece ignorado e excluído do pacote.

Fontes da política: [GitHub Actions concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
e [restrição de queue literal](https://github.github.com/gh-aw/reference/concurrency/#queue-behavior-queue).

## Correção pós-run 40791957919

Primeiro run hospedado com o pool: Windows falhou só em `test_performance`
(quadro de 87,4 ms contra o limite de 40 ms) porque a suíte, que cronometra
quadros reais, dividia os 4 núcleos com a faixa Python/cobertura e oito grupos
de partidas; o macOS foi cancelado junto. `ISOLATED_SUITES` em
`scripts/ci/check.py` tira essa suíte da faixa comum e a roda sozinha depois
do pool, com o mesmo perfil e o mesmo limite (nenhum teste afrouxado).
`test_ci_runner` cobre a ordem (faixa → pool → isolada) e falhou antes da
mudança. Local: automação 13/0, Ruff aprovado, runner real com
test_hud/test_grub_model/test_performance exit 0.
