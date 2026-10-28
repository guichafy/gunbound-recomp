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
- [ ] Atualizar o PR e observar execução hospedada, em especial Windows.

Decisões: antes da primeira tag usar o SHA de baseline fixado na configuração e a
versão atual do projeto; commits anteriores ficam fora da validação convencional.
PR usa título convencional; pushes analisam todos os commits desde a última tag.
Fila de até 100 execuções é limite nativo do GitHub, documentado, sem cancelamento
voluntário de pushes. Cobertura Python terá escopo explícito; não fingir cobertura
de linhas GDScript a partir do número de suítes. Instrumentação GDScript permanece
limite declarado da ferramenta, com resultados e inventário publicados separados.
