extends RefCounted
## Sala 1×1 sobre ready_back (REQ-02, REQ-36, ADR-092, ADR-096).
## Create no lobby abre esta sala. A grade é a única escolha de mobile:
## o clique vale para o piloto, e o lugar B passa o próximo clique à CPU.
## Os itens ficam nos 6 lugares do painel direito; a troca grava na hora.

const Choice = preload("res://scripts/room_choice.gd")
const RANDOM_CHOICE := Choice.RANDOM
const Mobiles = preload("res://scripts/mobiles.gd")
const Ranks = preload("res://scripts/classic_ranks.gd")
const Maps = preload("res://scripts/maps.gd")
const Weather = preload("res://scripts/weather.gd")
const MatchRules = preload("res://scripts/match.gd")
const RoomArt = preload("res://scripts/classic_room_art.gd")
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
const GRID_ORIGIN := Vector2(33, 396)
const GRID_STEP := Vector2(66, 44)
const GRID_ICON := Vector2(63, 44)
const GRID := [
	[4, "b_ready_mobile01"], [1, "b_ready_mobile02"], [3, "b_ready_mobile03"], [5, "b_ready_mobile04"],
	[2, "b_ready_mobile05"], [6, "b_ready_mobile06"], [7, "b_ready_mobile07"], [8, "b_ready_mobile08"],
	[9, "b_ready_mobile09"], [10, "b_ready_mobile10"], [11, "b_ready_mobile11"], [12, "b_ready_mobile12"],
	[13, "b_ready_mobile13"], [16, "b_ready_mobile14"], [RANDOM_CHOICE, "room_random"],
]

var ui
var room_art = RoomArt.new()
var portrait: TextureRect
var owner_label: Label
var status_line: Label
var climate_weights: Array[Label] = []
var owner_rank := Ranks.GM
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
var item_catalog: ScrollContainer
var item_content: Control
var item_up: TextureButton
var item_down: TextureButton
var player_random_preview: TextureRect
var cpu_random_preview: TextureRect
var player_random := false
var cpu_random := false
var item_slot_buttons: Array[TextureButton] = []
var equipped_buttons: Array = []
var item_grid_buttons: Array = []
var item_tab_buttons: Array = []
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
	var tag: Label = ui.label(root, "TREINO OFFLINE\n/   " + str(info.version), Vector2(6, 8), Vector2(96, 42), 10, ui.CREAM, true)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_constant_override("outline_size", 3)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	tag.size = Vector2(96,42)
	var stage: Control = Chrome.mount(root)
	chrome.place(stage, "room_back", Vector2.ZERO)
	build_header(stage,info)
	figures = preload("res://scripts/room_figures.gd").new()
	figures.name = "RoomFigures"
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
	# A faixa de identificação ocupa a base; contato44px acima do fundo.
	# O sprite mantém seu registro: contato24px abaixo da âncora.
	var floor_native := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 44.0)
	return floor_native - Vector2(0, NATIVE_GROUND)

func caption(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color = Color("edf5ff"), center: bool = false) -> Label:
	var node: Label = ui.label(parent, text, pos, size, font_size, color, true)
	node.add_theme_constant_override("outline_size", 2)
	node.add_theme_color_override("font_outline_color", Color("061018"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if size.y > 24 else TextServer.AUTOWRAP_OFF
	node.clip_text = true
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.size = size
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
	for team in ["A","B"]:
		for index in 4:
			var x := (39 if team=="A" else 497) + (index%2)*138
			var bottom := 188 + int(index/2.0)*152
			var height := 71 if team=="A" else 72
			texture_rect(stage,"Team%s%d"%[team,index],room_art.image("room_team_a" if team=="A" else "room_team_b"),Vector2(x-1,bottom+1-height),Vector2(127,height))
	# Team strips include opaque blue above the floor; draw the mobile over them.
	stage.add_child(figures)
	var player_slot := ghost(stage, PLAYER_SLOT, choose_player_side, "Escolher mobile do piloto — time A")
	player_slot.name = "PlayerSlot"
	room_buttons.append(player_slot)
	player_name = caption(stage,"",Vector2(PLAYER_SLOT.position.x+19,172),Vector2(101,14),10,Color("063342"))
	player_name.add_theme_constant_override("outline_size",0)
	player_mobile = caption(stage,"",PLAYER_SLOT.position+Vector2(6,4),Vector2(112,14),10,Color("ffe08a"))
	texture_rect(stage,"PlayerTeamRank",Ranks.icon(owner_rank,false),Vector2(PLAYER_SLOT.position.x+3,164),Vector2(10,17))
	var cpu_slot := ghost(stage, CPU_SLOT, choose_cpu_side, "Escolher mobile da máquina — time B")
	cpu_slot.name = "CpuSlot"
	room_buttons.append(cpu_slot)
	var cpu_name := caption(stage,"CPU",Vector2(CPU_SLOT.position.x+6,172),Vector2(112,14),10,Color("063342"))
	cpu_name.add_theme_constant_override("outline_size",0)
	cpu_mobile = caption(stage,"",CPU_SLOT.position+Vector2(6,4),Vector2(112,14),10,Color("ffe08a"))
	player_random_preview = texture_rect(stage,"PlayerRandomPreview",room_art.frame("room_random",0),Vector2(69,91),Vector2(63,47))
	cpu_random_preview = texture_rect(stage,"CpuRandomPreview",room_art.frame("room_random",0),Vector2(527,91),Vector2(63,47))
	player_random_preview.visible = false
	cpu_random_preview.visible = false

func build_centre(stage: Control, weather_label: String) -> void:
	var preview := texture_rect(stage, "RoomMapPreview", room_art.frame("room_maps",1), Vector2(332,51),Vector2(136,84))
	preview.mouse_filter = Control.MOUSE_FILTER_PASS
	preview.tooltip_text = "Miramo Town A — mapa fixo do treino"
	climate_weights.clear()
	for index in 8:
		var counter := caption(stage,"",Vector2(339+(index%4)*37,161+int(index/4.0)*39),Vector2(11,13),9,Color.WHITE,true)
		counter.name = "WeatherWeight%d" % index
		counter.mouse_filter = Control.MOUSE_FILTER_PASS
		climate_weights.append(counter)
	refresh_climate()
	# The source preview/backdrop already draws the sole arrow pair. Transparent
	# controls sit exactly over them; no duplicate graphics below the preview.
	var previous := ghost(stage,Rect2(322,94,24,24),func():pass,"O mapa segue Miramo Town A.")
	var following := ghost(stage,Rect2(454,94,24,24),func():pass,"O mapa segue Miramo Town A.")
	previous.name = "MapPrevious"
	following.name = "MapNext"
	previous.disabled = true
	following.disabled = true
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
	status_line = caption(stage,"Selecione o mobile do piloto ou da máquina.",Vector2(76,364),Vector2(408,15),10)
	status_line.name = "RoomStatus"
	grid_buttons.clear()
	grid_keys.clear()
	choice_label = caption(stage, "Escolhendo: piloto", Vector2(72, 398), Vector2(270, 18), 12, Color("edf5ff"), true)
	choice_label.visible = false
	for index in GRID.size():
		var id := int(GRID[index][0])
		var key := str(GRID[index][1])
		var captured := id
		var column := index % 5
		var row := int(index / 5.0)
		var at := GRID_ORIGIN + Vector2(column,row)*GRID_STEP
		var button: TextureButton = reference_button(stage,key,at,GRID_ICON) if id==RANDOM_CHOICE else chrome.button(stage,key,at)
		button.name = "MobileGrid%d" % id
		button.ignore_texture_size = true
		button.clip_contents = true
		button.custom_minimum_size = GRID_ICON
		button.size = GRID_ICON
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.tooltip_text = "Random — sorteia Knight ou Dragon ao iniciar" if id==RANDOM_CHOICE else str(Mobiles.definition(id).name)
		button.set_meta("vehicle_id", id)
		button.pressed.connect(func(): pick_vehicle(captured))
		grid_buttons.append(button)
		grid_keys.append(key)
		room_buttons.append(button)
		button.size = GRID_ICON

func build_portrait(stage: Control) -> void:
	portrait = texture_rect(stage,"RoomPortrait",room_art.frame("room_portraits",5),Vector2(378,390),Vector2(113,146))
	portrait.mouse_filter = Control.MOUSE_FILTER_PASS
	portrait_name = caption(stage, "", Vector2(378, 406), Vector2(110, 40), 13)
	portrait_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vehicle_info = caption(stage, "", Vector2(378, 448), Vector2(110, 80), 11, Color("c5d7ea"))
	vehicle_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Interior dos seis retângulos pretos de ready_back. y=400 é o poço abaixo:
# era ali que o nome "Dual" vazava para fora do lugar.
const ITEM_SLOT_ORIGIN := Vector2(524, 365)
const ITEM_SLOT_STEP := 36.0
const ITEM_SLOT_SIZE := Vector2(35, 31)
const ITEM_CATALOG := Rect2(522, 402, 216, 134)

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
	item_catalog = ScrollContainer.new()
	item_catalog.name = "ItemCatalog"
	item_catalog.position = ITEM_CATALOG.position
	item_catalog.size = ITEM_CATALOG.size
	item_catalog.clip_contents = true
	item_catalog.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_catalog.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	stage.add_child(item_catalog)
	item_content = Control.new()
	item_content.custom_minimum_size = Vector2(216,180)
	item_catalog.add_child(item_content)
	item_tab_buttons.clear()
	var order := ["dual","dual_plus","energy_up_2","energy_up_1","blood","change_wind","team_teleport","bunge_shot","power_up","teleport","thunder"]
	for index in order.size():
		var id: String = order[index]
		var button := TextureButton.new()
		button.focus_mode = Control.FOCUS_NONE
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.clip_contents = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.position = Vector2(4+(index%3)*70,int(index/3.0)*45)
		button.custom_minimum_size = Vector2(64,43)
		room_art.style_item(button,id,true)
		button.set_meta("item_id",id)
		button.tooltip_text = item_tip(id)
		button.pressed.connect(func():add_item(id))
		button.mouse_entered.connect(func():hover_item(id))
		item_content.add_child(button)
		button.size = Vector2(64,43)
		item_grid_buttons.append(button)
		var delay := caption(item_content,str(Items.definition(id).cost),button.position+Vector2(43,33),Vector2(20,9),7,Color.WHITE)
		delay.name = "ItemCost_"+id
		delay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		delay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_up = reference_button(stage,"room_item_up",Vector2(750,404),Vector2(17,48))
	item_down = reference_button(stage,"room_item_down",Vector2(750,487),Vector2(17,48))
	item_up.name = "ItemScrollUp"
	item_down.name = "ItemScrollDown"
	item_up.pressed.connect(func():item_catalog.scroll_vertical -= 45)
	item_down.pressed.connect(func():item_catalog.scroll_vertical += 45)
	room_buttons.append(item_up)
	room_buttons.append(item_down)
	var bar := item_catalog.get_v_scroll_bar()
	bar.changed.connect(sync_item_scroll)
	bar.value_changed.connect(func(_value):sync_item_scroll())
	call_deferred("sync_item_scroll")

func sync_item_scroll() -> void:
	if item_up==null or item_down==null:
		return
	var bar := item_catalog.get_v_scroll_bar()
	item_up.disabled = popup_open() or bar.value<=bar.min_value
	item_down.disabled = popup_open() or bar.value>=bar.max_value-bar.page

func reference_button(stage: Control, key: String, at: Vector2, bounds: Vector2) -> TextureButton:
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_NONE
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.position = at
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	room_art.style_reference(button,key)
	stage.add_child(button)
	button.custom_minimum_size = bounds
	button.size = bounds
	return button

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
	if status_line != null:
		status_line.text = "%s · Atraso %d · %d slot(s)" % [Items.definition(id).name,roundi(Items.delay(id)),Items.slots(id)]

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
	var bounds := Rect2(Vector2.ZERO, item_content.custom_minimum_size)
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
	refresh_climate()
	cpu_detail.text = "Dificuldade: " + DIFFICULTIES[saved_difficulty]
	var shown := nickname_input.text.strip_edges()
	player_name.text = shown if not shown.is_empty() else "Piloto"
	owner_label.text = player_name.text + " · " + Ranks.title(owner_rank)
	owner_label.tooltip_text = player_name.text + " · " + Ranks.description(owner_rank)
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
	sync_item_scroll()

func show_vehicle(id: int) -> void:
	player_random = false
	player_random_preview.visible = false
	player_vehicle_id = id
	var data: Dictionary = Mobiles.definition(id)
	portrait_name.text = str(data.name)
	var native_card := RoomArt.PORTRAITS.has(id)
	portrait.visible = native_card
	portrait_name.visible = not native_card
	vehicle_info.visible = not native_card
	if native_card:
		portrait.texture = room_art.frame("room_portraits",int(RoomArt.PORTRAITS[id]))
	portrait.tooltip_text = "%s · %d de vida · %d de movimento\n%s" % [data.name,data.hp,int(data.move),data.summary]
	player_mobile.text = str(data.name)
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), str(data.summary)]
	refresh_choice()

func show_cpu(id: int) -> void:
	cpu_random = false
	cpu_random_preview.visible = false
	cpu_vehicle_id = id
	cpu_mobile.text = str(Mobiles.definition(id).name)
	refresh_choice()

func refresh_choice() -> void:
	var picking_cpu := mobile_for == "cpu"
	if choice_label != null:
		choice_label.text = "Escolhendo: máquina" if picking_cpu else "Escolhendo: piloto"
	if status_line != null:
		status_line.text = "Selecionando %s · %s" % ["máquina" if picking_cpu else "piloto",("Random" if (cpu_random if picking_cpu else player_random) else Mobiles.definition(cpu_vehicle_id if picking_cpu else player_vehicle_id).name)]
	mark_grid(RANDOM_CHOICE if (cpu_random if picking_cpu else player_random) else (cpu_vehicle_id if picking_cpu else player_vehicle_id))

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
		room_art.style_item(head, id)
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
		if int(GRID[index][0])==RANDOM_CHOICE:
			room_art.style_reference(grid_buttons[index],grid_keys[index],4 if chosen else 0)
		else:
			chrome.paint(grid_buttons[index], grid_keys[index], 4 if chosen else 0)

func highlight(buttons: Array[Button], chosen: int) -> void:
	for j in range(buttons.size()):
		buttons[j].add_theme_stylebox_override("normal", selected_box(j == chosen))

func selected_box(selected: bool) -> StyleBoxFlat:
	return ui.box(Color("32666b") if selected else Color("24444e"), 9, ui.TEAL if selected else Color("47626a"))


func texture_rect(parent: Node, key: String, texture: Texture2D, at: Vector2, bounds: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.name = key
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.texture = texture
	node.position = at
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = bounds
	return node

func build_header(stage: Control, info: Dictionary) -> void:
	owner_rank = Ranks.normalize(info.get("rank",Ranks.GM))
	var title := caption(stage,"Treino offline",Vector2(86,12),Vector2(184,17),11)
	title.name = "RoomTitle"
	var capacity := caption(stage,"1 × 1",Vector2(302,12),Vector2(52,17),11,Color("ffe08a"),true)
	capacity.name = "RoomCapacity"
	var owner := caption(stage,str(info.nickname)+" · "+Ranks.title(owner_rank),Vector2(599,12),Vector2(155,17),11)
	owner.name = "RoomOwner"
	owner.mouse_filter = Control.MOUSE_FILTER_PASS
	owner_label = owner
	owner.tooltip_text = str(info.nickname)+" · "+Ranks.description(owner_rank)
	texture_rect(stage,"RoomRankIcon",Ranks.icon(owner_rank,true),Vector2(568,12),Vector2(25,15))

func refresh_climate() -> void:
	var weights: Array = MatchRules.ALL_WEATHER if saved_weather=="all" else Maps.get_map(Maps.DEFAULT).weather
	for index in climate_weights.size():
		climate_weights[index].text = str(weights[index])
		climate_weights[index].tooltip_text = "%s: peso %d\nEspelho: %d · Aleatório: %d" % [Weather.TYPES[index],weights[index],weights[8],weights[9]]


func show_random(side: String) -> void:
	if side=="cpu":
		cpu_random = true
		cpu_random_preview.visible = false
		cpu_mobile.text = "Random"
	else:
		player_random = true
		player_random_preview.visible = false
		player_mobile.text = "Random"
		portrait.visible = true
		portrait.texture = room_art.frame("room_portraits",0)
		portrait.tooltip_text = "Random — Knight ou Dragon, sorteado ao iniciar"
		portrait_name.visible = false
		vehicle_info.visible = false
	refresh_choice()
