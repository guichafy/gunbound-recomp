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
var mage = MageSprite.new()
var bigfoot = BigfootSprite.new()
var art = BattleArt.new()
var ui = UIFactory.new()
var model = Match.new()
var profile = Profile.new()
var sound
var screen := "menu"
var root: Control
var overlay: Control
var overlay_kind := ""
var background: Texture2D
var map_backgrounds := {}
var nickname_input: LineEdit
var vehicle := 2
var cpu_difficulty := 1
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
var match_id := ""
var reward := 0
var result_wait := -1.0
var effects: Array = []
var floating: Array = []
var shake := 0.0
var banner_time := 0.0
var banner_text := ""
var angle_label: Label
var power_label: Label
var angle_slider: HSlider
var power_slider: HSlider
var fire_button: Button
var pass_button: Button
var flip_button: Button
var move_left: Button
var move_right: Button
var weapon_buttons: Array[Button] = []
var health_bars: Array[ProgressBar] = []
var shield_bars: Array[ProgressBar] = []
var hp_labels: Array[Label] = []
var wind_label: Label
var timer_label: Label
var turn_label: Label
var movement_label: Label
var delay_label: Label
var shot_hint: Label
var power_meter: ProgressBar
var movement_meter: ProgressBar
var force_marks: Node2D
var queue_labels: Array[Label] = []
var queue_entries: Array = []
var queue_panel: Panel
var queue_title: Label
var queue_detail: Label

func _ready() -> void:
	background = load("res://assets/art/background.png")
	profile.load_profile()
	sound = Sound.new()
	add_child(sound)
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
	paused = false
	charging = false

func show_menu() -> void:
	screen = "menu"
	model.phase = "menu"
	result_wait = -1.0
	effects.clear()
	floating.clear()
	replace_root()
	var tag := ui.label(root, "TREINO DE ARTILHARIA   /   0.8.1", Vector2(80, 74), Vector2(530, 24), 14, ui.TEAL, true)
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
	ui.label(card, "DIFICULDADE DA MÁQUINA", Vector2(28, 372), Vector2(364, 22), 12, ui.TEAL, true)
	var difficulty_buttons: Array[Button] = []
	for index in range(3):
		var button := ui.button(card, ["Leve", "Normal", "Precisa"][index], Vector2(28 + index * 124, 405), Vector2(116, 42), func():
			cpu_difficulty = index
			for j in range(difficulty_buttons.size()):
				difficulty_buttons[j].add_theme_stylebox_override("normal", ui.box(Color("32666b") if j == index else Color("24444e"), 9, ui.TEAL if j == index else Color("47626a")))
		)
		difficulty_buttons.append(button)
		if index == cpu_difficulty:
			button.add_theme_stylebox_override("normal", ui.box(Color("32666b"), 9, ui.TEAL))
	ui.button(card, "INICIAR TREINO    →", Vector2(28, 481), Vector2(364, 56), start_match, true)
	ui.label(card, "NÍVEL %d    ·    %d XP    ·    %d VITÓRIAS" % [profile.level(), profile.xp, profile.wins], Vector2(28, 555), Vector2(364, 26), 13, ui.MUTED, true)
	ui.button(root, "Como jogar", Vector2(1030, 754), Vector2(190, 30), show_help)
	select_vehicle(vehicle)
	queue_redraw()

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
	model.start(vehicle, cpu_difficulty)
	art.reset(model.actors)
	match_id = str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())
	reward = 0
	result_wait = -1.0
	angle = clampf(45.0, model.aim_limits(0).x, model.aim_limits(0).y)
	power = 65.0
	weapon = 0
	charging = false
	cpu_plan.clear()
	effects.clear()
	floating.clear()
	replace_root()
	build_hud()
	consume_events()
	update_hud()

func build_hud() -> void:
	# The arena stays open; instruments are grouped in the classic lower console.
	health_bars.clear()
	shield_bars.clear()
	hp_labels.clear()
	for index in range(2):
		var actor: Dictionary = model.actors[index]
		var bar := make_meter(root, Vector2.ZERO, Vector2(96, 7), float(actor.max_hp), Match.VEHICLES[actor.vehicle].color)
		health_bars.append(bar)
		shield_bars.append(make_meter(root, Vector2.ZERO, Vector2(96, 5), maxf(1, actor.max_shield), Color("94baff")))
		var hp := ui.label(root, "", Vector2.ZERO, Vector2(174, 19), 12, Color.WHITE, true)
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp.add_theme_color_override("font_outline_color", ui.INK)
		hp.add_theme_constant_override("outline_size", 4)
		hp_labels.append(hp)
	wind_label = ui.label(root, "", Vector2(590, 111), Vector2(100, 25), 18, ui.INK, true)
	wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label = ui.label(root, "30", Vector2(1153, 20), Vector2(94, 64), 48, ui.AMBER, true)
	timer_label.add_theme_color_override("font_outline_color", ui.INK)
	timer_label.add_theme_constant_override("outline_size", 5)
	ui.label(root, "Tempo", Vector2(1160, 86), Vector2(85, 21), 13, ui.INK, true)
	turn_label = ui.label(root, "", Vector2(408, 135), Vector2(570, 28), 16, ui.CREAM, true)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_color_override("font_outline_color", ui.INK)
	turn_label.add_theme_constant_override("outline_size", 4)
	ui.button(root, "?", Vector2(18, 18), Vector2(38, 32), show_help)
	ui.button(root, "Ⅱ", Vector2(64, 18), Vector2(38, 32), show_pause)
	queue_panel = ui.metal_panel(root, Vector2(16, 544), Vector2(236, 114), Color("193650"))
	queue_title = ui.label(queue_panel, "", Vector2(13, 6), Vector2(216, 22), 13, ui.AMBER, true)
	queue_labels.clear()
	for row in range(2):
		queue_labels.append(ui.label(queue_panel, "", Vector2(14, 34 + row * 29), Vector2(212, 25), 14, ui.CREAM, true))
	queue_detail = ui.label(queue_panel, "", Vector2(13, 91), Vector2(213, 18), 11, ui.MUTED)
	ui.metal_panel(root, Vector2(0, 670), Vector2(1280, 130), Color("507498"))
	ui.metal_panel(root, Vector2(8, 678), Vector2(202, 113), Color("234564"))
	ui.label(root, "Armas", Vector2(20, 683), Vector2(180, 22), 13, ui.CREAM, true)
	weapon_buttons.clear()
	for index in range(3):
		var button := ui.button(root, ["1", "2", "SS"][index], Vector2(20 + index * 61, 711), Vector2(55, 42), func(): select_weapon(index))
		button.add_theme_font_size_override("font_size", 23)
		button.tooltip_text = "%s · atraso %d" % [model.weapon_rules(0, index).name, model.weapon_rules(0, index).delay]
		weapon_buttons.append(button)
	delay_label = ui.label(root, "", Vector2(20, 763), Vector2(180, 21), 12, ui.AMBER, true)
	ui.metal_panel(root, Vector2(218, 678), Vector2(180, 113), Color("234564"))
	angle_label = ui.label(root, "", Vector2(229, 683), Vector2(160, 31), 22, ui.AMBER, true)
	var limits: Vector2 = model.aim_limits(0)
	angle_slider = ui.slider(root, Vector2(230, 722), Vector2(153, 17), limits.x, limits.y, angle, func(value): angle = value)
	move_left = ui.button(root, "←", Vector2(230, 752), Vector2(42, 28), func(): pass)
	move_right = ui.button(root, "→", Vector2(277, 752), Vector2(42, 28), func(): pass)
	flip_button = ui.button(root, "F", Vector2(325, 752), Vector2(59, 28), flip)
	ui.metal_panel(root, Vector2(406, 678), Vector2(600, 113), Color("17314d"))
	power_label = ui.label(root, "", Vector2(420, 684), Vector2(260, 25), 18, ui.CREAM, true)
	shot_hint = ui.label(root, "", Vector2(694, 684), Vector2(297, 25), 13, ui.MUTED)
	power_meter = make_meter(root, Vector2(423, 728), Vector2(568, 20), 100, ui.AMBER)
	power_slider = ui.slider(root, Vector2(423, 721), Vector2(568, 30), 0, 100, power, func(value): power = maxf(15.0, value))
	power_slider.add_theme_stylebox_override("slider", ui.box(Color.TRANSPARENT, 0))
	power_slider.add_theme_stylebox_override("grabber_area", ui.box(Color.TRANSPARENT, 0))
	power_slider.add_theme_stylebox_override("grabber_area_highlight", ui.box(Color.TRANSPARENT, 0))
	movement_label = ui.label(root, "", Vector2(420, 762), Vector2(180, 21), 12, ui.MUTED)
	movement_meter = make_meter(root, Vector2(605, 768), Vector2(386, 6), model.movement_budget(), ui.TEAL)
	force_marks = Node2D.new()
	root.add_child(force_marks)
	force_marks.draw.connect(draw_force_marks)
	ui.metal_panel(root, Vector2(1014, 678), Vector2(258, 113), Color("234564"))
	fire_button = ui.button(root, "DISPARAR", Vector2(1027, 690), Vector2(231, 41), shoot, true)
	pass_button = ui.button(root, "Passar turno", Vector2(1027, 738), Vector2(231, 27), func():
		if player_can_act():
			charging = false
			model.pass_turn()
	)
	pass_button.add_theme_font_size_override("font_size", 13)
	ui.label(root, "Espaço: segurar e soltar", Vector2(1033, 768), Vector2(229, 18), 12, ui.MUTED)
	select_weapon(0)

func make_meter(parent: Node, position: Vector2, size: Vector2, maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = position
	bar.max_value = maximum
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_font_size_override("font_size", 1)
	for pair in [["background", Color("081a2b")], ["fill", color]]:
		var style := ui.box(pair[1], 1)
		style.set_content_margin_all(0)
		bar.add_theme_stylebox_override(pair[0], style)
	parent.add_child(bar)
	bar.size = size
	return bar

func draw_force_marks() -> void:
	for i in range(41):
		var x := 423.0 + i * 568.0 / 40.0
		force_marks.draw_line(Vector2(x, 728), Vector2(x, 728 + (8 if i % 10 == 0 else 4)), Color("071728"), 1.0)
		if i % 10 == 0:
			force_marks.draw_string(ui.font, Vector2(x - 8, 719), str(int(i * 2.5)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ui.MUTED)
	var previous: Dictionary = model.last_shots[0]
	if not previous.is_empty():
		var x := 423.0 + float(previous.power) * 568.0 / 100.0
		force_marks.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 754), Vector2(x + 5, 754), Vector2(x, 747)]), ui.CREAM)

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
		weapon_buttons[j].add_theme_stylebox_override("normal", ui.box(Color("32666b") if j == index else Color("24444e"), 9, ui.TEAL if j == index else Color("47626a")))

func shoot() -> void:
	if player_can_act():
		charging = false
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
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			angle = minf(model.aim_limits(0, weapon).y, angle + 38.0 * frame_delta)
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			angle = maxf(model.aim_limits(0, weapon).x, angle - 38.0 * frame_delta)
		if charging:
			power = minf(100.0, power + 65.0 * frame_delta)
			if power >= 100.0:
				shoot()
	model.tick(frame_delta)
	art.tick(model, frame_delta, charging, weapon, model.phase == "aim" and model.active == 1 and not cpu_plan.is_empty(), int(cpu_plan.get("weapon", 0)))
	consume_events()
	if model.phase == "aim" and model.active == 1:
		cpu_wait -= frame_delta
		if cpu_wait <= 0.0:
			if cpu_plan.is_empty():
				cpu_plan = model.choose_cpu_shot()
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
	shake = maxf(0.0, shake - frame_delta * 24.0)
	banner_time = maxf(0.0, banner_time - frame_delta)
	if result_wait >= 0.0:
		result_wait -= frame_delta
		if result_wait < 0.0:
			show_result()
	update_hud()

func consume_events() -> void:
	for event in model.events:
		art.react(event)
		match event.type:
			"turn":
				charging = false
				cpu_plan.clear()
				cpu_wait = 1.1
				banner_text = "SUA VEZ · %s" % profile.nickname if event.actor == 0 else "AUTÔMATO CALCULANDO A MIRA"
				banner_time = 1.9
				sound.play("turn")
				if weapon == 2 and not model.can_use_special(0):
					weapon = 0
			"fire":
				if model.actors[event.actor].vehicle != 2:
					sound.play("fire", mage.shoot_sounds[event.weapon])
			"projectile_launch":
				if event.vehicle == 2:
					sound.play("fire", bigfoot.shoot_sounds[event.weapon])
			"explosion":
				effects.append({"pos": event.position, "radius": event.radius, "weapon": event.weapon, "vehicle": event.get("vehicle", 2), "age": 0.0})
				shake = 7.0
				var original: AudioStream = null
				if event.get("vehicle", 2) in [1, 2]:
					original = (mage if event.vehicle == 1 else bigfoot).blast_sounds[event.weapon]
				sound.play("explosion", original)
			"damage":
				floating.append({"pos": event.position, "text": "−%d" % event.amount, "age": 0.0, "color": Color("ffe5b1")})
			"shield_damage":
				floating.append({"pos": event.position + Vector2(0, -22), "text": "−%d ESC" % event.amount, "age": 0.0, "color": Color("94baff")})
			"fall":
				floating.append({"pos": Vector2(model.actors[event.actor].pos.x, 560), "text": "QUEDA!", "age": 0.0, "color": Color("ffbc79")})
			"finished":
				charging = false
				reward = profile.award(match_id, model.winner == 0, model.winner == -1)
				result_wait = 1.7
				sound.play("result")
	model.events.clear()

func update_hud() -> void:
	if screen != "match":
		return
	queue_panel.position = Vector2(16, 544)
	for index in range(2):
		var actor: Dictionary = model.actors[index]
		if actor.hp > 0 and Rect2(16, 544, 236, 114).intersects(Rect2(actor.pos + Vector2(-90, 38), Vector2(180, 66))):
			queue_panel.position = Vector2(16, 74)
		health_bars[index].value = actor.hp
		health_bars[index].visible = actor.hp > 0
		health_bars[index].position = actor.pos + Vector2(-48, 40)
		hp_labels[index].visible = actor.hp > 0
		hp_labels[index].position = actor.pos + Vector2(-87, 54 if actor.vehicle == 1 else 49)
		shield_bars[index].position = actor.pos + Vector2(-48, 49)
		shield_bars[index].max_value = maxf(1, actor.max_shield)
		shield_bars[index].value = actor.shield
		shield_bars[index].visible = actor.vehicle == 1 and actor.hp > 0
		hp_labels[index].text = "%d / %d" % [actor.hp, actor.max_hp]
		if actor.vehicle == 1:
			hp_labels[index].text += " · %d ESC" % actor.shield
	wind_label.text = "%02d" % abs(int(model.wind))
	timer_label.text = "%02d" % int(ceil(model.turn_time)) if model.phase == "aim" else "—"
	timer_label.add_theme_color_override("font_color", Color("ff815e") if model.turn_time < 8.0 else ui.AMBER)
	var status := "Seu turno" if model.active == 0 else "Turno do Autômato"
	if model.phase == "flight":
		status = "Projétil em voo"
	elif model.phase == "settle":
		status = "Resolvendo impacto"
	elif model.phase == "finished":
		status = "Treino encerrado"
	turn_label.text = "%02d  /  %s" % [model.total_turns, status]
	var limits: Vector2 = model.aim_limits(0, weapon)
	angle = clampf(angle, limits.x, limits.y)
	# Range setters emit value_changed; do not let the old thumb overwrite the aim.
	angle_slider.set_block_signals(true)
	angle_slider.min_value = limits.x
	angle_slider.max_value = limits.y
	angle_slider.set_value_no_signal(angle)
	angle_slider.set_block_signals(false)
	angle_label.text = "Mira  %02d°" % int(angle)
	power_label.text = "%s  %03d%%" % ["Carregando" if charging else "Força", int(power)]
	power_slider.set_value_no_signal(power)
	power_meter.value = power
	movement_meter.max_value = model.movement_budget()
	movement_meter.value = model.movement_left
	var enabled := player_can_act()
	angle_slider.editable = enabled and not charging
	power_slider.editable = enabled and not charging
	fire_button.disabled = not enabled
	pass_button.disabled = not enabled
	flip_button.disabled = not enabled
	move_left.disabled = not enabled
	move_right.disabled = not enabled
	for index in range(weapon_buttons.size()):
		weapon_buttons[index].disabled = not enabled or (index == 2 and not model.can_use_special(0))
		weapon_buttons[index].add_theme_stylebox_override("normal", ui.metal_box(Color("ac7134") if index == weapon else Color("315880"), ui.AMBER if index == weapon else ui.STEEL))
	weapon_buttons[2].tooltip_text = "%s: terceiro turno próprio; um uso por partida." % model.weapon_rules(0, 2).name
	movement_label.text = "Movimento  %d" % int(ceil(model.movement_left))
	delay_label.text = "%s  +%d" % [model.weapon_rules(0, weapon).name, int(float(model.weapon_rules(0, weapon).delay) + float(Match.VEHICLES[vehicle].delay))]
	var previous: Dictionary = model.last_shots[0]
	shot_hint.text = "Último: %d° / %d%%" % [int(previous.angle), int(previous.power)] if not previous.is_empty() else "Marcador: tiro anterior"
	var displayed_weapon: int = weapon if model.active == 0 else int(cpu_plan.get("weapon", 0))
	queue_title.text = "Vez: " + (profile.nickname.left(18) if model.active == 0 else "Autômato")
	if model.phase == "aim" and model.active == 1 and cpu_plan.is_empty():
		queue_entries = []
		queue_labels[0].text = "Autômato escolhendo arma"
		queue_labels[1].text = "Previsão em instantes…"
		queue_detail.text = "Ordem depois do tiro"
		force_marks.queue_redraw()
		return
	queue_entries = model.initiative_preview(displayed_weapon)
	var preview_weapon: int = displayed_weapon if model.phase == "aim" else model.shot_weapon
	queue_detail.text = "Após %s: ordem por atraso" % model.weapon_rules(model.active, preview_weapon).name
	for row in range(queue_entries.size()):
		var entry: Dictionary = queue_entries[row]
		var name: String = profile.nickname if entry.actor == 0 else "Autômato"
		queue_labels[row].text = "%s %s   +%d" % ["▶" if row == 0 else "  ", name.left(12), int(entry.delay)]
		queue_labels[row].add_theme_color_override("font_color", ui.AMBER if row == 0 else ui.MUTED)
	force_marks.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	if event.pressed and event.physical_keycode == KEY_ESCAPE:
		if overlay != null:
			if overlay_kind != "result":
				close_overlay()
		elif screen == "match":
			show_pause()
		return
	if event.pressed and event.physical_keycode == KEY_H:
		show_help()
		return
	if not player_can_act():
		return
	if event.physical_keycode == KEY_SPACE:
		if event.pressed:
			charging = true
			power = 15.0
		elif charging:
			shoot()
	elif event.pressed:
		match event.physical_keycode:
			KEY_1: select_weapon(0)
			KEY_2: select_weapon(1)
			KEY_3: select_weapon(2)
			KEY_F: flip()
			KEY_ENTER: shoot()

func make_overlay(kind: String) -> Panel:
	if is_instance_valid(overlay):
		root.remove_child(overlay)
		overlay.queue_free()
	charging = false
	paused = true
	overlay_kind = kind
	overlay = Control.new()
	overlay.size = Vector2(1280, 800)
	root.add_child(overlay)
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
	paused = false
	if screen == "match" and model.phase == "finished":
		show_result()

func show_help() -> void:
	var card := make_overlay("help")
	ui.label(card, "Como jogar", Vector2(32, 25), Vector2(490, 50), 32, ui.CREAM, true)
	var lines := ["A / D ou ← / →     Mover o veículo", "W / S ou ↑ / ↓     Ajustar o ângulo", "ESPAÇO                  Carregar; soltar ou encher para disparar", "1 / 2 / 3                 Escolher a arma", "F                             Virar parado", "ESC                        Pausar / continuar"]
	for index in range(lines.size()):
		ui.label(card, lines[index], Vector2(32, 96 + index * 37), Vector2(500, 32), 17)
	ui.label(card, "O vento muda a trajetória. Use o último tiro como referência.\nArmas pesadas geram mais atraso. Especial: terceiro turno, um uso.\nZere a vida ou derrube o adversário para vencer.", Vector2(32, 335), Vector2(500, 70), 14, ui.MUTED)
	ui.button(card, "ENTENDI", Vector2(32, 424), Vector2(496, 42), close_overlay, true)

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
	var backdrop: Array = map_background(model.map_id) if screen != "menu" and model.terrain != null else []
	if backdrop.is_empty():
		draw_texture_rect(background, Rect2(0, 0, 1280, 800), false)
	else:
		draw_texture_rect_region(backdrop[0], Rect2(0, 0, 1280, 800), backdrop[1])
	if screen == "menu":
		draw_rect(Rect2(0, 0, 750, 800), Color(0.035, 0.13, 0.17, 0.30))
		draw_circle(Vector2(342, 617), 157.0, Color(0.93, 0.96, 0.87, 0.14))
		draw_arc(Vector2(342, 617), 169.0, 0.1, TAU - 0.4, 90, Color(0.78, 0.95, 0.88, 0.45), 1.5, true)
		draw_sprite(vehicle, Vector2(335, 662 + sin(elapsed * 1.6) * 5), 180.0, 1)
		return
	if model.terrain == null:
		return
	var offset := Vector2(sin(elapsed * 81.0), cos(elapsed * 74.0)) * shake
	draw_set_transform(offset)
	if not model.terrain.map_id.is_empty():
		# Original map: HD foreground carries its own crater and blackmask pixels.
		if model.terrain.visual_texture != null:
			draw_texture_rect(model.terrain.visual_texture, model.terrain.visual_rect, false)
	else:
		draw_procedural_terrain()
	for index in range(model.actors.size()):
		art.draw_actor(self, index, offset)
	draw_set_transform(offset)
	if model.phase == "aim" and model.active == 0:
		draw_aim_guide()
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
	art.draw_compass(self)
	if banner_time > 0.0 and model.phase == "aim":
		var width: float = ui.bold.get_string_size(banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 48.0
		draw_style_box(ui.box(Color(0.05, 0.15, 0.19, minf(0.9, banner_time)), 10), Rect2(640 - width / 2, 176, width, 42))
		draw_string(ui.bold, Vector2(664 - width / 2, 202), banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(ui.CREAM, minf(1.0, banner_time)))

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

func map_background(id: String) -> Array:
	# [texture, source region]: HD stitched file first, original Background.png otherwise.
	if id.is_empty():
		return []
	if not map_backgrounds.has(id):
		var map: Dictionary = Maps.get_map(id)
		var view: Rect2 = map.background_view
		var entry := []
		if ResourceLoader.exists(map.background_hd):
			var hd: Texture2D = load(map.background_hd)
			var source: Rect2 = map.background_hd_source
			var density := float(hd.get_width()) / source.size.x
			entry = [hd, Rect2((view.position - source.position) * density, view.size * density)]
		elif ResourceLoader.exists(map.background):
			entry = [load(map.background), view]
		map_backgrounds[id] = entry
	return map_backgrounds[id]

func draw_sprite(kind: int, pos: Vector2, width: float, facing: int, rotation: float = 0.0, _scale_amount: Vector2 = Vector2.ONE, color: Color = Color.WHITE) -> void:
	if kind == 1:
		mage.draw(self, pos, width, facing, rotation, mage.frame_index("idle", elapsed, 0, false), color)
		return
	if kind == 2:
		bigfoot.draw(self, pos, width, facing, rotation, bigfoot.frame_index("idle", elapsed, 0, false), color)
		return

func draw_aim_guide() -> void:
	var center: Vector2 = model.cannon_pivot(0)
	var facing: int = model.actors[0].facing
	var rotation: float = model.body_rotation(0)
	var limits: Vector2 = model.aim_limits(0, weapon)
	var start := rotation - deg_to_rad(limits.y) if facing == 1 else rotation + PI + deg_to_rad(limits.x)
	var end := rotation - deg_to_rad(limits.x) if facing == 1 else rotation + PI + deg_to_rad(limits.y)
	draw_arc(center, 62, start, end, 42, Color(0.3, 0.85, 0.42, 0.65), 8, true)
	for mark in range(int(limits.x), int(limits.y) + 1, 5):
		var direction: Vector2 = model.shot_velocity(0, mark, 100, weapon).normalized()
		draw_line(center + direction * 53, center + direction * (65 if mark % 15 == 0 else 61), Color(0.94, 1, 0.88, 0.85), 1, true)
	var direction: Vector2 = model.shot_velocity(0, angle, 100, weapon).normalized()
	var tip := center + direction * 73
	draw_line(center + direction * 38, tip, ui.AMBER, 2, true)
	draw_circle(tip, 5, ui.AMBER)
	draw_circle(tip, 2, ui.INK)
	var degrees: float = rad_to_deg(atan2(-direction.y, direction.x * facing))
	var label_pos := center + Vector2(-72 if facing == 1 else 25, -13)
	draw_string_outline(ui.bold, label_pos, "%d°" % roundi(degrees), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, ui.INK)
	draw_string(ui.bold, label_pos, "%d°" % roundi(degrees), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, ui.AMBER)
