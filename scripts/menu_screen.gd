extends RefCounted
## Sala 1×1 sobre ready_back (REQ-02, REQ-36, ADR-092, ADR-096).
## Create no lobby abre esta sala. A grade é a única escolha de mobile:
## o clique vale para o piloto, e o lugar B passa o próximo clique à CPU.
## Os itens ficam nos 6 lugares do painel direito; a troca grava na hora.

const Mobiles = preload("res://scripts/mobiles.gd")
const Items = preload("res://scripts/items.gd")
const Chrome = preload("res://scripts/classic_chrome.gd")
const DIFFICULTIES := ["Leve", "Normal", "Precisa"]
const WEATHER_MODES := ["original", "all"]
const WEATHER_LABELS := ["Original do mapa", "Todos os efeitos"]
# Lugares A (esquerda) e B (direita), canto superior. Interior azul medido
# em ready_back: y=63–188, colunas x=39–163 e x=497–621.
const PLAYER_SLOT := Rect2(39, 63, 124, 125)
const CPU_SLOT := Rect2(497, 63, 124, 125)
# Casco nativo no palco (o pai escala 4/3). 52 px mantém o Lightning
# dentro dos 124 px do lugar. A arena continua no casco de 60.
const MOBILE_WIDTH := 52.0
# mobile_sprite coloca o contato 24 px abaixo da âncora quando a largura < 150.
const NATIVE_GROUND := 24.0
# Poço escuro da grade em ready_back, x=28–367 e y=394–530. O PNG do
# ícone mede 63×47; cada botão fica menor que o passo para não invadir.
const GRID_PANEL := Rect2(28, 394, 340, 136)
const GRID_ORIGIN := Vector2(36, 424)
const GRID_STEP := Vector2(41, 40)
const GRID_ICON := Vector2(36, 28)
const GRID := [
	[4, "b_ready_mobile01"], [1, "b_ready_mobile02"], [3, "b_ready_mobile03"], [5, "b_ready_mobile04"],
	[2, "b_ready_mobile05"], [6, "b_ready_mobile06"], [7, "b_ready_mobile07"], [8, "b_ready_mobile08"],
	[9, "b_ready_mobile09"], [10, "b_ready_mobile10"], [11, "b_ready_mobile11"], [12, "b_ready_mobile12"],
	# b_ready_mobile14 do cliente é o Aduka (depois do Grub). O Dragon não
	# tem botão nesse XFS; o ícone sai do quadro 0 do atlas tank14.
	[13, "b_ready_mobile13"], [14, "b_ready_mobile_dragon"], [15, "b_ready_mobile_knight"], [16, "b_ready_mobile14"],
]

var ui
var chrome
var nickname_input: LineEdit
var difficulty_buttons: Array[Button] = []
var weather_buttons: Array[Button] = []
var room_buttons: Array[BaseButton] = []
var grid_buttons: Array[TextureButton] = []
var grid_keys: Array[String] = []
var vehicle_info: Label
var item_art
var loadout: Array = []
var item_catalog: Control
var item_slot_buttons: Array[TextureButton] = []
var equipped_buttons: Array = []
var item_grid_buttons: Array = []
var item_tab_buttons: Array = []
var item_tab := 0
var item_hovered := ""
var player_name: Label
var player_mobile: Label
var cpu_detail: Label
var cpu_mobile: Label
var weather_caption: Label
var portrait_name: Label
var choice_label: Label
var settings_popup: Panel
var dimmer: ColorRect
var figures: Node2D
var player_anchor := Vector2.ZERO
var cpu_anchor := Vector2.ZERO
var actions: Dictionary = {}
var saved_difficulty := 1
var saved_weather := "original"
var draft_difficulty := 1
var draft_weather := "original"
var nickname_snapshot := ""
var popup_kind := ""
var mobile_for := "player"
var player_vehicle_id := 2
var cpu_vehicle_id := 1

## `info`: version, nickname, difficulty, weather_mode, weather_label,
## items_label, items, level, xp, wins, cpu_vehicle.
## `actions`: select_vehicle, select_cpu_vehicle, select_difficulty, set_weather,
## show_items, start, show_shop, show_help, leave.
func build(root: Control, factory, info: Dictionary, callbacks: Dictionary) -> void:
	ui = factory
	chrome = Chrome.new()
	actions = callbacks
	item_art = info.get("item_art", null)
	if item_art == null:
		item_art = preload("res://scripts/item_art.gd").new()
	saved_difficulty = clampi(int(info.difficulty), 0, DIFFICULTIES.size() - 1)
	saved_weather = "all" if str(info.weather_mode) == "all" else "original"
	draft_difficulty = saved_difficulty
	draft_weather = saved_weather
	player_anchor = slot_anchor(PLAYER_SLOT)
	cpu_anchor = slot_anchor(CPU_SLOT)
	var tag: Label = ui.label(root, "TREINO OFFLINE   /   " + str(info.version), Vector2(6, 8), Vector2(96, 150), 11, ui.CREAM, true)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_constant_override("outline_size", 3)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	var stage: Control = Chrome.mount(root)
	chrome.place(stage, "room_back", Vector2.ZERO)
	figures = preload("res://scripts/room_figures.gd").new()
	figures.name = "RoomFigures"
	stage.add_child(figures)
	build_slots(stage)
	build_centre(stage, str(info.weather_label))
	build_grid(stage)
	build_portrait(stage)
	build_items(stage, info)
	build_bar(stage)
	dimmer = ColorRect.new()
	dimmer.color = Color(0.02, 0.05, 0.1, 0.62)
	dimmer.size = Vector2(1280, 800)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.visible = false
	root.add_child(dimmer)
	build_settings_popup(root, str(info.nickname))
	player_name.text = str(info.nickname)
	cpu_vehicle_id = int(info.cpu_vehicle)
	cpu_mobile.text = str(Mobiles.definition(cpu_vehicle_id).name)
	show_loadout(info.get("items", []))

func slot_anchor(rect: Rect2) -> Vector2:
	# Coordenadas do palco. O contato do sprite fica 24 px abaixo da âncora.
	var floor_native := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y)
	return floor_native - Vector2(0, NATIVE_GROUND)

func caption(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color = Color("edf5ff"), center: bool = false) -> Label:
	var node: Label = ui.label(parent, text, pos, size, font_size, color, true)
	node.add_theme_constant_override("outline_size", 2)
	node.add_theme_color_override("font_outline_color", Color("061018"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.clip_text = true
	if center:
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node

func ghost(parent: Node, rect: Rect2, callback: Callable, tip: String) -> Button:
	var node := Button.new()
	node.position = rect.position
	node.focus_mode = Control.FOCUS_NONE
	node.flat = true
	node.tooltip_text = tip
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		node.add_theme_stylebox_override(state, empty)
	node.pressed.connect(callback)
	parent.add_child(node)
	node.size = rect.size
	return node

func build_slots(stage: Control) -> void:
	var player_slot := ghost(stage, PLAYER_SLOT, choose_player_side, "A grade passa a escolher o mobile do piloto")
	player_slot.name = "PlayerSlot"
	room_buttons.append(player_slot)
	player_name = caption(stage, "", PLAYER_SLOT.position + Vector2(6, 4), Vector2(112, 16), 12)
	player_mobile = caption(stage, "", PLAYER_SLOT.position + Vector2(6, 20), Vector2(112, 14), 11, Color("ffe08a"))
	var cpu_slot := ghost(stage, CPU_SLOT, choose_cpu_side, "A grade passa a escolher o mobile da máquina")
	cpu_slot.name = "CpuSlot"
	room_buttons.append(cpu_slot)
	caption(stage, "CPU", CPU_SLOT.position + Vector2(6, 4), Vector2(112, 16), 12)
	cpu_mobile = caption(stage, "", CPU_SLOT.position + Vector2(6, 20), Vector2(112, 14), 11, Color("ffe08a"))

func build_centre(stage: Control, weather_label: String) -> void:
	var previous: TextureButton = chrome.button(stage, "b_ready_mapprev", Vector2(316, 224))
	var following: TextureButton = chrome.button(stage, "b_ready_mapnext", Vector2(456, 224))
	previous.disabled = true
	following.disabled = true
	previous.tooltip_text = "O mapa segue Miramo Town A."
	following.tooltip_text = "O mapa segue Miramo Town A."
	caption(stage, "Miramo Town A", Vector2(344, 226), Vector2(112, 24), 12, Color("edf5ff"), true)
	caption(stage, "Solo · 1×1", Vector2(320, 256), Vector2(160, 16), 11, Color("edf5ff"), true)
	var solo: TextureButton = chrome.button(stage, "b_ready_solo", Vector2(359, 274))
	solo.texture_hover = solo.texture_normal
	solo.texture_pressed = solo.texture_normal
	solo.texture_disabled = solo.texture_normal
	solo.disabled = true
	solo.tooltip_text = "O treino continua Solo 1×1."
	cpu_detail = caption(stage, "Dificuldade: " + DIFFICULTIES[saved_difficulty], Vector2(316, 302), Vector2(168, 16), 11, Color("ffe08a"), true)
	weather_caption = caption(stage, weather_label, Vector2(312, 320), Vector2(176, 18), 11, Color("9dffe2"), true)

func build_grid(stage: Control) -> void:
	grid_buttons.clear()
	grid_keys.clear()
	choice_label = caption(stage, "Escolhendo: piloto", Vector2(72, 398), Vector2(270, 18), 12, Color("edf5ff"), true)
	for index in GRID.size():
		var id := int(GRID[index][0])
		var key := str(GRID[index][1])
		var captured := id
		var column := index % 8
		var row := int(index / 8.0)
		var button: TextureButton = chrome.button(stage, key, GRID_ORIGIN + Vector2(column, row) * GRID_STEP)
		button.name = "MobileGrid%d" % id
		button.ignore_texture_size = true
		button.clip_contents = true
		button.custom_minimum_size = GRID_ICON
		button.size = GRID_ICON
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.tooltip_text = str(Mobiles.definition(id).name)
		button.set_meta("vehicle_id", id)
		button.pressed.connect(func(): pick_vehicle(captured))
		grid_buttons.append(button)
		grid_keys.append(key)
		room_buttons.append(button)
		button.size = GRID_ICON

func build_portrait(stage: Control) -> void:
	portrait_name = caption(stage, "", Vector2(378, 406), Vector2(110, 40), 13)
	portrait_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vehicle_info = caption(stage, "", Vector2(378, 448), Vector2(110, 80), 11, Color("c5d7ea"))
	vehicle_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Interior dos seis retângulos pretos de ready_back. y=400 é o poço abaixo:
# era ali que o nome "Dual" vazava para fora do lugar.
const ITEM_SLOT_ORIGIN := Vector2(524, 365)
const ITEM_SLOT_STEP := 36.0
const ITEM_SLOT_SIZE := Vector2(33, 29)
const ITEM_CATALOG := Rect2(522, 402, 216, 128)

func build_items(stage: Control, _info: Dictionary) -> void:
	item_slot_buttons.clear()
	for index in Items.MAX_SLOTS:
		var captured := index
		var button := TextureButton.new()
		button.focus_mode = Control.FOCUS_NONE
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.clip_contents = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.position = ITEM_SLOT_ORIGIN + Vector2(index * ITEM_SLOT_STEP, 0)
		button.custom_minimum_size = ITEM_SLOT_SIZE
		button.size = ITEM_SLOT_SIZE
		button.set_meta("item_id", "")
		button.set_meta("item_index", -1)
		button.pressed.connect(func(): press_slot(captured))
		stage.add_child(button)
		button.size = ITEM_SLOT_SIZE
		item_slot_buttons.append(button)
	item_catalog = Control.new()
	item_catalog.name = "ItemCatalog"
	item_catalog.position = ITEM_CATALOG.position
	item_catalog.size = ITEM_CATALOG.size
	item_catalog.clip_contents = true
	item_catalog.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(item_catalog)
	item_tab_buttons.clear()
	for index in 2:
		var captured_tab := index
		var label := "2 slots" if index == 0 else "1 slot"
		item_tab_buttons.append(plain_tab(item_catalog, label, Vector2(4 + index * 108, 4), Vector2(100, 16), func(): select_item_tab(captured_tab)))
	select_item_tab(0)

func plain_tab(parent: Node, text: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.focus_mode = Control.FOCUS_NONE
	node.clip_text = true
	node.custom_minimum_size = size
	node.add_theme_font_override("font", ui.font)
	node.add_theme_font_size_override("font_size", 10)
	node.add_theme_color_override("font_color", Color("edf5ff"))
	node.add_theme_color_override("font_hover_color", Color("edf5ff"))
	node.add_theme_color_override("font_pressed_color", Color("edf5ff"))
	node.add_theme_color_override("font_disabled_color", Color("ffe08a"))
	var box := tab_box()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		node.add_theme_stylebox_override(state, box)
	node.pressed.connect(action)
	parent.add_child(node)
	node.size = size
	return node

func tab_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0d3a52")
	box.set_corner_radius_all(2)
	box.content_margin_left = 2
	box.content_margin_right = 2
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box

func select_item_tab(index: int) -> void:
	item_tab = clampi(index, 0, 1)
	for j in item_tab_buttons.size():
		item_tab_buttons[j].disabled = j == item_tab
	for button in item_grid_buttons:
		if is_instance_valid(button):
			button.queue_free()
	item_grid_buttons.clear()
	var slots := 2 if item_tab == 0 else 1
	var columns := 3 if slots == 2 else 5
	var origin := Vector2(6, 24)
	var step := Vector2(70, 50) if slots == 2 else Vector2(42, 44)
	var icon := Vector2(64, 32) if slots == 2 else Vector2(36, 36)
	var shown := 0
	for id in Items.ORDER:
		if Items.slots(id) != slots:
			continue
		var captured: String = str(id)
		var column := shown % columns
		var row := int(shown / float(columns))
		var button := TextureButton.new()
		button.focus_mode = Control.FOCUS_NONE
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.clip_contents = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.position = origin + Vector2(column, row) * step
		button.custom_minimum_size = icon
		button.size = icon
		item_art.style_button(button, captured, false)
		button.tooltip_text = item_tip(captured)
		button.pressed.connect(func(): add_item(captured))
		button.mouse_entered.connect(func(): hover_item(captured))
		item_catalog.add_child(button)
		button.size = icon
		item_grid_buttons.append(button)
		shown += 1

func item_tip(id: String) -> String:
	var data: Dictionary = Items.definition(id)
	return "%s\nAtraso %s\n%s" % [data.name, str(roundi(Items.delay(id))), data.description]

func press_slot(index: int) -> void:
	if index < 0 or index >= item_slot_buttons.size():
		return
	var owner := int(item_slot_buttons[index].get_meta("item_index", -1))
	if owner >= 0:
		remove_item(owner)

func add_item(id: String) -> void:
	if not Items.has_id(id):
		return
	if Items.used_slots(loadout) + Items.slots(id) > Items.MAX_SLOTS:
		return
	var next: Array = loadout.duplicate()
	next.append(id)
	commit_loadout(next)

func remove_item(index: int) -> void:
	if index < 0 or index >= loadout.size():
		return
	var next: Array = loadout.duplicate()
	next.remove_at(index)
	commit_loadout(next)

func commit_loadout(next: Array) -> void:
	if actions.has("commit_items"):
		actions.commit_items.call(next)
	else:
		show_loadout(next)

func hover_item(id: String) -> void:
	item_hovered = id

func hover_line() -> Dictionary:
	if not Items.has_id(item_hovered):
		return {"name": "", "delay": "", "description": ""}
	var data: Dictionary = Items.definition(item_hovered)
	return {"name": str(data.name), "delay": str(roundi(Items.delay(item_hovered))), "description": str(data.description)}

func filled_slot_count() -> int:
	var count := 0
	for button in item_slot_buttons:
		if str(button.get_meta("item_id", "")) != "":
			count += 1
	return count

func slot_rect(index: int) -> Rect2:
	return Rect2(ITEM_SLOT_ORIGIN + Vector2(index * ITEM_SLOT_STEP, 0), ITEM_SLOT_SIZE)

## Um item de 2 slots cobre os dois retângulos e o vão entre eles.
func span_rect(start: int, span: int) -> Rect2:
	var width := ITEM_SLOT_SIZE.x + float(maxi(span, 1) - 1) * ITEM_SLOT_STEP
	return Rect2(slot_rect(start).position, Vector2(width, ITEM_SLOT_SIZE.y))

func icons_inside_slots() -> bool:
	if item_slot_buttons.size() != Items.MAX_SLOTS or equipped_buttons.size() != loadout.size():
		return false
	var unit := 0
	for index in loadout.size():
		var id := str(loadout[index])
		var span := Items.slots(id)
		if unit + span > item_slot_buttons.size():
			return false
		var cover := span_rect(unit, span)
		var head: TextureButton = item_slot_buttons[unit]
		if equipped_buttons[index] != head or not head.visible:
			return false
		if head.position != cover.position or head.size != cover.size:
			return false
		if str(head.get_meta("item_id", "")) != id or int(head.get_meta("item_index", -1)) != index or head.texture_normal == null:
			return false
		for step in range(1, span):
			var extra: TextureButton = item_slot_buttons[unit + step]
			if extra.visible or extra.texture_normal != null:
				return false
			if str(extra.get_meta("item_id", "")) != id or int(extra.get_meta("item_index", -1)) != index:
				return false
		unit += span
	if unit != filled_slot_count():
		return false
	for index in range(unit, item_slot_buttons.size()):
		var empty: TextureButton = item_slot_buttons[index]
		if not empty.visible or str(empty.get_meta("item_id", "")) != "" or empty.texture_normal != null:
			return false
		if empty.position != slot_rect(index).position or empty.size != ITEM_SLOT_SIZE:
			return false
	return true

func catalog_inside_panel() -> bool:
	if item_catalog == null or item_catalog.position != ITEM_CATALOG.position or item_catalog.size != ITEM_CATALOG.size:
		return false
	if not item_catalog.clip_contents:
		return false
	var bounds := Rect2(Vector2.ZERO, item_catalog.size)
	for button in item_tab_buttons:
		if not rect_inside(bounds, Rect2(button.position, button.size)):
			return false
	for button in item_grid_buttons:
		if not rect_inside(bounds, Rect2(button.position, button.size)):
			return false
	return true

func rect_inside(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x >= outer.position.x and inner.position.y >= outer.position.y \
		and inner.end.x <= outer.end.x + 0.01 and inner.end.y <= outer.end.y + 0.01

func build_bar(stage: Control) -> void:
	var exit_button: TextureButton = chrome.button(stage, "b_ready_exit", Vector2(36, 552))
	exit_button.name = "ExitRoom"
	exit_button.tooltip_text = "Volta ao lobby."
	exit_button.pressed.connect(actions.leave)
	room_buttons.append(exit_button)
	var change: TextureButton = chrome.button(stage, "b_ready_changeteam", Vector2(545, 552))
	change.name = "Change"
	change.tooltip_text = "Apelido, dificuldade da máquina e clima."
	change.pressed.connect(open_settings)
	room_buttons.append(change)
	var start: TextureButton = chrome.button(stage, "b_ready_start", Vector2(660, 559))
	start.name = "Start"
	start.tooltip_text = "Começa o treino com o ajuste gravado."
	start.pressed.connect(actions.start)
	room_buttons.append(start)

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

func choose_player_side() -> void:
	if popup_kind != "":
		return
	mobile_for = "player"
	refresh_choice()

func choose_cpu_side() -> void:
	if popup_kind != "":
		return
	mobile_for = "cpu"
	refresh_choice()

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
	cpu_detail.text = "Dificuldade: " + DIFFICULTIES[saved_difficulty]
	var shown := nickname_input.text.strip_edges()
	player_name.text = shown if not shown.is_empty() else "Piloto"
	close_popup()

func pick_vehicle(id: int) -> void:
	if mobile_for == "cpu":
		actions.select_cpu_vehicle.call(id)
	else:
		actions.select_vehicle.call(id)

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
	if is_instance_valid(nickname_input):
		nickname_input.release_focus()
	for button in room_buttons:
		button.disabled = false

func show_vehicle(id: int) -> void:
	player_vehicle_id = id
	var data: Dictionary = Mobiles.definition(id)
	portrait_name.text = str(data.name)
	player_mobile.text = str(data.name)
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), str(data.summary)]
	refresh_choice()

func show_cpu(id: int) -> void:
	cpu_vehicle_id = id
	cpu_mobile.text = str(Mobiles.definition(id).name)
	refresh_choice()

func refresh_choice() -> void:
	var picking_cpu := mobile_for == "cpu"
	if choice_label != null:
		choice_label.text = "Escolhendo: máquina" if picking_cpu else "Escolhendo: piloto"
	mark_grid(cpu_vehicle_id if picking_cpu else player_vehicle_id)

func _clear_item_button(button: TextureButton, index: int) -> void:
	var rect := slot_rect(index)
	button.position = rect.position
	button.custom_minimum_size = rect.size
	button.size = rect.size
	button.visible = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.set_meta("item_id", "")
	button.set_meta("item_index", -1)
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.tooltip_text = ""

func show_loadout(next: Array) -> void:
	loadout = Items.sanitize(next)
	equipped_buttons.clear()
	for index in item_slot_buttons.size():
		_clear_item_button(item_slot_buttons[index], index)
	var unit := 0
	for index in loadout.size():
		var id := str(loadout[index])
		var span := Items.slots(id)
		if unit + span > item_slot_buttons.size():
			break
		var cover := span_rect(unit, span)
		var head: TextureButton = item_slot_buttons[unit]
		head.set_meta("item_id", id)
		head.set_meta("item_index", index)
		item_art.style_button(head, id, false)
		head.position = cover.position
		head.custom_minimum_size = cover.size
		head.size = cover.size
		head.tooltip_text = str(Items.definition(id).name)
		equipped_buttons.append(head)
		for step in range(1, span):
			var extra: TextureButton = item_slot_buttons[unit + step]
			extra.visible = false
			extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
			extra.set_meta("item_id", id)
			extra.set_meta("item_index", index)
		unit += span

func mark_grid(id: int) -> void:
	for index in grid_buttons.size():
		var chosen := int(GRID[index][0]) == id
		chrome.paint(grid_buttons[index], grid_keys[index], 4 if chosen else 0)

func highlight(buttons: Array[Button], chosen: int) -> void:
	for j in range(buttons.size()):
		buttons[j].add_theme_stylebox_override("normal", selected_box(j == chosen))

func selected_box(selected: bool) -> StyleBoxFlat:
	return ui.box(Color("32666b") if selected else Color("24444e"), 9, ui.TEAL if selected else Color("47626a"))
