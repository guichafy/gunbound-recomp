extends RefCounted
## Sala 1×1 sobre ready_back (REQ-02, REQ-36, ADR-092, ADR-096).
## Create no lobby abre esta sala. A grade é a única escolha de mobile:
## o clique vale para o piloto, e o lugar B passa o próximo clique à CPU.
## Os itens ficam nos 6 lugares do painel direito; a troca grava na hora.

const I18n = preload("res://scripts/i18n.gd")
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
const TEAM_CAPACITY := 1
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
var settings_font: Font
var room_art = RoomArt.new()
var portrait: TextureRect
var owner_label: Label
var status_line: Label
var version_tag: Label
var climate_weights: Array[Label] = []
var owner_rank := Ranks.GM
var chrome
var nickname_input: LineEdit
var difficulty_buttons: Array[Button] = []
var weather_buttons: Array[Button] = []
var room_buttons: Array[BaseButton] = []
var stage: Control
var map_preview: TextureRect
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
var map_id := Maps.DEFAULT
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
	map_id = str(info.get("map_id",Maps.DEFAULT))
	item_art = info.get("item_art", null)
	if item_art == null:
		item_art = preload("res://scripts/item_art.gd").new()
	saved_difficulty = clampi(int(info.difficulty), 0, DIFFICULTIES.size() - 1)
	saved_weather = "all" if str(info.weather_mode) == "all" else "original"
	draft_difficulty = saved_difficulty
	draft_weather = saved_weather
	player_anchor = slot_anchor(PLAYER_SLOT)
	cpu_anchor = slot_anchor(CPU_SLOT)
	var tag: Label = ui.label(root, I18n.text("TREINO OFFLINE\n/   ") + str(info.version), Vector2(6, 8), Vector2(96, 42), 10, ui.CREAM, true)
	version_tag = tag
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_constant_override("outline_size", 3)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	tag.size = Vector2(96,42)
	stage = Chrome.mount(root)
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
	# Cliente004dba80: composição em base+(67,14), base(38,141)/(496,141).
	# O contato entra na faixa, em155; renderer tem contato24 abaixo da âncora.
	var floor_native := Vector2(rect.position.x + 66.0, rect.end.y - 33.0)
	return floor_native - Vector2(0, NATIVE_GROUND)

func caption(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color = Color("edf5ff"), center: bool = false) -> Label:
	var node: Label = ui.label(parent, text, pos, size, font_size, color, true)
	node.add_theme_constant_override("outline_size", 2)
	node.add_theme_color_override("font_outline_color", Color("061018"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if size.y > 24 else TextServer.AUTOWRAP_OFF
	node.clip_text = true
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.size = size
	if settings_font!=null and settings_popup!=null and (parent==settings_popup or settings_popup.is_ancestor_of(parent)):
		node.add_theme_font_override("font",settings_font)
		# BMFontRGBA retains its raster colours; tint the canvas contribution.
		node.modulate = color
		node.add_theme_color_override("font_color",Color.WHITE)
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

func slot_visible(index: int, capacity: int) -> bool:
	return index < capacity

func build_slots(stage: Control) -> void:
	for team in ["A","B"]:
		for index in 4:
			var x := (39 if team=="A" else 497) + (index%2)*138
			var bottom := 188 + int(index/2.0)*152
			var height := 71 if team=="A" else 72
			var active := slot_visible(index, TEAM_CAPACITY)
			# O poço rebaixado pertence ao fundo, inclusive quando a faixa está oculta.
			var strip := texture_rect(stage,"Team%s%d"%[team,index],room_art.image("room_team_a" if team=="A" else "room_team_b"),Vector2(x-1,bottom+1-height),Vector2(127,height))
			strip.visible = active
	# Team strips include opaque blue above the floor; draw the mobile over them.
	stage.add_child(figures)
	var player_slot := ghost(stage, PLAYER_SLOT, choose_player_side, "Escolher mobile do piloto — time A")
	player_slot.name = "PlayerSlot"
	room_buttons.append(player_slot)
	player_name = caption(stage,"",Vector2(PLAYER_SLOT.position.x+19,172),Vector2(76,14),10,Color("063342"))
	player_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	player_name.add_theme_constant_override("outline_size",0)
	player_mobile = caption(stage,"",PLAYER_SLOT.position+Vector2(6,4),Vector2(112,14),10,Color("ffe08a"))
	player_mobile.visible = false
	texture_rect(stage,"PlayerTeamRank",Ranks.icon(owner_rank,false),Vector2(PLAYER_SLOT.position.x+3,164),Vector2(10,17))
	var cpu_slot := ghost(stage, CPU_SLOT, choose_cpu_side, "Escolher mobile da máquina — time B")
	cpu_slot.name = "CpuSlot"
	room_buttons.append(cpu_slot)
	cpu_detail = caption(stage,I18n.text("CPU · %s") % I18n.text(DIFFICULTIES[saved_difficulty]),Vector2(CPU_SLOT.position.x+6,172),Vector2(112,14),10,Color("063342"))
	cpu_detail.name = "CpuDetail"
	cpu_detail.add_theme_constant_override("outline_size",0)
	cpu_mobile = caption(stage,"",CPU_SLOT.position+Vector2(6,4),Vector2(112,14),10,Color("ffe08a"))
	cpu_mobile.visible = false
	# ready_back indices6/7: dono e CPU prontos no treino offline.
	# Decoração IGNORE: o clique atravessa para PlayerSlot/CpuSlot.
	texture_rect(stage,"PlayerReady",room_art.frame("room_status",3),Vector2(143,111),Vector2(19,40))
	texture_rect(stage,"CpuReady",room_art.frame("room_status",3),Vector2(601,111),Vector2(19,40))
	texture_rect(stage,"RoomMasterKey",room_art.frame("room_master_key",0),Vector2(137,173),Vector2(22,13))
	player_random_preview = texture_rect(stage,"PlayerRandomPreview",room_art.frame("room_random",0),Vector2(69,91),Vector2(63,47))
	cpu_random_preview = texture_rect(stage,"CpuRandomPreview",room_art.frame("room_random",0),Vector2(527,91),Vector2(63,47))
	player_random_preview.visible = false
	cpu_random_preview.visible = false

func build_centre(stage: Control, weather_label: String) -> void:
	map_preview = texture_rect(stage, "RoomMapPreview", room_art.frame("room_maps",int(Maps.get_map(map_id).get("room_frame",1))), Vector2(332,51),Vector2(136,84))
	# Cave is explicitly selectable offline; native room frames call it Random.
	# Cover only that embedded name with the CAVE raster from load_stage0.
	var fixed_name := ColorRect.new()
	fixed_name.name = "MapFixedName"
	fixed_name.position = Vector2(7,1)
	fixed_name.size = Vector2(119,18)
	fixed_name.color = Color("00333c")
	fixed_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_preview.add_child(fixed_name)
	var cave_title := AtlasTexture.new()
	cave_title.atlas = load("res://assets/xfs/maps/cave/loading_a.png")
	cave_title.region = Rect2(13,4,44,14)
	texture_rect(fixed_name,"CaveTitle",cave_title,Vector2(37,2),Vector2(44,14))
	map_preview.mouse_filter = Control.MOUSE_FILTER_PASS
	map_preview.tooltip_text = "Miramo Town A — mapa fixo do treino"
	climate_weights.clear()
	# O fundo original contém poços pretos. Repor somente essa base com uma
	# amostra laranja limpa da textura ativa; os Labels não têm fundo próprio.
	var panel_fill := AtlasTexture.new()
	panel_fill.atlas = room_art.image("room_back")
	var density := panel_fill.atlas.get_width()/800.0
	panel_fill.region = Rect2(321*density,163*density,density,density)
	for index in 8:
		texture_rect(stage,"WeatherBase%d"%index,panel_fill,Vector2(337+(index%4)*37,160+int(index/4.0)*39),Vector2(15,17))
		var counter := caption(stage,"",Vector2(339+(index%4)*37,161+int(index/4.0)*39),Vector2(11,13),9,Color.WHITE,true)
		counter.name = "WeatherWeight%d" % index
		counter.mouse_filter = Control.MOUSE_FILTER_PASS
		climate_weights.append(counter)
	refresh_climate()
	# The source preview/backdrop already draws the sole arrow pair. Transparent
	# controls sit exactly over them; no duplicate graphics below the preview.
	var previous := ghost(stage,Rect2(322,94,24,24),func():cycle_map(-1),I18n.text("Mapa anterior"))
	var following := ghost(stage,Rect2(454,94,24,24),func():cycle_map(1),I18n.text("Próximo mapa"))
	previous.name = "MapPrevious"
	following.name = "MapNext"
	room_buttons.append(previous)
	room_buttons.append(following)
	# Placas de configuração, sem controles de modos ausentes do treino.
	for data in [
		["RoomMode","room_mode",Vector2(317,225),"Solo — treino offline."],
		["RoomSize","room_size",Vector2(403,225),"Um piloto contra uma máquina."],
		["RoomMapSide","room_map_side",Vector2(317,255),"Miramo Town A."],
		["RoomDeath","room_death",Vector2(403,255),"Sem morte súbita."],
		["RoomItems","room_items",Vector2(317,285),"Itens básicos — seis slots de equipamento."],
	]:
		var plate := texture_rect(stage,data[0],room_art.frame(data[1],0),data[2],Vector2(81,24))
		plate.mouse_filter = Control.MOUSE_FILTER_PASS
		plate.tooltip_text = data[3]
	var side_button := ghost(stage,Rect2(317,255,81,24),toggle_map_side,I18n.text("Trocar lado A/B do mapa"))
	side_button.name = "MapSide"
	room_buttons.append(side_button)
	# Clicking the existing preview selects the explicit offline Random choice.
	map_preview.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			if actions.has("select_map"):actions.select_map.call("random")
	)
	weather_caption = caption(stage, weather_label, Vector2(312, 329), Vector2(176, 14), 10, Color("9dffe2"), true)
	refresh_map(map_id)

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
	return I18n.text("%s\nAtraso %s\n%s") % [data.name, str(roundi(Items.delay(id))), data.description]

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
		status_line.text = I18n.text("%s · Atraso %d · %d slot(s)") % [Items.definition(id).name,roundi(Items.delay(id)),Items.slots(id)]

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
	var start: TextureButton = text_button(stage, "START", Vector2(660, 552))
	start.name = "Start"
	start.tooltip_text = "Mostra o mapa e onde cada piloto nasce, depois começa o treino."
	start.pressed.connect(actions.start)
	room_buttons.append(start)

func text_button(parent: Control, text: String, at: Vector2) -> TextureButton:
	return preload("res://scripts/classic_text_button.gd").create(parent,text,at,chrome,room_art)

func build_settings_popup(root: Control, nickname: String) -> void:
	settings_font = ui.font
	settings_popup = preload("res://scripts/settings_panel.gd").new(ui, actions.options, nickname,
		accept_settings, cancel_popup, choose_difficulty, choose_weather)
	settings_popup.changed.connect(actions.apply_options)
	settings_popup.cancelled.connect(cancel_popup)
	root.add_child(settings_popup)
	nickname_input = settings_popup.nickname_input
	difficulty_buttons = settings_popup.difficulty_buttons
	weather_buttons = settings_popup.weather_buttons

func popup_open() -> bool:
	return popup_kind != ""

func open_settings() -> void:
	if popup_kind != "":
		return
	settings_popup.begin_edit()
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
	if not actions.save_settings.call(nickname_input.text):
		settings_popup.show_save_error()
		return
	saved_difficulty = draft_difficulty
	saved_weather = draft_weather
	var label: String = str(actions.set_weather.call(saved_weather))
	actions.select_difficulty.call(saved_difficulty)
	weather_caption.text = label
	refresh_climate()
	cpu_detail.text = I18n.text("CPU · %s") % I18n.text(DIFFICULTIES[saved_difficulty])
	var shown := nickname_input.text.strip_edges()
	player_name.text = shown if not shown.is_empty() else "Piloto"
	owner_label.text = player_name.text + " · " + Ranks.title(owner_rank)
	owner_label.tooltip_text = player_name.text + " · " + I18n.text(Ranks.description(owner_rank))
	close_popup()
	refresh_language()

func pick_vehicle(id: int) -> void:
	if mobile_for == "cpu":
		actions.select_cpu_vehicle.call(id)
	else:
		actions.select_vehicle.call(id)

func cancel_popup() -> void:
	if popup_kind == "settings":
		settings_popup.restore()
		nickname_input.text = nickname_snapshot
		draft_difficulty = saved_difficulty
		draft_weather = saved_weather
	close_popup()
	refresh_language()

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
	portrait.tooltip_text = I18n.text("%s · %d de vida · %d de movimento\n%s") % [data.name,data.hp,int(data.move),I18n.text(data.summary)]
	player_mobile.text = str(data.name)
	vehicle_info.text = I18n.text("%d de vida · %d de movimento\n%s") % [data.hp, int(data.move), I18n.text(data.summary)]
	refresh_choice()

func show_cpu(id: int) -> void:
	cpu_random = false
	cpu_random_preview.visible = false
	cpu_vehicle_id = id
	cpu_mobile.text = str(Mobiles.definition(id).name)
	refresh_choice()

func refresh_choice() -> void:
	refresh_climate()
	var picking_cpu := mobile_for == "cpu"
	if choice_label != null:
		choice_label.text = I18n.text("Escolhendo: máquina" if picking_cpu else "Escolhendo: piloto")
	if status_line != null:
		status_line.text = I18n.text("Selecionando %s · %s") % [I18n.text("máquina" if picking_cpu else "piloto"),("Random" if (cpu_random if picking_cpu else player_random) else Mobiles.definition(cpu_vehicle_id if picking_cpu else player_vehicle_id).name)]
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
	for index in buttons.size():
		buttons[index].set_pressed_no_signal(index==chosen)

func refresh_language() -> void:
	version_tag.text = I18n.text("TREINO OFFLINE\n/   ") + str(ProjectSettings.get_setting("application/config/version", ""))
	cpu_detail.text = "CPU · " + I18n.text(DIFFICULTIES[saved_difficulty])
	weather_caption.text = actions.weather_label.call()
	if player_random:
		show_random("player")
	else:
		show_vehicle(player_vehicle_id)
	if cpu_random:
		show_random("cpu")
	else:
		show_cpu(cpu_vehicle_id)
	show_loadout(loadout)
	for button in item_grid_buttons:
		button.tooltip_text = item_tip(str(button.get_meta("item_id")))


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
	owner.tooltip_text = str(info.nickname)+" · "+I18n.text(Ranks.description(owner_rank))
	texture_rect(stage,"RoomRankIcon",Ranks.icon(owner_rank,true),Vector2(568,12),Vector2(25,15))

func cycle_map(direction: int) -> void:
	var ids := Maps.available_ids()
	if ids.is_empty():return
	var at := ids.find(map_id)
	if actions.has("select_map"):actions.select_map.call(ids[posmod(at+direction,ids.size())])

func toggle_map_side() -> void:
	var row := Maps.get_map(map_id)
	if row.is_empty():return
	var target := int(row.stage_index)+ (11 if int(row.stage_index)<11 else -11)
	for id in Maps.available_ids():
		if int(Maps.get_map(id).stage_index)==target and actions.has("select_map"):
			actions.select_map.call(id)
			return

func refresh_map(id: String) -> void:
	map_id = id
	var map := Maps.get_map(id)
	map_preview.get_node("MapFixedName").visible = not map.is_empty() and int(map.stage_index)%11==0
	var side_control = stage.get_node_or_null("MapSide")
	var side_plate = stage.get_node_or_null("RoomMapSide")
	if side_control!=null:side_control.disabled = map.is_empty()
	if side_plate!=null:side_plate.modulate.a = 0.35 if map.is_empty() else 1.0
	if map.is_empty():
		map_preview.texture = room_art.frame("room_maps",0)
		map_preview.tooltip_text = I18n.text("Mapa e lado aleatórios — definidos ao iniciar")
	else:
		map_preview.texture = room_art.frame("room_maps",int(map.room_frame))
		map_preview.tooltip_text = str(map.name)+" "+str(map.type)+" — "+I18n.text("Clique no mapa: aleatório")
		var side = stage.get_node_or_null("RoomMapSide")
		if side!=null:
			side.texture = load("res://assets/xfs/maps/ui/bside.png") if map.type=="B" else room_art.frame("room_map_side",0)
	refresh_climate()

func refresh_climate() -> void:
	# Same global stage/calendar contract as Match.start, including Random slots.
	var stage: Array = Maps.native_weather(Maps.get_map(map_id)) if saved_weather!="all" else [1,1,1,1,1,1,1]
	# The original room artwork keeps its eight fixed icon slots.
	var weights := [stage[0],stage[1],stage[2],stage[3],0,stage[5],stage[6],stage[4]]
	for index in climate_weights.size():
		climate_weights[index].text = str(int(weights[index]))
		var kind: String = Weather.TYPES[index]
		var name: String = {"protection":"Lua","ignorance":"Eclipse","weakness":"—"}.get(kind,preload("res://scripts/weather_art.gd").NAMES.get(kind,kind))
		climate_weights[index].tooltip_text = I18n.text("%s: peso %d")%[I18n.text(name),weights[index]]


## Keep the selected map and its embedded title, plus the room's figure composition.
## Random is already resolved by Game; only the room controls become inactive.
func present_loading() -> void:
	for button in room_buttons:
		button.disabled = true

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
