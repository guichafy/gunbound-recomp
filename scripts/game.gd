extends Node2D
## Presentation and input. Combat outcomes belong exclusively to MatchModel.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Profile = preload("res://scripts/profile.gd")
const UIFactory = preload("res://scripts/ui.gd")
const Sound = preload("res://scripts/sound.gd")
const BattleArt = preload("res://scripts/battle_art.gd")
const BigfootSprite = preload("res://scripts/bigfoot_sprite.gd")
const MageSprite = preload("res://scripts/mage_sprite.gd")
const Maps = preload("res://scripts/maps.gd")
const WeatherArt = preload("res://scripts/weather_art.gd")
const HudArt = preload("res://scripts/hud_art.gd")
const Options = preload("res://scripts/options.gd")
const OptionsPopup = preload("res://scripts/options_popup.gd")
var hud = HudArt.new()
var weather_art = WeatherArt.new()
var mage = MageSprite.new()
var bigfoot = BigfootSprite.new()
var art = BattleArt.new()
var ui = UIFactory.new()
var model = Match.new()
var profile = Profile.new()
# PopupGameOptions values; saved next to the profile (tests isolate both).
var options
var options_popup: Control
var sound
var screen := "menu"
var root: Control
var overlay: Control
var overlay_kind := ""
var background: Texture2D
var map_backgrounds := {}
# Camera: top-left world point of the view above the HUD (Camera.cs tracking 1/25).
const VIEW_SIZE := Vector2(1280, 664)
const CAMERA_DAMPENING := 25.0
var camera := Vector2.ZERO
var camera_manual := false
var dragging := false
var last_impact := Vector2.INF
var nickname_input: LineEdit
var vehicle := 2
var cpu_difficulty := 1
# Training option: the map's original weather preset or every effect (Thor included).
var weather_mode := "original"
var vehicle_buttons: Array[Button] = []
var vehicle_info: Label
var angle := 45.0
var power := 65.0
var weapon := 0
var charging := false
var paused := false
var elapsed := 0.0
var cpu_wait := 0.0
var cpu_plan: Dictionary = {}
# CPU aim search on a worker thread (REQ-32): starts with the CPU turn on a
# snapshot; cpu_plan only appears when it is done and the initial wait is over.
var cpu_search: Dictionary = {}
var cpu_task := -1
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
var charge_timer := 0.0
# Crosshair.UpdateShootingAngle key repeat: 0.15 s, −0.008 per step, minimum 0.03 s.
var aim_direction := 0
var aim_elapsed := 0.0
var aim_limit := 0.15

func _ready() -> void:
	# HUD HD sprites (3×) are drawn smaller than their pixels; mipmaps keep 1 px borders.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background = load("res://assets/art/background.png")
	profile.load_profile()
	if options == null:
		options = Options.new(profile.path.get_basename() + "-options.json")
		options.load_options()
	sound = Sound.new()
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
	result_wait = -1.0
	effects.clear()
	floating.clear()
	replace_root()
	var tag := ui.label(root, "TREINO DE ARTILHARIA   /   0.10.1", Vector2(80, 74), Vector2(530, 24), 14, ui.TEAL, true)
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
		var button := ui.button(card, Match.VEHICLES[index].name, Vector2(28 + slot * 186, 246), Vector2(178, 48), func(): select_vehicle(index))
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
	var weather_button := ui.button(card, weather_label(), Vector2(28, 438), Vector2(364, 34), func(): pass)
	weather_button.add_theme_font_size_override("font_size", 14)
	weather_button.tooltip_text = "Original: pesos do mapa (Miramo A não tem Thor, Espelho nem Fraqueza).\nTodos: pesos iguais para todos os climas, Thor incluído."
	weather_button.pressed.connect(func():
		weather_mode = "all" if weather_mode == "original" else "original"
		weather_button.text = weather_label()
	)
	ui.button(card, "INICIAR TREINO    →", Vector2(28, 484), Vector2(364, 52), start_match, true)
	ui.label(card, "NÍVEL %d    ·    %d XP    ·    %d VITÓRIAS" % [profile.level(), profile.xp, profile.wins], Vector2(28, 555), Vector2(364, 26), 13, ui.MUTED, true)
	ui.button(root, "Como jogar", Vector2(1030, 754), Vector2(190, 30), show_help)
	select_vehicle(vehicle)
	queue_redraw()

func weather_label() -> String:
	return "Clima: " + ("original do mapa" if weather_mode == "original" else "todos os efeitos (Thor)")

func select_vehicle(index: int) -> void:
	index = Match.normalize_vehicle(index)
	vehicle = index
	for j in range(vehicle_buttons.size()):
		vehicle_buttons[j].add_theme_stylebox_override("normal", ui.box(Color("32666b") if Match.PLAYABLE_VEHICLES[j] == index else Color("24444e"), 9, ui.TEAL if Match.PLAYABLE_VEHICLES[j] == index else Color("47626a")))
	var data: Dictionary = Match.VEHICLES[index]
	var description := "220 de escudo · duplo laser e especial EMP." if index == 1 else "T1: 4 bombas · T2: 6 · SS: 8 bombas."
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), description]
	queue_redraw()

func start_match() -> void:
	if screen == "menu" and is_instance_valid(nickname_input):
		profile.nickname = profile.clean_nickname(nickname_input.text)
		profile.save_profile()
	screen = "match"
	model.start(vehicle, cpu_difficulty, -1, Maps.DEFAULT, weather_mode)
	art.reset(model.actors)
	camera_manual = false
	dragging = false
	last_impact = Vector2.INF
	camera = clamp_camera(camera_goal())
	weather_art.reset(Maps.get_map(model.map_id))
	match_id = str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())
	reward = 0
	result_wait = -1.0
	angle = clampf(45.0, model.aim_limits(0).x, model.aim_limits(0).y)
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
		button.tooltip_text = "%s · atraso %d" % [model.weapon_rules(0, index).name, model.weapon_rules(0, index).delay]
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
	select_weapon(0)

func displayed_queue() -> Array:
	return queue_entries

func animation_state(index: int) -> String:
	return art.state_name(model, index, charging, model.phase == "aim" and model.active == 1 and not cpu_plan.is_empty())

func player_can_act() -> bool:
	return screen == "match" and model.phase == "aim" and model.active == 0 and not paused

func select_weapon(index: int) -> void:
	if screen != "match" or not player_can_act():
		return
	if index == 2 and not model.can_use_special(0):
		return
	weapon = index
	var limits: Vector2 = model.aim_limits(0, weapon)
	angle = clampf(angle, limits.x, limits.y)
	for j in range(weapon_buttons.size()):
		hud.style_button(weapon_buttons[j], j == index)

func cycle_weapon() -> void:
	# ShotButton.UpdateKeyboard: Tab moves to the next shot, skipping a disabled SS.
	var next := (weapon + 1) % 3
	if next == 2 and not model.can_use_special(0):
		next = 0
	select_weapon(next)

func begin_charge() -> void:
	# Mobile.Shoot: Space resets the strength bar and starts the shot sequence.
	if player_can_act():
		charging = true
		power = 0.0
		charge_timer = 0.0

func release_charge() -> void:
	if charging:
		shoot()

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
		model.actors[0].facing *= -1

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
		if charging:
			# TimedProgressBar: +2 every 0.04 s while held; full bar fires.
			charge_timer += frame_delta
			while charge_timer > 0.04 and power < 100.0:
				charge_timer -= 0.04
				power = minf(100.0, power + 2.0)
			if power >= 100.0:
				shoot()
	hud.tick(frame_delta, model, sound)
	model.tick(frame_delta)
	weather_art.tick(frame_delta, model)
	art.tick(model, frame_delta, charging, weapon, model.phase == "aim" and model.active == 1 and not cpu_plan.is_empty(), int(cpu_plan.get("weapon", 0)))
	consume_events()
	if model.phase == "aim" and model.active == 1:
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
	# Whole-degree steps: one per press, then a repeat that speeds up while held.
	var direction := 0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction = 1
	elif Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction = -1
	if direction != aim_direction:
		aim_direction = direction
		aim_elapsed = 0.0
		aim_limit = 0.15
		if direction != 0:
			step_angle(direction)
		return
	if direction == 0:
		return
	aim_elapsed += delta
	if aim_elapsed > aim_limit:
		aim_elapsed = 0.0
		aim_limit = maxf(aim_limit - 0.008, 0.03)
		step_angle(direction)

func step_angle(direction: int) -> void:
	var limits: Vector2 = model.aim_limits(0, weapon)
	angle = clampf(roundf(angle) + direction, limits.x, limits.y)

func consume_events() -> void:
	for event in model.events:
		art.react(event)
		hud.react(event, model)
		weather_art.react(event, model, sound)
		match event.type:
			"turn":
				camera_manual = false
				last_impact = Vector2.INF
				charging = false
				cpu_plan.clear()
				discard_cpu_search()
				cpu_wait = 1.1
				if event.actor == 0:
					# HUD.GrantTurn resets the strength bar; the marker keeps the last shot.
					power = 0.0
				sound.play("turn")
				if weapon == 2 and not model.can_use_special(0):
					weapon = 0
			"fire":
				camera_manual = false
				if model.actors[event.actor].vehicle != 2:
					sound.play("fire", mage.shoot_sounds[event.weapon])
			"projectile_launch":
				if event.vehicle == 2:
					sound.play("fire", bigfoot.shoot_sounds[event.weapon])
			"explosion":
				last_impact = event.position
				effects.append({"pos": event.position, "radius": event.radius, "weapon": event.weapon, "vehicle": event.get("vehicle", 2), "age": 0.0})
				shake = 7.0
				var original: AudioStream = null
				if event.get("vehicle", 2) in [1, 2]:
					original = (mage if event.vehicle == 1 else bigfoot).blast_sounds[event.weapon]
				sound.play("explosion", original)
			"fall":
				floating.append({"pos": Vector2(model.actors[event.actor].pos.x, minf(float(model.actors[event.actor].pos.y), model.terrain.world_size().y) - 80.0), "text": "QUEDA!", "age": 0.0, "color": Color("ffbc79")})
			"finished":
				charging = false
				reward = profile.award(match_id, model.winner == 0, model.winner == -1)
				result_wait = 1.7
				sound.play("result")
	model.events.clear()

func update_hud() -> void:
	if screen != "match":
		return
	var limits: Vector2 = model.aim_limits(0, weapon)
	angle = clampf(angle, limits.x, limits.y)
	var enabled := player_can_act()
	pass_button.disabled = not enabled
	flip_button.disabled = not enabled
	move_left.disabled = not enabled
	move_right.disabled = not enabled
	fire_button.disabled = not enabled
	for index in range(weapon_buttons.size()):
		var button: TextureButton = weapon_buttons[index]
		button.disabled = index == 2 and not model.can_use_special(0)
		if bool(button.get_meta("activated")) != (index == weapon):
			hud.style_button(button, index == weapon)
	weapon_buttons[2].tooltip_text = "%s: terceiro turno próprio; um uso por partida." % model.weapon_rules(0, 2).name
	var displayed_weapon: int = weapon if model.active == 0 else int(cpu_plan.get("weapon", 0))
	if model.phase == "finished":
		queue_entries = []
	elif model.phase == "aim" and model.active == 1 and cpu_plan.is_empty():
		queue_entries = current_order()
	else:
		queue_entries = model.initiative_preview(displayed_weapon)

## Turn order by current readiness only, while the CPU has not chosen a weapon.
func current_order() -> Array:
	var entries: Array = []
	for index in range(2):
		entries.append({"actor": index, "ready": float(model.actors[index].ready), "delay": maxf(0.0, float(model.actors[index].ready) - model.clock)})
	entries.sort_custom(func(a, b): return a.ready < b.ready or (is_equal_approx(a.ready, b.ready) and a.actor == model.active))
	return entries

## State the HUD draws from; HudArt never reads game.gd internals directly.
func hud_state() -> Dictionary:
	return {"power": power, "angle": hud.hud_angle(model, angle, weapon),
		"movement": model.movement_left / maxf(1.0, model.movement_budget()), "gold": reward, "queue": queue_entries,
		"player_name": profile.nickname, "weapon": weapon, "aim": angle, "paused_cpu": false}

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	if event.pressed and event.physical_keycode == KEY_ESCAPE:
		if overlay_kind == "options":
			accept_options()
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
	if overlay_kind == "options" and kind != "options":
		# Leaving the popup for the pause or help keeps its values like Accept.
		options.save_options()
	if is_instance_valid(overlay):
		root.remove_child(overlay)
		overlay.queue_free()
	charging = false
	paused = true
	overlay_kind = kind
	overlay = Control.new()
	overlay.size = Vector2(1280, 800)
	root.add_child(overlay)
	options_popup = null
	if is_instance_valid(options_button):
		options_button.disabled = kind == "options"
	return overlay

func make_overlay(kind: String) -> Panel:
	open_overlay(kind)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 800)
	shade.color = Color(0.025, 0.09, 0.12, 0.73)
	overlay.add_child(shade)
	return ui.panel(overlay, Vector2(360, 155), Vector2(560, 490), ui.INK, 22)

func close_overlay() -> void:
	if is_instance_valid(overlay):
		root.remove_child(overlay)
		overlay.queue_free()
	overlay = null
	overlay_kind = ""
	options_popup = null
	paused = false
	if is_instance_valid(options_button):
		options_button.disabled = false
	if screen == "match" and model.phase == "finished":
		show_result()

func show_help() -> void:
	var card := make_overlay("help")
	ui.label(card, "Como jogar", Vector2(32, 25), Vector2(490, 50), 32, ui.CREAM, true)
	var lines := ["← / → ou A / D        Mover o veículo", "↑ / ↓ ou W / S        Ângulo, 1° por toque", "ESPAÇO                  Segurar carrega a barra; soltar dispara", "TAB  ou  1 / 2 / 3    Trocar o tiro (S1, S2, SS)", "F8                           Passar o turno", "ESC  /  P                 Opções  /  pausa", "Arrastar a tela        Olhar o mapa; F vira parado"]
	for index in range(lines.size()):
		ui.label(card, lines[index], Vector2(32, 92 + index * 34), Vector2(500, 32), 17)
	ui.label(card, "Vento 2D e clima mudam a cada rodada (ícones no topo). Colunas\nalteram o tiro: Força, Fraqueza, Espelho, Tornado, Elétrico; Thor\natinge o impacto. Zere a vida ou derrube o adversário para vencer.", Vector2(32, 336), Vector2(500, 70), 14, ui.MUTED)
	ui.button(card, "ENTENDI", Vector2(32, 424), Vector2(496, 42), close_overlay, true)

## PopupGameOptions (HUD.cs GameOptionsOnClickAction): ESC/Options open it, Accept
## or ESC save and close. It pauses the training match; "PAUSA" or P open the pause.
func show_options() -> void:
	if screen != "match" or model.phase == "finished":
		return
	var layer := open_overlay("options")
	options_popup = OptionsPopup.new(options)
	options_popup.changed.connect(apply_options)
	options_popup.accepted.connect(accept_options)
	layer.add_child(options_popup)
	var pause_size := Vector2(84, 30)
	var pause := ui.button(options_popup, "PAUSA", options_popup.point(OptionsPopup.PAUSE_OFFSET) - pause_size * 0.5, pause_size, show_pause)
	pause.add_theme_font_size_override("font_size", 13)
	pause.modulate = Color(1, 1, 1, 0.82)
	pause.tooltip_text = "Pausa, recomeçar ou voltar ao menu (P)"

func apply_options() -> void:
	sound.set_volume(options.sfx / 100.0)
	queue_redraw()

func accept_options() -> void:
	# PopupGameOptions.CloseAction: overwrite the client settings file.
	options.save_options()
	close_overlay()

func show_pause() -> void:
	if screen != "match" or model.phase == "finished":
		return
	var card := make_overlay("pause")
	ui.label(card, "Uma pausa no combate.", Vector2(32, 27), Vector2(496, 55), 30, ui.CREAM, true)
	ui.label(card, "A partida e o relógio estão pausados.", Vector2(32, 91), Vector2(496, 35), 17, ui.MUTED)
	ui.button(card, "CONTINUAR", Vector2(32, 160), Vector2(496, 48), close_overlay, true)
	ui.button(card, "Como jogar", Vector2(32, 226), Vector2(240, 45), show_help)
	ui.button(card, "Som: " + ("ligado" if not sound.muted else "desligado"), Vector2(288, 226), Vector2(240, 45), func(): sound.muted = not sound.muted; show_pause())
	ui.button(card, "Recomeçar treino", Vector2(32, 300), Vector2(496, 45), start_match)
	ui.button(card, "Voltar ao menu", Vector2(32, 366), Vector2(496, 45), show_menu)
	ui.label(card, "Seu progresso de partidas concluídas fica salvo.", Vector2(32, 438), Vector2(496, 28), 14, ui.MUTED)

func show_result() -> void:
	if screen != "match" or model.phase != "finished":
		return
	var card := make_overlay("result")
	var result := "VITÓRIA!" if model.winner == 0 else ("EMPATE" if model.winner == -1 else "A MÁQUINA VENCEU")
	ui.label(card, "TREINO CONCLUÍDO", Vector2(32, 24), Vector2(496, 24), 12, ui.TEAL, true)
	ui.label(card, result, Vector2(32, 72), Vector2(496, 65), 38, ui.CREAM, true)
	ui.label(card, "Boa mira, %s." % profile.nickname if model.winner == 0 else "Cada cratera ensina. Tente uma nova trajetória.", Vector2(32, 145), Vector2(496, 45), 17, ui.MUTED)
	ui.panel(card, Vector2(32, 215), Vector2(496, 92), Color("23454d"), 12)
	ui.label(card, "+%d XP" % reward, Vector2(53, 230), Vector2(215, 35), 28, ui.TEAL, true)
	ui.label(card, "NÍVEL %d   ·   %d XP TOTAL" % [profile.level(), profile.xp], Vector2(53, 270), Vector2(450, 24), 14, ui.CREAM)
	ui.label(card, "%d turnos  ·  %s" % [model.total_turns, "progresso salvo neste Mac" if profile.last_save_ok else "não foi possível salvar o progresso"], Vector2(32, 324), Vector2(496, 35), 14, ui.MUTED)
	ui.button(card, "REVANCHE", Vector2(32, 386), Vector2(496, 47), start_match, true)
	ui.button(card, "Voltar ao menu", Vector2(32, 444), Vector2(496, 33), show_menu)

func _draw() -> void:
	if background == null:
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
		art.draw_actor(self, index, offset)
	hud.draw_world(self, model, offset, hud_state())
	draw_set_transform(offset)
	for projectile in model.projectiles:
		if not projectile.launched:
			continue
		var color: Color = model.weapon_rules(model.shot_actor, model.shot_weapon).color
		if model.actors[model.shot_actor].vehicle == 1:
			mage.draw_projectile(self, projectile, model.shot_weapon, offset)
			draw_set_transform(offset)
			continue
		var trail: Array = projectile.trail
		for index in range(1, trail.size()):
			draw_line(trail[index - 1], trail[index], Color(color, float(index) / trail.size() * 0.6), 2.0, true)
		if model.actors[model.shot_actor].vehicle == 2:
			bigfoot.draw_projectile(self, projectile, model.shot_weapon, offset)
			draw_set_transform(offset)
			continue
	draw_set_transform(Vector2.ZERO)
	weather_art.draw_shell_marks(self, model, offset)
	weather_art.draw_beams(self, offset)
	weather_art.draw_particles(self, offset)
	draw_set_transform(offset)
	for effect in effects:
		if effect.get("vehicle", 0) == 1:
			mage.draw_effect(self, effect, offset)
		elif effect.get("vehicle", 0) == 2:
			bigfoot.draw_effect(self, effect, offset)
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
		var label := "%s · %dm" % ["Você" if index == 0 else "Autômato", int(screen_pos.distance_to(edge) / 10.0)]
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
	# Position range of the camera; a world that fits the screen stays fixed.
	if model.terrain == null:
		return Rect2()
	var world: Vector2 = model.terrain.world_size()
	if world.x <= 1280.0 and world.y <= 800.0:
		return Rect2()
	var low := Vector2(minf(0.0, (world.x - VIEW_SIZE.x) * 0.5), 0.0)
	var high := Vector2(maxf(0.0, world.x - VIEW_SIZE.x), maxf(0.0, world.y - VIEW_SIZE.y))
	if world.x < VIEW_SIZE.x:
		high.x = low.x
	return Rect2(low, high - low)

func clamp_camera(value: Vector2) -> Vector2:
	var limits := camera_limits()
	return Vector2(clampf(value.x, limits.position.x, limits.end.x), clampf(value.y, limits.position.y, limits.end.y))

func camera_goal() -> Vector2:
	# Follow the shell in flight, then its impact, otherwise the active actor.
	var focus: Vector2 = model.actors[model.active].pos + Vector2(0, -60) if not model.actors.is_empty() else Vector2.ZERO
	if model.phase == "flight":
		for projectile in model.projectiles:
			if bool(projectile.launched):
				focus = projectile.pos
				break
	elif model.phase in ["settle", "finished"] and last_impact != Vector2.INF:
		focus = last_impact
	return focus - VIEW_SIZE * 0.5

func update_camera(delta: float) -> void:
	if not camera_manual:
		var follow := 1.0 - pow(1.0 - 1.0 / CAMERA_DAMPENING, delta * 60.0)
		camera = camera.lerp(clamp_camera(camera_goal()), follow)
	camera = clamp_camera(camera)

func _unhandled_input(event: InputEvent) -> void:
	# Drag the world (mouse or touch) to look around; tracking resumes next turn or shot.
	if screen != "match" or overlay != null or camera_limits().size == Vector2.ZERO:
		return
	# Touch is emulated as mouse by default; handle only one source to avoid double panning.
	var touch_as_mouse: bool = ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed and event.position.y < VIEW_SIZE.y
	elif event is InputEventScreenTouch and not touch_as_mouse:
		dragging = event.pressed and event.position.y < VIEW_SIZE.y
	elif event is InputEventMouseMotion and dragging:
		# A release consumed by the HUD must not leave the drag stuck on.
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			dragging = false
			return
		camera_manual = true
		camera = clamp_camera(camera - event.relative * options.scroll_factor())
	elif event is InputEventScreenDrag and dragging and not touch_as_mouse:
		camera_manual = true
		camera = clamp_camera(camera - event.relative * options.scroll_factor())

func draw_sprite(kind: int, pos: Vector2, width: float, facing: int, rotation: float = 0.0, _scale_amount: Vector2 = Vector2.ONE, color: Color = Color.WHITE) -> void:
	if kind == 1:
		mage.draw(self, pos, width, facing, rotation, mage.frame_index("idle", elapsed, 0, false), color)
		return
	if kind == 2:
		bigfoot.draw(self, pos, width, facing, rotation, bigfoot.frame_index("idle", elapsed, 0, false), color)
		return
