# SDD — contexto persistente 0.20.2

Neste repositório, SDD significa **desenvolvimento orientado por especificações**
(Spec-Driven Development). Esta é uma documentação do protótipo já entregue,
com requisitos ligados à implementação e à validação; não adotamos um framework
externo nem confundimos SDD com desenvolvimento conduzido por subagentes.

| Documento | Função |
|---|---|
| [TURTLE_T2_FIDELITY.md](TURTLE_T2_FIDELITY.md) | Movimento 0.20.2: onda T2, fontes, raster, testes e captura temporal |
| [TURTLE_ANIMATION_FIX.md](TURTLE_ANIMATION_FIX.md) | Correção 0.20.1: água contínua, divisão SS, revisão e captura temporal Full HD |
| [HANDOFF.md](HANDOFF.md) | Ponto de entrada: estado, execução, evidências, pendências e retomada |
| [BATTLE_FIDELITY_0_20.md](BATTLE_FIDELITY_0_20.md) | Estado implementado0.20, evidências, limites e registro final de harness/GPU/app |
| [BATTLE_FIDELITY_PLAN.md](BATTLE_FIDELITY_PLAN.md) | Execução das tarefas1–8 e plano original preservado |
| [CLASSIC_BALLISTICS_0_20.md](CLASSIC_BALLISTICS_0_20.md) | Contrato pré-código e fonte independente de aritmética/vento/Boomer implementados |
| [BATTLE_ASSET_MATRIX.md](BATTLE_ASSET_MATRIX.md) | Identidade, arte, EPA, emissão e áudio das48combinações |
| [BATTLE_SHOT_MATRIX.md](BATTLE_SHOT_MATRIX.md) | Pesquisa48tiros/44classes; fontes, confiança e lacunas |
| [BATTLE_MOBILE_FAMILY_PLANS.md](BATTLE_MOBILE_FAMILY_PLANS.md) | Próximos portes mecânicos, não entregues pela pesquisa |
| [BATTLE_FIDELITY_HANDOFF.md](BATTLE_FIDELITY_HANDOFF.md) | Investigação histórica de batalha com correções da revisão atual |
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
| [ITEMS_0_13.md](ITEMS_0_13.md) | Itens de batalha: regras do OpenBound, Select Item, arte HD e validação 0.13 |
| [QUALITY_REVIEW.md](QUALITY_REVIEW.md) | Revisão de qualidade 0.18.6: achados P1–P4, plano, portões e escopo reduzido |
| [AVATAR_CLASSIC_CATALOG.md](AVATAR_CLASSIC_CATALOG.md) | Catálogo clássico versão 280 e códigos do servidor (REQ-46) |

Skill de continuidade: `skills/gunbound-client-port/SKILL.md`
(`$gunbound-client-port`), REA e porte com mobiles/avatares aprovados
preservados; modernização posterior (ADR-088).

Ordem de retomada: hand-off → especificação → design → tarefas → decisões.
Para uma mudança, localizar o requisito, definir o delta da especificação,
planejar, implementar, verificar e atualizar o hand-off. Se o código divergir da
especificação, registrar a divergência e resolvê-la dentro da solicitação vigente.

Os documentos em `docs/superpowers/` e `docs/progress.md` preservam o histórico
da execução inicial. O conjunto `docs/sdd/` consolida o contexto atual.
O [README principal](../../README.md), o [guia de aprendizado](../APRENDIZADO.md),
o [roteiro funcional](../VALIDACAO.md) e a [origem da arte](../ART.md) o complementam.

Baseline inicial: **0.1.0**; versão atual **0.20.2**, em **2026-10-24** (America/Sao_Paulo) (fonte única:
`application/config/version`). O histórico Git identifica as revisões; não manter
hashes de commits dentro destes documentos. Os parágrafos abaixo sobre "entrega
atual" descrevem a época de cada versão; o estado vigente está no topo da SPEC.

Onda Turtle T2 0.20.2 implementada; revisão focal aprovada, suíte 588/0.
Harness 8020 checks Godot + 16 Python + 29 partidas sem falhas, parse aprovado.
Captura temporal 1920×1080/60 FPS inspecionada com pausa e dois sentidos.
App/ZIP 0.20.2 assinados, CRC/Info.plist válidos; fonte 163/0 e PCK 179/0
com ressalvas ambientais registradas. Aceite visual do T2 confirmado pelo usuário;
escuta e mouse manual sem validação registrada.
Registros 0.20/0.20.1 preservam resultados históricos, não provas deste pacote.

Assets HD atuais: [HD_ASSETS_0_6.md](HD_ASSETS_0_6.md), GPT Images e aparência
clássica; metadados/prompts em assets/hd e capturas1920×1080 em docs/hd.

Correção atual de sprites/animação: [ANIMATION_FIX_0_6_1.md](ANIMATION_FIX_0_6_1.md).

Correção atual de piloto/tiros/impactos:
[PILOT_SHOTS_FIX_0_6_2.md](PILOT_SHOTS_FIX_0_6_2.md), prévias em docs/projectiles.

Composição atual: [COMPOSITION_FIX_0_6_3.md](COMPOSITION_FIX_0_6_3.md),
referência original/HD e prévias em docs/composition.

Entrega atual: [SIDE_PILOT_ROSTER_0_6_4.md](SIDE_PILOT_ROSTER_0_6_4.md),
piloto em perfil e apenas Bigfoot/Mage. Prévia em docs/occlusion.
