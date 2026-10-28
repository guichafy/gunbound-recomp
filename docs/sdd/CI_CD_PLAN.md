# Plano de implementação CI/CD desktop

**Objetivo:** implementar REQ-52 e ampliar REQ-01 a Windows x86_64 sem alterar combate.
**Spec:** SPEC.md, CI_CD_DESIGN.md (proposta substituída pela implementação).
**Arquitetura:** Actions em PR e push main; fila `queue: max` no workflow inteiro;
versão calculada após entrar na fila; qualidade nativa em macOS/Windows;
release em draft publicada somente após os dois ZIPs e smoke aprovados.
**Restrições:** Godot 4.7.2; perfil temporário; nenhum certificado local exportado;
sem publicação de release nesta sessão. Atualizar o PR #11 já autorizado.

- [x] Bootstrap: Godot/templates e TestClient fixados, checksums e preparação de `.tools`.
- [x] Exportação: preset Windows, CLI configurável, ZIPs, licenças, smoke fora do projeto.
- [x] Versionador: testes de feat/fix/breaking/patch de manutenção, bootstrap e reexecução.
- [x] Runner: Python multiplataforma, timeout/exit/resumos, parse, Python coverage e relatório Godot.
- [x] Workflow: PR/main, permissões mínimas, SHAs, fila, artifacts, publicação idempotente.
- [x] Validar localmente, revisar e atualizar SDD.
- [x] PR11 integrado por rebase; main40752719203 aprovada nas duas plataformas,
  release0.21.0 publicada e tag/arquivos/checksums conferidos.

Decisões: antes da primeira tag usar o SHA de baseline fixado na configuração e a
versão atual do projeto; commits anteriores ficam fora da validação convencional.
PR usa título convencional; pushes analisam todos os commits desde a última tag.
Fila de até 100 execuções é limite nativo do GitHub, documentado, sem cancelamento
voluntário de pushes. Cobertura Python terá escopo explícito; não fingir cobertura
de linhas GDScript a partir do número de suítes. Instrumentação GDScript permanece
limite declarado da ferramenta, com resultados e inventário publicados separados.

## Proteção da main e anexos públicos — 28/10/2026

Pedido posterior autoriza configurar a proteção e simplificar próximas releases.
Trabalho na branch codex/main-protection-release-assets, criada da main atualizada;
entrega por PR, sem merge automático nem alteração da release0.21.0.

- [x] Versionar e aplicar configurações de proteção/checks e integração só por rebase.
- [x] Calcular a prévia pelos commits reais do PR e rejeitar mensagens inválidas
  antes do merge, mantendo também a validação do título convencional.
- [x] Testar publicação com dois ZIPs + SHA256SUMS, dados adulterados, retry de
  draft, falha de upload e preservação das releases antigas com seis anexos.
- [x] Validar sempre os seis arquivos internos antes de montar os três anexos
  públicos, sem gravar o consolidado na pasta de entrada (retry local limpo).
- [x] Conferir configuração remota, rodar39testes da automação,144Python, lint,
  revisão independente e atualizar SDD.

Entrega por commit/push da nova branch e PR para main, sem merge automático;
checks hospedados da nova revisão precisam ser conferidos no PR.
