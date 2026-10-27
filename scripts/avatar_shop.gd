extends Control
## Avatar Shop from the original client frames (ADR-130, AVATAR_SHOP_ORIGINAL).
## Geometry is the native 800×600 store: card/price/status rules come from
## the client draw routine 0x44a000; the rest is measured on gb-avatar.png.
const ShopArt = preload("res://scripts/classic_shop_art.gd")
const XfsStyle = preload("res://scripts/xfs_shop_style.gd")
const AvatarArt = preload("res://scripts/avatar_art.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Ranks = preload("res://scripts/classic_ranks.gd")
var art = ShopArt.new()
var avatar_art = AvatarArt.new()
## Approved BICUBIC4× chrome; false draws the native frames (fallback path).
var use_hd := true:
	set(value):
		use_hd = value
		art.use_hd = value

const CANVAS := Vector2(800,600)
const CARD_ORIGIN := Vector2(21,69)
const CARD_STEP := Vector2(163,161)
const CARD_SIZE := Vector2(160,156)
## Light portrait window inside store_avatar:0.
const PORTRAIT_AREA := Rect2(9,23,86,79)
## 0x44a000 draws the s*.img thumbnail at card+(52,62)+IMG pivot; all nine
## cards of gb-avatar.png match this anchor.
const PORTRAIT_ANCHOR := Vector2(52,62)
const ROW_ORIGIN := Vector2(571,109)
const ROW_SIZE := Vector2(176,17)
const ROWS_VISIBLE := 14
const LETTERBOX := Color("0b1622")
const HEADER_TEXT := Color8(208,236,245)
const GOLD_TEXT := Color8(86,175,190)
const CASH_TEXT := Color8(172,196,150)
const ROW_TEXT := Color8(180,241,255)
## Catalog bonus index (attack, health, defense, shield, shot_delay,
## item_delay, bunge, popularity) → store_icon pair, in client draw order.
const STAT_DISPLAY := [[4,8],[7,10],[0,12],[2,14],[1,16],[5,18],[6,20],[3,22]]
const SHOT_DELAY := 4

class Paint extends Node2D:
	var shop
	func _draw() -> void:
		shop.paint(self)

## Draws one detail layer through a callable (purchase window contents).
class Drawer extends Node2D:
	var draw_call: Callable
	func _draw() -> void:
		draw_call.call(self)

class CardButton extends Button:
	var shop
	var item: Dictionary
	var selected := false
	func _draw() -> void:
		shop.paint_card(self)

class RowButton extends Button:
	var shop
	var item: Dictionary
	func _draw() -> void:
		shop.paint_row(self)

## Bitmap text node so names stay inspectable and clipped to their area.
class ClassicText extends Control:
	var art
	var text := ""
	var color := Color.WHITE
	func _draw() -> void:
		art.draw_text(self,text,Vector2.ZERO,color)

var host
var model
var content: Control
var painter
var backdrop: ColorRect
var cards: Control
var modal: Control
var purchase_key := ""
var blocked: Array = []
var status_label: Label
var points_label: Label
var attribute_labels: Array = []
var add_buttons: Array = []
var remove_buttons: Array = []
var try_button: TextureButton
var buy_button: TextureButton
## "Experimentar", "Vestir" or "Vestido": the Try image has no caption.
var try_state := "Experimentar"
var left_button: TextureButton
var right_button: TextureButton
var empty_label: Label
var elapsed := 0.0
var inventory_scroll: ScrollContainer
var inventory_rows: VBoxContainer
var attributes_panel: Control
var attributes_button: Button
var gender_button: Button
var gift_button: TextureButton
var sell_button: TextureButton
var laundry_button: TextureButton
var exit_button: TextureButton
var buddy_button: TextureButton
var charge_button: TextureButton
var category_buttons: Array = []
var window_scale_state: Dictionary = {}
var attributes_feedback: Label
var portrait_cache: Dictionary = {}

func setup(owner, shop_model) -> void:
	host = owner
	model = shop_model
	# The arena uses a 1280x800 stretch canvas. Shop owns its native 4:3 fit directly
	# in window pixels, then restores the host's settings on every exit path.
	var window := get_window()
	window_scale_state = {"window":window,"size":window.content_scale_size,"mode":window.content_scale_mode,"factor":window.content_scale_factor}
	window.content_scale_size = Vector2i.ZERO
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_factor = 1.0
	set_as_top_level(true)
	position = Vector2.ZERO
	backdrop = ColorRect.new()
	backdrop.color = LETTERBOX
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	content = Control.new()
	content.size = CANVAS
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(content)
	painter = Paint.new()
	painter.shop = self
	content.add_child(painter)
	# Same assigned-rank badge as the lobby card (ADR-102), at the native slot.
	var badge := TextureRect.new()
	badge.name = "RankBadge"
	badge.texture = Ranks.icon(Ranks.normalize(model.profile.rank),false)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_SCALE
	badge.position = Vector2(172,9)
	badge.tooltip_text = Ranks.description(Ranks.normalize(model.profile.rank))
	content.add_child(badge)
	badge.size = Vector2(15,25)
	build_controls()
	build_side_controls()
	build_attributes()
	get_viewport().size_changed.connect(fit_viewport)
	fit_viewport()
	refresh(0,0)

func build_controls() -> void:
	var names := ["Cabeça","Corpo","Óculos","Bandeira"]
	var entries := ["b_store_cap","b_store_cloth","b_store_glasse","b_store_flag"]
	for i in range(4):
		var node := frame_button(entries[i],Vector2(35+i*53,556),func(): model.selected_key=""; refresh(i,0))
		node.tooltip_text = names[i]
		category_buttons.append(node)
	left_button = frame_button("b_store_up",Vector2(517,80),func(): refresh(model.category,model.page-1))
	right_button = frame_button("b_store_down",Vector2(517,488),func(): refresh(model.category,model.page+1))
	try_button = frame_button("b_store_puton",Vector2(359,556),try_selected)
	buy_button = frame_button("b_store_buy",Vector2(448,556),open_buy)
	buy_button.tooltip_text = "Comprar"
	sell_button = frame_button("b_myavatar_sell",Vector2(566,513),func(): pass)
	sell_button.disabled = true
	sell_button.tooltip_text = "Venda indisponível no catálogo local"
	laundry_button = frame_button("b_myavatar_dry",Vector2(639,513),func(): model.reset_preview(); refresh(model.category,model.page))
	laundry_button.tooltip_text = "Restaurar a prévia ao conjunto vestido"
	gift_button = frame_button("b_myavatar_gift",Vector2(712,513),func(): pass)
	gift_button.disabled = true
	gift_button.tooltip_text = "Presentes indisponíveis no treino offline"
	exit_button = frame_button("b_store_exit",Vector2(562,550),func(): host.leave_shop())
	buddy_button = frame_button("b_store_buddygame",Vector2(680,550),func(): pass)
	buddy_button.disabled = true
	buddy_button.tooltip_text = "Amigos e contas indisponíveis no treino offline"
	charge_button = frame_button("b_store_cashcharge",Vector2(485,7),func(): pass)
	charge_button.disabled = true
	charge_button.tooltip_text = "Saldo local de teste; recarga com dinheiro real indisponível"
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.position = ROW_ORIGIN
	inventory_scroll.size = Vector2(ROW_SIZE.x,ROW_SIZE.y*ROWS_VISIBLE)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	content.add_child(inventory_scroll)
	inventory_rows = VBoxContainer.new()
	inventory_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_rows.add_theme_constant_override("separation",0)
	inventory_scroll.add_child(inventory_rows)
	inventory_scroll.size = Vector2(ROW_SIZE.x,ROW_SIZE.y*ROWS_VISIBLE)
	frame_button("b_scroll_up",Vector2(759,117),func(): inventory_scroll.scroll_vertical-=int(ROW_SIZE.y))
	frame_button("b_scroll_down",Vector2(759,326),func(): inventory_scroll.scroll_vertical+=int(ROW_SIZE.y))
	empty_label = Label.new()
	empty_label.text = "Nenhum avatar nesta categoria"
	empty_label.position = Vector2(38,266)
	empty_label.size = Vector2(460,28)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.visible = false
	content.add_child(empty_label)

## Gender and pilot attributes have no control in the original store. They sit
## in the letterbox beside the 800×600 stage, leaving the original frame intact.
func build_side_controls() -> void:
	gender_button = side_button("",toggle_gender)
	gender_button.tooltip_text = "Alternar gênero do conjunto"
	attributes_button = side_button("Atributos",open_attributes)
	attributes_button.tooltip_text = "Atributos do piloto"
	update_gender_caption()
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",15)
	status_label.add_theme_color_override("font_color",Color("ffe999"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_label)

func side_button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_size_override("font_size",15)
	for i in range(4):
		node.add_theme_stylebox_override(["normal","hover","pressed","disabled"][i],XfsStyle.new("button",i))
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.add_theme_color_override("font_color",Color("003d57"))
	node.add_theme_color_override("font_hover_color",Color("003d57"))
	node.add_theme_color_override("font_pressed_color",Color("5a3700"))
	node.add_theme_color_override("font_disabled_color",Color("535d5f"))
	node.pressed.connect(action)
	add_child(node)
	return node

func update_gender_caption() -> void:
	gender_button.text = "♂ Masculino" if model.profile.gender==0 else "♀ Feminino"

## Original EPA button: frames 0 ready, 1 mouse, 2 push, 3 disable (4 active).
func frame_button(entry: String, at: Vector2, action: Callable) -> TextureButton:
	var node := TextureButton.new()
	node.name = entry
	node.position = at
	node.ignore_texture_size = true
	node.stretch_mode = TextureButton.STRETCH_SCALE
	node.focus_mode = Control.FOCUS_NONE
	node.size = art.size(entry+":0")
	paint_button(node,entry,false)
	node.pressed.connect(action)
	content.add_child(node)
	node.size = art.size(entry+":0")
	return node

func paint_button(node: TextureButton, entry: String, active: bool) -> void:
	var last := maxi(0,art.frame_count(entry)-1)
	node.texture_normal = art.texture("%s:%d" % [entry,4 if active and last>=4 else 0])
	node.texture_hover = art.texture("%s:%d" % [entry,4 if active and last>=4 else mini(1,last)])
	node.texture_pressed = art.texture("%s:%d" % [entry,mini(2,last)])
	node.texture_disabled = art.texture("%s:%d" % [entry,mini(3,last)])

func fit_viewport() -> void:
	size = get_viewport_rect().size
	var factor := minf(size.x/CANVAS.x,size.y/CANVAS.y)
	content.scale = Vector2.ONE*factor
	content.position = (size-CANVAS*factor)*0.5
	backdrop.size = size
	# Side controls live in the right letterbox and never cross the stage; a
	# window without room for them (near 4:3) stacks them over the top-left.
	var strip := Rect2(content.position+Vector2(CANVAS.x*factor,0),Vector2(maxf(0,size.x-content.position.x-CANVAS.x*factor),size.y))
	var fits := strip.size.x >= 72
	var width := minf(200,strip.size.x-16) if fits else 120.0
	var x := strip.position.x+8 if fits else 8.0
	var font_size := clampi(int(width/7),11,15)
	for node in [gender_button,attributes_button,status_label]:
		node.add_theme_font_size_override("font_size",font_size)
	gender_button.position = Vector2(x,16)
	gender_button.size = Vector2(width,36)
	attributes_button.position = Vector2(x,60)
	attributes_button.size = Vector2(width,36)
	status_label.position = Vector2(x,108)
	status_label.size = Vector2(width,160)

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(fit_viewport):
		get_viewport().size_changed.disconnect(fit_viewport)
	if not window_scale_state.is_empty():
		var window: Window = window_scale_state.window
		if is_instance_valid(window):
			window.content_scale_size = window_scale_state.size
			window.content_scale_mode = window_scale_state.mode
			window.content_scale_factor = window_scale_state.factor
		window_scale_state.clear()

## Original thumbnails only: XFS s*.img, or the legacy OpenBound portrait.
func portrait_for(item: Dictionary) -> Texture2D:
	var path := str(item.get("portrait",""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not portrait_cache.has(path):
		portrait_cache[path] = load(path)
	return portrait_cache[path]

## Thumbnail at native size: anchor + pivot for XFS records; legacy
## OpenBound portraits (no pivot) are centered on the same anchor.
func portrait_rect(item: Dictionary, anchor: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = portrait_for(item)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	var pivot = item.get("portrait_pivot")
	var shown := portrait_size(node.texture)
	node.position = anchor+(Vector2(pivot[0],pivot[1]) if pivot is Array and pivot.size()==2 else -shown*0.5)
	return node

func portrait_size(paint: Texture2D) -> Vector2:
	return paint.get_size() if paint != null else Vector2.ZERO

func bonus_description(item: Dictionary) -> String:
	var names := ["Ataque","Vida","Defesa","Regeneração","Atraso do tiro","Atraso do item","Cratera","Gold"]
	var values: Array=item.get("bonuses",[])
	var lines: PackedStringArray=[]
	for i in range(values.size()):
		if int(values[i])!=0:
			lines.append("%s: %+d" % [names[i],int(values[i])])
	return "\n".join(lines) if not lines.is_empty() else "Sem modificadores"

## 0x44a000: shot_delay shows "+" for values ≤0 and the negated value; every
## other stat shows "−" (even frame) only below zero, also negated.
static func stat_icon(index: int, base: int, value: int) -> Array:
	if index == SHOT_DELAY:
		return [base+1,-value] if value<=0 else [base,value]
	return [base,-value] if value<0 else [base+1,value]

## Nonzero item bonuses in client draw order: [icon frame, shown value].
func stat_entries(item: Dictionary) -> Array:
	var values: Array = item.get("bonuses",[])
	var result: Array = []
	for pair in STAT_DISPLAY:
		var value := int(values[pair[0]]) if pair[0]<values.size() else 0
		if value != 0:
			result.append(stat_icon(pair[0],pair[1],value))
	return result

func category_icon(category: int, gender: int) -> String:
	var g := clampi(gender,0,1)
	return "store_icon:%d" % [2+g,g,4+g,6][clampi(category,0,3)]

func toggle_gender() -> void:
	if model.profile.set_gender(1-model.profile.gender):
		model.preview = model.profile.equipped_set()
		model.selected_key = ""
		update_gender_caption()
		refresh(model.category,0)
	else:
		status_label.text = "Não foi possível salvar o gênero"

func build_attributes() -> void:
	attributes_panel = Control.new()
	attributes_panel.size = CANVAS
	attributes_panel.visible = false
	content.add_child(attributes_panel)
	var dim := ColorRect.new()
	dim.color = Color(0,0,0,0.65)
	dim.size = attributes_panel.size
	attributes_panel.add_child(dim)
	var box := Panel.new()
	box.size = Vector2(360,245)
	box.position = (CANVAS-box.size)*0.5
	box.add_theme_stylebox_override("panel",XfsStyle.new())
	box.name = "AttributeBox"
	attributes_panel.add_child(box)
	label(box,"Atributos do piloto",Vector2(16,12),Vector2(330,26),18)
	points_label = label(box,"",Vector2(16,44),Vector2(330,22),12)
	var attr_names := ["Ataque","Vida","Defesa","Regen.","Atraso tiro","Atraso item","Cratera","Gold %"]
	# Same store_icon "+" glyphs the client uses for each status.
	var icons := {}
	for pair in STAT_DISPLAY:
		icons[pair[0]] = pair[1]+1
	for i in range(8):
		var pos := Vector2(16+(i%2)*166,80+int(i/2)*25)
		var glyph := TextureRect.new()
		glyph.texture = art.texture("store_icon:%d" % icons[i])
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glyph.position = pos+Vector2(0,3)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.name = "AttributeIcon%d" % i
		box.add_child(glyph)
		glyph.size = Vector2(17,14)
		label(box,attr_names[i],pos+Vector2(20,0),Vector2(65,22),10)
		remove_buttons.append(text_button(box,"−",pos+Vector2(85,0),Vector2(22,22),func(): adjust(i,-1)))
		attribute_labels.append(label(box,"0",pos+Vector2(110,0),Vector2(25,22),11))
		add_buttons.append(text_button(box,"+",pos+Vector2(135,0),Vector2(22,22),func(): adjust(i,1)))
	attributes_feedback = label(box,"",Vector2(16,178),Vector2(328,16),10)
	text_button(box,"Salvar",Vector2(92,195),Vector2(90,28),func():
		if model.profile.commit_attributes(model.draft_attributes):
			status_label.text = "Atributos salvos"
			close_attributes()
		else:
			status_label.text = "Falha ao salvar atributos"
			attributes_feedback.text = "Não foi possível salvar. Tente novamente."
		update_attributes()
		painter.queue_redraw()
	).name = "SaveAttributes"
	text_button(box,"Cancelar",Vector2(192,195),Vector2(90,28),close_attributes).name = "CancelAttributes"

func label(parent: Node, text: String, pos: Vector2, area: Vector2, font_size: int = 11) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",Color.WHITE)
	node.add_theme_color_override("font_outline_color",Color.BLACK)
	node.add_theme_constant_override("outline_size",2)
	parent.add_child(node)
	# The default font may have enlarged the label before the font override.
	node.size = area
	return node

func text_button(parent: Node, text: String, pos: Vector2, area: Vector2, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.add_theme_font_size_override("font_size",11)
	for i in range(4):
		node.add_theme_stylebox_override(["normal","hover","pressed","disabled"][i],XfsStyle.new("button",i))
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.add_theme_color_override("font_color",Color("003d57"))
	node.add_theme_color_override("font_hover_color",Color("003d57"))
	node.add_theme_color_override("font_disabled_color",Color("535d5f"))
	node.pressed.connect(action)
	parent.add_child(node)
	node.size = area
	return node

func open_attributes() -> void:
	if is_instance_valid(modal) or attributes_panel.visible:
		return
	model.draft_attributes = model.profile.attributes.duplicate()
	attributes_feedback.text = ""
	block_controls(self,attributes_panel)
	update_attributes()
	attributes_panel.visible = true
	content.move_child(attributes_panel,content.get_child_count()-1)

func close_attributes() -> void:
	attributes_panel.visible = false
	model.draft_attributes = model.profile.attributes.duplicate()
	restore_controls()
	update_attributes()

func adjust(index: int, delta: int) -> void:
	var values: Array = model.draft_attributes.duplicate()
	values[index] = int(values[index])+delta
	if Attributes.valid(values,model.profile.level()):
		model.draft_attributes = values
	update_attributes()

func update_attributes() -> void:
	var total := 0
	for value in model.draft_attributes:
		total += int(value)
	var remaining := Attributes.budget(model.profile.level())-total
	points_label.text = "Nível %d · %d pontos restantes" % [model.profile.level(),remaining]
	for i in range(8):
		attribute_labels[i].text = str(model.draft_attributes[i])
		add_buttons[i].disabled = remaining <= 0 or int(model.draft_attributes[i]) >= 50
		remove_buttons[i].disabled = int(model.draft_attributes[i]) <= 0

func update_inventory() -> void:
	for child in inventory_rows.get_children():
		inventory_rows.remove_child(child)
		child.queue_free()
	for category in range(4):
		for item in model.catalog.inventory_items(model.profile.gender,category):
			if not model.profile.owns(item.key):
				continue
			var row := RowButton.new()
			row.shop = self
			row.item = item
			row.flat = true
			row.focus_mode = Control.FOCUS_NONE
			row.custom_minimum_size = ROW_SIZE
			row.name = "Owned_"+str(item.key).replace(":","_")
			row.tooltip_text = "Vestir "+str(item.name)+"\n"+bonus_description(item)
			for state in ["normal","hover","pressed","disabled","focus"]:
				row.add_theme_stylebox_override(state,StyleBoxEmpty.new())
			row.pressed.connect(func(): equip_inventory(item.key))
			inventory_rows.add_child(row)

func inventory_count() -> int:
	return inventory_rows.get_child_count() if is_instance_valid(inventory_rows) else 0

func equip_inventory(key: String) -> void:
	if model.profile.equip(key):
		model.preview = model.profile.equipped_set()
		model.selected_key = key
		model.query = ""
		status_label.text = "Avatar vestido e salvo"
		refresh(int(model.catalog.find(key).category),0)
	else:
		status_label.text = "Não foi possível salvar o avatar"

## Card grid of owned items (kept for the model's inventory filter).
func switch_tab(inventory: bool) -> void:
	model.inventory = inventory
	model.preview = model.profile.equipped_set()
	model.selected_key = ""
	refresh(model.category,0)

func refresh(category: int, page: int) -> void:
	if is_instance_valid(cards):
		content.remove_child(cards)
		cards.queue_free()
	cards = Control.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(cards)
	content.move_child(cards,1)
	var rows: Array = model.filter(category,model.query,model.inventory,page)
	empty_label.visible = rows.is_empty()
	for index in range(rows.size()):
		var item: Dictionary = rows[index]
		var card := CardButton.new()
		card.shop = self
		card.item = item
		card.selected = model.selected_key == item.key
		card.name = "Avatar"+str(index)
		card.position = CARD_ORIGIN+Vector2(index%3,int(index/3))*CARD_STEP
		card.focus_mode = Control.FOCUS_NONE
		for state in ["normal","hover","pressed","disabled","focus"]:
			card.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		card.tooltip_text = item.name+"\n"+str(item.get("description",""))+"\n"+bonus_description(item)
		card.pressed.connect(func():
			if model.select(item.key):
				refresh(model.category,model.page)
			else:
				status_label.text = "Não foi possível salvar o avatar"
		)
		cards.add_child(card)
		card.size = CARD_SIZE
		var portrait := portrait_rect(item,PORTRAIT_ANCHOR)
		portrait.name = "Portrait"
		card.add_child(portrait)
		portrait.size = portrait_size(portrait.texture)
		var title := ClassicText.new()
		title.name = "AvatarName"
		title.art = art
		title.text = str(item.name)
		title.position = Vector2(24,5)
		title.clip_contents = true
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title)
		title.size = Vector2(100,12)
	var item: Dictionary = model.catalog.find(model.selected_key)
	var owned: bool = not item.is_empty() and model.profile.owns(model.selected_key)
	var dressed: bool = owned and model.profile.equipped_set().get(str(category)) == model.selected_key and model.preview.get(str(category)) == model.selected_key
	try_state = ("Vestido" if dressed else "Vestir") if owned else "Experimentar"
	try_button.tooltip_text = try_state
	try_button.disabled = model.inventory or item.is_empty() or (dressed if owned else model.preview.get(str(category)) == model.selected_key)
	buy_button.disabled = model.inventory or item.is_empty() or model.profile.owns(model.selected_key) or not can_buy(item)
	left_button.disabled = model.page == 0
	right_button.disabled = model.page+1 >= model.last_page
	for i in range(category_buttons.size()):
		var entries := ["b_store_cap","b_store_cloth","b_store_glasse","b_store_flag"]
		paint_button(category_buttons[i],entries[i],i==category)
	for node in [left_button,right_button,try_button,buy_button,sell_button,laundry_button,gift_button,exit_button,buddy_button,charge_button]:
		paint_button(node,node.name,false)
	update_inventory()
	update_attributes()
	painter.queue_redraw()

func can_buy(item: Dictionary) -> bool:
	if item.get("source")=="xfs" and (not item.get("buyable",false) or not item.get("art_available",false)):
		return false
	return (int(item.get("gold_price",0))>0 and model.profile.gold>=int(item.gold_price)) or (int(item.get("cash_price",0))>0 and model.profile.cash>=int(item.cash_price))

func try_selected() -> void:
	if model.try_selected():
		status_label.text = "Avatar vestido e salvo" if model.profile.owns(model.selected_key) else "Prévia temporária · compre para vestir"
	else:
		status_label.text = "Não foi possível salvar o avatar"
	refresh(model.category,model.page)

func open_buy() -> void:
	if is_instance_valid(modal) or attributes_panel.visible or buy_button.disabled:
		return
	block_controls(self)
	purchase_key = model.selected_key
	var item: Dictionary = model.catalog.find(purchase_key)
	modal = Control.new()
	modal.size = CANVAS
	content.add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0,0,0,0.5)
	dim.size = modal.size
	modal.add_child(dim)
	var window_size := art.size("store_window_back:1")
	var box := TextureRect.new()
	box.name = "PurchasePanel"
	box.texture = art.texture("store_window_back:1")
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.position = (CANVAS-window_size)*0.5
	modal.add_child(box)
	box.size = window_size
	# Same anchor rule, centered on the window's left dark square.
	var portrait := portrait_rect(item,box.position+Vector2(69,89))
	portrait.name = "PurchasePortrait"
	modal.add_child(portrait)
	portrait.size = portrait_size(portrait.texture)
	var details := Drawer.new()
	details.name = "PurchaseDetails"
	details.draw_call = func(view: CanvasItem): paint_purchase(view,item)
	box.add_child(details)
	# Like PopupBuyAvatar: one button per priced currency, then Cancel; the
	# row is centered under the window's dark area.
	var actions: Array = []
	for currency: String in ["gold","cash"]:
		if int(item.get(currency+"_price",0)) > 0:
			actions.append(currency)
	actions.append("cancel")
	var step := art.size("b_storewindow_cancel:0").x+8
	var x := (window_size.x-(step*actions.size()-8))*0.5
	for action: String in actions:
		var node := TextureButton.new()
		node.name = "CancelPurchase" if action == "cancel" else action.capitalize()+"Purchase"
		var entry := "b_storewindow_"+action
		node.ignore_texture_size = true
		node.stretch_mode = TextureButton.STRETCH_SCALE
		node.focus_mode = Control.FOCUS_NONE
		paint_button(node,entry,false)
		node.position = box.position+Vector2(x,144)
		if action == "cancel":
			node.pressed.connect(close_buy)
		else:
			var price := int(item.get(action+"_price",0))
			var balance: int = model.profile.gold if action == "gold" else model.profile.cash
			node.disabled = balance < price
			node.tooltip_text = "Pagar %s %s · saldo %s" % [format_number(price),action.capitalize(),format_number(balance)]
			node.pressed.connect(func():
				if not is_instance_valid(modal):
					return
				var result: String = model.confirm_buy(purchase_key,action)
				close_buy()
				status_label.text = "Compra concluída" if result == "ok" else "Compra não concluída: "+result
				refresh(model.category,model.page)
			)
		modal.add_child(node)
		node.size = art.size(entry+":0")
		x += step

func paint_purchase(view: CanvasItem, item: Dictionary) -> void:
	art.draw_text(view,str(item.get("name","")),Vector2(122,52),Color.WHITE)
	var y := 72.0
	for entry in stat_entries(item).slice(0,3):
		art.draw(view,"store_icon:%d" % entry[0],Vector2(122,y))
		art.draw_digits(view,40,"%02d" % entry[1],Vector2(141,y+1),6,2)
		y += 18
	# Card price rows (y+110/+126) land inside the window's dark area.
	draw_prices(view,item,Vector2(140,-12))

func close_buy() -> void:
	if is_instance_valid(modal):
		modal.get_parent().remove_child(modal)
		modal.queue_free()
	modal = null
	restore_controls()
	purchase_key = ""

func restore_controls() -> void:
	for entry in blocked:
		if is_instance_valid(entry.node):
			entry.node.disabled = entry.disabled
	blocked.clear()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		# Mark handled while still in the tree; leave_shop removes this shop.
		get_viewport().set_input_as_handled()
		if is_instance_valid(modal):
			close_buy()
		elif attributes_panel.visible:
			close_attributes()
		else:
			host.leave_shop()

func _process(delta: float) -> void:
	elapsed += delta
	painter.queue_redraw()

func format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in range(text.length()):
		if i>0 and (text.length()-i)%3 == 0:
			result += ","
		result += text[i]
	return result

## Card body (0x44a000). Children draw the portrait and name on top.
func paint_card(card: CardButton) -> void:
	var item := card.item
	art.draw(card,"store_avatar:%d" % (1 if card.selected else 0),Vector2.ZERO)
	art.draw(card,category_icon(int(item.get("category",0)),int(item.get("gender",0))),Vector2(7,6))
	if int(item.get("gender",2)) in [0,1]:
		art.draw(card,"store_avatar:%d" % (2+int(item.gender)),Vector2(125,5))
	var entries := stat_entries(item)
	for n in range(mini(3,entries.size())):
		art.draw(card,"store_icon:%d" % entries[n][0],Vector2(104,34+18*n))
		art.draw_digits(card,40,"%02d" % entries[n][1],Vector2(123,35+18*n),6,2)
	draw_prices(card,item,Vector2.ZERO)

## Cash row y+110 (yellow, comma 279), Gold row y+126 (cyan, comma 280).
func draw_prices(view: CanvasItem, item: Dictionary, origin: Vector2) -> void:
	var cash := int(item.get("cash_price",0))
	var gold := int(item.get("gold_price",0))
	if gold > 0:
		art.draw_price(view,60,280,gold,origin+Vector2(14,126))
		art.draw(view,"store_avatar:5",origin+Vector2(110,126))
	else:
		art.draw(view,"store_avatar:6",origin+Vector2(66,126))
	if cash > 0:
		art.draw_price(view,50,279,cash,origin+Vector2(14,110))
		art.draw(view,"store_avatar:4",origin+Vector2(110,110))
	else:
		art.draw(view,"store_avatar:7",origin+Vector2(66,110))

## Inventory row: selection bar, equipped arrow, icon, name, two stats R→L.
func paint_row(row: RowButton) -> void:
	var item := row.item
	var category := int(item.get("category",0))
	if model.selected_key == item.key:
		art.draw(row,"store_myavatar:1",Vector2.ZERO)
	if model.profile.equipped_set().get(str(category)) == item.key:
		art.draw(row,"store_icon:7",Vector2(0,4))
	art.draw(row,category_icon(category,int(item.get("gender",0))),Vector2(6,2))
	var entries := stat_entries(item)
	# Name stops before the first status column drawn on this row.
	var limit: float = ROW_SIZE.x-24.0 if entries.is_empty() else 127.0-25.0*(mini(2,entries.size())-1)
	art.draw_text(row,str(item.name).substr(0,int(limit/ShopArt.FONT_ADVANCE)),Vector2(24,3),ROW_TEXT)
	for k in range(mini(2,entries.size())):
		art.draw(row,"store_icon:%d" % entries[k][0],Vector2(153-25*k,2))
		art.draw_digits(row,40,"%02d" % entries[k][1],Vector2(162-25*k,4),6,2)

func paint(view: Node2D) -> void:
	art.draw(view,"store_back:0",Vector2.ZERO)
	art.draw(view,"store_myavatar:0",Vector2(552,5))
	paint_header(view)
	var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
	avatar_art.draw(view,set_data,Transform2D(0,Vector2(-1,1),0,Vector2(612,92)),elapsed,Color.WHITE)
	var values: Array = Attributes.with_equipment(model.profile.attributes,model.catalog.bonuses(set_data))
	for i in range(STAT_DISPLAY.size()):
		var pair: Array = STAT_DISPLAY[i]
		var at := Vector2(672+(i%2)*57,39+int(i/2)*17)
		var shown := stat_icon(pair[0],pair[1],int(values[pair[0]]))
		art.draw(view,"store_icon:%d" % shown[0],at)
		art.draw_digits(view,40,"%02d" % shown[1],at+Vector2(20,0),6,2)
	art.draw_digits(view,0,"%3d" % mini(999,inventory_count()),Vector2(745,16),8,3)

func paint_header(view: Node2D) -> void:
	var code := Ranks.normalize(model.profile.rank)
	art.draw_text(view,str(model.profile.nickname).substr(0,22),Vector2(191,23),HEADER_TEXT)
	art.draw_text(view,"Rank",Vector2(326,9),HEADER_TEXT)
	right_text(view,Ranks.title(code),406,9,HEADER_TEXT)
	right_text(view,"%d GP" % int(model.profile.xp),412,23,HEADER_TEXT)
	art.draw_text(view,"GOLD :",Vector2(173,39),GOLD_TEXT)
	right_text(view,str(int(model.profile.gold)),264,39,GOLD_TEXT,173+42)
	art.draw_text(view,"CASH :",Vector2(320,39),CASH_TEXT)
	right_text(view,str(int(model.profile.cash)),412,39,CASH_TEXT,320+42)

## Right-aligned like the client; a longer local balance (test funds reach nine
## digits) starts after its caption instead of covering it.
func right_text(view: CanvasItem, text: String, right: float, y: float, color: Color, minimum_x: float = -INF) -> void:
	art.draw_text(view,text,Vector2(maxf(minimum_x,right-ShopArt.text_width(text)),y),color)

func block_controls(node: Node, except_node: Node = null) -> void:
	if node == except_node:
		return
	if node is BaseButton:
		blocked.append({"node":node,"disabled":node.disabled})
		node.disabled = true
	for child in node.get_children():
		block_controls(child,except_node)
