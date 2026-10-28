# Contexto para agentes — Gunbound Recomp

Leia primeiro `docs/sdd/HANDOFF.md`, depois `docs/sdd/SPEC.md` e
`docs/sdd/DESIGN.md`. `docs/sdd/README.md` explica a organização SDD.
Converse com o usuário em português.

## Objetivo do projeto

Reescrever em Godot, com fidelidade, os projetos de referência
[jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher) (launcher e
TestClient do cliente Thor's Hammer) e
[jglim/gunbound-server](https://github.com/jglim/gunbound-server) (emulador do
servidor). A meta é manter o comportamento original e, sobre essa base, dar
suporte multiplataforma (macOS, Windows, Linux, Android e iOS) e permitir novas
funcionalidades. A etapa atual cobre o cliente em treino offline 1×1; servidor,
rede e multiplayer seguem no roadmap e só entram com pedido do usuário.
Extensões e modernizações são declaradas como tais, nunca misturadas ao porte fiel.

## Escopo de fontes — ADR-132

Este repositório porta apenas o cliente clássico **GunBound Thor's Hammer**.
OpenBound (versão Season 2, diferente) está fora do escopo: não consultar, não
anexar como pasta adicional e não usar como fonte de regra, dado ou arte. Onde
o cliente ainda não comprova um comportamento, o porte fica como adaptação
declarada. Regras e assets herdados dessa fase continuam ativos até serem
substituídos pelo cliente; a pasta `assets/openbound/` mantém o nome histórico
e suas atribuições/licença. Registros antigos em `docs/sdd` citam o OpenBound
como histórico, não como instrução.

## Restauração Bigfoot/Mage 0.20.3 — caminho atual

Pedido posterior substitui a preservação HD desses dois mobiles na ADR-088.
Ler docs/sdd/ORIGINAL_MAGE_BIGFOOT.md e ADR-089. Catálogo ativo usa
ClassicSprite/ClassicMageSprite e subpastas `original/` de mage e bigfoot
(tank2/tank5, EPA, contato e RiderPivot nativos). Escala igual aos demais
clássicos; tiros/impactos/miras/auras originais. HD anterior preservado em disco;
avatares/equipamentos e regras mantidos. Mage T1/T2 conservam composição
adaptada, sem alegação de paridade integral do laser.
Harness 8059 checks +17 Python +29 partidas aprovado; galeria GPU210 frames,
pausa30 idênticos; app/ZIP0.20.3 assinados, PCK44/0. Aceite visual do usuário,
escuta/mouse e captura específica menu/loja/arena pendentes (timeout UI).

Bigfoot 4× (ADR-115): folhas originais com BICUBIC4× por quadro em
assets/hd/classic/mobiles_smooth_4x/bigfoot; MobileLooks `smooth` e
mobile_smooth_art.gd validam/caem no nativo; só recortes de origem ×4. Ler
docs/sdd/BIGFOOT_SMOOTH_4X.md. Regenerar com scripts/build_bigfoot_smooth_hd.py.

## Resultado da partida e loading — ADR-139/138

Fim do treino abre a janela do cliente (`classic_result.gd`, catálogo
`assets/xfs/result` via `scripts/import_xfs_result.py`): painéis WIN/LOSE por
time, linhas com rank1/font.fnt/numfont e só o OK (volta à sala). Ler
docs/sdd/RESULT_SCREEN_NATIVE.md; P = XP do porte, CPU 0P/Chick, adaptações
declaradas. Teste test_result_screen + test_import_xfs_result; captura
tests/capture_result_screen.gd. Start da sala passa pela tela de loading
(PR #5, ADR-138/REQ-49, LOADING_SCREEN.md).

## Avatar Shop original — ADR-130

Ler docs/sdd/AVATAR_SHOP_ORIGINAL.md. Loja desenhada com os frames do
`graphics.xfs` (`classic_shop_art.gd`, `assets/xfs/shop`, 4× em
`assets/hd/classic/shop_smooth_4x`); regras de card/preço/status do cliente
0x44a000/0x44c460. `AvatarArt` usa peças nativas por padrão em loja, sala e
batalha: isso substitui o uso ativo do HD de avatares (0.17/0.18), preservado
em disco. Não reintroduzir busca, rótulos PT ou arte GPT na loja.
Teste test_shop_original; captura tests/capture_shop_original.gd.

## Estado e escopo

Protótipo 0.20.5 em Godot 4.7.2 + GDScript (versão única em
`application/config/version` do `project.godot`), identidade "Gunbound Recomp"
(app/ZIP/bundle renomeados; documentos históricos citam o nome anterior
"Brisa de Aço"). Escopo:
desktop macOS, treino offline 1×1 contra CPU. O elenco jogável é o dos 16
mobiles do cliente (REQ-45, ADR-083): IDs 1 Mage, 2 Bigfoot e 3 Nak preservados;
4–16 são Armor, Trico, Boomer, Raon, Lightning, JD, ASate, Ice, Turtle, Grub,
Dragon, Knight e Aduka, com arte original. Bigfoot e Mage usam a arte original conforme a restauração 0.20.3;
derivados HD anteriores preservados em disco. Escaravelho foi removido por solicitação do usuário.
O perfil recomeçou na pasta `app_userdata/Gunbound Recomp`, sem migração.
Ranking foi explicitamente retirado. Rede, contas, multiplayer e mobile estão
no roadmap; não os implemente sem uma nova solicitação. A engine deve preservar
a possibilidade de exportar para macOS, Windows, Linux, Android e iOS.
O usuário quer aprender com o resultado e validar um protótipo funcional.

Mage tem escudo/regen, mira própria, duplo laser helicoidal e EMP, revisados
pelo cliente (ADR-126/128/129). Bigfoot tem T1 com 4 bombas, T2 duas rajadas de 3
e SS com 8, ainda como adaptação herdada (`docs/sdd/BIGFOOT_ATTACKS_0_5.md`).
Itens entraram em 0.13 (ver seção abaixo); o roster completo entrou em 0.19 e os
portes especiais restantes estão nos planos por família. Estado por mobile em
`docs/MOBILES.md`. Ao portar outro mobile, siga a skill gunbound-client-port.

## Porte fiel do cliente e próxima modernização

Usar `skills/gunbound-client-port/SKILL.md` (`$gunbound-client-port`) ao
reescrever comportamento do cliente no Godot ou investigar diferenças de
fidelidade. A skill reúne REA, evidência, aritmética, animação/raster e
validação; complementa gunbound-classic-hd.
O usuário autorizou engenharia reversa do binário client-side para informar
e ajustar o porte. Cliente original comprovado prevalece; onde faltar prova,
manter a adaptação identificada, sem anunciar paridade integral.
Ghidra headless é o caminho preferencial da skill, com runner/exportador
incluídos. Ler `references/ghidra.md` e `docs/sdd/GHIDRA_SKILL_VALIDATION.md`.
Ghidra12.2 direto funciona; REA6.7.0 aceita apenas12.1.x. Não confundir a
compatibilidade do conector com a análise direta, nem copiar C decompilado
sem confirmar ABI, ASM, LUTs e consumidores.
Projetos-alvo da reescrita: jglim/gunbound-launcher (TestClient) e
jglim/gunbound-server. O servidor não comprova sozinho o render do cliente e,
nesta etapa, não amplia o escopo offline.
Preservar todos os 16 mobiles, avatares/equipamentos e HD já aprovados
(avatares e loja: ADR-130 trocou o uso ativo do HD pelos originais).
Modernização do design de mobile/avatar fica para uma etapa posterior
solicitada pelo usuário. Não substituir a aparência atual durante o porte.

## Grub — ADR-150

Ler docs/sdd/GRUB_CLIENT_FIX.md. S1/SS θ+2 e S2 com 4 corpos vêm do MainAction `0x471fd0`.
S2/SS ricocheteiam por `grub_flight.gd` (tick `0x49fd40`/`0x486ea0`) e `grub_surface.gd`
(`0x4a1740`); fixtures em `tests/fixtures/grub_*_native.json` foram geradas rodando o PE num
emulador (`tests/tools/grub_oracle`, Unicorn fora do projeto). SS fere a cada quadro; dano/cratera
da linha type 12. Sem o par biônico 10/70 (a linha type 12 não o contém; só o Grub). Tornado, atributos do dono e contato do T1 são adaptações.
Sem rastro (ADR-120). Luz: `bullet13nl/sl` e `tank13l.img` (`CharacterSpritesheetLight.png`) são
aditivas via `grub_sprite.gd` (emenda da ADR-150). Testes test_grub_{surface,flight,model} e
test_grub_assets.py; captura tests/capture_grub.gd.

## Tiros Raon — ADR-116

Ler RAON_CLASSIC_FIX.md (seção ADR-116). Mobile06_MainAction: T1 idx0/2/3
(comum, fase0, fase180); T2 dois tiros no mesmo ângulo com força nativa
P+15/P−15; SS P+15 (`native_power` na emissão, somado após quantizar, sem
clamp). Balas T2/SS só colidem com terreno; supermina anda para a direita
só com vx>0. Teste test_raon_shots; captura GPU tests/capture_raon_shots.gd.
Minas (ADR-117): pos = pixel do chão; AnimateMine nativo (inclinação, queda,
gatilho 8 px pelos pés, explosão y−10); desenho por `RaonEffect.draw_transform`.
Teste test_raon_mines; captura tests/capture_raon_mines.gd com
`--disable-vsync --always-on-top` (janela oculta fica lenta).
Rastro (ADR-118): T1 do Raon desenha 7 cópias anteriores, alfa 255−32k
(`ClassicSprite.trail_levels`), **apenas no T1 do Raon** (`has_trail`, ADR-120,
pedido do usuário). Não estender a outros tiros sem novo pedido.

## Turtle T2 0.20.2 — caminho atual

Ler `docs/sdd/TURTLE_T2_FIDELITY.md` e ADR-087. `turtle_flight.gd` usa
fase 0/180, amplitude 1000, avanço 5 e contador 0 por projétil: dez ticks de
crescimento, depois decaimento. Onda/colisão usa heading pré-aceleração;
seções ±10 usam heading pós-aceleração e pixel inteiro. Carrier não acumula
o offset. `water_sides` acompanha o histórico copiado pela previsão; renderer
interpola cópias e envia dois triângulos explícitos por quad T2 para aceitar
seções cruzadas. T1 mantém draw_polygon; T1/SS e avatares preservados.

Suíte T2 final 588/0, revisão SPEC/qualidade aprovada após P2 de raster;
probes independentes 28667+46+32 sem falhas. Harness 8020 checks Godot + 16 Python
+ 29 partidas, parse aprovado. GPU temporal 1920×1080/60 FPS, 270 quadros,
normal/P1/Tornado nos dois sentidos e pausa 30 quadros idênticos. App/ZIP
0.20.2 assinados/conferidos; fonte 163/0, PCK isolado 179/0/exit0, ressalvas
ambientais CA/editor_settings explícitas e override ausente do ROOT/PCK.
Cliente original não executado; escuta/mouse sem validação registrada.
Aceite visual do T2 confirmado pelo usuário: “Agora funcionou”. Tornado, colisão/dano e física dos filhos SS continuam
adaptações. Não usar resultados das versões abaixo como prova desta entrega.

## Turtle 0.20.1 — base preservada

Ler `docs/sdd/TURTLE_ANIMATION_FIX.md` e ADR-086. WaterEffect usa UV 1/8,
alpha(255−16i)/255 e seções compartilhadas; interpolar somente cópia visual
do histórico. Turtle SS: normal até 43, change no 44 por dez ticks, seis filhos
bullet12c e remoção do pai sem explosão aérea. `burst` exige `split` para
flight=open. Hold estabiliza endpoints visuais; evento/efeito preserva
child/ss_state. Pai normal usa Flame3+SSFlame, change/filhos somente Flame3.

Revisão focal aprovada após três P2; suíte 158/0 e probe 18 cenários/4628 checks
sem falhas. Captura real 1920×1080/60 FPS, 270 quadros, pausa 30 quadros validada;
escuta/mouse pendentes. Harness final 7432 checks Godot + 16 Python + 29 partidas
sem falhas, parse aprovado. App/ZIP 0.20.1 assinados/conferidos; PCK 170/0
com erro ambiental de CA explícito, sem SCRIPT ERROR/leaks. Override ausente
do ROOT/PCK. Resultados/logs no registro Turtle. Os números
0.20.0 abaixo são históricos. HUD/limites/trava SS preservados; dano e física
numérica dos filhos permanecem adaptações, sem alegação de porte integral.

## Base da fidelidade0.20 — histórico da entrega

Ler `docs/sdd/BATTLE_FIDELITY_0_20.md`, `CLASSIC_BALLISTICS_0_20.md` e
ADR-084/085. Tarefas 1–7 implementadas; tarefa 8 é pesquisa de 48 tiros e planos
por família, não porte integral. Código integrado; harness final 7287 checks Godot,
16 Python/29 partidas, sem falhas. App/ZIP 0.20.0 assinados; PCK 160 checks
sem falhas de assertiva, erro ambiental de CA explicitado. QA tem limite de
resolução; recaptura Full HD/escuta pendentes. Detalhes no registro 0.20. Não usar números históricos como
validação desta versão nem presumir que o app anterior foi atualizado.

`classic_ballistics.gd`: 20 Hz/24.8, LUTs pré-aquecidas, aceleração congelada,
força nativa convertida uma vez; Slice3 s e P mínimo 1. `boomer_flight.gd`
decide SS normal/change/cnormal (freeze36–45, retomada 46); não inferir por
idade visual. `classic_shot_timing.gd` guarda48timelines/grupos; som em
projectile_launch, pose Dual separada. `classic_projectile_art.gd` desenha
WaterEffect sem cabeça Armor. Minas mantêm autoria/Gold e compartilham o
passo com a previsão; filhos/cristais passam por ShellState. Colisão nunca
usa interpolação. Na0.20.0, `open/hold` do Armor/Turtle publicava estado visual
sem alterar a mecânica; paraTurtle isso foi substituído pelaADR-086. Contato ASate0 → −3 é mudança visual registrada.

Dano/colisão refinada/tornado e famílias ASate/JD/Aduka/Grub/Knight não são
paridade nativa completa; seguir `BATTLE_MOBILE_FAMILY_PLANS.md` em novo porte.
Preservar originais/HD e perfil real. Override local de certificados não
pode ser exportado. Rodar harness com modelos, cenas e 29 partidas previstas
(13 seeds+16 mobiles); `--quick` omite as duas suítes de partidas.

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

O remoto `origin` (github.com/guichafy/gunbound-recomp) existe desde o PR #1.
Não publique nem envie mudanças a um remoto sem solicitação do usuário.

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

Mage(ID1) e Bigfoot(ID2); Nak(ID3) desde 0.15 (seção Nak). Escaravelho retirado; não reintroduzir ID0.
VEHICLES é Dictionary; PLAYABLE_VEHICLES separa slots dos IDs. normalize_vehicle
mapeia IDs inválidos para2; CPU por Mobiles.opponent (1↔2, Nak→Mage). Não alterar IDs restantes.
Piloto ativo é pilot_side.png com perna distante oculta, mesmo registro/assento;
ler SIDE_PILOT_ROSTER_0_6_4.md. PNG anterior preservado. Captura capture_side_pilot.gd
144frames/PNG/MP4/GIF em docs/occlusion; test_roster.gd e suites existentes.
Assets scarab/tortoise mantidos como histórico, excluídos do export macOS;
ícone agora piloto. Progresso local não inclui mobile selecionado e foi preservado.

## Mapa Miramo Town 0.8 — estado atual

Arena padrão é Miramo Town A (ID20), arena fixa 1280×800, escolhas
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
Vector2; fixtures com literal 640 pedem `start(..., "")`. Arte/sons herdados
em assets/openbound/weather e thor (nome histórico). Usuário decidiu: sem outros mapas nem HD
novo. Testes test_weather.gd/test_map.gd; capturas capture_weather.gd e
capture_map.gd (docs/weather, docs/map).

## HUD original 0.10 — estado atual

Ler HUD_0_10.md. HUD de batalha em hud_art.gd (offsets herdados, tela virtual
800×500 × 1,6; mundo 1280×664). Sprites herdados em assets/openbound/hud;
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

ADR-057. `match.gd` decide turno, dano e resultado. Catálogo de regras em
`mobiles.gd` (IDs 1, 2 e 3); apresentação por mobile em `mobile_looks.gd`. Previsão só pelos campos de `flight_snapshot.gd`. Dano em
`damage.gd`, agenda em `turn_table.gd`. Cena delega a `aim_control.gd`,
`camera_rig.gd` e `match_overlay.gd`. Papéis `Match.PLAYER` e `Match.CPU`.
`battle_art` não lê campos da cena: recebe o contexto de `actor_context`.
Treino segue 1×1; não adicionar rede neste corte.


## Itens de batalha 0.13 — estado atual

Ler ITEMS_0_13.md (REQ-35..37, ADR-058). Catálogo `items.gd` (11 itens, custo
original ÷ 7,5). Regras no `match.gd`: `use_item`, `shot_shells` (Dual/Dual+/
Teleport/Thunder) usado por `fire` e `predict_shot`; efeito do turno em
`actors[i].turn_item` (copiado pela previsão), limpo em `TurnTable.schedule`.
Cada projétil guarda `weapon`; sinalizador (`beacon`) só colide com o terreno.
CPU sem itens. No turno próprio o item sai do slot na
hora (ADR-065) e a aura UsingItem HD acompanha o mobile. Cena: `item_bar.gd` (barra F1–F6, fila no
turno adversário, ITEM LOCKED na Ignorância), `item_art.gd` (botões, sinalizador,
chamas; Teleport2 = Teleport1 invertido), `select_item_popup.gd` (menu "Itens";
carga em `options.items`). Arte HD via `scripts/build_items_hd.py` e Codex
(`refs`, gerar `gen_<folha>.png`, depois sem argumento). Testes test_items.gd e
test_items_scene.gd; captura tests/capture_items.gd (docs/items).
## Shop de avatar 0.14 — caminho atual

Substituído pela ADR-130 na loja e nos avatares ativos; histórico abaixo.

Ler AVATAR_SHOP.md e AVATAR_SHOP_PLAN.md. Quatro slots, catálogo original
15registros, perfil version2 com saldo inicial1000Gold/Cash uma vez, conjuntos
por gênero e unissex compartilhado. ShopModel mantém preview temporário;
Profile valida/transaciona com rollback. PlayerAttributes:10por avanço do nível
local,180total,50por atributo. Atores copiam atributos/equipamento no start;
CPU/previsão usam mesmas regras. AvatarArt substitui piloto no rig quando
recebe contexto; legado preservado sem contexto. GoldRewards segue fluxo herdado
4/1resultado, Popularity cumulativa; XP separado. ItemDelay fórmula apenas
até integrar código de itens. Assets originais, sem novo HD. Suites
test_avatar_catalog/profile/shop/art, test_attributes e test_gold_rewards;
capture_avatar_shop gera capturas GPU e smoke separado confere PCK exportado.

Encaixe0.14.1 (ADR-060): AvatarArt usa origem Body via registro nativo do
MobileSprite no rig, não o pivô hip do pilot_side nem offset(0,−8). Chassis
oculta parte inferior das peças equipadas. Ver AVATAR_MOUNT_FIX.md
e test_avatar_mount24; comparação em docs/avatar-shop/mount-comparison.png.

Avatares HD0.14.2 (ADR-061):13peças em5folhas GPT Images1254×1254, constantes
com registro original. AvatarHD/catalog_avatar_hd.py guardam recortes,
janela/pivô/deslocamentos; AvatarArt usa HD com fallback. Fontes originais
preservadas. Regenerar catalog.json ao trocar PNG. Source/.gdignore exclui
referências; preset inclui avatars/*.json. Tests test_avatar_hd e captura
capture_avatar_hd_roster. Ver AVATAR_HD.md; não é geração quadro a quadro.

Integração main0.14.3 (ADR-062): itens0.13 + Shop/HD0.14.2. Match.start recebe
loadout7º, atributos8º. ItemDelay ativo no custo original truncado antes÷7,5;
Attack/bonus−Defense e Dig/bonus somam. Isso substitui os limites antigos de
ItemDelay acima. Test test_shop_items_integration39; suite1584+10partidas.

## Animação aprovada e skill de arte clássica HD

Substituído pela ADR-130 na loja e nos avatares ativos; histórico abaixo.

0.14.4/ADR-063 substitui deslocamentos do centro alpha por quadro: peças HD
mantêm registro constante; respiração usa relógio contínuo e poses misturam
geometria exibida por ator em0,14s. Não reintroduzir offsets de silhueta como
movimento anatômico. Shop tem Vestir persistido; Experimentar é temporário
para não possuídos. Suavidade/aparência confirmadas pelo usuário.

Para regenerar/animar arte Gunbound Classic, consulte a skill reutilizável
`skills/gunbound-classic-hd/SKILL.md` (`$gunbound-classic-hd` no Codex).
Inclui prompts, distinção Full HD1920×1080/pixels úteis dos sprites, pivôs,
montagem Body/mobile, transições, fallback e validação. Referências específicas
do projeto ficam separadas das técnicas gerais. Não mudar combate/perfil como
efeito de uma tarefa apenas de arte.


## Shop clássico 0.14.5 — layout atual

Substituído pela ADR-130 na loja e nos avatares ativos; histórico abaixo.

Ler AVATAR_SHOP_CLASSIC_0_14_5.md/ADR-064. Primeira foto do usuário define3×3,
nove itens/página e inventário lateral vestível sempre visível. Catálogo da época mantinha
preços15registros; não inventar chapéus ou stats da imagem. Atributos
em modal separado, confirmar/cancelar com rollback. Cards166×147, janela146×90,
retratos126×78 com aspecto preservado. Test test_avatar_shop_classic e captura
capture_avatar_shop_classic em1920×1080/120frames60Hz; smoke separado do PCK.
Worktree codex/avatar-shop-classic integrada à main por solicitação explícita.
1758checks+10partidas e smoke do PCK principal passaram; app/ZIP0.14.5 em builds.
Branch/worktree preservados como referência, sem publicação.

## Nak 0.15 — estado atual

Ler docs/sdd/NAK_0_15.md (REQ-43, ADR-074). Terceiro mobile, ID 3, contra o
Mage na CPU; 1↔2 inalterado. Arte/flipbook/dano/voo vêm do
cliente original (jglim/gunbound-launcher TestClient, baixado com autorização em
`.tools/gunbound-client/`) lido por `scripts/gunbound_xfs.py` (entradas em blocos
LZHUF de 4 KB) e `scripts/import_nak_assets.py`. S2 `burrow` (vy ÷ 2, sobe 2×
gravidade, explode no primeiro pixel livre) e SS `ghost` (só mobiles) ficam no
laço comum do `match.gd`. `nak_sprite.gd` espelha o desenho (atira pela cauda),
bolha `emotion1` no idle e RIDER_ADJUST (+5,+4). Sem HD ainda (usuário adiou a
geração): `HD_KINDS` do rig/projéteis só Bigfoot/Mage; miras Nak 1×. Dúvidas
sobre o cliente original: perguntar ao usuário. Teste test_nak.gd; captura
tests/capture_nak.gd (docs/nak). Seeds 91–93 de test_matches jogam com o Nak.

## Regras de batalha 0.18.2 — estado atual

Ler docs/sdd/BATTLE_RULES_AUDIT.md (REQ-44, ADR-076). Política do usuário:
regra original comprovada por engenharia reversa (GunBound-Decomp + `.dat`
do cliente) prevalece; senão vale a adaptação declarada (ADR-132). Delay original = `[28]` base + custo
do tiro `[30/31/32]` + segundos inteiros gastos até o disparo × `[29]` (10).
`TurnTable.shot_cost` serve à agenda e à prévia. Turno 30 s; passe 200 sem
tempo; abertura sorteada (`Match.RANDOM_OPENING`; fixtures usam o padrão
PLAYER e testes de cena fixam `opening = 0`). Balística herdada (0.18, substituída pela 0.20): gravidade
196, força × 100 / massa 14, vento × 1,2; piso de força 15 e relógio real
mantidos. Nak 770/920/1320, Mage 730/regen 30, itens do `itemdata.dat`.
Mantidos: empate de iniciativa para o outro, empate por morte dupla, passe
sem travar SS. As seeds de test_matches mudaram de propósito (valores no
hand-off). Balística e dano originais em ponto fixo não foram portados.
0.18.2: a CPU cobra 2 s fixos (`TurnTable.CPU_THINK_SECONDS`) e o relógio dela
fica parado durante a busca (`Match.cpu_thinking`); a fila do HUD vem de
`TurnTable.current_order`. Queda: deriva `wind.x / 45` por passo de gravidade
(3 px, +0,15), ADR-077.

## Revisão de qualidade 0.18.6 — estado atual

Ler QUALITY_REVIEW.md (ADR-081). Sem mudança de regra: golden master local de
26 partidas (eventos + campos do ator) idêntico à `main` 0.18.5, além das
seeds 81–93. Pontos de extensão: `mobile_looks.gd` (sprite, layout HD do rig,
estilo do projétil HD, aura UsingItem e relógios de pose por mobile; Nak declara
"sem aura"), `sprite_pose.gd` (parâmetros de `MobileSprite.draw`/`MobileRig.draw`),
`delay_units.gd` (única conversão ÷7,5; catálogos guardam o custo original em
`cost`), `item_effects.gd` (efeitos por tipo "effect"/"shot" de `items.gd`),
`weather_contact.gd`, `gold_tracker.gd`, `cpu_planner.gd` atrás da fachada do
Match, `json_store.gd`, `Attributes.ATTACK..POPULARITY` no lugar dos índices,
`TurnTable.order` como regra única de ordem. Cena: `scene.aim.*`/`scene.rig.*`
(sem proxies), `scene.cpu` (`cpu_turn.gd`), `scene.menu` (`menu_screen.gd`),
`scene.overlays.kind/layer/options_popup` (sinais opened/closed). Suítes herdam
`tests/support/suite.gd`; `check.sh` compila todos os scripts e capturas e
limita cada suíte (`SUITE_TIMEOUT`). Atores/projéteis seguem Dictionary (motivo
no plano), com fábricas em `actor_state.gd`/`shell_state.gd`. Fases são
`Match.PHASE_*` (strings).

## Brilho do Great Devil 0.18.7 — estado atual

ADR-082 substitui ADR-079. A luz do chifre (`xfs:0:0:71|layer:1`) é
`great_devil_horn_light.png`, derivada da silhueta do chifre HD por
`scripts/build_devil_horn_light.py` com o perfil do L clássico, registrada sobre
a cabeça via `overlay_base`. Não regerar uma luz solta nem reativar
`light_curve`. Rodar o script se a cabeça HD mudar ou se `register_xfs_avatar_hd.py batch_005`
for reexecutado (ele devolve a célula gerada à camada); depois recapturar o QA.
Evidência em `docs/horn-classic`; ver HORN_AURA_FIX.md.

