# Contexto para agentes — Brisa de Aço

Leia primeiro `docs/sdd/HANDOFF.md`, depois `docs/sdd/SPEC.md` e
`docs/sdd/DESIGN.md`. `docs/sdd/README.md` explica a organização SDD.
Converse com o usuário em português.

## Estado e escopo

Protótipo 0.6.1 em Godot 4.7.2 + GDScript. Escopo:
desktop macOS, treino offline 1×1 contra CPU, arte do protótipo + Bigfoot/Mage originais
e progresso local.
Ranking foi explicitamente retirado. Rede, contas, multiplayer e mobile estão
no roadmap; não os implemente sem uma nova solicitação. A engine deve preservar
a possibilidade de exportar para macOS, Windows, Linux, Android e iOS.
O usuário quer aprender com o resultado e validar um protótipo funcional.

Pedido posterior ao baseline: integrar assets reais e mobiles do OpenBound,
incluindo Bigfoot. A restrição de arte original descreve a entrega anterior e
não veta essa nova solicitação. Ver `docs/sdd/ORIGINAL_ASSETS.md`: pacote externo
recebido e validado em `.tools/source-assets/content/`, 813 arquivos. Bigfoot já
integrado visualmente com piloto/quadros/projéteis em `assets/openbound/bigfoot/`.
Mage substitui Carapaça com escudo/regen, mira própria, duplo laser helicoidal e
EMP; ver `docs/sdd/MAGE_0_4.md`. Bigfoot tem T1 com4 bombas, T2 duas rajadas de3 e SS com8, com lançamentos
temporizados, dados/Fx/áudio originais e adaptações descritas em
`docs/sdd/BIGFOOT_ATTACKS_0_5.md`. Demais mobiles, resistências, itens, clima/Thor
e regenHP continuam pendentes.
Não pedir novamente caminho/ZIP/link. Ver `docs/sdd/BIGFOOT_0_3.md` e `docs/sdd/MAGE_0_4.md`.

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

## Arte HD 0.6

Derivados GPT Images em assets/hd; ver docs/sdd/HD_ASSETS_0_6.md. Aparência
clássica confirmada. Originais e sons preservados;32 quadros chave por mobile,
4 fases por tiro/6 por explosão, duração/estados antigos. Menu usa heroes.
Recortes metadata alpha>8/255 em atlas_regions.json; regenerar com
scripts/catalog_hd_assets.py quando substituir PNG. Preset deve incluir esse
JSON. Não apagar originais: orientam geometria e fallback. Modelo inalterado.
Teste tests/test_hd_assets.gd e captura GPU tests/capture_hd_assets.gd (1920×1080).

## Correção de animação 0.6.1

Render de mobile usa mobile_rig.gd/peças constantes mobile_parts.png, não mais
os atlas gerados quadro a quadro. Ver ANIMATION_FIX_0_6_1.md. Piloto fixo,
âncoras constantes, relógio pose_age; wheel_phase acumulada por deslocamento.
Fallback conjunto integral original se peças/piloto/catalogo válido ausentes.
Preservar janelas reais de recorte no catalogador. Teste test_mobile_animation.gd
e capture_mobile_animation.gd (216 frames GPU, PNG/MP4/GIF em docs/animation).
Histórico acima sobre32 quadros/menuheroes descreve0.6, substituído no render.
