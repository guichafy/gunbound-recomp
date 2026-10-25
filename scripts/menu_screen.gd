extends RefCounted
## Start room (REQ-02, REQ-36, ADR-092). The entry is the 1×1 room: the player
## and the machine, Miramo Town in the centre, and Iniciar on the saved setup.
## Match settings (nickname, difficulty, weather) live in one popup and apply
## on Accept. Mobile and items keep their own room buttons.

const Mobiles = preload("res://scripts/mobiles.gd")
const DIFFICULTIES := ["Leve", "Normal", "Precisa"]
const WEATHER_MODES := ["original", "all"]
const WEATHER_LABELS := ["Original do mapa", "Todos os efeitos"]
const PLAYER_SLOT := Rect2(36, 64, 380, 476)
const CPU_SLOT := Rect2(864, 64, 380, 476)
const CENTER_SLOT := Rect2(432, 64, 416, 476)

var ui
var nickname_input: LineEdit
var vehicle_buttons: Array[Button] = []
var difficulty_buttons: Array[Button] = []
var weather_buttons: Array[Button] = []
var room_buttons: Array[Button] = []
var vehicle_info: Label
var items_button: Button
var player_name: Label
var player_mobile: Label
var cpu_detail: Label
var cpu_mobile: Label
var weather_caption: Label
var portrait_name: Label
var settings_popup: Panel
var mobile_popup: Panel
var dimmer: ColorRect
var player_anchor := Vector2.ZERO
var cpu_anchor := Vector2.ZERO
var actions: Dictionary = {}
var saved_difficulty := 1
var saved_weather := "original"
var draft_difficulty := 1
var draft_weather := "original"
var nickname_snapshot := ""
var popup_kind := ""

## `info`: version, nickname, difficulty, weather_mode, weather_label,
## items_label, level, xp, wins.
## `actions`: select_vehicle(id), select_difficulty(index), set_weather(mode),
## show_items, start, show_shop, show_help.
func build(root: Control, factory, info: Dictionary, callbacks: Dictionary) -> void:
	ui = factory
	actions = callbacks
	saved_difficulty = clampi(int(info.difficulty), 0, DIFFICULTIES.size() - 1)
	saved_weather = "all" if str(info.weather_mode) == "all" else "original"
	draft_difficulty = saved_difficulty
	draft_weather = saved_weather
	player_anchor = Vector2(PLAYER_SLOT.position.x + PLAYER_SLOT.size.x * 0.5, PLAYER_SLOT.end.y - 78)
	cpu_anchor = Vector2(CPU_SLOT.position.x + CPU_SLOT.size.x * 0.5, CPU_SLOT.end.y - 78)
	# Direct child: test_scene reads the version from root labels only.
	var tag: Label = ui.label(root, "TREINO OFFLINE   /   " + str(info.version), Vector2(36, 18), Vector2(460, 24), 13, ui.TEAL, true)
	tag.add_theme_constant_override("outline_size", 2)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	var title: Label = ui.label(root, "Treino offline", Vector2(360, 12), Vector2(560, 36), 26, ui.CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_slot(root, PLAYER_SLOT, "player")
	build_centre(root, str(info.weather_label))
	build_slot(root, CPU_SLOT, "cpu")
	build_status(root, info)
	build_portrait(root)
	build_bar(root, info)
	dimmer = ColorRect.new()
	dimmer.color = Color(0.02, 0.05, 0.1, 0.62)
	dimmer.size = Vector2(1280, 800)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.visible = false
	root.add_child(dimmer)
	build_settings_popup(root, str(info.nickname))
	build_mobile_popup(root)
	player_name.text = str(info.nickname)

func build_slot(root: Control, rect: Rect2, who: String) -> void:
	var slot: Panel = ui.panel(root, rect.position, rect.size, Color(0.05, 0.14, 0.24, 0.22), 12)
	var plate: Panel = ui.panel(slot, Vector2(14, rect.size.y - 72), Vector2(rect.size.x - 28, 56), Color(0.05, 0.12, 0.2, 0.88), 8)
	if who == "player":
		player_name = ui.label(plate, "", Vector2(12, 4), Vector2(plate.size.x - 24, 26), 18, ui.CREAM, true)
		player_mobile = ui.label(plate, "", Vector2(12, 28), Vector2(plate.size.x - 24, 22), 13, ui.MUTED)
	else:
		var machine: Label = ui.label(plate, "Máquina", Vector2(12, 4), Vector2(plate.size.x - 24, 26), 18, ui.CREAM, true)
		machine.add_theme_color_override("font_color", ui.CREAM)
		cpu_detail = ui.label(plate, DIFFICULTIES[saved_difficulty], Vector2(12, 28), Vector2(150, 22), 13, ui.TEAL, true)
		cpu_mobile = ui.label(plate, "", Vector2(160, 28), Vector2(plate.size.x - 176, 22), 13, ui.MUTED)
		cpu_mobile.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func build_centre(root: Control, weather_label: String) -> void:
	var panel: Panel = ui.panel(root, CENTER_SLOT.position, CENTER_SLOT.size, Color(0.06, 0.16, 0.28, 0.72), 12)
	weather_caption = ui.label(panel, weather_label, Vector2(20, 18), Vector2(376, 28), 15, ui.TEAL, true)
	weather_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var map_name: Label = ui.label(panel, "Miramo Town A", Vector2(20, 196), Vector2(376, 40), 26, ui.CREAM, true)
	map_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fixed: Label = ui.label(panel, "Solo · 1×1", Vector2(20, 242), Vector2(376, 24), 14, ui.MUTED)
	fixed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func build_status(root: Control, info: Dictionary) -> void:
	var panel: Panel = ui.panel(root, Vector2(36, 556), Vector2(812, 132), Color(0.05, 0.13, 0.22, 0.78), 12)
	ui.label(panel, "NÍVEL %d    ·    %d XP    ·    %d VITÓRIAS" % [info.level, info.xp, info.wins], Vector2(22, 28), Vector2(768, 28), 16, ui.CREAM, true)
	ui.label(panel, "Um duelo contra a máquina, nas alturas.", Vector2(22, 68), Vector2(768, 28), 16, ui.MUTED)

func build_portrait(root: Control) -> void:
	var panel: Panel = ui.panel(root, Vector2(864, 556), Vector2(380, 132), Color(0.05, 0.13, 0.22, 0.78), 12)
	portrait_name = ui.label(panel, "", Vector2(20, 16), Vector2(340, 30), 20, ui.CREAM, true)
	vehicle_info = ui.label(panel, "", Vector2(20, 50), Vector2(340, 70), 14, ui.MUTED)

func build_bar(root: Control, info: Dictionary) -> void:
	room_buttons.clear()
	room_buttons.append(bar_button(root, "Mobile", Vector2(36, 704), Vector2(140, 48), open_mobile))
	items_button = bar_button(root, str(info.items_label), Vector2(188, 704), Vector2(180, 48), actions.show_items)
	items_button.tooltip_text = "Escolher os itens da barra F1–F6 (Select Item)"
	room_buttons.append(items_button)
	var settings: Button = bar_button(root, "Configurações", Vector2(380, 704), Vector2(200, 48), open_settings)
	settings.tooltip_text = "Apelido, dificuldade da máquina e clima"
	room_buttons.append(settings)
	room_buttons.append(bar_button(root, "Shop", Vector2(592, 704), Vector2(130, 48), actions.show_shop))
	room_buttons.append(bar_button(root, "Como jogar", Vector2(734, 704), Vector2(170, 48), actions.show_help))
	var start: Button = ui.button(root, "INICIAR", Vector2(1004, 704), Vector2(240, 48), actions.start, true)
	start.tooltip_text = "Começa o treino com o ajuste gravado"
	room_buttons.append(start)

func bar_button(root: Control, text: String, position: Vector2, size: Vector2, callback: Callable) -> Button:
	var button: Button = ui.button(root, text, position, size, callback)
	button.add_theme_font_size_override("font_size", 15)
	return button

func build_settings_popup(root: Control, nickname: String) -> void:
	settings_popup = ui.panel(root, Vector2(390, 150), Vector2(500, 460), Color("0d2740"), 14)
	settings_popup.visible = false
	ui.label(settings_popup, "Configurações da partida", Vector2(28, 22), Vector2(444, 36), 22, ui.CREAM, true)
	ui.label(settings_popup, "APELIDO", Vector2(28, 72), Vector2(444, 18), 12, ui.TEAL, true)
	nickname_input = LineEdit.new()
	nickname_input.position = Vector2(28, 96)
	nickname_input.size = Vector2(444, 46)
	nickname_input.text = nickname
	nickname_input.max_length = 20
	nickname_input.placeholder_text = "Como devemos chamar você?"
	nickname_input.add_theme_font_override("font", ui.font)
	nickname_input.add_theme_font_size_override("font_size", 19)
	nickname_input.add_theme_color_override("font_color", ui.CREAM)
	nickname_input.add_theme_color_override("caret_color", ui.TEAL)
	nickname_input.add_theme_stylebox_override("normal", ui.box(Color("203e4b"), 8, Color("49636c")))
	nickname_input.add_theme_stylebox_override("focus", ui.box(Color("203e4b"), 8, ui.TEAL, 2))
	settings_popup.add_child(nickname_input)
	ui.label(settings_popup, "DIFICULDADE DA MÁQUINA", Vector2(28, 162), Vector2(444, 18), 12, ui.TEAL, true)
	difficulty_buttons.clear()
	for index in range(DIFFICULTIES.size()):
		var captured := index
		var button: Button = ui.button(settings_popup, DIFFICULTIES[index], Vector2(28 + index * 152, 188), Vector2(144, 40), func(): choose_difficulty(captured))
		button.add_theme_font_size_override("font_size", 15)
		difficulty_buttons.append(button)
	ui.label(settings_popup, "CLIMA", Vector2(28, 248), Vector2(444, 18), 12, ui.TEAL, true)
	weather_buttons.clear()
	for index in range(WEATHER_MODES.size()):
		var mode: String = WEATHER_MODES[index]
		var button: Button = ui.button(settings_popup, WEATHER_LABELS[index], Vector2(28 + index * 228, 274), Vector2(216, 40), func(): choose_weather(mode))
		button.add_theme_font_size_override("font_size", 14)
		weather_buttons.append(button)
	ui.label(settings_popup, "Aceitar grava e volta à sala. Iniciar continua separado.", Vector2(28, 332), Vector2(444, 36), 13, ui.MUTED)
	ui.button(settings_popup, "Cancelar", Vector2(28, 388), Vector2(210, 44), cancel_popup)
	ui.button(settings_popup, "Aceitar", Vector2(262, 388), Vector2(210, 44), accept_settings, true)
	highlight(difficulty_buttons, saved_difficulty)
	highlight(weather_buttons, WEATHER_MODES.find(saved_weather))

func build_mobile_popup(root: Control) -> void:
	mobile_popup = ui.panel(root, Vector2(250, 168), Vector2(780, 420), Color("0d2740"), 14)
	mobile_popup.visible = false
	ui.label(mobile_popup, "Escolha o mobile", Vector2(28, 20), Vector2(560, 34), 22, ui.CREAM, true)
	vehicle_buttons.clear()
	for slot in range(Mobiles.PLAYABLE.size()):
		var id: int = Mobiles.PLAYABLE[slot]
		var column := slot % 4
		var row := int(slot / 4)
		var button: Button = ui.button(mobile_popup, Mobiles.definition(id).name, Vector2(28 + column * 184, 70 + row * 64), Vector2(172, 52), func(): pick_vehicle(id))
		button.add_theme_font_size_override("font_size", 16)
		vehicle_buttons.append(button)
	ui.button(mobile_popup, "Fechar", Vector2(588, 348), Vector2(164, 44), cancel_popup)

func popup_open() -> bool:
	return popup_kind != ""

func open_settings() -> void:
	if popup_kind != "":
		return
	nickname_snapshot = nickname_input.text
	draft_difficulty = saved_difficulty
	draft_weather = saved_weather
	highlight(difficulty_buttons, draft_difficulty)
	highlight(weather_buttons, WEATHER_MODES.find(draft_weather))
	show_popup("settings", settings_popup)
	nickname_input.grab_focus()

func open_mobile() -> void:
	if popup_kind != "":
		return
	show_popup("mobile", mobile_popup)

func choose_difficulty(index: int) -> void:
	draft_difficulty = clampi(index, 0, DIFFICULTIES.size() - 1)
	highlight(difficulty_buttons, draft_difficulty)

func choose_weather(mode: String) -> void:
	draft_weather = "all" if mode == "all" else "original"
	highlight(weather_buttons, WEATHER_MODES.find(draft_weather))

func accept_settings() -> void:
	if popup_kind != "settings":
		return
	saved_difficulty = draft_difficulty
	saved_weather = draft_weather
	var label: String = str(actions.set_weather.call(saved_weather))
	actions.select_difficulty.call(saved_difficulty)
	weather_caption.text = label
	cpu_detail.text = DIFFICULTIES[saved_difficulty]
	var shown := nickname_input.text.strip_edges()
	player_name.text = shown if not shown.is_empty() else "Piloto"
	close_popup()

func pick_vehicle(id: int) -> void:
	actions.select_vehicle.call(id)
	close_popup()

func cancel_popup() -> void:
	if popup_kind == "settings":
		nickname_input.text = nickname_snapshot
		draft_difficulty = saved_difficulty
		draft_weather = saved_weather
	close_popup()

func show_popup(kind: String, popup: Panel) -> void:
	popup_kind = kind
	dimmer.visible = true
	popup.visible = true
	for button in room_buttons:
		button.disabled = true

func close_popup() -> void:
	popup_kind = ""
	dimmer.visible = false
	settings_popup.visible = false
	mobile_popup.visible = false
	if is_instance_valid(nickname_input):
		nickname_input.release_focus()
	for button in room_buttons:
		button.disabled = false

## Marks the chosen mobile and describes it. The machine shows its opponent.
func show_vehicle(id: int) -> void:
	highlight(vehicle_buttons, Mobiles.PLAYABLE.find(id))
	var data: Dictionary = Mobiles.definition(id)
	var foe: Dictionary = Mobiles.definition(Mobiles.opponent(id))
	portrait_name.text = str(data.name)
	player_mobile.text = str(data.name)
	cpu_mobile.text = str(foe.name)
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), str(data.summary)]

func highlight(buttons: Array[Button], chosen: int) -> void:
	for j in range(buttons.size()):
		buttons[j].add_theme_stylebox_override("normal", selected_box(j == chosen))

func selected_box(selected: bool) -> StyleBoxFlat:
	return ui.box(Color("32666b") if selected else Color("24444e"), 9, ui.TEAL if selected else Color("47626a"))
