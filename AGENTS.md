# Contexto para agentes — Brisa de Aço

Leia primeiro `docs/sdd/HANDOFF.md`, depois `docs/sdd/SPEC.md` e
`docs/sdd/DESIGN.md`. `docs/sdd/README.md` explica a organização SDD.
Converse com o usuário em português.

## Estado e escopo

Protótipo 0.2.0 em Godot 4.7.2 + GDScript. Escopo:
desktop macOS, treino offline 1×1 contra CPU, arte original e progresso local.
Ranking foi explicitamente retirado. Rede, contas, multiplayer e mobile estão
no roadmap; não os implemente sem uma nova solicitação. A engine deve preservar
a possibilidade de exportar para macOS, Windows, Linux, Android e iOS.
O usuário quer aprender com o resultado e validar um protótipo funcional.

Pedido posterior ao baseline: integrar assets reais e mobiles do OpenBound,
incluindo Bigfoot. A restrição de arte original descreve a entrega anterior e
não veta essa nova solicitação. Ver `docs/sdd/ORIGINAL_ASSETS.md`: pacote externo
recebido e validado em `.tools/source-assets/content/`, 813 arquivos. Não pedir
novamente caminho/ZIP/link. Integrar os sprites reais; não gerar substitutos nem
anunciar mobiles integrados antes de implementar e verificar o jogo atualizado.

## Trabalho orientado por especificação

- Antes de mudar comportamento, identifique os requisitos `REQ-*` afetados.
- Para nova funcionalidade, atualize a especificação e o plano da mudança antes
  do código, usando a solicitação atual para definir o escopo.
- Registre decisões relevantes em `docs/sdd/DECISIONS.md`; preserve o histórico
  e indique quando uma decisão foi substituída.
- Ao concluir, atualize `TASKS.md` e `HANDOFF.md` com resultados observados,
  pendências e limites da validação. Documentos não substituem a leitura do código.
- Instruções atuais do usuário prevalecem. A autorização da entrega inicial
  não é autorização permanente para novas funcionalidades ou publicação.

## Invariantes e validação

- `match.gd` decide turno, dano e resultado; `game.gd` apresenta estado/eventos.
- Previsão da CPU e disparos reais compartilham física e regras de colisão.
- Mira é relativa ao apoio; `shot_velocity`/`muzzle` fazem a conversão de
  inclinação e direção. HUD e CPU devem usar essas funções, sem duplicar geometria.
- `battle_art.gd` guarda apenas animações. Não usar posições interpoladas para colisão.
- Carga é crescente e dispara uma vez a 100%; a pausa cancela a carga sem atirar.
- Resultado não pode duplicar XP. Testes usam perfil isolado, nunca o perfil real.
- Preserve imagens originais, arquivos `.gd.uid` e configurações `.png.import`.
- `.godot/`, `.tools/` e `builds/` são locais e ignorados pelo Git.
- Prepare `.tools/` antes dos testes. Em checkout novo, importe o projeto primeiro.
- Execute as verificações pertinentes descritas em `docs/sdd/HANDOFF.md`.
  Mudanças em regras de combate exigem os testes de modelos e partidas completas;
  mudanças de navegação/input exigem os testes de cena.
- Se entregar aplicativo atualizado, reexporte com `scripts/build_macos.py` e
  confira a assinatura. Rodar o projeto não atualiza o aplicativo já exportado.

Não há remoto Git configurado no baseline. Não publique nem envie mudanças
a um remoto sem solicitação do usuário.
