# Contexto para agentes — Gunbound Recomp

Leia primeiro `docs/sdd/HANDOFF.md`, depois `docs/sdd/SPEC.md` e
`docs/sdd/DESIGN.md`. `docs/sdd/README.md` explica a organização SDD.
Converse com o usuário em português.

## Estado e escopo

Protótipo 0.7.0 em Godot 4.7.2 + GDScript, identidade "Gunbound Recomp"
(app/ZIP/bundle renomeados; documentos históricos citam o nome anterior
"Brisa de Aço"). Escopo:
desktop macOS, treino offline 1×1 contra CPU, apenas Bigfoot/Mage com derivados HD
e progresso local. Escaravelho foi removido por solicitação do usuário.
O perfil recomeçou na pasta `app_userdata/Gunbound Recomp`, sem migração.
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

## Referência C# em `~/Workspaces/Gunbound`

`/Users/guichafy/Workspaces/Gunbound` é o projeto open source em C# (OpenBound)
que estamos reescrevendo em Godot neste repositório, com algumas melhorias e
preferências do usuário. Está configurado como pasta adicional das sessões
(devin-cli `.devin/config.json`, Claude Code `.claude/settings.json`, Codex
`~/.codex/config.toml`). Consulte-o como fonte de dados, mecânicas e assets
originais; não modifique essa fonte sem solicitação explícita. No Devin CLI,
`/add-dir /Users/guichafy/Workspaces/Gunbound` anexa a pasta como workspace
extra da sessão quando necessário.

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
  Exceção (ADR-056): no modo Drag a força segue o arraste (pode diminuir e
  tremer) e só dispara ao soltar; ainda é um disparo único e cancelável.
- Resultado não pode duplicar XP. Testes usam perfil isolado, nunca o perfil real.
- Preserve imagens originais, arquivos `.gd.uid` e configurações `.png.import`.
- `.godot/`, `.tools/` e `builds/` são locais e ignorados pelo Git.
- Prepare `.tools/` antes dos testes. Em checkout novo, importe o projeto primeiro.
- Execute as verificações pertinentes descritas em `docs/sdd/HANDOFF.md`.
  `./scripts/check.sh` roda todas as suites (`--quick` omite partidas longas).
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

## Piloto e tiros 0.6.2 — caminho atual

Ver PILOT_SHOTS_FIX_0_6_2.md. Piloto completo pilot_seated.png, um sprite1×1;
não remontar cabeça/corpo do rider. projectile_art.gd usa seis cabeças fixas,
chama recortada de shots.png, rastro contínuo Mage, crossfade de impactos/EMP.
Bigfoot aponta DIREITA na fonte (velocity.angle, sem PI). Todo consumidor exige
catalog_valid/regiões completas, fallback original. Offset de tremor só visual.
Teste test_pilot_projectiles.gd; capture_pilot_projectiles.gd gera72frames/PNG.
783checks nesta entrega; docs/projectiles preserva GPU PNG/MP4/GIF.

## Composição 0.6.3 — ajuste atual

Ver docs/sdd/COMPOSITION_FIX_0_6_3.md. Rig usa relação44px piloto/hulls49/46,
não mais altura29. Caixas/assentos/arma/rodas em sample compartilhados pelo draw;
piece preserva aspecto e camadas chassis/piloto/arma/rodas dão encaixe. Menu/arena
mesmos parâmetros. Tiros preservados. tests/capture_mobile_composition.gd
compara original/HD e poses em dois sentidos; docs/composition contém PNG/MP4/GIF.

## Roster/perfil0.6.4 — estado atual

Só Mage(ID1) e Bigfoot(ID2). Escaravelho retirado; não reintroduzir ID0.
VEHICLES é Dictionary; PLAYABLE_VEHICLES separa slots dos IDs. normalize_vehicle
mapeia IDs inválidos para2; CPU sempre3−id. Não alterar IDs restantes.
Piloto ativo é pilot_side.png com perna distante oculta, mesmo registro/assento;
ler SIDE_PILOT_ROSTER_0_6_4.md. PNG anterior preservado. Captura capture_side_pilot.gd
144frames/PNG/MP4/GIF em docs/occlusion; test_roster.gd e suites existentes.
Assets scarab/tortoise mantidos como histórico, excluídos do export macOS;
ícone agora piloto. Progresso local não inclui mobile selecionado e foi preservado.

## Mapa Miramo Town 0.8 — estado atual

Arena padrão é Miramo Town A do OpenBound (ID20), arena fixa 1280×800, escolhas
do usuário. Ler MAP_0_8.md. Colisão = alpha do ForegroundA original amostrado
na grade 640×400 (maps.gd/terrain.load_map); HD foreground_a.png é só visual,
alpha = máscara original. Crateras apagam HD e escurecem anel ×0,4. Spawns
sorteados por metade da lista de Map.cs. Terreno procedural = fallback e
fixtures (`start(..., "")`). Blocos GPT brutos em assets/hd/maps/*/source
(.gdignore); rodar scripts/build_map_hd.py ao trocar blocos. Codex CLI gera
imagens com `-m gpt-5.6-sol` (modelo padrão do config é recusado). Teste
test_map.gd; captura capture_map.gd em docs/map. Clima/outros mapas pendentes.

## Câmera, clima e Thor 0.9 — estado atual

Ler WEATHER_CAMERA_0_9.md. Mundo do mapa é nativo 1:1 (1800×1800, grade
900×900); ADR-044 substitui a arena fixa/escala de 0.8. Câmera em game.gd
(seguimento 1/25, arrasto). Vento 2D e clima/Thor ficam em weather.gd e no laço
comum de match.gd; previsão da CPU sempre simula em cópias. Wind fixtures usam
Vector2; fixtures com literal 640 pedem `start(..., "")`. Arte/sons originais
em assets/openbound/weather e thor. Usuário decidiu: sem outros mapas nem HD
novo. Testes test_weather.gd/test_map.gd; capturas capture_weather.gd e
capture_map.gd (docs/weather, docs/map).

## HUD original 0.10 — estado atual

Ler HUD_0_10.md. HUD do OpenBound em hud_art.gd (offsets HUD.cs, tela virtual
800×500 × 1,6; mundo 1280×664). Sprites originais em assets/openbound/hud;
HD 3× GPT Images em assets/hd/hud via scripts/build_hud_hd.py (folhas brutas
em hud/source com .gdignore; rodar `refs`, gerar, depois sem argumento).
Carga original 0→100 em 2 s (+2/0,04 s); Tab/F8/↑↓ do original; extras
discretos ← → F ● para mouse/toque. Teste test_hud.gd; captura capture_hud.gd
(docs/hud, HD e original lado a lado).
Popup de opções 0.10.1: ESC/Options abre PopupGameOptions original
(options_popup.gd; valores em options.gd, gravados ao lado do perfil). Só SFX,
Scroll Speed e Background têm efeito; demais esmaecidos. Pausa própria em P e
no extra PAUSA. Ver seção 0.10.1 de HUD_0_10.md/ADR-052.

## Performance, BGM e popup HD 0.11 — estado atual

Ler PERF_LIMITS_0_11.md. Busca da CPU: begin_cpu_plan (principal) →
search_cpu_plan (WorkerThreadPool, só o retrato) → finish_cpu_plan; plano
idêntico a choose_cpu_shot (wrapper dos testes). Nunca ler estado vivo na
thread; descartar com discard_cpu_search. BGM: temas LevelScene em
assets/openbound/music, sound.play_music/stop_music, mudo cobre música.
Popup HD pela folha options de build_hud_hd.py. Teste test_performance.gd.

## Modo de mira 0.12 — estado atual

Ler AIMING_0_12.md. Rádio Aiming Mode ativo (options.aiming: 0 Drag, 1 Slice
padrão). A lógica do Drag está em `aim_control.gd` (`begin_drag`, tremor com
`drag_rng`, soltura). A cena encaminha `charging`: o setter encerra o Drag.
Botão direito/meio olha o mapa. Mouse Speed: TODO (escalar `DRAG_FULL_POWER`
em `aim_control.gd`). Skins: só Blue.
Teste test_aiming.gd.

## Arquitetura SOLID — estado atual

ADR-057. `match.gd` decide turno, dano e resultado. Catálogo em `mobiles.gd`
(IDs 1 e 2). Previsão só pelos campos de `flight_snapshot.gd`. Dano em
`damage.gd`, agenda em `turn_table.gd`. Cena delega a `aim_control.gd`,
`camera_rig.gd` e `match_overlay.gd`. Papéis `Match.PLAYER` e `Match.CPU`.
`battle_art` não lê campos da cena: recebe o contexto de `actor_context`.
Treino segue 1×1; não adicionar rede neste corte.


## Shop de avatar 0.14 — caminho atual

Ler AVATAR_SHOP.md e AVATAR_SHOP_PLAN.md. Quatro slots, catálogo original
15registros, perfil version2 com saldo inicial1000Gold/Cash uma vez, conjuntos
por gênero e unissex compartilhado. ShopModel mantém preview temporário;
Profile valida/transaciona com rollback. PlayerAttributes:10por avanço do nível
local,180total,50por atributo. Atores copiam atributos/equipamento no start;
CPU/previsão usam mesmas regras. AvatarArt substitui piloto no rig quando
recebe contexto; legado preservado sem contexto. GoldRewards segue fluxo C#
4/1resultado, Popularity cumulativa; XP separado. ItemDelay fórmula apenas
até integrar código de itens. Assets originais, sem novo HD. Suites
test_avatar_catalog/profile/shop/art, test_attributes e test_gold_rewards;
capture_avatar_shop gera capturas GPU e smoke separado confere PCK exportado.

Encaixe0.14.1 (ADR-060): AvatarArt usa origem Body via registro nativo do
MobileSprite no rig, não o pivô hip do pilot_side nem offset(0,−8). Chassis
oculta parte inferior das peças equipadas como no C#. Ver AVATAR_MOUNT_FIX.md
e test_avatar_mount24; comparação em docs/avatar-shop/mount-comparison.png.

Avatares HD0.14.2 (ADR-061):13peças em5folhas GPT Images1254×1254, constantes
com registro original. AvatarHD/catalog_avatar_hd.py guardam recortes,
janela/pivô/deslocamentos; AvatarArt usa HD com fallback. Fontes originais
preservadas. Regenerar catalog.json ao trocar PNG. Source/.gdignore exclui
referências; preset inclui avatars/*.json. Tests test_avatar_hd e captura
capture_avatar_hd_roster. Ver AVATAR_HD.md; não é geração quadro a quadro.
