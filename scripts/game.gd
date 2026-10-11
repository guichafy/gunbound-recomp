extends Node2D
## Presentation and input. Combat outcomes belong exclusively to MatchModel.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Profile = preload("res://scripts/profile.gd")
const UIFactory = preload("res://scripts/ui.gd")
const Sound = preload("res://scripts/sound.gd")
var ui = UIFactory.new()
var model = Match.new()
var profile = Profile.new()
var sound
var screen := "menu"
var root: Control
var overlay: Control
var overlay_kind := ""
var background: Texture2D
var sprites: Array[Texture2D] = []
var regions: Array[Rect2] = []
var nickname_input: LineEdit
var vehicle := 0
var cpu_difficulty := 1
var vehicle_buttons: Array[Button] = []
var vehicle_info: Label
var angle := 45.0
var power := 65.0
var weapon := 0
var charging := false
var charge_direction := 1.0
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
var hp_labels: Array[Label] = []
var wind_label: Label
var timer_label: Label
var turn_label: Label
var movement_label: Label
var delay_label: Label
var shot_hint: Label

func _ready() -> void:
	background = load("res://assets/art/background.png")
	for path in ["res://assets/art/scarab.png", "res://assets/art/tortoise.png"]:
		var texture: Texture2D = load(path)
		sprites.append(texture)
		# Ignore faint generated glow padding; retain the original PNG unchanged.
		regions.append(Rect2(336, 90, 895, 813) if sprites.size() == 1 else Rect2(215, 151, 1112, 824))
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
	var tag := ui.label(root, "TREINO DE ARTILHARIA   /   0.1", Vector2(80, 74), Vector2(530, 24), 14, ui.TEAL, true)
	tag.add_theme_constant_override("outline_size", 2)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	var title := ui.label(root, "BRISA\nDE AÇO", Vector2(74, 130), Vector2(650, 235), 80, ui.CREAM, true)
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.1, 0.16, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 5)
	ui.label(root, "Mire. Sinta o vento. Faça a cratera.", Vector2(80, 390), Vector2(630, 38), 23)
	ui.label(root, "Um duelo contra a máquina, nas alturas.", Vector2(80, 430), Vector2(630, 28), 17, Color("d7e8e6"))
	ui.label(root, "UM JOGO ORIGINAL DE ARTILHARIA POR TURNOS", Vector2(80, 753), Vector2(720, 22), 12, Color("c4d6d5"), true)
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
	for index in range(2):
		var button := ui.button(card, Match.VEHICLES[index].name, Vector2(28 + index * 186, 246), Vector2(178, 48), func(): select_vehicle(index))
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
	vehicle = index
	for j in range(vehicle_buttons.size()):
		vehicle_buttons[j].add_theme_stylebox_override("normal", ui.box(Color("32666b") if j == index else Color("24444e"), 9, ui.TEAL if j == index else Color("47626a")))
	var data: Dictionary = Match.VEHICLES[index]
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), "Ágil, com recuperação mais rápida." if index == 0 else "Resistente, com recuperação mais lenta."]
	queue_redraw()

func start_match() -> void:
	if screen == "menu" and is_instance_valid(nickname_input):
		profile.nickname = profile.clean_nickname(nickname_input.text)
		profile.save_profile()
	screen = "match"
	model.start(vehicle, cpu_difficulty)
	match_id = str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())
	reward = 0
	result_wait = -1.0
	angle = 45.0
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
	ui.panel(root, Vector2(20, 18), Vector2(1240, 91), Color("112b38"), 15)
	health_bars.clear()
	hp_labels.clear()
	for index in range(2):
		var left := 43.0 if index == 0 else 917.0
		var actor: Dictionary = model.actors[index]
		var name: String = profile.nickname if index == 0 else "AUTÔMATO"
		ui.label(root, name + "  ·  " + Match.VEHICLES[actor.vehicle].name.to_upper(), Vector2(left, 28), Vector2(320, 24), 16, ui.CREAM, true)
		var bar := ProgressBar.new()
		bar.position = Vector2(left, 59)
		bar.size = Vector2(320, 8)
		bar.max_value = actor.max_hp
		bar.value = actor.hp
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_font_size_override("font_size", 1)
		var bar_background := ui.box(Color("304653"), 4)
		var bar_fill := ui.box(Match.VEHICLES[actor.vehicle].color, 4)
		for style in [bar_background, bar_fill]:
			style.content_margin_top = 0
			style.content_margin_bottom = 0
			style.content_margin_left = 0
			style.content_margin_right = 0
		bar.add_theme_stylebox_override("background", bar_background)
		bar.add_theme_stylebox_override("fill", bar_fill)
		root.add_child(bar)
		# Set the size after styling: the default theme initially clamps it taller.
		bar.size = Vector2(320, 8)
		health_bars.append(bar)
		hp_labels.append(ui.label(root, "", Vector2(left, 74), Vector2(320, 22), 12, ui.MUTED))
	wind_label = ui.label(root, "", Vector2(458, 29), Vector2(240, 30), 23, ui.TEAL, true)
	ui.label(root, "VENTO", Vector2(458, 71), Vector2(180, 20), 11, ui.MUTED, true)
	timer_label = ui.label(root, "30", Vector2(730, 26), Vector2(90, 36), 30, ui.CREAM, true)
	ui.label(root, "SEGUNDOS", Vector2(729, 72), Vector2(100, 20), 11, ui.MUTED, true)
	turn_label = ui.label(root, "", Vector2(455, 125), Vector2(500, 28), 17, ui.INK, true)
	ui.button(root, "?", Vector2(1158, 123), Vector2(38, 34), show_help)
	ui.button(root, "Ⅱ", Vector2(1204, 123), Vector2(38, 34), show_pause)
	ui.panel(root, Vector2(20, 680), Vector2(1240, 101), Color("112b38"), 15)
	ui.label(root, "ARSENAL", Vector2(36, 691), Vector2(170, 18), 11, ui.MUTED, true)
	weapon_buttons.clear()
	for index in range(3):
		var text: String = "%d · %s" % [index + 1, Combat.WEAPONS[index].name]
		weapon_buttons.append(ui.button(root, text, Vector2(36 + index * 137, 720), Vector2(129, 43), func(): select_weapon(index)))
	angle_label = ui.label(root, "", Vector2(466, 693), Vector2(220, 26), 17, ui.CREAM, true)
	angle_slider = ui.slider(root, Vector2(466, 734), Vector2(215, 23), 10, 85, angle, func(value): angle = value)
	power_label = ui.label(root, "", Vector2(721, 693), Vector2(280, 26), 17, ui.CREAM, true)
	power_slider = ui.slider(root, Vector2(721, 734), Vector2(265, 23), 15, 100, power, func(value): power = value)
	fire_button = ui.button(root, "DISPARAR    ↗", Vector2(1040, 701), Vector2(200, 48), shoot, true)
	ui.label(root, "Segure e solte ESPAÇO", Vector2(1043, 757), Vector2(205, 20), 12, ui.MUTED)
	move_left = ui.button(root, "← A", Vector2(28, 627), Vector2(63, 33), func(): pass)
	move_right = ui.button(root, "D →", Vector2(99, 627), Vector2(63, 33), func(): pass)
	flip_button = ui.button(root, "Virar · F", Vector2(174, 627), Vector2(104, 33), flip)
	movement_label = ui.label(root, "", Vector2(295, 632), Vector2(180, 22), 13, ui.INK, true)
	delay_label = ui.label(root, "", Vector2(494, 632), Vector2(285, 22), 13, ui.INK, true)
	pass_button = ui.button(root, "Passar turno", Vector2(1094, 627), Vector2(151, 33), func():
		if player_can_act():
			charging = false
			model.pass_turn()
	)
	shot_hint = ui.label(root, "", Vector2(750, 632), Vector2(333, 24), 13, ui.INK, true)
	select_weapon(0)

func player_can_act() -> bool:
	return screen == "match" and model.phase == "aim" and model.active == 0 and not paused

func select_weapon(index: int) -> void:
	if screen != "match" or not player_can_act():
		return
	if index == 2 and not model.can_use_special(0):
		return
	weapon = index
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
	elapsed += delta
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
			angle = minf(85.0, angle + 38.0 * frame_delta)
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			angle = maxf(10.0, angle - 38.0 * frame_delta)
		if charging:
			power = clampf(power + charge_direction * 65.0 * frame_delta, 15.0, 100.0)
			if power >= 100.0:
				charge_direction = -1.0
			elif power <= 15.0:
				charge_direction = 1.0
	model.tick(frame_delta)
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
		if effects[i].age > 0.75:
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
				sound.play("fire")
			"explosion":
				effects.append({"pos": event.position, "radius": event.radius, "weapon": event.weapon, "age": 0.0})
				shake = 7.0
				sound.play("explosion")
			"damage":
				floating.append({"pos": event.position, "text": "−%d" % event.amount, "age": 0.0, "color": Color("ffe5b1")})
			"fall":
				floating.append({"pos": Vector2(model.actors[event.actor].pos.x, 560), "text": "QUEDA!", "age": 0.0, "color": Color("ffbc79")})
			"finished":
				charging = false
				reward = profile.award(match_id, model.winner == 0, model.winner == -1)
				result_wait = 1.2
				sound.play("result")
	model.events.clear()

func update_hud() -> void:
	if screen != "match":
		return
	for index in range(2):
		var actor: Dictionary = model.actors[index]
		health_bars[index].value = actor.hp
		hp_labels[index].text = "%d / %d VIDA     ·     ATRASO %d" % [actor.hp, actor.max_hp, maxi(0, int(float(actor.ready) - model.clock))]
	wind_label.text = ("←  " if model.wind < 0.0 else "→  ") + "%02d" % abs(int(model.wind))
	timer_label.text = "%02d" % int(ceil(model.turn_time)) if model.phase == "aim" else "—"
	timer_label.add_theme_color_override("font_color", Color("ffb58a") if model.turn_time < 8.0 else ui.CREAM)
	var status := "SEU TURNO" if model.active == 0 else "TURNO DO AUTÔMATO"
	if model.phase == "flight":
		status = "PROJÉTIL EM VOO"
	elif model.phase == "settle":
		status = "RESOLVENDO IMPACTO"
	elif model.phase == "finished":
		status = "TREINO ENCERRADO"
	turn_label.text = "TURNO %02d   ·   %s" % [model.total_turns, status]
	angle_label.text = "ÂNGULO    %02d°" % int(angle)
	power_label.text = "FORÇA    %03d%%" % int(power)
	angle_slider.set_value_no_signal(angle)
	power_slider.set_value_no_signal(power)
	var enabled := player_can_act()
	angle_slider.editable = enabled
	power_slider.editable = enabled
	fire_button.disabled = not enabled
	pass_button.disabled = not enabled
	flip_button.disabled = not enabled
	move_left.disabled = not enabled
	move_right.disabled = not enabled
	for index in range(weapon_buttons.size()):
		weapon_buttons[index].disabled = not enabled or (index == 2 and not model.can_use_special(0))
		weapon_buttons[index].add_theme_stylebox_override("normal", ui.box(Color("32666b") if index == weapon else Color("24444e"), 9, ui.TEAL if index == weapon else Color("47626a")))
	weapon_buttons[2].tooltip_text = "Disponível no terceiro turno próprio; um uso por partida."
	movement_label.text = "MOVIMENTO  %d" % int(ceil(model.movement_left))
	delay_label.text = "ATRASO DO TIRO  +%d" % int(float(Combat.WEAPONS[weapon].delay) + float(Match.VEHICLES[vehicle].delay))
	var previous: Dictionary = model.last_shots[0]
	shot_hint.text = "ANTERIOR  %d° / %d%%" % [int(previous.angle), int(previous.power)] if not previous.is_empty() else "W/S: ângulo · 1/2/3: arma"

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
			charge_direction = 1.0
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
	var lines := ["A / D ou ← / →     Mover o veículo", "W / S ou ↑ / ↓     Ajustar o ângulo", "ESPAÇO                  Segurar força; soltar para disparar", "1 / 2 / 3                 Escolher a arma", "F                             Virar o canhão", "ESC                        Pausar / continuar"]
	for index in range(lines.size()):
		ui.label(card, lines[index], Vector2(32, 96 + index * 37), Vector2(500, 32), 17)
	ui.label(card, "O vento muda a trajetória. Use o último tiro como referência.\nArmas pesadas geram mais atraso. Especial: terceiro turno, um uso.\nZere a vida ou derrube o adversário para vencer.", Vector2(32, 335), Vector2(500, 70), 14, ui.MUTED)
	ui.button(card, "ENTENDI", Vector2(32, 424), Vector2(496, 42), close_overlay, true)

func show_pause() -> void:
	if screen != "match" or model.phase == "finished":
		return
	var card := make_overlay("pause")
	ui.label(card, "Uma pausa na brisa.", Vector2(32, 27), Vector2(496, 55), 30, ui.CREAM, true)
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
	draw_texture_rect(background, Rect2(0, 0, 1280, 800), false)
	if screen == "menu":
		draw_rect(Rect2(0, 0, 750, 800), Color(0.035, 0.13, 0.17, 0.30))
		draw_circle(Vector2(342, 617), 157.0, Color(0.93, 0.96, 0.87, 0.14))
		draw_arc(Vector2(342, 617), 169.0, 0.1, TAU - 0.4, 90, Color(0.78, 0.95, 0.88, 0.45), 1.5, true)
		draw_sprite(vehicle, Vector2(335, 662 + sin(elapsed * 1.6) * 5), 270.0, 1)
		return
	if model.terrain == null:
		return
	var offset := Vector2(sin(elapsed * 81.0), cos(elapsed * 74.0)) * shake
	draw_set_transform(offset)
	draw_texture_rect(model.terrain.texture, Rect2(0, 0, 1280, 800), false)
	# Small vegetation details follow the current collision surface.
	for x in range(48, 1240, 31):
		var y: float = model.terrain.surface_at(x)
		if y > 610.0:
			continue
		draw_line(Vector2(x, y), Vector2(x - 3, y - 7), Color("4b8050"), 2.0, true)
		if x % 3 == 0:
			draw_circle(Vector2(x - 3, y - 8), 2.2, Color("f4d5b2"))
	for index in range(model.actors.size()):
		var actor: Dictionary = model.actors[index]
		if int(actor.hp) <= 0:
			continue
		var pos: Vector2 = actor.pos
		draw_set_transform(pos + offset)
		draw_circle(Vector2(0, 25), 35.0, Color(0.03, 0.09, 0.1, 0.13))
		if model.active == index and model.phase == "aim":
			draw_arc(Vector2(0, 8), 50.0 + sin(elapsed * 4.0) * 2.0, -2.9, -0.25, 40, Match.VEHICLES[actor.vehicle].color, 2.0, true)
		draw_set_transform(offset)
		draw_sprite(actor.vehicle, pos, 105.0, actor.facing)
		var actor_angle := angle if index == 0 else float(cpu_plan.get("angle", 45.0))
		var direction := Vector2(cos(deg_to_rad(actor_angle)) * int(actor.facing), -sin(deg_to_rad(actor_angle)))
		var pivot := pos + Vector2(0, -14)
		draw_line(pivot, pivot + direction * 38.0, Color("172c35"), 13.0, true)
		draw_line(pivot, pivot + direction * 36.0, Match.VEHICLES[actor.vehicle].color.darkened(0.16), 7.0, true)
		draw_circle(pivot, 7.0, Color("efe3bd"))
		var name: String = profile.nickname if index == 0 else "Autômato"
		var width: float = ui.bold.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_style_box(ui.box(Color(0.05, 0.15, 0.19, 0.88), 6), Rect2(pos.x - width * 0.5 - 10, pos.y - 92, width + 20, 25))
		draw_string(ui.bold, Vector2(pos.x - width * 0.5, pos.y - 74), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ui.CREAM)
		draw_style_box(ui.box(Color("223f48"), 3), Rect2(pos.x - 38, pos.y - 60, 76, 5))
		draw_style_box(ui.box(Match.VEHICLES[actor.vehicle].color, 3), Rect2(pos.x - 38, pos.y - 60, maxf(1, 76.0 * float(actor.hp) / actor.max_hp), 5))
	if model.phase == "aim" and model.active == 0:
		draw_aim_guide()
	for projectile in model.projectiles:
		var color: Color = Combat.WEAPONS[model.shot_weapon].color
		var trail: Array = projectile.trail
		for index in range(1, trail.size()):
			draw_line(trail[index - 1], trail[index], Color(color, float(index) / trail.size() * 0.6), 2.0, true)
		draw_circle(projectile.pos, 11.0, Color(color, 0.18))
		draw_circle(projectile.pos, 5.0, color)
		draw_circle(projectile.pos + Vector2(-1, -1), 2.0, Color.WHITE)
	for effect in effects:
		var t := float(effect.age) / 0.75
		var pos: Vector2 = effect.pos
		var radius := float(effect.radius)
		draw_circle(pos, radius * (0.2 + t * 1.3), Color(1.0, 0.78, 0.38, (1.0 - t) * 0.33))
		draw_arc(pos, radius * (0.35 + t), 0, TAU, 50, Color(1.0, 0.96, 0.8, 1.0 - t), maxf(1.0, (1.0 - t) * 6.0), true)
		for index in range(12):
			var direction := Vector2.from_angle(index * TAU / 12.0)
			var particle_pos := pos + direction * radius * t * 1.5 + Vector2(0, t * t * 80.0)
			draw_circle(particle_pos, maxf(1.0, 4.0 * (1.0 - t)), Color("f8d3a4") * Color(1, 1, 1, 1.0 - t))
	for item in floating:
		var pos: Vector2 = item.pos + Vector2(-22, -70 - float(item.age) * 34.0)
		draw_string(ui.bold, pos + Vector2(1, 2), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.05, 0.12, 0.18, 1.0 - float(item.age) / 1.5))
		draw_string(ui.bold, pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(item.color, 1.0 - float(item.age) / 1.5))
	draw_set_transform(Vector2.ZERO)
	if banner_time > 0.0 and model.phase == "aim":
		var width: float = ui.bold.get_string_size(banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 48.0
		draw_style_box(ui.box(Color(0.05, 0.15, 0.19, minf(0.9, banner_time)), 10), Rect2(640 - width / 2, 176, width, 42))
		draw_string(ui.bold, Vector2(664 - width / 2, 202), banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(ui.CREAM, minf(1.0, banner_time)))

func draw_sprite(kind: int, pos: Vector2, width: float, facing: int) -> void:
	var region := regions[kind]
	var height := width * region.size.y / region.size.x
	var rect := Rect2(-width * 0.5, -height + width * 0.23, width, height)
	draw_set_transform(pos, 0.0, Vector2(facing, 1))
	draw_texture_rect_region(sprites[kind], rect, region)
	draw_set_transform(Vector2.ZERO)

func draw_aim_guide() -> void:
	# A short launch-direction guide helps read the angle without solving the shot.
	var pos: Vector2 = model.muzzle(0, angle)
	var direction := Vector2(cos(deg_to_rad(angle)) * int(model.actors[0].facing), -sin(deg_to_rad(angle)))
	for index in range(1, 6):
		draw_circle(pos + direction * (index * 13.0), 2.0, Color(0.98, 0.99, 0.92, 0.85 - index * 0.1))
	var center: Vector2 = model.actors[0].pos + Vector2(0, -14)
	draw_arc(center, 62, -PI / 2, 0 if int(model.actors[0].facing) > 0 else -PI, 35, Color(0.12, 0.28, 0.3, 0.3), 1.0, true)
