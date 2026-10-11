# SDD — contexto persistente

Neste repositório, SDD significa **desenvolvimento orientado por especificações**
(Spec-Driven Development). Esta é uma documentação do protótipo já entregue,
com requisitos ligados à implementação e à validação; não adotamos um framework
externo nem confundimos SDD com desenvolvimento conduzido por subagentes.

| Documento | Função |
|---|---|
| [HANDOFF.md](HANDOFF.md) | Ponto de entrada: estado, execução, evidências, pendências e retomada |
| [SPEC.md](SPEC.md) | Objetivo, escopo, requisitos identificados e critérios de aceitação |
| [DESIGN.md](DESIGN.md) | Arquitetura implementada, estados, contratos e invariantes |
| [DECISIONS.md](DECISIONS.md) | Decisões, motivos e consequências |
| [TASKS.md](TASKS.md) | Entregas, rastreabilidade, tarefas abertas e roadmap |

Ordem de retomada: hand-off → especificação → design → tarefas → decisões.
Para uma mudança, localizar o requisito, definir o delta da especificação,
planejar, implementar, verificar e atualizar o hand-off. Se o código divergir da
especificação, registrar a divergência e resolvê-la dentro da solicitação vigente.

Os documentos em `docs/superpowers/` e `docs/progress.md` preservam o histórico
da execução inicial. O conjunto `docs/sdd/` consolida o contexto atual.
O [README principal](../../README.md), o [guia de aprendizado](../APRENDIZADO.md),
o [roteiro funcional](../VALIDACAO.md) e a [origem da arte](../ART.md) o complementam.

Baseline: protótipo **0.1.0**, consolidado em **2026-10-11**. O histórico Git
identifica as revisões; não manter hashes de commits dentro destes documentos.
