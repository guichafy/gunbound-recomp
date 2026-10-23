# Design implementado

Estado vigente: 0.12 mais a reorganização abaixo. As seções anteriores a
«Integração Mage 0.4» guardam o histórico: terreno 640×400, força a 65 pontos/s,
CPU com Carapaça e som só PCM não descrevem o jogo atual. O contrato que o
código segue é esta seção e `HANDOFF.md`.

## Arquitetura SOLID

`match.gd` continua dono de `phase`, `actors` e da fila `events`. A cena
orquestra e não decide dano. Papéis do treino 1×1: `Match.PLAYER` (0) e
`Match.CPU` (1).

| Arquivo | Responsabilidade |
|---|---|
| `scripts/mobiles.gd` | Catálogo Mage/Bigfoot: armas, mira, escudo, som e texto. Sem ramo por ID |
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
separados do C#. Profile3 converte identidades verificadas (Pilot Goggle1→2),
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
12N/A são acessórios vazios/placeholders sem arte, com razão explícita.

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

Saldo de teste0.18.5/ADR-080: Profile usa 999.999.999 em cada moeda como padrão.
`game._ready` chama a concessão única após `load_profile`; carteira legível
sem marcador recebe o novo saldo e marcador na mesma transação. Snapshots
carregam o marcador para rollback. Carteiras inválidas não ganham recarga por
essa migração. Fixture explícita do catálogo legado conserva 1000 por moeda.
