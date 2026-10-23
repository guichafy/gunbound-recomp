# Entregas e próximos trabalhos

## Curva do chifre0.18.4 (REQ-10/20/39, ADR-079)

- [x] Reproduzir perda perceptível da0.18.3 no tamanho real da prévia (teste GPU vermelho).
- [x] Restaurar textura L/opacidade/pulsação anteriores; corrigir somente curva via mesh UV fixa.
- [x] Conferir pontos reais do chifre, dois sentidos, inclinação,162frames e30pausados idênticos.
- [x] Medir brilho na loja Avatar/Mobile contra referência sem luz; revisão independente sem achados.
- [x] Regressões5299checks+13Python e QA37lotes/550avatares/629camadas sem pendências.
- [x] App/ZIP0.18.4 exportados/assinados; PCK fora do projeto PASS e pulso confirmado nas duas prévias.
- [x] Usuário testou a 0.18.4, relatou melhora e solicitou revisão/commit/envio à main remota.

## Aura do Great Devil Head 0.18.3 (REQ-10/20/39, ADR-078)

- [x] Derivar o halo do ouro da própria cabeça HD, usando origem e escala compartilhadas.
- [x] Desenhar a aura atrás da anatomia e manter pulsação/pausa; originais preservados.
- [x] GPU 1920×1080: 162 quadros, dois sentidos, inclinação e 30 quadros pausados idênticos; ouro dentro do limite físico de transparência da fonte.
- [x] Revisão independente e guarda contra perfil de contorno inválido na camada base.
- [x] Main: 5296 checks +13Python; QA37lotes/550avatares/629camadas e auditoria runtime sem pendências.
- [x] App/ZIP0.18.3 exportados, assinatura estrita e smoke PCK fora do projeto PASS; prévias Avatar/Mobile conferidas no PCK.
- [x] Usuário testou0.18.3 e rejeitou brilho/animação imperceptíveis; substituída pela0.18.4 acima.

## Release 0.18.2 (auditoria; ADR-076 complementos, ADR-077)

- [x] CPU com tempo fixo de 2 s e relógio parado durante a busca; testes de seed/ordem.
- [x] Fila do HUD em `TurnTable.current_order`; teste de empate.
- [x] Deriva da queda por passo de gravidade (ADR-077); teste de magnitude.
- [x] posmod do vento, guarda de `density`, docs de baseline/gravidade/Mage/ItemDelay.
- [x] check.sh completo: 5287 checks + 13 partidas; App/ZIP 0.18.2 e smoke do PCK.
- [x] PR2 mesclado à main (`59a676d`); integrado à árvore local antes da entrega 0.18.3.
- [ ] Opcional: tirar `model.phase = "menu"` do `game.gd`; centralizar a espera da tarefa da CPU.

## Paridade das regras de batalha (REQ-44, ADR-076)

- [x] Auditar Godot × C# × cliente original; engenharia reversa de ComputeTurnDelay/CommitTurnDelay e `.dat`.
- [x] Decisões do usuário: original comprovado > C#; tempo gasto no delay; abertura sorteada; passe 200.
- [x] Nak 770/920/1320, Mage 730/30, delays de item do itemdata, balística C# (196/14/1,2).
- [x] CPU com refino local; teste de cena da CPU abrindo; test_battle_rules (36).
- [x] check.sh completo: 3926 checks + 13 partidas, zero falhas (worktree `claude/battle-rules-parity`).
- [x] Integrar à main (a25a471) e reexportar App/ZIP 0.18.1, assinatura e smoke do PCK conferidos.
- [ ] Usuário validar a sensação de mira/alcance no app 0.18.1; decidir recalibração do erro da CPU.
- [ ] Opcional: engenharia reversa da balística em ponto fixo e do dano original; termo `[34]` = 200.
- [ ] Opcional: morte súbita do original (limite de turnos em BeginNewTurn).

## Migração HD integral dos avatares — pedido atual
## Revisão0.18 e sincronização main

- [x] Preservar pendentes0.17 em3eb2b01; confirmar PR1 MERGED/ancestralidade.
- [x] Reproduzir mistura Staring/Normal em L e corrigir preparação/fallback.
- [x] Regenerar luz única do Great Devil; registrar20âncoras de cabeça HD.
- [x] GPU20modelos/360frames60Hz/pausa e loja real1920×1080.
- [x] Revisão independente, QA37lotes/550registros renovado.
- [x] Regressão5234checks+13partidas e Python13 PASS.
- [x] Export/PCK0.18, versão0.18.0 e assinatura estrita conferidos.
- [x] Histórico da migração preservado na main remota; confirmado ao atualizar a árvore local para o merge PR2 `59a676d`.
- [ ] NakHD: confirmação explícita pedida pela revisão automática;21outputs/
      patch preservados em source/pending_integration, runtime original ativo.
- [ ] Após confirmação: corrigir separação S2/SS, testesHD/HUD, GPU/export Nak.

## Migração HD integral dos avatares0.17

- [x] Medir escopo real:562registros,550com peças,629camadas,12N/A.
- [x] Identificar/corrigir transparência ARGB4444 de cinco acessórios, RED→GREEN.
- [x] Controle por registro: miniatura, peça vestível, efeito, registro e validação.
- [x] Preparar37lotes com1161componentes; brutos/prompts excluídos do export.
- [x] Regenerar e conferir629camadas vestíveis +532miniaturas, além das18anteriores.
- [x] Consumir HD no personagem vestido:550/550, sem fallback oculto; rig preservado.
- [x] GPU por lote com ambos mobiles/sentidos;360frames60Hz, pausa idêntica.
- [x] Controle HTML/CSV com prévia GPU vestida e motivos dos12N/A.
- [x] Regressão3887checks+13partidas após integração Nak;1744checks de HD e11Python.
- [x] App/ZIP0.17.0 assinados; smoke PCK externo passou:550peças/629camadas e fluxos.
- [ ] Usuário validar a aparência final no aplicativo reaberto.

## Avatar Shop XFS0.16 (ADR-071/072)

- [x] Extrair catálogo562/479compráveis, frames/pivôs/camadas L e retratos nativos.
- [x] Layout XFS800×600, grade3×3, inventário à direita, preços sem blur/overposição.
- [x] Compra/equipamento/perfil3 com migração por identidade e rollback.
- [x] Bônus por peça nos cards/conjunto/combate/previsão, inclusive penalidade de delay.
- [x] Fundo e18miniaturas regenerados; cobertura vestível limitada explicitada.
- [x] 3163checks+10partidas;106checks após atlas, Python8, GPU/PCK passaram.
- [x] App/ZIP0.16.0 assinados, smoke do PCK isolado e capturas1920×1080/60Hz.
- [x] Usuário validou e apontou lacuna de HD no personagem: novo plano acima.

## Avatar Shop Full HD pelo vídeo0.15 (ADR-070)

- [x] Inspecionar vídeo/imagem e aplicar ordem confirmada Presente→Comprar→Experimentar.
- [x] Composição16:9, grade3×3, inventário compacto amarelo e alternância Avatar/Mobile.
- [x] Texto nítido, molduras vetoriais e preço uniforme verificado em GPU/PCK.
- [x] Regenerar fundo e retrato compartilhado de slot vazio; metadados/fallback/mipmaps.
- [x] Corrigir escala real da Window e restaurar menu/batalha, incluindo ESC/reentrada.
- [x] 1949checks rápidos e10partidas completas sem falhas; achado da revisão corrigido.
- [x] GPU1920×1080/120frames60Hz, app/ZIP0.15.0 assinados e smoke isolado do PCK.
- [ ] Usuário validar a aparência e os fluxos no aplicativo reaberto.

## Auditoria de estado/layout da loja0.14.9 (ADR-069)

- [x] Conferir C# e aplicar escolha do usuário: abas sobre cards e Try→Buy→Gift.
- [x] Corrigir seleção oculta, rollback/erro no clique da grade e mensagem de busca vazia.
- [x] Separar arte/legenda/hitbox, alinhar categorias e corrigir size após fonte.
- [x] Preservar proporção da prévia com crop uniforme e faixa de preço nítida.
- [x] 1913checks+10partidas sem falhas; revisão independente sem achados.
- [x] GPU1920×1080/120frames60Hz e smoke real do PCK em/tmp, incluindo batalha.
- [x] App/ZIP0.14.9 reexportados, versão conferida e assinatura estrita válida.
- [ ] Usuário validar layout/fluxos no aplicativo atualizado.

## Nak 0.15 (ADR-074)

- [x] Catálogo ID 3 com dados do fork (HP, mira, delays, sons, miras, RiderPivot).
- [x] Leitor próprio do cliente original; correção dos blocos LZHUF de 4 KB.
- [x] Arte, flipbook (`tank3.epa`), projéteis e explosões originais importados.
- [x] Dano/raio do characterdata; S2 subterrâneo e SS fantasma revertidos do cliente.
- [x] Menu com três mobiles, miras do HUD, partidas 91–93 e test_nak (55 checks).
- [x] Captura GPU em docs/nak (stills, MP4 60 fps, GIF ampliado).
- [ ] Arte HD do Nak: pedido atual substitui adiamento; preparados masters/código.
      Integração aguarda confirmação específica exigida pela revisão automática.
- [ ] Usuário validar sensação de S2/SS e encaixe do piloto no app.
- [x] App reexportado/assinado na entrega0.17 dos avatares HD, mantendo Nak original.

## Paridade Mage/Bigfoot com o C# (ADR-066)

- [x] Regeneração de escudo em todos os mobiles a cada turno, com teto do C#.
- [x] SS aberto no primeiro turno e trava de quatro turnos próprios.
- [x] Dano inverso, caixa por mobile, EMP pelo vão da caixa.
- [x] Queda sem dano de vida, vento no ar, sinalizador 0,4 s no Bigfoot.
- [x] Fumaça do Bigfoot e poses de segundo dano, choque, queda e parede.
- [x] Skill `skills/gunbound-mobile-port` para o próximo porte.
- [ ] Usuário validar a sensação do dano e do SS no aplicativo.

## Fundo de preço sem blur0.14.8 (ADR-068)

- [x] Substituir tira esticada por preenchimento vetorial central, mantendo moldura/rebites.
- [x] GPUFullHD: fundo uniforme (527cores antes→1depois), incluindo confirmação no PCK.
- [x] 1848checks rápidos sem falhas; app/ZIP0.14.8 assinados e smoke isolado passou.
- [ ] Usuário validar o fundo nítido no aplicativo atualizado.

## Moldura/preço e efeito dos avatares0.14.7 (ADR-067)

- [x] Retirar faixa plana sobreposta e compor preços dentro da moldura HD/nativa.
- [x] Explicitar “Cosmético · sem bônus”, tooltip/popup, sem inventar stats da imagem.
- [x] 1848checks rápidos sem falhas, revisão independente sem achados.
- [x] GPU1920×1080 HD/fallback/roster/compra,120frames60FPS; referência preservada.
- [x] App/ZIP0.14.7 reexportados, assinatura estrita e smoke GPU/PCK isolado passaram.
- [ ] Usuário validar os cards atualizados no app.

## Auditoria OpenBound e UI HD0.14.6 (ADR-066)

- [x] Comparar C#/JSON/80originais, catálogo15 sem diferenças; registrar adaptações vigentes.
- [x] Corrigir ícones dos atributos, ciclos/FPS e clique após soltura com regressão real.
- [x] Popup com retrato/categoria/preço/saldo e moeda única central, tamanho fixo.
- [x] Regenerar quatro folhas1254×1254 por GPT Images;20texturas UI, alpha/registro/fallback.
- [x] Corrigir escala de bordas/popup vista na GPU; revisão independente final sem achados.
- [x] Harness1848checks+10partidas, zero falhas; GPU1920×1080/120frames60FPS.
- [x] App/ZIP0.14.6, assinatura estrita e smoke GPU/PCK isolado fora do projeto passaram.
- [ ] Usuário validar aparência/fluxo da interface HD no aplicativo.

## Aura UsingItem e saída do slot (ADR-065)

- [x] No turno próprio o item sai do slot na hora, inclusive o que já estava marcado.
- [x] Aura verde separada do corpo, 20 quadros a 19 fps, folhas 4× Bigfoot e Mage.
- [x] test_items_scene 46 checks; captura `docs/items/using-item-12.png` (1920×1080).
- [ ] Usuário ver o efeito no aplicativo (a aura está incluída no export0.14.6).
- [x] Suíte completa repetida na0.14.6:1848checks+10partidas, zero falhas.

## Loja clássica 0.14.5 (ADR-064)

- [x] Integrar à main por pedido explícito;1758checks+10partidas, app/ZIP e smoke PCK na pasta principal.
- [x] Comparar as duas fotos e C#, reproduzir quatro diferenças da grade/retrato.
- [x] Grade3×3, nove itens/página, retratos centrais e moedas coloridas.
- [x] Inventário lateral vestível persistido e prévia/saldo compactos.
- [x] Atributos em modal, cancelar/ESC, confirmar e feedback de falha/rollback.
- [x] Regressão1758checks sem falhas; revisão independente sem Critical/Important.
- [x] GPU1920×1080 e120frames60fps; fontes originais/hash preservados.
- [x] App/ZIP0.14.5 assinados; PCK real compra/vestir/recarga/batalha passou.
- [ ] Usuário validar fidelidade visual da composição e fluxo no app.

## Skill Gunbound Classic HD

- [x] Consolidar referências/práticas comprovadas em skill reutilizável.
- [x] Separar geração, registro/animação e detalhes específicos do projeto.
- [x] Validar estrutura e cenários de aplicação; instalar no Codex pessoal.

## Avatar contínuo e Vestir0.14.4 (ADR-063)

- [x] Reproduzir saltos de registro e ação de vestir ausente no Shop.
- [x] Registro HD constante; respiração conjunta e transições por ator.
- [x] Vestir possuído transacional, prévia temporária e recarga/batalha com4slots.
- [x] 1731checks+10partidas, revisão independente sem achados, GPU360frames.
- [x] App/ZIP0.14.4 assinados; smoke GPU do PCK com equipamento persistido.
- [x] Usuário confirmou aparência/suavidade no aplicativo atualizado.
- [ ] Validação manual completa do fluxo Vestir pelo usuário (smoke automatizado passou).

## Integração à main0.14.3 (ADR-062)

- [x] Preservar entregas itens0.13 e Shop/HD0.14.2, resolvendo conflitos.
- [x] ItemDelay ativo; ataque/Dig aditivos; contratos loadout/atributos separados.
- [x] Integração39 e suite1584+10partidas sem falhas; revisão independente limpa.
- [x] App/ZIP0.14.3 exportados na pasta principal, assinatura e smoke PCK válidos.
- [ ] Usuário validar conjunto no aplicativo da pasta principal.

## Itens de batalha 0.13.0 (ADR-058)

- [x] Levantar Item.cs, Mobile.cs, MatchManager, HUD, EquippedButtonBar,
      PopupSelectItem, TeleportationBeacon e SpecialEffectBuilder.
- [x] ITEMS_0_13.md, REQ-35..37, ADR-058 antes do código.
- [x] Modelo: 11 itens, custo ÷ 7,5, Dual/Dual+/Thunder/Teleport no voo e na
      previsão, ataque/cavar, cura limitada, um item por turno, SS travado.
- [x] Arte: 19 originais copiados; HD Full HD por Codex GPT Images (5 folhas).
- [x] Cena: barra F1–F6, fila no turno adversário, ITEM LOCKED, popup
      Select Item no menu, sinalizador/chamas/sons, pose UsingItem.
- [x] test_items (49), test_items_scene (42); check.sh 1205 checks + 10
      partidas; seeds 81–90 idênticas à 0.12; app/ZIP 0.13.0 assinados.
- [ ] Usuário validar os itens no app.
- [ ] CPU usar itens (exige rebaselinar seeds).
- [x] ItemDelay integrado ao uso real dos itens na0.14.3.
- [ ] Preço em ouro de itens continua fora do treino (não é compra de avatar).
## Avatares HD0.14.2 (ADR-061)

- [x] Gerar13peças transparentes em5folhas GPT Images1254×1254, estilo dos mobiles.
- [x] Preservar fontes; catálogo/hashes/janela/pivô/deslocamentos e fallback.
- [x] Integrar no piloto e retratos; aspecto preservado e card87×45.
- [x] HD139, Shop19 e quick1454sem falhas; capturasGPU das6famílias/poses.
- [x] App/ZIP0.14.2, assinatura e PCK conferidos.
- [ ] Usuário validar visual HD no inventário e aplicativo.

## Encaixe do avatar 0.14.1

- [x] Reproduzir desalinhamento do inventory.png e comparar registro C#.
- [x] Montagem por RiderPivot/body origin, proporção nativa e oclusão por chassis.
- [x] test_avatar_mount24; quick1314; GPU inventário/poses/comparação.
- [x] App/ZIP0.14.1 e PCK/assinatura verificados.
- [ ] Usuário conferir o novo encaixe.

## Shop de avatar 0.14.0 (ADR-059, REQ-38..41)

- [x] Worktree de main, branch codex/avatar-shop, especificação/plano aprovados.
- [x] Catálogo15 e assets originais; migração perfil2 e compras/equipamento atômicos.
- [x] Shop/Inventário, filtros/busca/páginas, experimentar e confirmação Gold/Cash.
- [x] Composição de quatro peças nos previews/menu/arena, dois mobiles e sentidos.
- [x] Oito atributos e distribuição; modificadores Match/CPU/previsão e Gold.
- [x] Revisão independente e correções reproduzidas em RED→GREEN.
- [x] Check completo1282+10partidas; quick final1290, zero falhas;7capturasGPU.
- [x] App/ZIP0.14.0 exportados no worktree; PCKpreview/catálogo e assinatura válidos.
- [x] ItemDelay integrado ao uso real na main0.14.3.
- [ ] Usuário validar aplicativo; decidir integração da branch posteriormente.
- [ ] GPT Images permanece opção permitida; não solicitado como etapa obrigatória.

## Reorganização SOLID (ADR-057)

- [x] Catálogo `mobiles.gd` no lugar dos ramos por ID.
- [x] `flight_snapshot.gd` como cópia fechada da previsão.
- [x] Dano e turno atrás da fachada do Match.
- [x] Mira, câmera e overlays extraídos; cena continua orquestrando.
- [x] Contexto de desenho em `battle_art`.
- [x] Papéis `PLAYER`/`CPU` e injeção da máscara.
- [x] Conferir `./scripts/check.sh` (1114 checks, seeds 81–90, zero falhas).

## Modo de mira 0.12.0

- [x] Pesquisa: OpenBound só declara AimType; Drag do GunBound por guias.
- [x] AIMING_0_12.md, REQ-34, ADR-056 antes do código.
- [x] Rádio Aiming Mode ativo e gravado; Drag com arraste, tremor, soltura
      robusta, cancelamentos e pan no botão direito.
- [x] test_aiming (25); check.sh 1114 checks + 10 partidas; app/ZIP 0.12.0.
- [ ] Usuário validar o Drag no app.
- [ ] TODO Mouse Speed: habilitar o slider e escalar `DRAG_FULL_POWER`.
- [ ] Interface: só skin Blue (decisão do usuário).

## Performance e limites 0.11.0

- [x] Medir a trava: busca da CPU 90–314 ms num frame no início do turno dela.
- [x] PERF_LIMITS_0_11.md, REQ-32/33, revisão de REQ-31, ADR-053..055.
- [x] Busca da CPU em thread sobre retrato; plano idêntico; seeds 81–90 iguais;
      60 FPS sem picos no turno da CPU; disparo em ~1,85 s como antes.
- [x] Popup HD por GPT Images (Codex), fallback e captura lado a lado.
- [x] BGM com os 12 temas originais, slider ativo e gravado.
- [x] check.sh 1088 checks + 10 partidas; app/ZIP 0.11.0 reexportados e assinados.
- [x] Medido nos dois cenários: CPU Bigfoot travava 336–484 ms, agora ≤ 18 ms.
- [ ] Usuário validar no app (troca de turno, música, popup HD).
- [ ] Fora do escopo/limite: Aiming Mode, Mouse Speed, skins além da Blue,
      fonte Consolas; pico de carga no primeiro frame da partida.

## Popup de opções original 0.10.1

- [x] Levantar PopupGameOptions/PopupMenu/SliderBar/RadioButtonSet/Accept no C#.
- [x] HUD_0_10.md (seção 0.10.1), REQ-31, ADR-052 antes do código.
- [x] Sprites Blue/Options + Accept com SHA; BarFrame (BMP) com bytes idênticos.
- [x] options_popup.gd/options.gd; ESC/Options → popup, P/PAUSA → pausa;
      SFX, Scroll Speed e Background aplicados e gravados no Accept.
- [x] test_hud +29 checks (116); check.sh 1045 checks + 10 partidas; captura docs/hud/hud-options-popup.png.
- [x] Reexportado junto da 0.11.0.
- [ ] Fora do escopo: Aiming Mode, Mouse Speed, BGM (sem música), skins de HUD
      além da Blue, HD do popup.

## HUD original de batalha 0.10.0

- [x] Levantar HUD.cs, Crosshair, WindCompass, Delayboard, HealthBar, fontes e
      botões no C#; usuário escolheu HD GPT Images, carga original e extras discretos.
- [x] Fase A: HUD_0_10.md, ADR-049..051, originais + SHA, pipeline e 5 folhas HD.
- [x] Fases B/C: hud_art.gd, integração em game.gd, mira/vida/dano, input original.
- [x] Fase D: test_hud (87, inclui faixas de mira × limites legais), testes migrados, 1016 checks + 10 partidas, capturas
      docs/hud, app/ZIP 0.10.0 e PCK verificados.
- [ ] Usuário validar o HUD no aplicativo (mouse, toque, áudio do relógio).
- [ ] Fora do escopo: itens/slots F1–F6, ouro real, chat, rank, MatchStatus.
      (PopupGameOptions entregue na 0.10.1.)

## Câmera, vento, clima e Thor 0.9.0

- [x] Levantar Camera/Weather/Thor/ParticleBuilder no C#; usuário decidiu escopo
      (sem outros mapas/HD, escala nativa, vento 2D, commits por fase).
- [x] Fase A: mundo nativo 1800×1800, câmera com seguimento/arrasto, parallax, setas.
- [x] Fase C: vento 2D, fila/colunas/efeitos de clima, Thor e raio elétrico no laço comum.
- [x] Fase D: colunas, satélite, feixes, ícones e partículas com sprites originais.
- [x] 923+ checks e 10 partidas; capturas GPU docs/map e docs/weather; app/PCK.
- [ ] Usuário validar câmera, clima e Thor no aplicativo.
- [ ] Fora do escopo por decisão: outros mapas, HD de clima/Thor, itens (Ignorance).

## Mapa Miramo Town0.8.0/0.8.1

- [x] Levantar mapas/dados no C# (Map.cs, Topography, LevelScene, RoomMetadata).
- [x] Usuário escolheu Miramo Town A e arena fixa; MAP_0_8.md, REQ-21, ADR-042/043.
- [x] GPT Images (Codex image_gen): 3 blocos do foreground, costura/manifest reprodutíveis.
- [x] Colisão pelo alpha original, visual HD, crateras com anel ×0,4, spawns por metade.
- [x] Colisão cortada na linha do HUD (y670) após revisão; fallback visual original; test_map 31 checks.
- [x] 856 checks + 10 partidas no mapa; capturas GPU em docs/map; app/PCK validados.
- [x] Fundo HD 1920×1536 concluído em 0.8.1 (2º bloco após reset do limite); emenda inspecionada.
- [x] Usuário validou o mapa; commit/tag local v0.8.0.
- [x] Clima/Thor, partícula e câmera entregues em 0.9.0; outros mapas descartados pelo usuário.

## Identidade e harness0.7.0

- [x] Renomear projeto/config/export/build para "Gunbound Recomp" 0.7.0.
- [x] Atualizar strings do jogo e rótulos de QA; docs vivos e ADR-040/041.
- [x] Criar `scripts/check.sh` consolidando as14suites com logs e saída de falha.
- [x] Reexecutar harness completo, reexportar app/ZIP e verificar assinatura.
- [ ] Usuário validar identidade/funcionamento no aplicativo 0.7.0.

## Perfil/roster0.6.4

- [x] Diagnosticar perna distante embutida no mestre; editar via GPT Images.
- [x] Integrar perfil único sem mudar proporção/assento/tiros, preservar PNGs.
- [x] Remover Escaravelho ativo, separar IDs/slots e corrigir CPU de Mage.
- [x] Migrar fixtures reais;825checks e10partidas, zero falhas.
- [x] Capturas144framesGPU, menu/arena; revisão sem achados bloqueantes.
- [x] App0.6.4 exportado, assinatura/runtime/PCK isolado; SDD/Git local.
- [ ] Usuário validar sobreposição/seleção no aplicativo.

## Composição0.6.3

- [x] Comparar original/HD e localizar escala relativa incorreta.
- [x] Calibrar piloto/canhão/rodas/assento, preservar aspecto e camadas.
- [x] Regressão RED→GREEN,788checks, comparação/120frames GPU e capturas reais.
- [x] Revisão sem achados bloqueantes, app0.6.3/assinatura/runtime/PCK válidos.
- [x] SDD e Git local atualizados.
- [ ] Usuário avaliar composição corrigida no aplicativo.

## Piloto, tiros e impactos 0.6.2

- [x] Diagnosticar anatomia separada, cabeça variável e orientação Bigfoot.
- [x] Gerar piloto completo/seis cabeças GPT Images, preservar fontes/originais.
- [x] Integrar piloto proporcional, chama separada, rastro contínuo e impactos.
- [x] Preservar posição física, duração, pausa, tremor e fallback de recursos.
- [x] RED→GREEN,783checks,72framesGPU e16capturas reais de jogo.
- [x] Revisão aprovada após corrigir catálogo inválido de impactos/EMP.
- [x] Reexportar0.6.2, validar assinatura/runtime/PCK; atualizar SDD/Git local.
- [ ] Usuário validar personagem e T1/T2/SS visualmente no aplicativo.

## Correção de animação 0.6.1

- [x] Identificar inconsistências anatômicas/estado e redimensionamento por aura.
- [x] Gerar peças GPT Images e integrar rig contínuo/piloto fixo/fallback original.
- [x] Preservar fase das rodas, pausa, arma do recuo e reinício.
- [x] Verificar667checks,216framesGPU e16capturas de jogo; revisão aprovada.
- [x] Reexportar app0.6.1, validar assinatura/runtime/PCKisolado; SDD e Git local.
- [ ] Usuário validar visualmente/funcionalmente a correção no aplicativo.


## Assets HD 0.6

- [x] Confirmar aparência clássica com detalhes mais nítidos.
- [x] Gerar sete PNGs GPT Images: mobiles, piloto, tiros/Fx, heroes eEMP.
- [x] Integrar recortes/alinhamento/fallback; conservar tamanho e combate.
- [x] Verificar439checks,10partidas e exportação independente.
- [x] Reexportar aplicativo0.6.0 e verificar assinatura profunda/estrita.
- [x] Usuário avaliou HD e relatou inconsistências; corrigidas tecnicamente em0.6.1.

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
