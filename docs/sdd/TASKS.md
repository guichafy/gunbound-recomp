# Entregas e próximos trabalhos

## Baseline implementado

| Tarefa | Status | Requisitos | Evidência |
|---|---|---|---|
| T-01 — modelos de terreno, física e partida | Concluída | REQ-03–08 | `test_runner.gd`, `test_matches.gd` |
| T-02 — perfil, menu, HUD, input, resultados e apresentação | Concluída | REQ-02, 03, 09–11 | `test_runner.gd`, `test_scene.gd`, capturas e arte |
| T-03 — revisão, correções e pacote macOS | Concluída | REQ-01, 12 | Correções registradas, assinatura e launch; roteiro funcional |
| T-04 — SDD, hand-off e baseline Git | Concluída no snapshot que contém este documento | REQ-12 | `AGENTS.md`, `docs/sdd/`, commit inicial |
| T-05 — pesquisa de referências e aprovação de 0.2 | Concluída | REQ-13–18 | `GUNBOUND_REFERENCES.md`, aprovação “implementa” |
| T-06 — implementar e entregar refinamento 0.2 | Concluída tecnicamente; validação do usuário pendente | REQ-13–18 | 102 verificações, seis partidas, revisão, capturas e pacote 0.2.0 |
| T-07 — Bigfoot visual com assets reais | Concluída tecnicamente; aceitação pendente | REQ-19 parcial | 130 verificações, oito partidas, sprites/piloto/projéteis, capturas e app 0.3.0 |

O plano original permanece em `docs/superpowers/plans/2026-10-11-prototype.md`.
Os estados acima distinguem implementação entregue de aceitação pelo usuário.

## Ajuste visual concluído 0.3.1

- [x] Reduzir Bigfoot/piloto na arena (80→60) e no menu (230→180).
- [x] Inspecionar novas capturas e repetir 28 checks Bigfoot.
- [x] Reexportar/validar aplicativo e registrar commit local com SDD atualizado.

## Pendência atual

- [x] Receber, extrair e verificar o pacote externo: `.tools/source-assets/content/`,
  813 arquivos, incluindo todos os 803 assets do pipeline do fork.
- [x] Integrar Bigfoot visualmente, com piloto/quadros/projéteis originais.
- [x] Portar ataques próprios do Bigfoot T1/T2/SS (0.5; adaptações documentadas).
- [ ] Integrar outros mobiles e sistemas pendentes conforme nova solicitação.

- [x] Aprovação do pacote em `REFINEMENT_0_2.md` com “implementa”.
- [x] Implementar e verificar tecnicamente o refinamento 0.2.

- [ ] Usuário validar mouse/teclado, partida, pausa, especial, resultado, revanche
  e persistência seguindo `docs/VALIDACAO.md`.
- [ ] Registrar feedback e priorizar correções/refinos conforme esse resultado.

Não há bug impeditivo conhecido aberto no baseline; isso não substitui validação
do usuário. IA estacionária, um mapa e fragmentos suspensos
  são limites conhecidos, fora do refinamento 0.2 concluído nesta sessão.

## Roadmap para refinamento futuro

1. Refinar desktop após feedback: balanceamento, IA, controles e apresentação.
2. Definir e validar builds Windows/Linux quando solicitados.
3. Especificar multiplayer: autoridade da simulação, sincronização, salas privadas,
   matchmaking, identidade/progresso, reconexão e segurança. Tecnologia do servidor
   ainda em aberto; experiência anterior com Node.js não é escolha de backend.
4. Refinar ranking junto ao multiplayer; definir regras antes de implementar.
5. Expandir formatos 2×2 e demais modos após estabelecer o multiplayer.
6. Após desktop, discutir mobile: UI/UX, toque, exportação Android/iOS, cross-play
   e progresso compartilhado. Não há decisão tomada de controles nem integração.

Distribuição pública, notarização Apple, monetização e serviços externos exigem
escopo próprio. O roadmap é contexto e não uma autorização para executar tudo.

## Mage 0.4 — REQ-19

- [x] Especificar perfil, ataques e adaptações antes do código (`MAGE_0_4.md`).
- [x] Copiar atlas, lasers, orbe, efeitos, áudio e offsets originais; hashes/avisos.
- [x] Integrar escudo, regeneração, S2 hélice, EMP, CPU/fila/HUD e animações.
- [x] RED→GREEN Mage/modelos/interface; suites existentes e oito partidas naturais.
- [x] Revisão independente/correção da salva, capturas, exportação/assinatura e Git local.
- [x] 181 checks e oito partidas; runtime e pacote PCK exportados verificados.
- [ ] Validação funcional do usuário no aplicativo atualizado.

## Bigfoot T1/T2/SS 0.5 — REQ-03–09, REQ-19

- [x] Identificar emitter, dados e assets no C#; especificar antes do código.
- [x] T1/T2/SS temporizados, forças/ângulos, danos e mira por arma.
- [x] Áudio/Fx originais, HUD, render e pausa/reinício de bombas pendentes.
- [x] 251 checks, dez partidas, revisão independente e capturas GPU.
- [x] Exportação/assinatura/PCK/startup0.5.0 e registro Git/SDD final.
- [ ] Validação funcional do usuário.
