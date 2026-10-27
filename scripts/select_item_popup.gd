extends Control
## PopupSelectItem.cs (PopupMenu, TabButtonList, EquippedButtonBar) with the
## original Interface/Popup/Blue/SelectItem sprites. Offsets are the C# ones,
## relative to the popup centre on the 800×500 virtual screen, scaled by
## K = 1.6. Client item/checkmark art with declared1x gaps (ADR-133).
## Edits the loadout in options.gd (PlayerInformation.SelectedItemTypeList).

signal accepted

const Items = preload("res://scripts/items.gd")
const K := 1.6
const SIZE := Vector2(401, 404)
const TITLE_HEIGHT := 30.0
const FONT_SIZE := 19  # Consolas 10 pt, as in options_popup.gd
const NAME_SIZE := 21  # Consolas 11 pt
const LINE_HEIGHT := 12.0
const NAME_OFFSET := Vector2(-182, 68)
const DESCRIPTION_OFFSET := Vector2(-182, 88)
const COST_OFFSET := Vector2(182, 68)
const DELAY_LABEL_OFFSET := Vector2(60, 68)
const EQUIPPED_OFFSET := Vector2(-182, 157)
const TAB_OFFSET := Vector2(-145, -148)
const TAB_STEP := 80.0
const TAB_SIZE := Vector2(82, 30)
const TABS := ["2 Slots", "1 Slot"]
const ACCEPT_OFFSET := Vector2(175, 178)
# CreateItemList: first cell, spacing and elements per line for each tab.
const GRID := {2: {"base": Vector2(-79, -78), "step": Vector2(85, 40), "per_line": 4},
	1: {"base": Vector2(-138, -78), "step": Vector2(40, 40), "per_line": 9}}
const NO_ITEM := "No item selected"

var options
var art
var font: SystemFont
var tab := 0
var hovered := ""
var grid_buttons: Array = []
var equipped_buttons: Array = []
var tab_buttons: Array = []
var accept_button: TextureButton
# Texts sit above the tab buttons (SpriteText depth over InterfacePopupButtons).
var text_layer: Control
var drag_window := false
var drag_start := Vector2.ZERO

func _init(values, item_art) -> void:
	options = values
	art = item_art
	size = SIZE * K
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Menlo", "Monaco", "DejaVu Sans Mono", "monospace"])
	for index in range(TABS.size()):
		var button := TextureButton.new()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.focus_mode = Control.FOCUS_NONE
		button.size = TAB_SIZE * K
		button.position = point(TAB_OFFSET + Vector2(TAB_STEP * index, 0)) - button.size * 0.5
		# TabIndex: Disabled (0) is the selected face, Normal (82) the others.
		button.texture_normal = art.region("TabIndex.png", Rect2(Vector2(82, 0), TAB_SIZE))
		button.texture_disabled = art.region("TabIndex.png", Rect2(Vector2.ZERO, TAB_SIZE))
		button.pressed.connect(func(): select_tab(index))
		add_child(button)
		tab_buttons.append(button)
	accept_button = TextureButton.new()
	accept_button.ignore_texture_size = true
	accept_button.stretch_mode = TextureButton.STRETCH_SCALE
	accept_button.focus_mode = Control.FOCUS_NONE
	accept_button.size = Vector2(20, 25) * K
	accept_button.position = point(ACCEPT_OFFSET) - accept_button.size * 0.5
	accept_button.tooltip_text = "Accept (ESC)"
	var accept: Texture2D = preload("res://scripts/client_hud_assets.gd").new().texture("PopupAccept.png", preload("res://assets/openbound/hud/PopupAccept.png"))
	var accept_density := float(accept.get_width()) / 80.0
	var faces: Array[AtlasTexture] = []
	for frame in range(4):
		var face := AtlasTexture.new()
		face.atlas = accept
		face.region = Rect2(Vector2(frame * 20, 0) * accept_density, Vector2(20, 25) * accept_density)
		faces.append(face)
	accept_button.texture_normal = faces[0]
	accept_button.texture_hover = faces[1]
	accept_button.texture_pressed = faces[2]
	accept_button.texture_disabled = faces[3]
	accept_button.pressed.connect(func(): accepted.emit())
	add_child(accept_button)
	text_layer = Control.new()
	text_layer.size = size
	text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_layer.draw.connect(draw_texts)
	add_child(text_layer)
	select_tab(0)
	rebuild_equipped()
	center_on(Vector2(640, 400))

## Local point of a PopupSelectItem offset (relative to the popup centre).
func point(offset: Vector2) -> Vector2:
	return (SIZE * 0.5 + offset) * K

func center_on(screen_point: Vector2) -> void:
	position = (screen_point - size * 0.5).round()

func make_item_button(id: String, top_left: Vector2, action: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	button.size = Vector2(art.button_width(id), art.BUTTON_HEIGHT) * K
	button.position = point(top_left).round()
	art.style_button(button, id, false)
	button.set_meta("item", id)
	button.pressed.connect(action)
	button.mouse_entered.connect(func(): hover(id))
	add_child(button)
	if text_layer != null:
		move_child(text_layer, -1)
	return button

## TabButtonList.OnClick + PopupSelectItem.CreateItemList.
func select_tab(index: int) -> void:
	tab = index
	for j in range(tab_buttons.size()):
		tab_buttons[j].disabled = j == index
	for button in grid_buttons:
		remove_child(button)
		button.queue_free()
	grid_buttons.clear()
	var slots := 2 if index == 0 else 1
	var grid: Dictionary = GRID[slots]
	var shown := 0
	for id in Items.ORDER:
		if Items.slots(id) != slots:
			continue
		var cell := Vector2(shown % int(grid.per_line), int(shown / int(grid.per_line)))
		var top_left: Vector2 = grid.base - grid.step + grid.step * cell
		grid_buttons.append(make_item_button(id, top_left, func(): add_item(id)))
		shown += 1
	redraw()

## EquippedButtonBar.AddItemIntoBarAction: ignored when it does not fit.
func add_item(id: String) -> void:
	if Items.used_slots(options.items) + Items.slots(id) > Items.MAX_SLOTS:
		return
	options.items.append(id)
	rebuild_equipped()

## PopupSelectItem.RemoveButtonAction.
func remove_item(index: int) -> void:
	if index >= 0 and index < options.items.size():
		options.items.remove_at(index)
	rebuild_equipped()

func rebuild_equipped() -> void:
	for button in equipped_buttons:
		remove_child(button)
		button.queue_free()
	equipped_buttons.clear()
	var x := EQUIPPED_OFFSET.x
	for index in range(options.items.size()):
		var id: String = options.items[index]
		equipped_buttons.append(make_item_button(id, Vector2(x, EQUIPPED_OFFSET.y), func(): remove_item(index)))
		x += art.button_width(id) - 1.0
	redraw()

## PopupSelectItem.OnBeginHooverAction.
func hover(id: String) -> void:
	hovered = id
	redraw()

func redraw() -> void:
	queue_redraw()
	if text_layer != null:
		text_layer.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.y < TITLE_HEIGHT * K:
			drag_window = true
			drag_start = event.position
		elif not event.pressed:
			drag_window = false
		accept_event()
	elif event is InputEventMouseMotion and drag_window:
		# PopupMenu.OnBeingDragged keeps the whole window on the screen.
		var target: Vector2 = position + event.position - drag_start
		position = Vector2(clampf(target.x, 0.0, 1280.0 - size.x), clampf(target.y, 0.0, 800.0 - size.y)).round()
		accept_event()

func text(value: String, top_left: Vector2, color: Color, font_size: int = FONT_SIZE, align_right: bool = false) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(top_left.x - (width if align_right else 0.0), top_left.y + font.get_ascent(font_size))
	text_layer.draw_string_outline(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color.BLACK)
	text_layer.draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var background: Texture2D = art.textures["SelectItemBackground.png"]
	draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)

func draw_texts() -> void:
	# Tabs: white and lifted when selected, grey otherwise (TabButtonList).
	for index in range(TABS.size()):
		var label: String = TABS[index]
		var center := point(TAB_OFFSET + Vector2(TAB_STEP * index, 0))
		var measure := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var lift := measure.y / 3.0 if index == tab else 0.0
		text(label, center - Vector2(measure.x * 0.5, measure.y * 0.5 + lift), Color.WHITE if index == tab else Color.GRAY)
	var name := NO_ITEM
	var color := Color.WHITE
	var cost := "---"
	var description := ""
	if Items.has_id(hovered):
		var data: Dictionary = Items.definition(hovered)
		name = data.name
		color = Items.color(hovered)
		cost = str(roundi(Items.delay(hovered)))
		description = data.description
	text(name, point(NAME_OFFSET), color, NAME_SIZE)
	text("Delay Cost:", point(DELAY_LABEL_OFFSET), Color.WHITE, NAME_SIZE)
	text(cost, point(COST_OFFSET), Color.WHITE, NAME_SIZE, true)
	var lines := description.split("\n")
	for index in range(lines.size()):
		text(lines[index], point(DESCRIPTION_OFFSET + Vector2(0, LINE_HEIGHT * index)), Color.WHITE)
