# Design implementado

## Acabamento conservador ativo — ADR-101

DiretórioHD ativo: `assets/hd/classic/buttons_smooth_4x`, catálogo gerado a
partir das fontes com BICUBIC por quadro e alpha em nearest. Atlas exatos
anteriores permanecem em `buttons_4x`. O consumidor mantém a mesma conversão
de recortes e a mesma geometria lógica da ADR-100. Importação pode reparar
RGB sob alpha0; testes comparam a contribuição visível e o alpha, sem tratar
RGB invisível como alteração do desenho. Ver `CLASSIC_BUTTONS_SMOOTHING.md`.

## Consumo dos botões4× — ADR-100

`ClassicChrome` lê o catálogo4× ao lado do manifest nativo. Valida registro,
escala/dimensões e textura importada; fornece um atlasHD válido ou fallback
nativo. `frame_size` e os controles continuam em pixels nativos; somente a
região do `AtlasTexture` usa densidade4. Cache separa caminhos HD/nativos.
Lobby/menu não duplicam conversão nem alteram o layout. Os dois JSONs entram
no preset de exportação. Validação: `CLASSIC_BUTTONS_HD_INTEGRATION.md`.

## Skill HD — restauração fiel (ADR-099)

`skills/gunbound-classic-hd` usa fonte visual única e prompt integral de
restauração. `scripts/validate_restoration.py` dessa skill lê imagens, mede
dimensões/grade/alpha e diferenças por célula; não edita PNGs e não aprova
aparência. Ensaios separados em `docs/classic-hd-restoration` não são recursos
do runtime. Evidência em `CLASSIC_HD_RESTORATION_SKILL.md`.

Para repetição exata pedida/aceita, `scripts/upscale_exact.py` na skill
salva um PNG novo com nearest inteiro e preservação de RGBA. O verificador
usa `--exact-pixels` para conferir todos os pixels na resolução final,
além da geometria/alpha. Média RGB sozinha não comprova esse contrato.

O lote `assets/hd/classic/buttons_4x` reúne42atlas/197estados. Seu catálogo
guarda escala4, dimensão/célula/regiões ampliadas, ordem/registro nativo e
hashes de origem/saída. Os consumidores atuais continuam usando o catálogo
nativo: a entrega de PNGs ampliados não muda coordenadas lógicas da interface.

## ASate/JD/Aduka/Raon 0.20.5

`AsateEffect`, `JDEffect`, `AdukaEffect` e `RaonEffect` isolam o estado de
família. `Match.battle_effects` retém efeitos após o guia e `satellites`
guarda Ion por dono; ambos têm cópia profunda no FlightSnapshot. Filhos
ASate usam ShellState e aceleração própria, com seções históricas para o
renderer. Guias não substituem o dano dos filhos/Thor/minas. Um cristal JD
por dono: novo impacto substitui o anterior. Ações anexas de item/clima
ocorrem no guia uma vez; não se multiplicam pelos filhos do Ion.

Minas novas preservam dono/arma e relógios privados; SS retém o turno até a
detonação. A fase `mines` resolve a agenda S2 antes de liberar `aim`, sem
consumir o relógio do piloto ou aceitar passe/disparo. Predição reconhece
`mine_plant` e `thor` como candidatos, além de explosão/miss/teleport.
`AsateArt` desenha Ion/laser originais e `AdukaBeamArt` usa CanvasItem aditivo
próprio, sem trocar o material do jogo. EPA controla poses dos quatro.
Fontes, adaptações e validação: SPECIAL_MOBILES_CLASSIC_FIX.md e registros
por família. Não é declaração de paridade integral do combate nativo.

## Apresentação original Bigfoot/Mage 0.20.3

Catálogo ativo encaminha Bigfoot/Mage ao atlas original/EPA/contato nativo.
Importação em subpastas original/, sem sobrescrever fontes anteriores;
render de atlas ignora rig e tiros HD. Mage conserva composição S1T/S2T
original do OpenBound. Ver ORIGINAL_MAGE_BIGFOOT.md e ADR-089.


Estado vigente: **0.20.2**, ADR-084/085/086/087. A seção abaixo complementa a
arquitetura SOLID e substitui as descrições históricas de balística C#,
integração120 Hz, carga 2 s e piso15%. Resumo e limites em
[BATTLE_FIDELITY_0_20.md](BATTLE_FIDELITY_0_20.md); contrato aritmético em
[CLASSIC_BALLISTICS_0_20.md](CLASSIC_BALLISTICS_0_20.md).

## Física e apresentação0.20

`ClassicBallistics` integra pares inteiros24.8 a 20 Hz; `move` antecede colisão
e `finish_tick` aplica aceleração. ShellState guarda estadoFP, velocidade
inicial exata, relógios, endpoints anteriores e todos os parâmetros de
regras. `shot_velocity_fp` concentra clamp/geometria/quantização; `pos` e
`velocity` são projeções para os consumidores existentes. Acumuladores
preservam resíduos e evitam perda de tick em 30/60/120FPS.

`Match.advance_projectile_tick` avança minas e projéteis para execução e
previsão. `GoldTracker.collect_mine` credita o dono e marca mortes já
contabilizadas, sem alterar shot_actor. Filhos e cristais usam ShellState.
FlightSnapshot duplica terreno/atores/clima/minas/estado, arma os projéteis e
reconstrói volleys. Física e ShotTiming são pré-aquecidos na thread principal;
CpuPlanner não lê arquivos, recursos ou estado vivo durante a busca.

`BoomerFlight` decide curva, freeze36–45 antes do clima e transformação46.
`ClassicFlight.open_shell/hold` publica os estados do Armor e a transição
Turtle descrita abaixo. Cena recebe eventos; `ClassicShotTiming` fornece
EPA, emissão e som por grupo. `pose_start_at` separa a pose Dual do spawn;
`projectile_launch` toca um som por grupo. O modelo nunca usa posição
interpolada: `Game.draw_projectiles` altera só uma cópia visual, e
`ClassicProjectileArt` lê o histórico para WaterEffect. Contato opaco vem
do importador, não de Image.load; assets originais/HD são preservados.

Colisão varrida, dano/cratera, tornado, demais órbitas/hélices e beacon continuam
adaptações identificadas. As famílias pesquisadas mas não portadas estão em
`BATTLE_MOBILE_FAMILY_PLANS.md`; nenhuma tabela de renderização decide dano.

## Turtle T2 0.20.2

`TurtleFlight` implementa `flight=turtle_wave`, com contador, fase, amplitude
e avanço próprios. `ClassicFlight.prepare/hit_point/finish_tick` conecta
esse estado ao laço compartilhado. `fp_pos` continua a trajetória central;
`hit_pos` recebe o deslocamento perpendicular calculado com velocidade FP
pré-aceleração. Após `Physics.finish_tick`, registra seção de meia largura 10
com heading pós-aceleração e avança a agenda inteira. Não há IO no worker.

`water_sides` acompanha o histórico de pontos. O renderer ancora as seções
no pixel inteiro, interpola cópias e reutiliza suas bordas. Para T2,
`triangle_data` emite índices 0/1/2, 0/2/3 e `draw_water` os envia diretamente
ao RenderingServer; isso preserva quads cruzados que ear-clipping rejeitava.
T1 mantém `draw_polygon`. Dual/Dual+ têm estados separados, e Teleport limpa
flight para continuar como beacon sem onda. Dados T1/SS/avatares preservados.
Contrato, fontes e resultados: [TURTLE_T2_FIDELITY.md](TURTLE_T2_FIDELITY.md).

## Turtle 0.20.1

`ClassicProjectileArt` usa uma seção transversal compartilhada por amostra,
UV horizontal 1/8 e alpha(255−16i)/255. A interpolação de todo o histórico
ocorre na cópia visual; `draw_fraction` nunca alimenta colisão.

`ShellState` preserva `transform_ticks/transform_hold`. Turtle SS abre no 44º
tick físico, mantém change por dez ticks e publica `split`; o laço comum
real/previsão cria seis filhos via ShellState e remove o pai. Divisão não chama
explosão. `burst` exige a sentinela para flight=open, evitando filhos no impacto
do tick 44. Hold estabiliza os endpoints anteriores usados pelo renderer.

`ClassicSprite` seleciona `SSChild.png`/bullet12c para o filho; evento e efeito
carregam `child/ss_state`. Pai normal compõe Flame3+SSFlame; pai em change e
filho usam Flame3. Dano/velocidade/dispersão dos filhos continuam adaptações.
Detalhes, revisão e evidência temporal em [TURTLE_ANIMATION_FIX.md](TURTLE_ANIMATION_FIX.md).

## Arquitetura SOLID

`match.gd` continua dono de `phase`, `actors` e da fila `events`. A cena
orquestra e não decide dano. Papéis do treino 1×1: `Match.PLAYER` (0) e
`Match.CPU` (1).

| Arquivo | Responsabilidade |
|---|---|
| `scripts/mobiles.gd` | Catálogo dos16mobiles (com classic_mobiles): armas/custo original, força/gravidade, mira e atributos; emissão pelo catálogo ShotTiming |
| `scripts/flight_snapshot.gd` | Lista fechada copiada por `predict_shot` e pela busca da CPU |
| `scripts/damage.gd` | `blast` e `deal_damage`; o Match chama e guarda os eventos |
| `scripts/turn_table.gd` | Agenda, passe, previsão de iniciativa e fim de partida |
| `scripts/aim_control.gd` | Carga Slice, Drag e repetição das teclas de mira |
| `scripts/camera_rig.gd` | Seguimento, limites e impacto |
| `scripts/match_overlay.gd` | Ajuda, opções, pausa e resultado |
| `scripts/game.gd` | Fachada da cena: menu, HUD, laço, desenho e thread da CPU |
| `scripts/battle_art.gd` | Poses. O desenho recebe um contexto, não os campos da cena |

A máscara entra em `Match.start(..., mask)`. Sem máscara, o Match cria o
terreno, como os testes. Som e perfil são criados em `game.gd._ready` quando
a cena ainda não os recebeu. `weather.gd` e `combat.gd` seguem concretos:
previsão e tiro real compartilham os dois.

## Revisão de qualidade 0.18.6

ADR-081, plano em `QUALITY_REVIEW.md`. Nenhuma regra mudou (golden master de
26 partidas idêntico à `main` 0.18.5). Pontos de extensão e responsabilidades:

| Arquivo | Responsabilidade |
|---|---|
| `scripts/mobile_looks.gd` | Apresentação por mobile: script do sprite, layout HD do rig, estilo do projétil HD ("flame"/"ribbon"), aura UsingItem e relógios de pose compartilhados. Rig, projéteis, itens, cena e miras do HUD leem daqui |
| `scripts/sprite_pose.gd` | Objeto de parâmetros de `MobileSprite.draw`/`MobileRig.draw` (posição, largura, lado e estado da animação, campos opcionais nomeados) |
| `scripts/delay_units.gd` | Única conversão custo original → unidade de atraso (÷7,5), com redução de atributo truncada como no C#; `TurnTable.DELAY_SCALE` aponta para ela |
| `scripts/item_effects.gd` | Efeitos de item por tipo do catálogo: instantâneos (`heal`, `health_cost`, `turn_wind`) e de tiro (`second_volley`, `beacon`, `electric`) |
| `scripts/weather_contact.gd` | Contato projétil × colunas de clima e trajeto do tornado |
| `scripts/gold_tracker.gd` | Metadados de Gold do tiro: início, coleta por explosão e fechamento |
| `scripts/cpu_planner.gd` | Plano da CPU em três passos (grade + refino ADR-076); liga/desliga `cpu_thinking`; a busca roda na thread só sobre o snapshot |
| `scripts/actor_state.gd`, `scripts/shell_state.gd` | Fábricas únicas do formato de ator e de projétil (Dictionary) |
| `scripts/json_store.gd` | Leitura tolerante e gravação atômica do perfil e das opções |
| `scripts/cpu_turn.gd` | Turno da CPU na cena: espera, tarefa no WorkerThreadPool, disparo |
| `scripts/lobby_screen.gd` | Lobby clássico (entrada): Create abre a sala, Avatar abre a loja, EXIT encerra; arte em `classic_chrome.gd` |
| `scripts/menu_screen.gd` | Sala 1×1 no `ready_back`, alcançada pelo Create; popups do mobile, da CPU e da partida, com a API anterior |
| `tests/support/suite.gd` | Base das suítes: `check`, `report`, `finish` no formato lido pelo `check.sh` |

`TurnTable.order` é a única regra de ordem (agenda, prévia com `shot_cost`,
`current_order` da fila do HUD). `Match` continua a fachada: `weather_interact`,
`tornado_step`, `apply_weather_contact`, `begin/search/score/finish_cpu_plan`,
`blast`, `deal_damage`, `schedule`, `pass_turn` e `current_order` delegam aos
módulos acima. Fases são `Match.PHASE_MENU/AIM/FLIGHT/SETTLE/FINISHED`
(strings, por compatibilidade com eventos e testes). `MatchOverlay` guarda a
camada aberta (`kind`, `layer`, popups) e avisa a cena por sinais; a cena não
expõe mais propriedades que só repassavam `AimControl`/`CameraRig`
(`scene.aim.*`, `scene.rig.*`). `check.sh` compila todos os scripts e capturas
antes das suítes e limita cada suíte a `SUITE_TIMEOUT` segundos.

Adiado com motivo: classes tipadas para ator/projétil. `duplicate(true)` não
copia Objects (o snapshot da CPU compartilharia atores vivos com a thread),
`Object.get(k, padrão)` não existe e as suítes montam fixtures como
Dictionary. As fábricas concentram o formato até essa migração.

## Componentes e responsabilidades

Tabela da entrega 0.2, mantida como histórico. As responsabilidades atuais
estão na seção anterior.

| Arquivo | Responsabilidade |
|---|---|
| `scenes/main.tscn`, `scripts/game.gd` | Cena, menu/HUD, input, pausa, overlays, desenho, efeitos, CPU e recompensa |
| `scripts/ui.gd` | Construção e estilo de controles |
| `scripts/battle_art.gd` | Estado visual separado, interpolação, rodas/canhão, recuo, dano, destruição, explosão e bússola |
| `scripts/bigfoot_sprite.gd` | Atlas Bigfoot, FPS/ciclos, piloto e offsets por quadro, projéteis, nearest por CanvasTexture |
| `scripts/terrain.gd` | Máscara sólida 640×400, células de 2 px, mapa original (alpha do foreground) ou procedural, visual HD, superfície, crateras e raycast DDA |
| `scripts/maps.gd` | Catálogo de mapas OpenBound (Map.cs): spawns, clima, recorte HD e partícula, em coordenadas nativas |
| `scripts/weather.gd` | Vento 2D, fila de clima, colunas, Thor e XP (modelo puro, copiado na previsão) |
| `scripts/weather_art.gd` | Apresentação de colunas, Thor, feixes, ícones e partículas de chão |
| `scripts/build_map_hd.py` | Costura blocos GPT Images do mapa, aplica a máscara original e grava manifest |
| `scripts/combat.gd` | Parâmetros das armas, integração, colisão, dano e previsão de trajetória |
| `scripts/match.gd` | Atores, RNG, projéteis, fases, movimento, disponibilidade, CPU e resultado |
| `scripts/profile.gd` | JSON local, saneamento, recompensa e gravação temporária seguida de rename |
| `scripts/sound.gd` | Efeitos PCM originais sintetizados em memória |
| `scripts/build_macos.py` | Exportação, nomes internos ASCII, assinatura ad-hoc, verificação e ZIP |

Os modelos herdam `RefCounted`; apresentação usa `Node2D`/controles Godot.
Não há backend, servidor, banco externo, serviço de conta ou dependência npm.

## Fluxo de partida

`menu → aim → flight → settle → aim`, até `finished`.

- `start`: gera arena, cria dois atores, limpa filas/projéteis/especial e inicia
  o jogador em `aim` com vento, orçamento e 30 segundos novos.
- `aim`: aceita deslocamento e um disparo válido; timeout/passar agenda novo ator.
- `flight`: usa acumulador com passo `1/120 s`; varre todo o segmento entre posições.
- `settle`: espera 0,55 s, acomoda veículos, aplica quedas e decide o resultado
  antes de agendar a próxima ação.
- `finished`: elimina projéteis, emite resultado; a apresentação concede XP uma
  vez e abre as ações de revanche/menu. Ajuda fechada nessa fase restaura resultado.
- Pausa pertence à apresentação, que deixa de avançar a partida e o trabalho da
  CPU. `screen`/overlay da view e `phase` do modelo são estados distintos.

## Contratos e invariantes

`MatchModel` expõe atores, projéteis, fase e uma fila `events`. A view consome os
eventos `turn`, `pass`, `fire`, `explosion`, `damage`, `fall`, `finished` para
som, partículas, texto e resultado. View não calcula dano nem ordena turnos.

`Combat.advance` integra aceleração constante: `a=(0, 196) + vento×1,2`
(vento 2D em unidades de força; ADR-076, antes `(vento×1,5, 260)`),
`p'=p+vΔt+aΔt²/2`, `v'=v+aΔt`. Previsão e voo real usam esse integrador e
`trace_segment`: primeiro impacto entre máscara sólida e círculos dos veículos.
O atirador é ignorado somente durante os primeiros 0,15 s em ambos os caminhos.

Na versão 0.2, `MatchModel.body_rotation(index)` estima apoios x±18 a partir da
máscara, descarta apoios distantes e limita a inclinação a ±30°.
`shot_velocity(index, angle, power, weapon)` gira a direção local antes de lançar.
`cannon_pivot` gira o offset do canhão; `muzzle` usa a mesma direção. CPU, view e
voo consomem essa geometria. A mira local pode diferir do ângulo no mundo.

`initiative_preview(weapon)` retorna duas entradas `{actor, ready, delay}`,
incluindo custo do veículo e desempate idêntico ao scheduler, sem alterar estado.
Durante voo/resolução considera a arma do tiro; a view aguarda escolha da CPU
antes de exibir previsão. Vida/identificação são protegidas de sobreposição pelo
reposicionamento do painel da fila.

`BattleArt` guarda apenas poses/tempos; atualiza com o delta de apresentação,
consome eventos e nunca escreve no modelo. A pausa impede seu avanço e cancela
carga. Força sobe 65 pontos/s e dispara a 100% uma vez; botão/Enter mantêm tiro direto.
Os estilos metálicos são gradientes em memória, compartilhados por cor/contorno.

Em 0.3, Bigfoot tem índice 2; CPU usa Carapaça como adversário. `BattleArt` guarda
`pose_age` e reinicia o relógio ao trocar de pose/arma de carga. Recuo usa a arma
registrada em `last_shots`, para não trocar SS por S1 após um turno curto.
Corpo e piloto usam quadros originais, sem rodas/canhão artificiais adicionais.
JSON do piloto mantém arquivo intacto e normaliza sua vírgula final em memória.
O preset inclui esse JSON; o pacote inclui avisos/licença de referência.

Terreno desenhado e colisão derivam da mesma máscara. Explosão altera a máscara,
depois atualiza sua textura. Fragmentos não desabam; veículos perdem suporte e caem.
Os atrasos `ready`/`clock` representam disponibilidade lógica, não segundos reais.

Perfil padrão: `user://profile.json`, versão JSON 1, campos `nickname`, `xp`,
`wins`, `matches`, `awarded`. Nível é derivado. `awarded` retém os últimos 64 IDs
para impedir recompensa repetida recente; não é um histórico ilimitado nem
proteção antifraude. Não renomear `config/name` sem planejar migração do caminho.

## Arte, execução e distribuição

Três PNGs gerados com GPT Images. As regiões dos sprites são selecionadas pela
view; arquivos originais permanecem intactos. Cenário, veículos e canhões são
combinados com terreno e efeitos por código. Fontes são do sistema, com fallback.

Build macOS Universal arm64/x86_64 usa `.tools/macos.zip`. Nome exibido contém
acento; executável/PCK internos usam `BrisaDeAco` para evitar falha de assinatura
observada. Build ad-hoc local sem notarização; só macOS foi testado.
App exportado incorpora a fonte no momento da exportação e exige novo build
após alterações. Caches, templates e binários não entram no Git.

Não há garantia de determinismo entre plataformas nem protocolo de rede definido.
RNG com seed explícita permite cenários repetíveis nos testes atuais.

## Integração Mage 0.4

`mobile_sprite.gd` concentra leitura/recorte/filtragem dos atlas e piloto;
`bigfoot_sprite.gd` e `mage_sprite.gd` fornecem dados/tiros próprios. Mage substitui
Carapaça no índice1. Modelo consulta `weapon_rules`, `aim_limits` e
`projectile_parameters` por ator; view e CPU consomem essas regras. Deslocamento
helicoidal passa por `Combat.sample_position`; `hit_pos` é posição física real
do componente, independente da interpolação visual do veículo.

Escudo integra o estado do modelo, absorve explosões antes de HP e regenera no
turno próprio até220+HPperdido. EMP zera escudo próximo antes da explosão. HUD
mostra barra azul/valor e usa os limites de mira. Eventos carregam veículo de
origem para escolher Fx/áudio mesmo após mudança de turno. Carga da CPU acompanha
plano/arma; recuo usa `last_shots`. Morte Mage completa25quadros antes do resultado.
Detalhes de fonte/adaptações em `MAGE_0_4.md`, avisos/hashes em `assets/openbound/`.

Para salvas, `predict_shot` executa `advance_projectiles` num modelo temporário
com atores duplicados e `Terrain.collision_copy`. Crateras e morte afetam os
componentes restantes na mesma ordem do voo real. A cópia manipula só máscara,
sem imagens/GPU, e não altera recursos ou eventos do modelo vivo.

## Ataques Bigfoot 0.5

`bigfoot_attacks.gd` guarda o perfil e a função `salvo(weapon)` do emitter.
`weapon_rules` escolhe perfil Bigfoot; `aim_limits(index, weapon)` fornece limite
por tiro. `shot_velocity` limita a mira base e depois aplica dispersão espelhada,
e acrescenta força após limitar entrada (T2 aceita componentes11–104%).
Todas as bombas Bigfoot compartilham a origem `muzzle(index, angle, weapon)`.

Projéteis guardam `spawn_at` e `launched`; `flight_elapsed` conta tempo de salva.
Passo fixo lança bombas elegíveis e integra somente o trecho posterior ao spawn.
`age` mede voo, sem contar espera. Bombas pendentes mantêm o voo vivo e não são
desenhadas; `projectile_launch` emite áudio original de cada lançamento.
Pausa não avança relógio da salva. Reinício limpa tempo e projéteis.

CPU executa a salva em cópia de modelo/máscara/atores até12s após último spawn.
Ordem/crateras/dano idênticos ao voo real. Mira do HUD muda por arma; atualização
de limites do slider bloqueia sinais para o thumb antigo não sobrescrever mira.
BigfootSprite desenha Fx originais e áudio de impacto consultando veículo de
origem do evento, mesmo após mudança de turno. Escaravelho e Mage mantêm seus
perfis e formatos anteriores; fonte/adaptações em BIGFOOT_ATTACKS_0_5.

## Derivados HD 0.6

`hd_sheet.gd` renderiza derivados GPT Images com filtragem linear. Metadados de
`assets/hd/atlas_regions.json` guardam grade/dimensões e recortes sem ruído de
alpha≤8/255. Leitura usa números normalizados em int: JSON do Godot retorna
floats, cuja igualdade de Array não corresponde aos arrays de inteiros.
Dimensões/grade devem coincidir com a textura; sem catálogo válido, usa recorte
por alpha da engine. Sem textura/quadro, o consumidor renderiza original.

`mobile_sprite.gd.hd_frame` converte os índices originais para4 quadros por
estado. Aliases BigfootSS-carga/recuoT2 e Mage-recuos preservam a organização
existente; baixa saúde escurece o derivado. O estado/FPS/tempo continua vindo do
mesmo frame_index/BattleArt. A área opaca do quadro original determina destino,
preservando pivô/chão e offsets do piloto, com metadados/imagens cacheados.
Menus usam a imagem maior heroes; arena usa atlas. Tiros/Fx mantêm contagem,
rotação, posição real e duração antiga, selecionando quadros HD proporcionais.
Modelo de combate, terreno e perfil não foram modificados.

`capture_hd_assets.gd` renderiza framebuffer1920×1080 com cena original1280×800
escalada uniformemente1,35 e margem96px de cada lado. O stretch de Window
excluía barras laterais e retornava1728×1080; a captura corrige somente o setup
de QA, sem alterar resolução lógica ou exportação do jogo. Perfis são isolados.

## Correção HD 0.6.1

`mobile_rig.gd` substitui somente o render dos mobiles por peças constantes
`mobile_parts.png` e cabeça/corpo constantes do rider. `sample(pose,age,weapon)`
produz transformações contínuas sem redimensionar corpo/piloto; aura e clarão
são overlays. `BattleArt` passa pose_age/arma correta e acumula wheel_phase
pelo deslocamento visual. Pausa congela relógio/fase. A sede do piloto acompanha
chassis; pneus têm contato fixo enquanto suspensão se move. Morte colapsa/faz
fade do conjunto. Menu/arena usam mesmos assets. Sem rig completo/catalog_valid,
`mobile_sprite.gd` desenha integralmente original/piloto e offsets originais.
Antigos hd_frame/hd_rows e uso de heroes/atlas de mobile saíram do caminho ativo.
Tiros/Fx continuam HDSheet.destination, sem mudar combate. Catalogo de peças usa
janelas reais entre objetos para conter as bordas completas, pois a geração
não respeitou exatamente a grade. Requer metadados válidos para evitar clipping.

## Piloto e projéteis 0.6.2 (substitui estes caminhos anteriores)

mobile_rig usa pilot_seated.png 1×1, figura completa com proporção preservada,
pivô dos quadris no assento. Substitui cabeça/corpo separados de0.6.1.
projectile_art.gd usa projectile_heads.png 3×2: uma cabeça constante por arma,
centrada em hit_pos/pos, ângulo da velocidade; não usa posição interpolada.
Flamas isoladas via componentes de shots.png ficam atrás da cabeça Bigfoot,
pulsam por age; Mage usa polyline sobre trail real, com gradiente e tint por phase.
Cabeças não mudam tamanho/identidade em voo. SS gira overlays, não troca o orbe.

Impactos effects.png usam crossfade6fases, envelope contínuo de escala/alpha,
dimensões máximas originais calculadas uma vez, mantendo centro e proporções.
EMP usa seu círculo constante girando. Duração vem de effect_capacity/30.
Game passa offset visual de tremor explicitamente; física não recebe offset.
Relógios são os mesmos age físicos/de efeitos, pausados pela cena. Cada caminho
exige textura, recortes não vazios e catalog_valid; falha retorna false e os
sprites usam originais. Mobile também exige o piloto válido como conjunto.
Nenhuma mudança em match/combat/terrain/profile ou suas regras.

## Composição 0.6.3

Rig compartilhado por menu/arena recalibrado contra o idle original. União alpha
corpo/cabeça do piloto mede44px; hulls49/46px resultam em altura53,88/57,39 no
layout base60. Fonte piloto mantém aspecto, quadris normalizados0,78/0,88.
Bigfoot: assento17/−20, corpo60×24 em−30/−31, canhão25×21 pivot−17/−37,
rodas24 em±18/−12. Mage: assento18/−28, corpo60×36, cajado29×23 pivot−19/−34.
As peças são contidas em caixas preservando aspecto. Camadas chassis→piloto→
arma→rodas; suspensão afeta assento/arma, rodas seguem o apoio. O conjunto
recebe flip/inclinação/escala uniformes; animações/tiros/regras preservados.
Metadados do layout usados pelo draw e pelo teste de composição.

## Perfil/roster0.6.4

Piloto mestre pilot_side.png1254×1254, perna distante oculta no PNG por GPT Images.
Registro271/153/703/977 preserva caixa anterior à esquerda/topo/direita, incluindo
4px adicionais embaixo para conter a nova silhueta sem cortar. Padding vazio
esquerdo impede recentrar pelo alpha e deslocar mãos/quadris. Altura/hip anchor
anteriores mantidos. Apenas troca de fonte, animações/tiros inalterados.

Match.VEHICLES é Dictionary com IDs1Mage/2Bigfoot; PLAYABLE_VEHICLES=[1,2] ordena
UI. normalize_vehicle converte ID0/−1/99 em2. Start normaliza e CPU usa3−id.
UI aplica ID nas closures/seleção; dificuldade e arma continuam seus próprios
slots0/1/2. Registro/render/armas genéricas Escaravelho saíram do caminho ativo;
Combat guarda só física compartilhada, sem tabela de armas genéricas.
Física de Mage/Bigfoot preserva velocidade base1, parâmetros próprios e previsões.
Assets anteriores preservados mas scarab/tortoise excluídos do export. Ícone novo.
Perfil não persiste veículo, apenas apelido/XP/vitórias/partidas/IDs recompensados.

## Mapa Miramo Town 0.8

`Maps.MAPS["miramo_town_a"]` descreve o recorte do alpha original
(x17–1783, y1344–1800) e o topo y420 da arena; `k = 1280/1766`.
`Terrain.load_map` amostra o alpha original no centro de cada célula (cache
estático por mapa, cópia por partida) e carrega `foreground_a.png` 2560×661
como `visual`. `carve` atualiza células e, se houver visual, apaga o círculo em
pixels HD e escurece o anel `radius+3` por 0,4 (`Topography.CreateErosion`).
`collision_copy` não leva visual. `Match.start(..., map)` usa
`Maps.DEFAULT`; mapa vazio/inválido gera o terreno procedural. Spawns: um por
metade, sorteados pelo `rng` da partida. `game.gd` desenha a janela do fundo
(HD quando existir, senão `Background.png` original) e o `visual_texture` no
`visual_rect`; grama e borda procedurais só no fallback. Câmera continua fixa.

## Câmera, vento, clima e Thor 0.9

Mundo nativo: `Terrain.load_map` dimensiona a grade pelo `ForegroundA` inteiro
(1800×1800 → 900×900 células); `world_size`, `void_y/is_void`,
`Combat.out_of_bounds` e o clamp de movimento derivam dele (procedural
continua 640×400 / 1280×800). `first_solid_y` é calculado uma vez, como
`FirstCollidableBlockY`. `carve` devolve as células removidas.

`game.gd` mantém `camera` (canto superior esquerdo da vista 1280×670; 1280×664 desde 0.10): segue
mobile ativo → projétil lançado → impacto com fator `1/25` por quadro;
arrastar (mouse/toque, `_unhandled_input`) liga `camera_manual` até o próximo
`turn`/`fire`. O mundo é desenhado com `offset = tremor − camera`; barras e
rótulos convertem para tela; setas na borda para mobiles fora da vista. O fundo
usa uma janela 1,6:1 que desliza pela fração da câmera dentro da cobertura HD.

`weather.gd` (modelo puro, copiável): pesos do preset, fila de 4, rodada = 2
turnos, vento 2D (força/ângulo, perturbação, Wind), colunas com fusão/limpeza,
Thor (posição, nível, XP). `match.gd`: cada projétil guarda `damage`,
`inside`, `influenced`, `electric`, `thor`, `tornado`; `apply_weather_contact`
roda antes de cada passo do laço comum; `tornado_step` substitui a balística
enquanto ativo; `explode` → `blast` → Thor → raio elétrico. `predict_shot`
sempre simula em cópias (máscara, atores, vento, clima). `weather_art.gd`
apresenta colunas, satélite, feixes, ícones e partículas de chão, sem decidir
combate; a pausa congela porque `_process` não avança.

## HUD original de batalha 0.10

`hud_art.gd` (apresentação, sem regras) desenha o HUD do OpenBound com os
offsets de `HUD.cs` numa tela virtual 800×500 × 1,6 (`bar_point`): barra de
ação, barras de força/movimento, marcador anterior, seletor, ângulos (fontes
numéricas por `SpriteNumericField`), roleta de clima, Delayboard, bússola,
TurnTimer; no mundo (1:1): mira (`CrosshairFrame` + faixa por mobile/tiro +
ponteiro pela direção de `shot_velocity`), vida (76 px, vida+escudo), nome,
balão do relógio da CPU e contador de dano acumulado. Texturas HD 3× em
`assets/hd/hud` com fallback para `assets/openbound/hud`. Botões S1/S2/SS,
Options e SkipTurn são `TextureButton` com as regiões de `Button.cs`. `game.gd`
cuida do input original (carga 0→100 a +2/0,04 s, Tab, F8, ↑/↓ com repetição
acelerada) e entrega um `hud_state()`; `match.gd` não mudou.

## Itens de batalha 0.13

- `items.gd`: catálogo (ordem de `Item.ItemPresets`, slots, categoria, custo,
  descrições). Delay = custo ÷ 7,5.
- `match.gd`: `use_item(slot)` valida (fase de mira, ator ativo, um por turno,
  Ignorância) e aplica cura/Blood/Change Wind na hora; efeitos de tiro ficam em
  `actors[i].turn_item`. `shot_shells` monta Dual/Dual+/Teleport/Thunder e é a
  única fonte de projéteis de `fire` e `predict_shot`. Cada projétil leva
  `weapon`, `volley`, `beacon` e `wind_scale`; `explode` lê a arma do projétil,
  o ataque (Power Up/Blood) e o cavar (Bunge Shot); `land_beacon` teletransporta.
  `TurnTable.schedule` limpa o item ao fim do turno.
- `damage.gd`: multiplicador de ataque após o decaimento, truncado.
- Cena: `item_bar.gd` (EquippedButtonBar/UseItemAction/GrantTurn/LockItem),
  `item_art.gd` (botões HD/originais, sinalizador, chamas e sons),
  `select_item_popup.gd` (PopupSelectItem); carga em `options.items`.
- `battle_art`: pose `using_item`, segunda rajada repete o recuo, teletransporte
  sem deslizar. Eventos novos: `item`, `volley`, `teleport`.
- ADR-065: o botão usado some do slot no uso (a barra recompacta) e
  `item_art.draw_using` desenha a aura verde por cima do mobile, 20 quadros
  a 19 fps, no pivô do atlas. O corpo HD só sobe um pouco; não ganha brilho
  de carga.

## Shop de avatar 0.14 (REQ-38..41)

Catalog e ShopModel separam dados, filtros e preview da tela original800×600
(render uniforme4/3, margens laterais na viewport1280×800). Profile version2
guarda moedas, posse por chave composta, conjuntos por gênero e atributos;
compras/equipamento/confirmar/resultado usam snapshot, rename e rollback.
A seção shop inválida não renova o saldo de teste.

AvatarArt desenha os atlas originais com pivôs e10FPS, conservando grade real
e profundidade Flag→Head→Goggles→Body. MobileRig troca o piloto no mesmo
assento; sem contexto conserva o caminho anterior. BattleArt recebe contexto
de equipamento da partida; não lê o perfil.

PlayerAttributes guarda orçamento/modificadores puros; Match injeta atributos
em atores antes do primeiro turno. Damage aplica ataque−defesa somente no
projétil primário; Dig só aumenta erosão; delays/regen/HUD compartilham regras.
FlightSnapshot copia atores/atributos/Gold em profundidade; simulação não toca
perfil, moeda real ou estado vivo.

GoldRewards reproduz os caminhos1×1 C#, com ângulo HUD=trajetória central+180.
Só impactos com dano positivo entram nos metadados de Gold; boomer/backward
consideram alvo inimigo. FinishGoldShot agrega salvo uma vez após acomodação;
Profile.award recebe Gold junto do XP, usando awarded para impedir repetição.
ItemDelay é contrato puro até integração da funcionalidade de itens.

Registro0.14.1: MobileSprite.configure transmite RiderPivot idle e geometria
nativa ao MobileRig.register_avatar. avatar_transform aplica escala60/hull e
origem `(RiderPivot−(0,contact_y−pivot_y))×escala` ao conjunto; rotação/offset da
pose envolvem esse ponto. Avatar equipado é desenhado antes do chassis, que
oculta pernas/corpo inferior; sem contexto, o piloto legado mantém seu draw.

AvatarHD0.14.2: catálogo independente de recortes transparentes e janela/pivô
nativos. Cada imagem é contida com aspecto original, preservando a posição
normalizada do pivô; offsets por quadro deslocavam o mesmo sprite fixo (essa
parte foi substituída pela continuidade0.14.4/ADR-063 abaixo). AvatarArt
consulta HD antes da textura original; ausência/invalidez retorna ao original
por peça. Retratos usam AtlasTexture da mesma região, dimensionados só depois
do expand_mode para impedir minimum-size de texturas grandes na UI.

## Integração0.14.3

Atores recebem tanto items/turn_item quanto attributes/gold_state. Assinatura:
Match.start(vehicle,difficulty,seed,map,weather,mask,loadout,attributes_by_actor).
Damage.blast acrescenta shooter depois de attack para manter chamadas anteriores.
No projétil primário, fator(1+(Attack+bonus−Defense)/100); erosão usa Dig+bonus.
Items.delay(id,reduction=0) reduz/trunca custo original antes÷7,5. Arm/previsão
usam shot_shells para todas as salvas; Shadow Gold nunca escreve no perfil.
## Continuidade e equipamento0.14.4

REQ-10/19/20/38/39, ADR-063. AvatarHD mantém o recorte de referência no pivô
nativo e não usa variação dos centros das silhuetas para animar peças HD.
AvatarArt conserva relógio de quadros para fallback original; peças HD formam
um grupo rígido. MobileRig recebe relógio absoluto do avatar para respiração.
BattleArt.presentation guarda estado anterior/atual por ator e mistura só
geometria visual durante0,14s; interrupção começa no estado exibido. MobileRig
recebe esse retrato por avatar_context.rig_state. Modelo/CPU não o consultam.

AvatarShopModel.try_selected experimenta não possuídos e equipa possuídos via
Profile.equip (persistência/rollback existentes). UI troca Experimentar por
Vestir/Vestido segundo posse e prévia. A compra não equipa automaticamente.
Transição entre abas restaura a prévia do conjunto persistido. Game.start_match
continua copiando Profile.equipped_set para actor_avatars; recarga e restart
com as quatro categorias estão cobertos em test_avatar_continuity.

## Avatar Shop clássico 0.14.5

ADR-064: AvatarShop preserva a tela800×600 e escala uniforme; apresentação
substituída pela grade3×3 (nove itens/página) da foto enviada. Inventário lateral
lista todas as peças possuídas compatíveis com o gênero, independentemente de
busca/categoria, e chama Profile.equip para vestir transacionalmente. Equipar
atualiza a prévia e não debita saldo. Retratos HD126×78 centrados em janela146×90;
StyleBoxTexture mantém bordas/header nativos ao ampliar card166×147.

Atributos continuam no ShopModel/Profile, apresentados em modal separado:
entrada bloqueada sob a camada escura, ESC/Cancelar descartam rascunho,
Salvar fecha somente após transação bem-sucedida. Erro fica visível no painel.
Shop/Inventário, compra Gold/Cash, gêneros, busca e animações originais mantidos.
Essa seção substitui a descrição histórica do layout5×5; catálogo/preços e
BattleArt/AvatarArt/AvatarHD permanecem os mesmos.

## Auditoria e UI HD0.14.6

ADR-066, REQ-20/38/39/40. ShopHD valida catálogo/version/registro4× e dimensões
das texturas; falha solicita o recurso nativo. AvatarShop converte somente
recortes de textura pela densidade, sem alterar hitboxes ou dimensões lógicas.
ShopCardStyle desenha nove recortes: bordas6/22/6/6 em pixels de UI, recortes
correspondentes em pixels da textura. Popup define EXPAND_IGNORE_SIZE antes
de receber a textura e conserva228×286×1,6. Retrato/categoria/preços e saldo
identificam a compra; moeda única é centralizada.

Ícones de atributo usam os índices13/17/15/23/9/19/21/11 de AttributeMenu.cs.
animation_frame reproduz Foward (repetição) e Cycle (ida/volta, extremos
duplicados) do FlipbookAnimation C#: Buy/Try usam Cycle no hover; setas1..19
a28FPS, Exit hover23/click25FPS. Click começa em pressed (soltura), guarda
click_age e completa até Normal enfileirado, mesmo depois de soltar o mouse.
Categorias ativadas/controles desabilitados mantêm o respectivo quadro.

build_shop_hd.py empacota fontes sem editar originais e registra mestres GPT
Images em20texturas; source/.gdignore contém referências, brutos e prompts.
GENERATION.json/catalog.json guardam origem, dimensão real1254×1254 de cada
folha, hashes e recortes úteis. PNGs runtime são4× das janelas nativas, o que
não significa4× detalhes gerados: a densidade útil varia por objeto.
Cor/volume vêm da geração; alpha de cenário/molduras conserva a fonte.
Mestres de botão permanecem fixos e variam brilho pelos quadros/relógios;
gestos/desenhos específicos do flipbook original continuam no fallback.

Export inclui explicitamente catalog.json/GENERATION.json da nova UI. O smoke
deve executar fora do projeto com --path /private/tmp: FileAccess pode encontrar
JSON solto no filesystem local mesmo ao usar --main-pack. Smoke isolado do
PCK confirmou referências/brutos ausentes e todas as20texturasHD presentes.

## Card/preço/efeito0.14.7

ADR-067, REQ-20/38/39. ShopCardStyle divide a vertical em header, painel
branco, sua borda inferior, faixa azul extraída da textura e acabamento
inferior nativo (incluindo rebites). Preço é texto sobre essa composição;
ColorRect sobreposto foi retirado. Card166×147 preservado, retrato126×66
com aspecto constante e linha “Cosmético · sem bônus”. Tooltip explica que
as melhorias de combate pertencem a Atributos; popup repete a informação.
Catálogo C# não define bônus por peça; nenhum modificador foi inventado.

## Fundo de preço nítido0.14.8

ADR-068 substitui somente o preenchimento central da faixa0.14.7: em vez
de ampliar a tira75..76 da imagem para27px de UI, ShopCardStyle desenha
retângulo vetorial opaco RGB121/159/211 nesse destino. Demais recortes
mantêm bordas branca/laterais/rebites. GPUFullHD e PCK real confirmam cor
uniforme sem borrado; PNGs/mipmaps/arte dos retratos permanecem inalterados.

## Estado e composição da loja0.14.9

ADR-069, REQ-20/38/39/40. ShopModel.filter limpa selected_key quando o item
não está na página visível; select confirma a seleção depois de Profile.equip
bem-sucedido. A grade mostra erro de persistência e mantém seleção/prévia ao
falhar. Busca vazia mostra mensagem fora do container de cards.

Abas Loja/Inventário ficam acima da grade que filtram. Rodapé segue
Experimentar/Vestir → Comprar → Presente, escolha explícita do usuário baseada
no C#. Inventário lateral e grade3×3 permanecem. Botões reservam altura própria
para arte e legenda usando margin transparente de AtlasTexture; região nativa,
relógios e fallback preservados. Hitbox contém também o texto. Categorias têm
baseline comum, e Label reaplica size depois do override de fonte, evitando
mínimo herdado da fonte padrão16px. Prévia Miramo usa crop central e escala
uniforme, preservando aspecto sem alterar rig/mobile/pivô. Faixa de preço0.14.8
continua vetorial, sem novo PNG ou mudança de combate/perfil/atributos.


## Avatar Shop em16:9 / vídeo0.15

ADR-070 substitui as coordenadas da loja0.14.5/0.14.9. Canvas virtual
1066⅔×600; em1920×1080 escala uniforme1,8. Cards240×140, passo252×148,
origem(308,42), retrato172×68; grade3×3/nove por página. Inventário de oito
linhas visíveis, destaque amarelo nos slots vestidos. Abas/busca ficam acima
da grade; categorias abaixo; rodapé Presente→Comprar→Experimentar/Vestir.

A loja salva content_scale_size/mode/factor da Window, usa pixels da janela
com top_level e restaura essas propriedades no _exit_tree, inclusive saída
por ESC/reentrada/batalha. Isso evita somar o stretch1280×800 da arena ao
encaixe16:9. Em1280×800 a loja fica1280×720, centralizada com40px verticais.
Modais são filhos da composição e acompanham o mesmo encaixe. ESC marca o
input tratado antes de remover a loja. Testes e capturas usam config real.

Prévia padrão mostra o conjunto de avatar, com pivô constante e respiração;
Avatar/Mobile alterna só apresentação. Mobile preserva montagem/rig e crop
uniforme do cenário. Tipografia duplica a fonte local com oversampling3 para
renderizar texto nítido na escala FullHD, sem alterar fontes da batalha/menu.
Molduras angulares e faixa de preço são vetoriais; mantêm corRGB121/159/211.

Novos PNGs gerados via GPT Images/gunbound-classic-hd: fundo1672×941 e retrato
compartilhado No Goggles/No Flag1254×1254RGBA (recorte útil870×1076). JSONs
registram tamanho/hash/origem e crop estável, validados no carregamento.
Metadados ausentes/inválidos retornam fallback nativo. Retrato é só catálogo:
nenhuma peça foi adicionada ao rig;15registros e13peças continuam iguais.
Referências/brutos/prompts ficam em shop/source/video_0_15, excluídos do PCK.
FullHD descreve a composição final1920×1080, não as dimensões dos PNGs fonte.


## Avatar Shop XFS0.16 — estado atual

ADR-071/072 substituem coordenadas e restrição do catálogo0.15. Canvas800×600
centrado1440×1080 em1920×1080; fundo cobre laterais. Cards160×156, origem25/70,
passo164×160; retratos84×76 e stats em coluna separada. Inventário à direita.

Catálogo XFS562/479compráveis e camadas/retratos extraídos offline; runtime
consome JSON/PNGs, sem protocolo de rede. IDs xfs:gênero:categoria:id são
separados do C#. REQ-46/ADR-089 acrescenta `classic.json`: os mesmos 562 registros com
o WORD/DWORD do servidor (slot corpo, cabeça, olho, bandeira; bit 15 masculino)
e texto CP949. A categoria da loja não muda. Profile3 converte identidades verificadas (Pilot Goggle1→2),
conserva Kappa como legado, não concede saldo novamente e mantém rollback.
Bandeiras mf compartilhadas; ff vazio. Ghost aceita camada L sem base.

Atributos do piloto e bônus assinados por peça são compostos uma vez em
Match.start (nono argumento), teto50por atributo sem consumir orçamento do
piloto. O snapshot fechado copia valores para previsão/CPU; partida já aberta
não lê equipamentos vivos. Penalidades negativas também alteram atraso.

A cobertura HD0.16 é parcial:18miniaturas novas e peças antigas equivalentes.
A migração integral posterior usa controle por registro/camada, masters com
registro constante e validação separada de miniaturas; AVATAR_HD_MIGRATION.md.

## Avatares XFS HD0.17

AvatarXfsHD lê assets/hd/avatars/xfs/catalog.json:629camadas e532retratos novos,
38atlas com recortes/dimensões/hash e janela nativa por componente. AvatarArt
prioriza o conjunto novo integral da peça; originais/13masters antigos ficam
como fallback e compatibilidade. Shop consulta retratos separadamente.549bases
e80L cobrem550itens (Ghost sóL);18retratos anteriores completam550miniaturas.

Material translúcido preserva a opacidade nativa; camadas de luz convertem
preto para ausência de emissão em textura de memória, sem editar PNGs. Pulsação
segue material da fonte, não o sufixoL sozinho. Registro permanece fixo ao longo
da animação do rig. Controle/aceite separado do runtime exige capturas atuais
por lote, assinatura de recorte/registro/renderer e auditoria do consumidor real.
12N/A são acessórios vazios/place holders sem arte, com razão explícita.

## Revisão0.18 — estado de efeito e Nak HD

Cabeça e L compartilham a faixa Normal da fonte na preparação de seus mestres.
O fallback conserva faixa Normal/Staring por categoria, inclusive L; o HD não
mistura formas frontais de Staring com mestre lateral. Ver ADR-075 e
AVATAR_EFFECT_ALIGNMENT.md. Nak recebe renderer HD próprio delegado pelo rig,
com geometria de combate preservada; NAK_HD.md documenta medição e fallback.

Aura Great Devil: avatar_contour_glow.gd gera e guarda em memória uma máscara
de ouro na janela do chifre do próprio mestre HD. Distância de contorno gera
aura com recorte/origem/escala compartilhados. draw_behind compõe antes da
cabeça, preservando a superfície; efeito separado original continua preservado.

Correção0.18.4/ADR-079 substitui essa composição: Great Devil volta a usar a
textura L anterior sobre a cabeça, com opacidade/pulsação anteriores. Nove
marcos medidos na cabeça e na luz produzem64faixas UV constantes em ArrayMesh,
com pivô/flip/inclinação comuns. Só geometria muda; cache sem relógio. A máscara
0.18.3 fica preservada para comparação histórica, sem entrada no catálogo ativo.

Brilho clássico 0.18.7/ADR-082 substitui a malha curvada no catálogo: a camada
L do Great Devil usa `overlay_base` e um PNG derivado da silhueta do chifre HD
(`build_devil_horn_light.py`). `AvatarXfsHD.piece` registra a luz na janela da
cabeça (deslocamento −20 px na fonte, mesma escala), exige tamanho igual ao da
cabeça mais a margem e opacidade em 0–1; qualquer desvio cai no fallback
original completo. `curve_light`/`light_curve` e a máscara 0.18.3 ficam como
histórico sem entrada ativa.

Saldo de teste0.18.5/ADR-080: Profile usa 999.999.999 em cada moeda como padrão.
`game._ready` chama a concessão única após `load_profile`; carteira legível
sem marcador recebe o novo saldo e marcador na mesma transação. Snapshots
carregam o marcador para rollback. Carteiras inválidas não ganham recarga por
essa migração. Fixture explícita do catálogo legado conserva 1000 por moeda.
