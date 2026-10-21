extends Node2D
## Presentation and input. Combat outcomes belong exclusively to MatchModel.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const AvatarShop = preload("res://scripts/avatar_shop.gd")
const ShopModel = preload("res://scripts/avatar_shop_model.gd")
var shop
var actor_avatars: Array = []
var gold_reward := 0
const Profile = preload("res://scripts/profile.gd")
const UIFactory = preload("res://scripts/ui.gd")
const Sound = preload("res://scripts/sound.gd")
const BattleArt = preload("res://scripts/battle_art.gd")
const BigfootSprite = preload("res://scripts/bigfoot_sprite.gd")
const MageSprite = preload("res://scripts/mage_sprite.gd")
const NakSprite = preload("res://scripts/nak_sprite.gd")
const Maps = preload("res://scripts/maps.gd")
const WeatherArt = preload("res://scripts/weather_art.gd")
const HudArt = preload("res://scripts/hud_art.gd")
const Options = preload("res://scripts/options.gd")
const OptionsPopup = preload("res://scripts/options_popup.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const AimControl = preload("res://scripts/aim_control.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")
const MatchOverlay = preload("res://scripts/match_overlay.gd")
const ItemArt = preload("res://scripts/item_art.gd")
const ItemBar = preload("res://scripts/item_bar.gd")
const SelectItemPopup = preload("res://scripts/select_item_popup.gd")
const Items = preload("res://scripts/items.gd")
var hud = HudArt.new()
var item_art = ItemArt.new()
var item_bar = ItemBar.new(item_art)
var weather_art = WeatherArt.new()
var mage = MageSprite.new()
var bigfoot = BigfootSprite.new()
var nak = NakSprite.new()
var art = BattleArt.new()
var ui = UIFactory.new()
var model = Match.new()
var profile = null
# PopupGameOptions values; saved next to the profile (tests isolate both).
var options
var options_popup: Control
var items_popup: Control
var items_button: Button
var sound = null
var screen := "menu"
var root: Control
var overlay: Control
var overlay_kind := ""
var background: Texture2D
var map_backgrounds := {}
const VIEW_SIZE := CameraRig.VIEW_SIZE
var rig := CameraRig.new()
var aim := AimControl.new()
var overlays := MatchOverlay.new()
var camera: Vector2:
	get:
		return rig.position
	set(value):
		rig.position = value
var camera_manual: bool:
	get:
		return rig.manual
	set(value):
		rig.manual = value
var dragging := false
var pan_mask := MOUSE_BUTTON_MASK_LEFT
var last_impact: Vector2:
	get:
		return rig.last_impact
	set(value):
		rig.last_impact = value
var nickname_input: LineEdit
var vehicle := 2
var cpu_difficulty := 1
# Training option: the map's original weather preset or every effect (Thor included).
var weather_mode := "original"
var vehicle_buttons: Array[Button] = []
var vehicle_info: Label
var angle: float:
	get:
		return aim.angle
	set(value):
		aim.angle = value
var power: float:
	get:
		return aim.power
	set(value):
		aim.power = value
var weapon: int:
	get:
		return aim.weapon
	set(value):
		aim.weapon = value
var charging: bool:
	get:
		return aim.charging
	set(value):
		aim.charging = value
var drag_aiming: bool:
	get:
		return aim.drag_aiming
	set(value):
		aim.drag_aiming = value
var aim_direction: int:
	get:
		return aim.aim_direction
	set(value):
		aim.aim_direction = value
var aim_limit: float:
	get:
		return aim.aim_limit
	set(value):
		aim.aim_limit = value
var drag_rng:
	get:
		return aim.drag_rng
	set(value):
		aim.drag_rng = value
var paused := false
var elapsed := 0.0
var cpu_wait := 0.0
var cpu_plan: Dictionary = {}
# CPU aim search on a worker thread (REQ-32): starts with the CPU turn on a
# snapshot; cpu_plan only appears when it is done and the initial wait is over.
var cpu_search: Dictionary = {}
var cpu_task := -1
# Who opens the next match: Match.RANDOM_OPENING in play (ADR-076); tests pin a side.
var opening := Match.RANDOM_OPENING
var match_id := ""
var reward := 0
var result_wait := -1.0
var effects: Array = []
var floating: Array = []
var shake := 0.0
var fire_button: Button
var pass_button: TextureButton
var options_button: TextureButton
var flip_button: Button
var move_left: Button
var move_right: Button
var weapon_buttons: Array[TextureButton] = []
var queue_entries: Array = []
var sprites := {}

func _ready() -> void:
	# HUD HD sprites (3×) are drawn smaller than their pixels; mipmaps keep 1 px borders.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background = load("res://assets/art/background.png")
	sprites[1] = mage
	sprites[2] = bigfoot
	sprites[3] = nak
	if profile == null:
		profile = Profile.new()
	profile.load_profile()
	if options == null:
		options = Options.new(profile.path.get_basename() + "-options.json")
		options.load_options()
	aim.drag_rng.randomize()
	if sound == null:
		sound = Sound.new()
	if sound.get_parent() != self:
		add_child(sound)
	apply_options()
	show_menu()

func replace_root() -> void:
	if is_instance_valid(root):
		remove_child(root)
		root.queue_free()
	root = Control.new()
	root.size = Vector2(1280, 800)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	overlay = null
	overlay_kind = ""
	options_popup = null
	paused = false
	charging = false

func show_menu() -> void:
	screen = "menu"
	model.phase = "menu"
	discard_cpu_search()
	sound.stop_music()
	result_wait = -1.0
	effects.clear()
	floating.clear()
	replace_root()
	var tag := ui.label(root, "TREINO DE ARTILHARIA   /   0.18.1", Vector2(80, 74), Vector2(530, 24), 14, ui.TEAL, true)
	tag.add_theme_constant_override("outline_size", 2)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	var title := ui.label(root, "GUNBOUND\nRECOMP", Vector2(74, 130), Vector2(650, 235), 80, ui.CREAM, true)
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.1, 0.16, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 5)
	ui.label(root, "Mire. Sinta o vento. Faça a cratera.", Vector2(80, 390), Vector2(630, 38), 23)
	ui.label(root, "Um duelo contra a máquina, nas alturas.", Vector2(80, 430), Vector2(630, 28), 17, Color("d7e8e6"))
	ui.label(root, "ARTILHARIA POR TURNOS · TREINO OFFLINE 1×1", Vector2(80, 753), Vector2(720, 22), 12, Color("c4d6d5"), true)
	var card := ui.panel(root, Vector2(800, 112), Vector2(420, 620), Color("112b38"), 22)
	ui.label(card, "Preparar treino", Vector2(28, 25), Vector2(364, 44), 30, ui.CREAM, true)
	ui.label(card, "Uma arena. Você e a máquina.", Vector2(28, 73), Vector2(364, 24), 16, ui.MUTED)
	ui.label(card, "SEU APELIDO", Vector2(28, 115), Vector2(364, 22), 12, ui.TEAL, true)
	nickname_input = LineEdit.new()
	nickname_input.position = Vector2(28, 144)
	nickname_input.size = Vector2(364, 47)
	nickname_input.text = profile.nickname
	nickname_input.max_length = 20
	nickname_input.placeholder_text = "Como devemos chamar você?"
	nickname_input.add_theme_font_override("font", ui.font)
	nickname_input.add_theme_font_size_override("font_size", 19)
	nickname_input.add_theme_color_override("font_color", ui.CREAM)
	nickname_input.add_theme_color_override("caret_color", ui.TEAL)
	nickname_input.add_theme_stylebox_override("normal", ui.box(Color("203e4b"), 8, Color("49636c")))
	nickname_input.add_theme_stylebox_override("focus", ui.box(Color("203e4b"), 8, ui.TEAL, 2))
	card.add_child(nickname_input)
	ui.label(card, "ESCOLHA SEU VEÍCULO", Vector2(28, 214), Vector2(364, 22), 12, ui.TEAL, true)
	vehicle_buttons.clear()
	for slot in range(Match.PLAYABLE_VEHICLES.size()):
		var index: int = Match.PLAYABLE_VEHICLES[slot]
		# Three slots share the 364 px row, like the difficulty buttons below.
		var button := ui.button(card, Match.VEHICLES[index].name, Vector2(28 + slot * 124, 246), Vector2(116, 48), func(): select_vehicle(index))
		button.add_theme_font_size_override("font_size", 14)
		vehicle_buttons.append(button)
	vehicle_info = ui.label(card, "", Vector2(28, 303), Vector2(364, 50), 15, ui.MUTED)
	ui.label(card, "DIFICULDADE DA MÁQUINA", Vector2(28, 360), Vector2(364, 22), 12, ui.TEAL, true)
	var difficulty_buttons: Array[Button] = []
	for index in range(3):
		var button := ui.button(card, ["Leve", "Normal", "Precisa"][index], Vector2(28 + index * 124, 388), Vector2(116, 40), func():
			cpu_difficulty = index
			for j in range(difficulty_buttons.size()):
				difficulty_buttons[j].add_theme_stylebox_override("normal", ui.box(Color("32666b") if j == index else Color("24444e"), 9, ui.TEAL if j == index else Color("47626a")))
		)
		difficulty_buttons.append(button)
		if index == cpu_difficulty:
			button.add_theme_stylebox_override("normal", ui.box(Color("32666b"), 9, ui.TEAL))
	var weather_button := ui.button(card, weather_label(), Vector2(28, 438), Vector2(240, 34), func(): pass)
	weather_button.add_theme_font_size_override("font_size", 14)
	weather_button.tooltip_text = "Original: pesos do mapa (Miramo A não tem Thor, Espelho nem Fraqueza).\nTodos: pesos iguais para todos os climas, Thor incluído."
	weather_button.pressed.connect(func():
		weather_mode = "all" if weather_mode == "original" else "original"
		weather_button.text = weather_label()
	)
	# PopupSelectItem (REQ-36): the six equipped slots used in every match.
	items_button = ui.button(card, items_label(), Vector2(276, 438), Vector2(116, 34), show_items)
	items_button.add_theme_font_size_override("font_size", 14)
	items_button.tooltip_text = "Escolher os itens da barra F1–F6 (Select Item)"
	ui.button(card, "INICIAR TREINO    →", Vector2(28, 484), Vector2(364, 52), start_match, true)
	ui.label(card, "NÍVEL %d    ·    %d XP    ·    %d VITÓRIAS" % [profile.level(), profile.xp, profile.wins], Vector2(28, 555), Vector2(364, 26), 13, ui.MUTED, true)
	ui.button(root, "Shop de avatar", Vector2(810,754), Vector2(200,30), show_shop)
	ui.button(root, "Como jogar", Vector2(1030, 754), Vector2(190, 30), show_help)
	select_vehicle(vehicle)
	queue_redraw()

func show_shop() -> void:
	if screen == "menu" and is_instance_valid(nickname_input):
		profile.nickname = profile.clean_nickname(nickname_input.text)
	if not profile.save_profile():
		return
	discard_cpu_search()
	sound.stop_music()
	replace_root()
	screen = "shop"
	shop = AvatarShop.new()
	root.add_child(shop)
	shop.setup(self,ShopModel.new(profile))
	queue_redraw()

func weather_label() -> String:
	return "Clima: " + ("original do mapa" if weather_mode == "original" else "todos (Thor)")

func select_vehicle(index: int) -> void:
	index = Match.normalize_vehicle(index)
	vehicle = index
	for j in range(vehicle_buttons.size()):
		vehicle_buttons[j].add_theme_stylebox_override("normal", ui.box(Color("32666b") if Match.PLAYABLE_VEHICLES[j] == index else Color("24444e"), 9, ui.TEAL if Match.PLAYABLE_VEHICLES[j] == index else Color("47626a")))
	var data: Dictionary = Match.VEHICLES[index]
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), str(data.summary)]
	queue_redraw()

func start_match() -> void:
	if screen == "menu" and is_instance_valid(nickname_input):
		profile.nickname = profile.clean_nickname(nickname_input.text)
		profile.save_profile()
	screen = "match"
	model.start(vehicle, cpu_difficulty, -1, Maps.DEFAULT, weather_mode, Terrain.new(), options.items, [profile.attributes, []], [profile.equipment_bonuses(), []], opening)
	item_art.clear()
	actor_avatars = [profile.equipped_set(), profile.catalog.defaults(0)]
	# LevelScene: ChangeSong(SongParameter.LevelScene); keeps playing across rematches.
	sound.play_music()
	art.reset(model.actors)
	camera_manual = false
	dragging = false
	last_impact = Vector2.INF
	camera = clamp_camera(camera_goal())
	weather_art.reset(Maps.get_map(model.map_id))
	match_id = str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())
	reward = 0
	gold_reward = 0
	result_wait = -1.0
	angle = clampf(45.0, model.aim_limits(Match.PLAYER).x, model.aim_limits(Match.PLAYER).y)
	power = 0.0
	weapon = 0
	charging = false
	cpu_plan.clear()
	discard_cpu_search()
	effects.clear()
	floating.clear()
	replace_root()
	build_hud()
	consume_events()
	update_hud()

func build_hud() -> void:
	# OpenBound action bar (HUD.cs): sprite buttons sit on the bar drawn in _draw.
	hud.reset(model)
	var blocker := Control.new()
	blocker.position = Vector2(0, VIEW_SIZE.y)
	blocker.size = Vector2(1280, 800 - VIEW_SIZE.y)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(blocker)
	# Shot strength selector: a draggable reference marker (does not set the power).
	var selector := Control.new()
	var area: Rect2 = hud.strength_rect().grow_individual(0, 8, 0, 8)
	selector.position = area.position
	selector.size = area.size
	selector.mouse_filter = Control.MOUSE_FILTER_STOP
	selector.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			hud.set_selector_from_screen(selector.position.x + event.position.x)
	)
	root.add_child(selector)
	weapon_buttons.clear()
	for index in range(3):
		var button: TextureButton = hud.make_button(root, "shot", index)
		button.pressed.connect(func(): select_weapon(index))
		button.tooltip_text = "%s · atraso %d" % [model.weapon_rules(Match.PLAYER, index).name, model.weapon_rules(Match.PLAYER, index).delay]
		weapon_buttons.append(button)
	options_button = hud.make_button(root, "options")
	options_button.tooltip_text = "Opções (ESC) · pausa (P)"
	options_button.pressed.connect(show_options)
	pass_button = hud.make_button(root, "skip")
	pass_button.tooltip_text = "Passar o turno (F8)"
	pass_button.pressed.connect(pass_turn)
	# Discreet extras for mouse/touch play; the original only has the keyboard.
	var extras := Vector2(1062, VIEW_SIZE.y - 40)
	move_left = ui.button(root, "←", extras, Vector2(40, 32), func(): pass)
	move_right = ui.button(root, "→", extras + Vector2(44, 0), Vector2(40, 32), func(): pass)
	flip_button = ui.button(root, "F", extras + Vector2(88, 0), Vector2(36, 32), flip)
	fire_button = ui.button(root, "●", extras + Vector2(128, 0), Vector2(78, 32), func(): pass, true)
	fire_button.tooltip_text = "Segure para carregar e solte para disparar (ou Espaço)"
	fire_button.button_down.connect(begin_charge)
	fire_button.button_up.connect(release_charge)
	for button in [move_left, move_right, flip_button, fire_button]:
		button.add_theme_font_size_override("font_size", 15)
		button.modulate = Color(1, 1, 1, 0.82)
	item_bar.build(self, root)
	select_weapon(0)

func displayed_queue() -> Array:
	return queue_entries

func animation_state(index: int) -> String:
	return art.state_name(model, index, charging, model.phase == "aim" and model.active == Match.CPU and not cpu_plan.is_empty())

func player_can_act() -> bool:
	return screen == "match" and model.phase == "aim" and model.active == Match.PLAYER and not paused

func select_weapon(index: int) -> void:
	if screen != "match" or not player_can_act():
		return
	if Match.SPECIAL_WEAPON == index and not model.can_use_special(Match.PLAYER):
		return
	weapon = index
	var limits: Vector2 = model.aim_limits(Match.PLAYER, weapon)
	angle = clampf(angle, limits.x, limits.y)
	for j in range(weapon_buttons.size()):
		hud.style_button(weapon_buttons[j], j == index)

func cycle_weapon() -> void:
	# ShotButton.UpdateKeyboard: Tab moves to the next shot, skipping a disabled SS.
	var next := (weapon + 1) % 3
	if next == Match.SPECIAL_WEAPON and not model.can_use_special(Match.PLAYER):
		next = 0
	select_weapon(next)

func begin_charge() -> void:
	aim.begin_charge(self)

func release_charge() -> void:
	aim.release_charge(self)

func begin_drag(x: float) -> void:
	aim.begin_drag(self, x)

func update_drag(x: float, relative_x: float) -> void:
	aim.update_drag(x, relative_x)

func release_drag() -> void:
	aim.release_drag(self)

## HUD.UseItemAction on the own turn: the match validates and applies the item;
## DisableSS moves an SS selection to the second shot.
func use_item(slot: int) -> bool:
	if not player_can_act() or not model.use_item(slot):
		return false
	if weapon == Match.SPECIAL_WEAPON:
		select_weapon(1)
	return true

func pass_turn() -> void:
	if player_can_act():
		charging = false
		model.pass_turn()

func shoot() -> void:
	if player_can_act():
		charging = false
		hud.previous_power = power
		hud.previous_angle = hud.hud_angle(model, angle, weapon)
		model.fire(angle, power, weapon)

func flip() -> void:
	if player_can_act():
		model.actors[Match.PLAYER].facing *= -1

func _process(delta: float) -> void:
	if not paused:
		elapsed += minf(delta, 0.1)
	queue_redraw()
	if screen != "match" or paused:
		return
	var frame_delta := minf(delta, 0.1)
	if player_can_act():
		var direction := 0.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or move_left.is_pressed():
			direction -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or move_right.is_pressed():
			direction += 1.0
		if not is_zero_approx(direction):
			model.move_actor(direction, frame_delta)
		update_aim_keys(frame_delta)
		aim.tick(self, frame_delta)
	hud.tick(frame_delta, model, sound)
	item_art.tick(frame_delta)
	model.tick(frame_delta)
	weather_art.tick(frame_delta, model)
	art.tick(model, frame_delta, charging, weapon, model.phase == "aim" and model.active == Match.CPU and not cpu_plan.is_empty(), int(cpu_plan.get("weapon", 0)))
	consume_events()
	if model.phase == "aim" and model.active == Match.CPU:
		if cpu_plan.is_empty() and cpu_search.is_empty():
			start_cpu_search()
		cpu_wait -= frame_delta
		if cpu_wait <= 0.0:
			if cpu_plan.is_empty():
				if WorkerThreadPool.is_task_completed(cpu_task):
					WorkerThreadPool.wait_for_task_completion(cpu_task)
					cpu_task = -1
					cpu_plan = model.finish_cpu_plan(cpu_search)
					cpu_search = {}
					cpu_wait = 0.75
			else:
				model.fire(cpu_plan.angle, cpu_plan.power, cpu_plan.weapon)
				cpu_plan.clear()
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += frame_delta
		if effects[i].age > 1.5:
			effects.remove_at(i)
	for i in range(floating.size() - 1, -1, -1):
		floating[i].age += frame_delta
		if floating[i].age > 1.5:
			floating.remove_at(i)
	update_camera(frame_delta)
	shake = maxf(0.0, shake - frame_delta * 24.0)
	if result_wait >= 0.0:
		result_wait -= frame_delta
		if result_wait < 0.0:
			show_result()
	update_hud()

func start_cpu_search() -> void:
	cpu_search = model.begin_cpu_plan()
	var plan := cpu_search
	cpu_task = WorkerThreadPool.add_task(func(): Match.search_cpu_plan(plan), false, "CPU aim search")

## A running search only reads its own snapshot; wait for it before dropping it.
func discard_cpu_search() -> void:
	if cpu_task >= 0:
		WorkerThreadPool.wait_for_task_completion(cpu_task)
		cpu_task = -1
	cpu_search = {}

func _exit_tree() -> void:
	discard_cpu_search()

func update_aim_keys(delta: float) -> void:
	aim.update_keys(self, delta)

func step_angle(direction: int) -> void:
	aim.step_angle(self, direction)

func actor_context(index: int) -> Dictionary:
	var cpu_weapon := int(cpu_plan.get("weapon", model.last_shots[index].get("weapon", 0)))
	return {
		"charging": charging,
		"cpu_charging": model.phase == "aim" and model.active == Match.CPU and not cpu_plan.is_empty(),
		"player_weapon": weapon,
		"cpu_weapon": cpu_weapon,
		"avatar_context": {"equipment":actor_avatars[index],"age":elapsed} if actor_avatars.size()==2 else {},
		"atlas": sprite_for(int(model.actors[index].vehicle)),
		"elapsed": elapsed,
		"shadow": ui.box(Color(0.02, 0.04, 0.1, 0.28), 10),
	}

func actor_frame(index: int) -> int:
	return art.atlas_frame(model, index, actor_context(index))

func sprite_for(vehicle_id: int):
	return sprites.get(vehicle_id)

func play_mobile_shot(event: Dictionary) -> void:
	var id := int(event.vehicle) if event.has("vehicle") else int(model.actors[event.actor].vehicle)
	# A Dual second volley sounds like a new shot; the teleport beacon has its own.
	var moment: String = "fire" if event.type == "volley" else event.type
	if not Mobiles.has_id(id) or Mobiles.shot_sound_on(id) != moment or bool(event.get("beacon", false)) or event.get("item", "") == "teleport":
		return
	var body = sprite_for(id)
	if body == null:
		return
	sound.play("fire", body.shoot_sounds[event.weapon])

func consume_events() -> void:
	var granted := -1
	for event in model.events:
		art.react(event)
		hud.react(event, model)
		weather_art.react(event, model, sound)
		item_art.react(event, sound)
		match event.type:
			"turn":
				granted = int(event.actor)
				camera_manual = false
				last_impact = Vector2.INF
				charging = false
				cpu_plan.clear()
				discard_cpu_search()
				cpu_wait = 1.1
				if event.actor == Match.PLAYER:
					# HUD.GrantTurn resets the strength bar; the marker keeps the last shot.
					power = 0.0
				sound.play("turn")
				if weapon == Match.SPECIAL_WEAPON and not model.can_use_special(Match.PLAYER):
					weapon = 0
			"fire":
				camera_manual = false
				play_mobile_shot(event)
			"volley":
				play_mobile_shot(event)
			"projectile_launch":
				play_mobile_shot(event)
			"explosion":
				last_impact = event.position
				var vehicle_id := int(event.get("vehicle", Mobiles.DEFAULT_ID))
				effects.append({"pos": event.position, "radius": event.radius, "weapon": event.weapon, "vehicle": vehicle_id, "age": 0.0})
				shake = 7.0
				var original: AudioStream = null
				var body = sprite_for(vehicle_id)
				if body != null:
					original = body.blast_sounds[event.weapon]
				sound.play("explosion", original)
			"fall":
				floating.append({"pos": Vector2(model.actors[event.actor].pos.x, minf(float(model.actors[event.actor].pos.y), model.terrain.world_size().y) - 80.0), "text": "QUEDA!", "age": 0.0, "color": Color("ffbc79")})
			"finished":
				charging = false
				gold_reward = model.player_gold_reward()
				reward = profile.award(match_id, model.winner == Match.PLAYER, model.winner == -1, gold_reward)
				result_wait = 1.7
				sound.play("result")
	model.events.clear()
	# HUD.GrantTurn after the turn events: drop the used item, run a queued one.
	if granted >= 0 and screen == "match":
		item_bar.on_turn(self, granted)

func update_hud() -> void:
	if screen != "match":
		return
	var limits: Vector2 = model.aim_limits(Match.PLAYER, weapon)
	angle = clampf(angle, limits.x, limits.y)
	var enabled := player_can_act()
	pass_button.disabled = not enabled
	flip_button.disabled = not enabled
	move_left.disabled = not enabled
	move_right.disabled = not enabled
	fire_button.disabled = not enabled
	item_bar.sync(self)
	for index in range(weapon_buttons.size()):
		var button: TextureButton = weapon_buttons[index]
		button.disabled = index == Match.SPECIAL_WEAPON and not model.can_use_special(Match.PLAYER)
		if bool(button.get_meta("activated")) != (index == weapon):
			hud.style_button(button, index == weapon)
	weapon_buttons[Match.SPECIAL_WEAPON].tooltip_text = "%s: liberado no primeiro turno; depois do uso, volta em quatro turnos próprios." % model.weapon_rules(Match.PLAYER, Match.SPECIAL_WEAPON).name
	var displayed_weapon: int = weapon if model.active == Match.PLAYER else int(cpu_plan.get("weapon", 0))
	if model.phase == "finished":
		queue_entries = []
	elif model.phase == "aim" and model.active == Match.CPU and cpu_plan.is_empty():
		queue_entries = current_order()
	else:
		queue_entries = model.initiative_preview(displayed_weapon)

## Turn order by current readiness only, while the CPU has not chosen a weapon.
## The rule (tie favours the other side) lives in TurnTable.current_order.
func current_order() -> Array:
	return model.current_order()

## State the HUD draws from; HudArt never reads game.gd internals directly.
func hud_state() -> Dictionary:
	return {"power": power, "angle": hud.hud_angle(model, angle, weapon),
		"movement": model.movement_left / maxf(1.0, model.movement_budget()), "gold": maxi(0,int(model.actors[Match.PLAYER].gold_state.gold)), "queue": queue_entries,
		"player_name": profile.nickname, "weapon": weapon, "aim": angle, "paused_cpu": false}

func _unhandled_key_input(event: InputEvent) -> void:
	if screen == "shop":
		return
	if not event is InputEventKey or event.echo:
		return
	if event.pressed and event.physical_keycode == KEY_ESCAPE:
		if overlay_kind == "options":
			accept_options()
		elif overlay_kind == "items":
			accept_items()
		elif overlay != null:
			if overlay_kind != "result":
				close_overlay()
		elif screen == "match":
			show_options()
		return
	if event.pressed and event.physical_keycode == KEY_P and screen == "match" and overlay_kind in ["", "options"]:
		show_pause()
		return
	if event.pressed and event.physical_keycode == KEY_H:
		show_help()
		return
	# F1–F6 press the item buttons (extra; also queues on the other turn).
	if event.pressed and screen == "match" and overlay == null and event.physical_keycode >= KEY_F1 and event.physical_keycode <= KEY_F6:
		item_bar.key(self, event.physical_keycode - KEY_F1)
		return
	if not player_can_act():
		return
	if event.physical_keycode == KEY_SPACE:
		if event.pressed:
			begin_charge()
		else:
			release_charge()
	elif event.pressed:
		match event.physical_keycode:
			KEY_TAB: cycle_weapon()
			KEY_F8: pass_turn()
			KEY_1: select_weapon(0)
			KEY_2: select_weapon(1)
			KEY_3: select_weapon(2)
			KEY_F: flip()

## Full-screen layer that pauses the match and blocks the HUD below it.
func open_overlay(kind: String) -> Control:
	return overlays.open(self, kind)

func make_overlay(kind: String) -> Panel:
	return overlays.make(self, kind)

func close_overlay() -> void:
	overlays.close(self)

func show_help() -> void:
	overlays.show_help(self)

func show_options() -> void:
	overlays.show_options(self)

func apply_options() -> void:
	sound.set_volume(options.sfx / 100.0)
	sound.set_music_volume(options.bgm / 100.0)
	queue_redraw()

func accept_options() -> void:
	options.save_options()
	close_overlay()

func show_items() -> void:
	overlays.show_items(self)

func items_label() -> String:
	return "Itens (%d/6)" % Items.used_slots(options.items)

## Closing the popup keeps the menu (and the nickname being typed) in place.
func accept_items() -> void:
	options.items = Items.sanitize(options.items)
	options.save_options()
	close_overlay()
	if is_instance_valid(items_button):
		items_button.text = items_label()

func show_pause() -> void:
	overlays.show_pause(self)

func show_result() -> void:
	overlays.show_result(self)

func _draw() -> void:
	if background == null:
		return
	if screen == "shop":
		draw_rect(Rect2(0,0,1280,800),Color("11223c"))
		return
	var backdrop: Dictionary = map_background(model.map_id) if screen != "menu" and model.terrain != null else {}
	if screen == "match" and not options.background:
		# PopupGameOptions "Background: Off" hides the map backdrop.
		draw_rect(Rect2(0, 0, 1280, 800), Color.BLACK)
	elif backdrop.is_empty():
		draw_texture_rect(background, Rect2(0, 0, 1280, 800), false)
	else:
		draw_texture_rect_region(backdrop.texture, Rect2(0, 0, 1280, 800), background_region(backdrop))
	if screen == "menu":
		draw_rect(Rect2(0, 0, 750, 800), Color(0.035, 0.13, 0.17, 0.30))
		draw_circle(Vector2(342, 617), 157.0, Color(0.93, 0.96, 0.87, 0.14))
		draw_arc(Vector2(342, 617), 169.0, 0.1, TAU - 0.4, 90, Color(0.78, 0.95, 0.88, 0.45), 1.5, true)
		draw_sprite(vehicle, Vector2(335, 662 + sin(elapsed * 1.6) * 5), 180.0, 1)
		return
	if model.terrain == null:
		return
	var offset := (Vector2(sin(elapsed * 81.0), cos(elapsed * 74.0)) * shake - camera).round()
	draw_set_transform(offset)
	if not model.terrain.map_id.is_empty():
		# Original map: HD foreground carries its own crater and blackmask pixels.
		if model.terrain.visual_texture != null:
			draw_texture_rect(model.terrain.visual_texture, model.terrain.visual_rect, false)
	else:
		draw_procedural_terrain()
	# Weather layers draw in world space with their own offset (identity canvas).
	draw_set_transform(Vector2.ZERO)
	weather_art.draw_columns(self, model, offset)
	weather_art.draw_thor(self, model, offset)
	draw_set_transform(offset)
	for index in range(model.actors.size()):
		art.draw_actor(self, model, index, offset, actor_context(index))
		if art.motion[index].pose == "using_item":
			var body = sprite_for(int(model.actors[index].vehicle))
			if body != null:
				item_art.draw_using(self, body, art.motion[index], int(model.actors[index].facing), offset)
	hud.draw_world(self, model, offset, hud_state())
	draw_set_transform(offset)
	for projectile in model.projectiles:
		if not projectile.launched:
			continue
		if bool(projectile.get("beacon", false)):
			item_art.draw_beacon(self, projectile, offset)
			draw_set_transform(offset)
			continue
		var shooter := int(model.actors[model.shot_actor].vehicle)
		var body = sprite_for(shooter)
		if body == null:
			continue
		# Each shell keeps its weapon (Dual+ mixes S1 and S2 in one turn).
		var shell_weapon := int(projectile.get("weapon", model.shot_weapon))
		var color: Color = model.weapon_rules(model.shot_actor, shell_weapon).color
		if Mobiles.generic_trail(shooter):
			var trail: Array = projectile.trail
			for index in range(1, trail.size()):
				draw_line(trail[index - 1], trail[index], Color(color, float(index) / trail.size() * 0.6), 2.0, true)
		body.draw_projectile(self, projectile, shell_weapon, offset)
		draw_set_transform(offset)
	draw_set_transform(Vector2.ZERO)
	weather_art.draw_shell_marks(self, model, offset)
	weather_art.draw_beams(self, offset)
	weather_art.draw_particles(self, offset)
	draw_set_transform(offset)
	for effect in effects:
		var body = sprite_for(int(effect.get("vehicle", -1)))
		if body != null:
			body.draw_effect(self, effect, offset)
	item_art.draw_flames(self, offset)
	draw_set_transform(offset)
	for item in floating:
		var pos: Vector2 = item.pos + Vector2(-22, -70 - float(item.age) * 34.0)
		draw_string_outline(ui.bold, pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 5, Color(0.05, 0.12, 0.18, 1.0 - float(item.age) / 1.5))
		draw_string(ui.bold, pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(item.color, 1.0 - float(item.age) / 1.5))
	draw_set_transform(Vector2.ZERO)
	draw_offscreen_markers()
	hud.draw_screen(self, model, hud_state())

func draw_procedural_terrain() -> void:
	draw_texture_rect(model.terrain.texture, Rect2(0, 0, 1280, 800), false)
	# Small vegetation details follow the current collision surface.
	for x in range(48, 1240, 31):
		var y: float = model.terrain.surface_at(x)
		if y > 610.0:
			continue
		draw_line(Vector2(x, y), Vector2(x - 3, y - 7), Color("4b8050"), 2.0, true)
		if x % 3 == 0:
			draw_circle(Vector2(x - 3, y - 8), 2.2, Color("f4d5b2"))

func draw_offscreen_markers() -> void:
	# Edge arrows for actors the camera does not show, so the target is never lost.
	var view := Rect2(Vector2.ZERO, VIEW_SIZE)
	for index in range(model.actors.size()):
		var actor: Dictionary = model.actors[index]
		var screen_pos: Vector2 = Vector2(actor.pos) - camera
		if int(actor.hp) <= 0 or view.grow(-10).has_point(screen_pos):
			continue
		var edge := Vector2(clampf(screen_pos.x, 34.0, VIEW_SIZE.x - 34.0), clampf(screen_pos.y, 74.0, VIEW_SIZE.y - 30.0))
		var direction := (screen_pos - edge).normalized()
		if direction == Vector2.ZERO:
			continue
		var tint: Color = Match.VEHICLES[actor.vehicle].color
		var tip := edge + direction * 16.0
		var side := direction.orthogonal() * 10.0
		draw_colored_polygon(PackedVector2Array([tip, edge - side, edge + side]), tint)
		draw_polyline(PackedVector2Array([tip, edge - side, edge + side, tip]), ui.INK, 2.0, true)
		var label := "%s · %dm" % ["Você" if index == Match.PLAYER else "Autômato", int(screen_pos.distance_to(edge) / 10.0)]
		var width: float = ui.bold.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var text_pos := edge - direction * 22.0 + Vector2(-width * 0.5, 5)
		text_pos.x = clampf(text_pos.x, 8.0, VIEW_SIZE.x - width - 8.0)
		draw_string_outline(ui.bold, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, ui.INK)
		draw_string(ui.bold, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint.lightened(0.25))

func map_background(id: String) -> Dictionary:
	# HD stitched file first, original Background.png otherwise; source = covered original pixels.
	if id.is_empty():
		return {}
	if not map_backgrounds.has(id):
		var map: Dictionary = Maps.get_map(id)
		var entry := {}
		if ResourceLoader.exists(map.background_hd):
			var hd: Texture2D = load(map.background_hd)
			var source: Rect2 = map.background_hd_source
			entry = {"texture": hd, "source": source, "density": float(hd.get_width()) / source.size.x}
		elif ResourceLoader.exists(map.background):
			var original: Texture2D = load(map.background)
			entry = {"texture": original, "source": Rect2(Vector2.ZERO, original.get_size()), "density": 1.0}
		map_backgrounds[id] = entry
	return map_backgrounds[id]

func background_region(backdrop: Dictionary) -> Rect2:
	# LevelScene parallax: the 1.6:1 window slides across the background as the
	# camera crosses its range, limited to the pixels the file covers.
	var source: Rect2 = backdrop.source
	var window := Vector2(source.size.x, source.size.x / 1.6)
	if window.y > source.size.y:
		window = Vector2(source.size.y * 1.6, source.size.y)
	var limits := camera_limits()
	var fraction := Vector2.ZERO
	if limits.size.x > 0.0:
		fraction.x = (camera.x - limits.position.x) / limits.size.x
	if limits.size.y > 0.0:
		fraction.y = (camera.y - limits.position.y) / limits.size.y
	var top_left := source.position + (source.size - window) * fraction
	return Rect2((top_left - source.position) * float(backdrop.density), window * float(backdrop.density))

func camera_limits() -> Rect2:
	return rig.limits(model.terrain if model != null else null)

func clamp_camera(value: Vector2) -> Vector2:
	return rig.fit(model.terrain if model != null else null, value)

func camera_goal() -> Vector2:
	return rig.goal(model)

func update_camera(delta: float) -> void:
	rig.update(delta, model)

## Drag aiming sees the motion and the release before the HUD, so letting go
## over the action bar (or a lost release) still ends the drag.
func _input(event: InputEvent) -> void:
	if not (charging and drag_aiming):
		return
	if event is InputEventMouseMotion:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			release_drag()
		else:
			update_drag(event.position.x, event.relative.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release_drag()

func _unhandled_input(event: InputEvent) -> void:
	if screen != "match" or overlay != null:
		return
	# Drag mode: a left press in the world during the player's aim starts the shot.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and options.drag_aiming() and player_can_act() and event.position.y < VIEW_SIZE.y:
		begin_drag(event.position.x)
		dragging = false
		return
	# Drag the world (mouse or touch) to look around; tracking resumes next turn or shot.
	if camera_limits().size == Vector2.ZERO:
		return
	# Touch is emulated as mouse by default; handle only one source to avoid double panning.
	var touch_as_mouse: bool = ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		# The right (or middle) button always looks around; Drag mode needs it.
		dragging = event.pressed and event.position.y < VIEW_SIZE.y
		pan_mask = {MOUSE_BUTTON_LEFT: MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_RIGHT: MOUSE_BUTTON_MASK_RIGHT, MOUSE_BUTTON_MIDDLE: MOUSE_BUTTON_MASK_MIDDLE}[event.button_index]
	elif event is InputEventScreenTouch and not touch_as_mouse:
		dragging = event.pressed and event.position.y < VIEW_SIZE.y
	elif event is InputEventMouseMotion and dragging:
		# A release consumed by the HUD must not leave the drag stuck on.
		if not (event.button_mask & pan_mask):
			dragging = false
			return
		camera_manual = true
		camera = clamp_camera(camera - event.relative * options.scroll_factor())
	elif event is InputEventScreenDrag and dragging and not touch_as_mouse:
		camera_manual = true
		camera = clamp_camera(camera - event.relative * options.scroll_factor())

func draw_sprite(kind: int, pos: Vector2, width: float, facing: int, rotation: float = 0.0, _scale_amount: Vector2 = Vector2.ONE, color: Color = Color.WHITE) -> void:
	var body = sprite_for(kind)
	if body == null:
		return
	body.draw(self, pos, width, facing, rotation, body.frame_index("idle", elapsed, 0, false), color, "idle", elapsed, 0, false, 0, {"equipment":profile.equipped_set(),"age":elapsed})
