# Shop de avatar — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar Shop/inventário dos quatro tipos de avatar e os oito atributos com efeitos reais no treino offline.

**Architecture:** Catálogo e regras em modelos RefCounted; cena Shop apresenta e encaminha ações. Perfil realiza transações locais; Match aplica atributos copiados no início da partida, com o mesmo cálculo no voo e na previsão. Arte composta substitui somente o piloto e conserva o rig dos mobiles.

**Tech Stack:** Godot 4.7.2, GDScript, JSON local; Python 3 para empacotar os assets existentes, sem dependências novas de runtime.

**Spec:** [AVATAR_SHOP.md](AVATAR_SHOP.md), aprovada pelo usuário em 2026-10-12.

## Global Constraints

- Worktree: `/Users/guichafy/.codex/worktrees/avatar-shop/DemoGame`, branch `codex/avatar-shop`, criada de `main`; trabalhar sempre nele.
- Fonte C# `/Users/guichafy/Workspaces/Gunbound` somente leitura; alterações não commitadas de itens da pasta principal não entram neste corte.
- Treino offline 1×1, Mage ID1 e Bigfoot ID2. Ranking permanece retirado. Sem contas, rede, novos mobiles, mapas ou pagamentos.
- Godot deve continuar permitindo exportação macOS/Windows/Linux/Android/iOS; sem dependência de sistema específica no jogo.
- Saldo inicial **1.000 Gold e 1.000 Cash**, uma vez; preços originais; nunca usar XP como moeda.
- Pontos `min(max(nível_local - 1, 0) * 10, 180)`, oito inteiros 0..50. XP/nível/vitórias existentes preservados.
- Match decide dano/turno/resultado; game apresenta. Nenhuma posição interpolada entra na física. CPU usa retrato isolado e não consulta perfil/UI.
- Preservar PNGs originais, `.gd.uid` e `.png.import`; derivados GPT Images são opcionais, não fazem parte da execução obrigatória deste plano.
- Preparar `.tools` e importar antes de testes em checkout novo; perfis/capturas usam caminhos em `.tools`, nunca `user://profile.json` real.
- Check completo obrigatório após modificadores: modelos, cena e dez partidas. Nenhum push/publicação. App só é atualizado por novo export e assinatura.
- ItemDelay terá fórmula/testes e contrato de integração; uso real depende do código de itens fora deste worktree. Relatar esse limite.

## Review Focus

1. Perfil com seção Shop danificada: sanear sem conceder saldo novamente nem apagar XP; teste na tarefa 2.
2. Compra/modal com seleção alterada ou clique repetido: usar identidade capturada e uma transação, sem débito duplo; tarefas 2 e 4.
3. Troca de gênero: reter compras e equipamento de ambos, compartilhar unissex sem confundir Basic ID0; tarefas 1, 2 e 4.
4. Dig/atributos em busca da CPU: alterar cratera/copiar arrays somente na simulação, mantendo resultado igual ao tiro real; tarefa 3.
5. Saída do Shop com rascunho/preview: descartar alterações não confirmadas e guardar conjunto real para a arena; tarefas 4 e 5.

## Arquivos e contratos

| Arquivo | Responsabilidade |
|---|---|
| `scripts/import_avatar_assets.py` | Empacotar metadados, sprites, portraits e interface originais; gerar hashes |
| `assets/openbound/avatars/catalog.json`, `manifest.json` | Dados normalizados com identidade composta e origem |
| `assets/openbound/avatars/{Male,Female,Unissex}/...` | Atlas e retratos preservados |
| `assets/openbound/shop/...` | Sprites da cena, botões, abas, indicadores, popup e previews |
| `scripts/avatar_catalog.gd` | Resolver/filtar itens, gênero/unissex, defaults e recursos |
| `scripts/player_attributes.gd` | Orçamento, saneamento, rascunho e modificadores puros |
| `scripts/profile.gd` | Persistência e transações Shop/resultado |
| `scripts/avatar_shop_model.gd` | Filtros/paginação, seleção, preview e delegação ao perfil |
| `scripts/avatar_shop.gd` | Tela e controles, modal de compra e painel de atributos |
| `scripts/avatar_art.gd` | Transformações e animação do rider composto |
| `scripts/gold_rewards.gd` | Contabilidade C# pertinente ao 1×1, isolada no modelo |
| `scripts/{match,damage,mobiles,turn_table,flight_snapshot}.gd` | Modificadores e atribuição de Gold compartilhados |
| `scripts/{game,battle_art,mobile_sprite,mobile_rig,hud_art,match_overlay}.gd` | Navegação, render do equipamento e apresentação de Gold/XP |
| `tests/test_avatar_{catalog,profile,shop,art}.gd`, `test_attributes.gd`, `test_gold_rewards.gd` | Suites novas com perfis isolados |
| `tests/capture_avatar_shop.gd` | Capturas GPU reais e poses |

Chamadas públicas propostas (definidas nas tarefas abaixo; não renomear entre tarefas):

```gdscript
# Catalog
func find(key: String) -> Dictionary
func key_for(gender: int, category: int, id: int) -> String
func items(gender: int, category: int) -> Array
func defaults(gender: int) -> Dictionary # categorias "0".."3" -> key
# Attributes (static)
func budget(level: int) -> int
func sanitize(values: Array, level: int) -> Array
func valid(values: Array, level: int) -> bool
func damage(base: int, attack: int, defense: int) -> int
func health(base: int, points: int) -> int
func heal(base: int, points: int) -> int
func delay(original: int, points: int) -> float # truncamento original, /7.5
func crater(base: float, points: int) -> float
# Profile (mesmo objeto/caminho existente)
func owns(key: String) -> bool
func equipped_set(gender: int = -1) -> Dictionary
func purchase(key: String, currency: String) -> String # ok/owned/funds/invalid/save
func equip(key: String) -> bool
func set_gender(value: int) -> bool
func commit_attributes(values: Array) -> bool
func award(match_id: String, victory: bool, draw: bool = false, gold_delta: int = 0) -> int
# ShopModel
func _init(player_profile, avatar_catalog = null) -> void
func filter(category: int, query: String, inventory: bool, page: int = 0) -> Array
func select(key: String) -> bool
func try_selected() -> bool
func confirm_buy(key: String, currency: String) -> String
# AvatarArt
func sample(equipment: Dictionary, age: float, staring: bool = false) -> Array
func draw(view: Node2D, equipment: Dictionary, transform: Transform2D, age: float, tint: Color) -> bool
# Match: adicionar argumento final opcional; chamadas antigas continuam válidas.
func start(vehicle: int, cpu_difficulty: int = 1, seed_value: int = -1,
    map: String = Maps.DEFAULT, weather_mode: String = "original", mask = null,
    attributes_by_actor: Array = []) -> void
# View
func show_shop() -> void
# Shop (Control com filho Node2D para draw)
func setup(host, shop_model) -> void
```

## Tarefa 1 — Catálogo e assets (REQ-38/39)

**Files:** criar importador, pastas de assets, avatar_catalog, test_avatar_catalog; modificar `export_presets.cfg` para incluir `assets/openbound/avatars/*.json` e manifest do Shop; gerar UIDs pelo Godot. Origem dos assets: `OpenBound-Assets/Game Assets`; JSON fonte: `Openbound Network Object Library/DatabaseSeed/AvatarMetadata.json`.

**Interfaces:** produz Catalog com as quatro funções acima. Item tem `key`, `gender`, `category`, `id`, `name`, `date`, `gold_price`, `cash_price`, `pivot` [x,y], `frame_size` [w,h], `atlas` e `portrait`; ausentes opcionais ID0 usam dummy/nenhum draw. Ordenar por ID após filtro de gênero e unissex.

- [ ] Escrever suite com harness `extends SceneTree`, `checks/failures/check`, `_initialize -> run` diferido e `quit(0 if failures == 0 else 1)`, como test_roster. Usar script carregado dinamicamente para observar falta do módulo:

```gdscript
var Catalog = load("res://scripts/avatar_catalog.gd")
check(Catalog != null, "Catalog exists")
if Catalog == null:
    quit(1)
    return
var c = Catalog.new()
check(c.entries.size() == 15, "Exactly the four source categories")
check(c.items(0, 0).size() == 5 and c.items(1, 0).size() == 1, "Gender catalogs")
check(c.items(1, 3).size() == 2, "Unisex flag available to female")
check(c.find("0:0:138").gold_price == 99999999, "Kappa original price")
check(c.find("1:0:0").key != c.find("0:0:0").key, "Basic identity includes gender")
```

- [ ] Rodar `./scripts/check.sh test_avatar_catalog`: deve falhar pela ausência do catálogo.
- [ ] Implementar importador com `Path`, `json`, `re`, `shutil`, `hashlib`; remover comentários de linha do JSON em memória, filtrar AvatarCategory<4, preencher preços omitidos com zero, copiar bytes sem editar imagens. Copiar atlas/portraits por Gender textual original (Unissex), todas as dependências de interface de AvatarShop/PopupBuyAvatar/Button/AnimatedButtonBuilder, `Misc/Dummy` e preview Miramo. O manifest identifica source relativo ao projeto C# e SHA256; não incluir caminhos pessoais no conteúdo do jogo. Validar presença/dimensões no Godot contra `frame_size` antes de disponibilizar item.

```python
rows = [row for row in rows if row['AvatarCategory'] < 4]
key = f"{row['Gender']}:{row['AvatarCategory']}:{row['ID']}"
shutil.copyfile(source, target)
assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256(target.read_bytes()).digest()
```

- [ ] Implementar `find` devolvendo `{}` para chave inexistente; `key_for` procura gênero e depois Unissex; `defaults` devolve os quatro ID0 válidos. Loader usa caminhos `res://`; catalog deve estar incluído no export. Suite verifica cada atlas/retrato/hash, frame válido 0/10/11/21, existência do dummy e ausência de categorias 4..7.
- [ ] Importar e rodar suite até passar; commit local `feat: import original avatar shop catalog and assets`.

## Tarefa 2 — Perfil e transações (REQ-38/40)

**Files:** modificar profile; criar player_attributes (orçamento/saneamento), test_avatar_profile; adicionar suite ao check.sh. Consome Catalog. Produz funções Profile/Attributes acima.

Persistência: JSON version2 com todos os campos antigos e `shop` contendo `version:1`, `gold`, `cash`, `gender`, `owned` (Array de keys), `equipped` (Dictionary com sets "0" e "1"), `attributes` (8 inteiros). Defaults básicos dos dois gêneros e vazios unissex pertencem ao jogador. Se shop não existe, inicializar os dois saldos em1000 e salvar na primeira abertura. Se shop existe mas saldo está danificado, usar0 (não repor1000). Sanitizar posses/equipamento com catálogo; leitura idempotente limpa coleções antes de carregar.

- [ ] Suite começa removendo `.tools/avatar-profile.json`/`.tmp`, testa ausência/legado e as operações ainda inexistentes:

```gdscript
var p = Profile.new("res://.tools/avatar-profile.json")
p.load_profile()
check(p.gold == 1000 and p.cash == 1000, "Test grant once")
check(p.purchase("0:0:1", "gold") == "ok", "Buy by source price")
check(p.gold == 900 and p.owns("0:0:1"), "Atomic debit and ownership")
check(p.purchase("0:0:1", "cash") == "owned" and p.cash == 1000, "Repeated purchase cannot debit")
check(p.purchase("0:0:138", "gold") == "funds", "Kappa unaffordable")
check(p.purchase("0:0:0", "gold") != "ok", "Free Basic cannot be bought")
```

- [ ] Rodar `./scripts/check.sh test_avatar_profile` e observar falha das novas operações.
- [ ] Implementar Attributes: budget com nível−1, valores de tipos não numéricos=0; rejeitar confirm com tamanho !=8, frações, fora0..50 ou soma acima orçamento. Saneamento de load trunca/clampa e reduz excedente em ordem determinística; não aumenta pontos.

```gdscript
static func budget(level: int) -> int:
    return mini(maxi(level - 1, 0) * 10, 180)
# purchase: capturar estado anterior -> validar -> alterar -> save -> rollback se falhou.
# Receber key/currency, resolver preço no Catalog; nunca receber preço da UI.
```

- [ ] Estender save para serialização única e rename existente; transações restauram estado completo em falha. Equip só possui e compatível com gênero; set_gender só0/1 e salva. commit_attributes copia a Array validada. award preserva retorno XP e registra XP/Gold/awarded numa gravação; mesmo ID produz0 e nenhuma mudança. Gold final clampa0..1e9, descontos não geram dívida.
- [ ] Completar testes: save path em diretório inexistente provoca `save`; repetição/reload não repõe saldo; legado mantém nickname/XP/wins/matches/awarded; shop com saldo String vira0; arrays corrompidos; equipamento não possuído volta Basic; unissex comprado uma vez disponível aos dois; alteração do array passado não muda perfil; confirmar sem orçamento e49→50→51; soma180/181 e levels1/2/19/999. Limpar fixtures; rodar suite e test_runner; commit `feat: persist avatar ownership currencies and attribute allocation`.

## Tarefa 3 — Atributos no Match e previsão (REQ-41)

**Files:** modificar player_attributes, match, damage, mobiles, turn_table, flight_snapshot; criar test_attributes. Consome valores saneados; produz Match.start com argumento opcional e funções puras damage/health/heal/delay/crater. CPU recebe zeros na cena, mas testes podem injetar atributos nos dois atores.

- [ ] Escrever e rodar testes vermelhos com exemplos literais do C#:

```gdscript
check(A.damage(200, 30, 20) == 220, "Attack minus Defense")
check(A.health(760, 50) == 1140, "Health does not multiply shield")
check(A.heal(35, 10) == 38, "Regeneration truncates")
check(is_equal_approx(A.delay(770, 33), 515.0 / 7.5), "Delay truncates before conversion")
check(A.crater(25.0, 50) == 37.5, "Dig scales erosion only")
var m = Match.new()
m.start(1, 1, 42, "", "original", null, [[0,50,0,50,50,0,50,0], []])
check(m.actors[0].hp == 1140 and m.actors[0].shield == 220, "Actor life and base shield")
```

- [ ] Implementar fórmulas; adicionar `attributes` copiados em cada ator no start antes do primeiro begin_turn, zero para arrays ausentes. weapon_rules retorna cópia dos dados com delay original convertido e reduzido, sem mutar catálogo compartilhado. Para atributos0 conservar exatamente os floats do baseline; para nãozero usar `int(round(base_delay*7.5)*(1-points/100.0))/7.5`. Passe não usa AttackDelay; preview/fila e schedule usam a mesma weapon_rules.

```gdscript
static func damage(base: int, attack: int, defense: int) -> int:
    return maxi(0, int(base * (1.0 + (attack - defense) / 100.0)))
static func heal(base: int, points: int) -> int:
    return int(base * (1.0 + points / 100.0))
static func delay(original: int, points: int) -> float:
    return int(original * (1.0 - points / 100.0)) / 7.5
```

- [ ] Aplicar Attack/Defense no dano primário já calculado pelo falloff atual, antes do escudo; passar shooter somente nesse caminho. Thor sobrescreve CalculateDamage na fonte; LightningDamage é direto: conservar sem atributos. Dig modifica apenas terrain.carve no tiro primário; EMP e raio de dano conservam valores. Mobiles.on_turn usa heal em regen de escudo e max_shield relativo à vida máxima nova; Proteção usa heal(35, Regeneration), não cria regen HP base para Mage/Bigfoot.
- [ ] Testar dano próprio, defesa e shield, EMP, raio climático, passe, regen cap, vida crítica/HUD. Para cada mobile/arma, usar fixture controlada, chamar predict_shot e depois disparar/tick até resolver, comparar HP/escudo/crateras sem alterar estado vivo. Snapshot actors duplicate(true) já leva atributos; testar mutação de arrays e ThreadPool sem leitura viva. ItemDelay ganha função delay(custo_original, pontos); suite verifica600,50→40 e custo0→0 sem declarar itens ativos.
- [ ] Rodar test_attributes, test_performance e check.sh completo (obrigatório por regras de combate); seeds81–90 com atributos0 devem manter tiros/vencedor/HP. Commit `feat: apply player attributes to shared combat and prediction`.

## Tarefa 4 — Modelo e tela do Shop (REQ-38/40)

**Files:** criar avatar_shop_model, avatar_shop, test_avatar_shop; modificar game para show_shop, draw/process/input e botão de menu. Consome Profile/Catalog/Attributes; produz setup/show_shop e ShopModel.

Modelo guarda category/query/inventory/page/last_page/selected_key, preview equipamento copiado e draft_attributes. filter reseta/clampa página aos resultados, aplica owned somente no inventário. Seleção no inventário chama equip; na loja apenas selected. Modal captura key numa variável separada da seleção, confirm_buy usa essa key. `try_selected` muda só preview. Sair descarta draft/preview. UI desabilita Try/Buy conforme item/saldo e conserva bloqueio do modal também por teclado.

- [ ] Suite vermelha de filtros/experimento/modal e rascunho:

```gdscript
var s = ShopModel.new(p, c)
s.select("0:0:1")
check(not p.owns("0:0:1"), "Selection never buys")
s.try_selected()
check(s.preview["0"] == "0:0:1" and p.equipped_set()["0"] == "0:0:0", "Try is temporary")
s.filter(0, "missing", false, 99)
check(s.page == 0 and s.last_page == 1, "Empty filter clamps page")
```

- [ ] Rodar test_avatar_shop e observar falha. Implementar modelo e tela em viewport1280×800 com transformação uniforme do canvas original800×600, dimensão conferida do Background. Usar escala4/3, origem(106.6667,0) e centro original(400,300); controles e fundo recebem a mesma transformação, com laterais discretas de106.67px. Isso contém inclusive offsets±285 sem esticar nem cortar rodapé. Usar sprites Background/Foreground1/2, TabIndex, Hat/Body/Goggles/Flag, Try/Buy/indicadores e popup original; quatro categorias extras ficam desabilitadas se presentes no artwork. Nomes e controles traduzidos, IDs/preços originais. Cards5×5 com offsets108×86 na escala escolhida, nome truncado como C#, tooltip nome integral, valores moedas e equipado/possui. Campos acessíveis pelo teclado e estados disabled sem click-through.

```gdscript
# O key do modal não depende da seleção após abertura.
var purchase_key := model.selected_key
gold_button.pressed.connect(func():
    var status: String = model.confirm_buy(purchase_key, "gold")
    show_purchase_feedback(status)
)
# Menu: show_shop salva nickname se mudou, cancela busca/carga, para música,
# replace_root, screen="shop", add_child(Shop), setup(self, ShopModel.new(profile)).
```

- [ ] Painel dos oito atributos usa ícones originais, remanescentes e +/−, Accept/Cancel; não habilitar + com50 ou sem remanescentes. Confirmar chama commit_attributes e só limpa draft após save; cancel recopia. Header mostra nível/Gold/Cash e gênero com sets separados. Voltar/ESC sai se sem modal; ESC em modal cancela modal antes de sair. game não processa batalha nem inicia arrasto/mira quando screen shop; ajustar _draw para distinguir explicitamente menu/shop/match.
- [ ] Completar testes de fixture>25 cards, busca em página2 com nenhum resultado, subset inventoried, trocar categoria/gênero, cliques reais via root.push_input em abas/cards/Try/Buy/Cancel/Gold/Cash e +/Accept. Mudar selected enquanto modal existe não muda purchase_key. Duplo clique debit uma vez. Salvar nickname/seleção de mobile ao retornar e iniciar partida. Em level1 painel mostra0 disponível sem pedir XP ao perfil real. Rodar suite + suites cena/HUD/mira; commit `feat: add original avatar shop inventory and allocation UI`.

## Tarefa 5 — Rider composto nos previews e arena (REQ-39)

**Files:** criar avatar_art, test_avatar_art; modificar mobile_rig/mobile_sprite/battle_art/game. Consome Catalog/equipment snapshot; produz sample/draw. Adicionar argumento final opcional `avatar_context: Dictionary = {}` ao draw de MobileSprite e MobileRig para conservar chamadas antigas/tests históricas. Contexto: equipment, age; BattleArt só recebe ctx, não consulta perfil.

- [ ] Teste vermelho de frame/pivô/camadas e isolamento:

```gdscript
var pieces = AvatarArt.new().sample(c.defaults(0), 0.0)
check(pieces.size() == 2, "No goggles/flag produce no visible pieces")
check(pieces[0].category == 0 and pieces[1].category == 1, "Source depth: head before body")
check(pieces[0].frame == 11, "Head normal uses frames11..21")
check(AvatarArt.new().sample(c.defaults(0), 1.0)[0].frame == 21, "10 FPS")
```

- [ ] Rodar test_avatar_art. Implementar sample: Body frames0..10; Hat/Goggles/Flag normal11..21, staring0..10, ciclo11frames a10FPS. Âncoras base Body(0,0), Head(7,−17), Goggles(9,−17), Flag(11,−17) no sistema original faces-left; pivô/size por metadata, ordem confirmada de DepthParameter/SpriteSortMode.FrontToBack: Flag0.043, Head0.044, Goggles0.045, Body0.046; desenhar flag→head→goggles→body. Camadas de chassis/arma/rodas seguem o rig vigente, com o rider no lugar do piloto.

```gdscript
var frame := int(floor(age * 10.0)) % 11
if category != 1 and not staring:
    frame += 11
var source := Rect2(Vector2(frame * frame_size.x, 0), frame_size)
var target := Rect2(anchor - pivot, frame_size)
# Aplicar transform única ao conjunto; source nunca redefine escala por alpha.
```

- [ ] Rig HD mantém chassis/arma/rodas. Quando avatar_context válido, substituir piece do pilot_side pelo AvatarArt com os quadris Body alinhados ao mesmo seat, usando escala conjunta baseada nos44px originais; ocultação chassis/piloto/arma/rodas preservada. Se contexto vazio preservar piloto anterior como compatibilidade; se recurso de peça falha, render original Basic coerente e sem piloto duplicado. Caminho original de MobileSprite usa rider_offset(frame) e atlas composto, não rider_body/head fixos. Relógio age compartilhado pausável, não usar view.elapsed oculto no novo caminho.
- [ ] Shop mostra avatar independente ampliado e preview no mobile selecionado; shop/inventário usam contextos distintos. Arena snapshot equipment/gender no start, CPU básicos, battle_art recebe avatar_context. Confirmar pause/hurt/dead/facing/slope/moving/recoil mantém anchors/escala; vestir não altera model HP/colisão/tiro. Testar catálogo inválido/textura ausente e defaults femininos/unissex; rodar art + test_mobile_animation/test_roster/test_pilot_projectiles e ajustar apenas expectativas do caminho ativo mantendo testes do legado. Commit `feat: compose equipped avatar in shop previews and battle rider`.

## Tarefa 6 — Gold e Popularity (REQ-41/10)

**Files:** criar gold_rewards/test_gold_rewards; modificar match/damage/turn_table/flight_snapshot/game/hud_art/match_overlay/profile quando necessário. Fonte executável GameClientProvider.cs620–935 e NetworkObjectParameters235–282. Produz GoldRewards.apply_shot(state: Dictionary, shot: Dictionary, popularity: int) -> Dictionary, GoldRewards.result_bonus(victory: bool, draw: bool) -> int. State {gold, enemy_damage}; Shot {enemy_damage, ally_damage, enemy_kills, ally_kills, angle, travelled, tornado, mirror, boomer, backward}. Campos Actor `gold_state` e Match `shot_gold` são copiados em FlightSnapshot para não escrever no vivo.

- [ ] Escrever teste vermelho para limiares e fluxo literal:

```gdscript
var state := {"gold":0, "enemy_damage":0}
var shot := {"enemy_damage":200, "ally_damage":0, "enemy_kills":0,
    "ally_kills":0, "angle":30.0, "travelled":1.0,
    "tornado":false, "mirror":false, "boomer":false, "backward":false}
state = GoldRewards.apply_shot(state, shot, 50)
check(state.gold == 7, "5 Gold then int(x1.5)")
state = GoldRewards.apply_shot(state, shot, 50)
check(state.gold == 18, "Source multiplies accumulated Gold per shot")
check(GoldRewards.result_bonus(true, false) == 4, "C# uses ExperienceWin1v1 for Gold")
check(GoldRewards.result_bonus(false, false) == 1, "C# uses ExperienceLose1v1 for Gold")
```

- [ ] Rodar test_gold_rewards; implementar função pura sem perfil/RNG: kill enemy+30, ally/suicide−50; ally_damage>30→−10; somente com enemy_damage!=0 ou enemy_kills>0: angle70..120 e travelled>4→10, senão>2.5→5; tornado+10/mirror+10; boomer+10/backward+5; enemy_damage>500→15, >250→10, >150→5; cruzar1000→10, cruzar3000→30; manter literal branch2000 inalcançável (o C# repete condição1000). MultipleKill+60 é incapaz no1×1 e não vira bônus artificial. Popularity int((gold acumulado+delta)*(1+p/100)) por tiro com informação de dano. Resultado4/1 depois da popularidade, empate0 como adaptação ao empate já existente; não bonificar saldo inicial. Registrar essas peculiaridades em DECISIONS e texto de aprendizado.
- [ ] Match agrega componentes de um único shot/turno como ProjectileDamageInformation; usar dano relatado de HP+escudo conforme a fonte, unificar kills após settle para bungee; cada pellet não finaliza Gold sozinho. Guardar ângulo lançado, facing/start/end, maior duração de voo e clima interagido; fórmula boomer/backward literal do C#, com conversão de coordenadas/ângulo explicitamente testada. Golpes sem informação de dano não bonificam. Falls sem autoria válida só resultado; CPU acumula estado próprio sem ganhar moeda no perfil do jogador. Snapshot copia shot_gold e gold_state em isolamento.
- [ ] Perfil recebe gold_delta = gold_state do jogador + result_bonus, na mesma award do XP; repeats guardados em awarded. HUD Gold agora mostra Gold apurado na partida, resultado mostra Gold/XP separados. Não persistir Gold durante previsão nem creditar parcialmente a cada frame. Testar replay/finished duplicado, save failure e reload; negativas clamp somente no saldo final. Gold não afeta escolha física da CPU.
- [ ] Fixtures de limites exatos150/151/250/251/500/501, friend30/31, flight2.5/2.51/4/4.01, angle69/70/120/121, kill self/enemy, milestones1000/2000/3000 e cumulatividade. Verificar cópia de state não altera entrada; test_gold_rewards/test_attributes/check.sh completo. Commit `feat: port offline Gold scoring and Popularity rewards`.

## Tarefa 7 — Validação integrada, documentação e entrega

**Files:** criar capture_avatar_shop; atualizar README/docs/APRENDIZADO/docs/VALIDACAO, SPEC/DESIGN/DECISIONS/TASKS/HANDOFF e check.sh. Assets opcionais HD não são exigidos; descrever fidelidade e adaptações sem afirmar geração nova.

- [ ] Acrescentar as seis suites novas a ALL/QUICK do check.sh (catálogo, perfil, shop, art, atributos, gold). Incluir teste que inicia pela cena com atributos/equipamentos confirmados, modificação posterior do perfil não muda partida viva; thread da CPU e tiro real concordam. Smoke test do catálogo em PCK de teste com `--export-pack` se houver template necessário, sem instalar dependências.
- [ ] Escrever captura com viewport1920×1200, `root.content_scale_size=Vector2i.ZERO`, setup perfil isolado xp3600 para orçamento180, sound.muted, equipamento Space Marine/Goggles/Blue Flag confirmado. Capturar shop-default, purchase-gold, inventory-equipped, attribute-draft e ambos mobiles/direções/encosta e pausa:

```gdscript
await process_frame
await RenderingServer.frame_post_draw
assert(root.get_texture().get_image().save_png("res://docs/avatar-shop/shop.png") == OK)
```

- [ ] Executar `/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_avatar_shop.gd`; inspecionar PNGs com view_image. Ajustar composição/clipping/contraste, recapturar somente se houve mudança. Não usar captura de teste como alegação de uso manual pelo usuário.
- [ ] Rodar `./scripts/check.sh` completo, observar cada suite/exitcode; conferir10 partidas e compare baseline de atributos0, `git diff --check`, fonte C# intocada. Se falha, diagnosticar a causa antes de corrigir. Registrar contagem real e limites: ItemDelay função sem uso real até integração de itens, HD novo não gerado, teste manual do app ainda não feito.
- [ ] Revisar branch inteira (modelo/transações/render/thread/Gold/persistência/export). Confirmar cada REQ38..41 contra evidência, não declarar completude de efeito ItemDelay indisponível. Atualizar documentação de arquitetura/SDD e manual de compra/XP→pontos. Commit `docs: record avatar shop validation and remaining item dependency`.
- [ ] Entregar branch/worktree, capturas e instrução de executar projeto no Godot. Se nesta execução for entregue app: reutilizar template macOS local copiado para `.tools/macos.zip`, rodar `scripts/build_macos.py`, verificar `codesign --verify --deep --strict --verbose=2 'builds/Gunbound Recomp.app'` e conferir catálogo/interface/atlas no pacote; informar versão e caminhos reais. Sem merge/push automático.

## Ordem e execução proposta

1→2→3→4→5→6→7. As tarefas compartilham contratos de perfil/render/Match;
execução nativa nesta conversa é recomendada para manter os ajustes próximos.
Se o usuário preferir subagentes, aplicar o workflow específico após essa escolha.
Não iniciar código antes da revisão deste plano; a aprovação da especificação
já foi recebida e não deve ser pedida novamente.

## Auto-revisão do plano

REQ38→1/2/4; REQ39→1/5/7; REQ40→2/4; REQ41→3/6/7; persistência REQ10→2/6;
thread REQ32→3/6; dependência REQ35→3/7. Interfaces consistentes; casos de
Review Focus associados a testes nas tarefas indicadas. Estado: plano escrito,
sem execução de código novo; baseline previamente validado1114checks+10partidas.
