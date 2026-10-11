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
| [GUNBOUND_REFERENCES.md](GUNBOUND_REFERENCES.md) | Pesquisa dos três vídeos e do fork OpenBound, com origem e limites dos assets |
| [REFINEMENT_0_2.md](REFINEMENT_0_2.md) | Design aprovado, plano e evidência da entrega 0.2 |
| [ORIGINAL_ASSETS.md](ORIGINAL_ASSETS.md) | Pedido de mobiles reais, auditoria do fork e arquivos externos necessários |
| [BIGFOOT_0_3.md](BIGFOOT_0_3.md) | Recorte, plano e limites da integração Bigfoot 0.3 |
| [MAGE_0_4.md](MAGE_0_4.md) | Mage: assets, ataques, escudo, adaptações e validação 0.4 |
| [BIGFOOT_ATTACKS_0_5.md](BIGFOOT_ATTACKS_0_5.md) | T1/T2/SS Bigfoot: emitter, regras, áudio/Fx e validação 0.5 |

Ordem de retomada: hand-off → especificação → design → tarefas → decisões.
Para uma mudança, localizar o requisito, definir o delta da especificação,
planejar, implementar, verificar e atualizar o hand-off. Se o código divergir da
especificação, registrar a divergência e resolvê-la dentro da solicitação vigente.

Os documentos em `docs/superpowers/` e `docs/progress.md` preservam o histórico
da execução inicial. O conjunto `docs/sdd/` consolida o contexto atual.
O [README principal](../../README.md), o [guia de aprendizado](../APRENDIZADO.md),
o [roteiro funcional](../VALIDACAO.md) e a [origem da arte](../ART.md) o complementam.

Baseline inicial: **0.1.0**; versão atual **0.6.0**, em **2026-10-11**. O histórico Git
identifica as revisões; não manter hashes de commits dentro destes documentos.

Assets HD atuais: [HD_ASSETS_0_6.md](HD_ASSETS_0_6.md), GPT Images e aparência
clássica; metadados/prompts em assets/hd e capturas1920×1080 em docs/hd.
