extends Control
## XFS client shop; native proportions are independent of arena transforms.
const SpritePose = preload("res://scripts/sprite_pose.gd")
const Assets := "res://assets/openbound/shop/"
const ShopHD = preload("res://scripts/shop_hd.gd")
const XfsStyle = preload("res://scripts/xfs_shop_style.gd")
const CardStyle = preload("res://scripts/shop_card_style.gd")
var hd = ShopHD.new()
var use_hd := true
const AvatarArt = preload("res://scripts/avatar_art.gd")
var avatar_art = AvatarArt.new()
const Attributes = preload("res://scripts/player_attributes.gd")
class Paint extends Node2D:
	var shop
	func _draw() -> void:
		shop.paint(self)
var host
var model
var content: Control
var painter
var cards: Control
var modal: Control
var purchase_key := ""
var blocked: Array = []
var status_label: Label
var balance_label: Label
var points_label: Label
var attribute_labels: Array = []
var add_buttons: Array = []
var remove_buttons: Array = []
var try_button
var try_caption: Label
var buy_button
var page_label: Label
var empty_label: Label
var left_button
var right_button
var search: LineEdit
var elapsed := 0.0
var texture_cache: Dictionary = {}
var animated: Array = []
var tab_buttons: Array = []
var inventory_rows: VBoxContainer
var attributes_panel: Control
var attributes_button: Button
var gender_button: Button
var gift_button
var preview_mobile := false
var category_buttons: Array = []
var chrome_labels: Array = []
var xfs_frames: Dictionary = {}
var xfs_background: Texture2D
var xfs_portraits: Dictionary = {}
var backdrop: TextureRect
var preview_buttons: Array = []
var inventory_count: Label
var wide_background: Texture2D
var empty_slot_portrait: Texture2D
var shop_font: Font
var window_scale_state: Dictionary = {}
var attributes_feedback: Label
const CANVAS := Vector2(800,600)
const GRID_ORIGIN := Vector2(25,70)
const GRID_STEP := Vector2(164,160)
const CARD_SIZE := Vector2(160,156)
const PORTRAIT_SIZE := Vector2(84,76)
const CASH_COLOR := Color("ffe34e")
const GOLD_COLOR := Color("74edf1")
# AttributeMenu.AddAttributePoints, original 6-column ButtonIcons sheet.
const ATTRIBUTE_ICONS := [13,17,15,23,9,19,21,11]
func texture(path: String):
	if use_hd:
		var derived = hd.texture(path)
		if derived != null:
			return derived
	if not texture_cache.has(path):
		texture_cache[path] = load(Assets + path + ".png")
	return texture_cache[path]
func density(path: String) -> float:
	return 4.0 if use_hd and hd.texture(path) != null else 1.0
func atlas(path: String, cell: Vector2, frame: int) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = texture(path)
	cell *= density(path)
	var columns := int(result.atlas.get_width() / cell.x)
	result.region = Rect2(Vector2(frame % columns, int(frame / columns)) * cell, cell)
	return result
func button_texture(path: String, cell: Vector2, frame: int, icon_height: float, area: Vector2) -> AtlasTexture:
	var result := atlas(path,cell,frame)
	if icon_height>0:
		# Transparent presentation padding reserves caption space without changing
		# the native frame region, registration or animation clock.
		var padding := Vector2(maxf(0,area.x-cell.x),cell.y*(area.y/icon_height-1))*density(path)
		result.margin = Rect2(Vector2(padding.x*0.5,0),padding)
	return result
func label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int = 11) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",Color.WHITE)
	node.add_theme_color_override("font_outline_color",Color.BLACK)
	node.add_theme_constant_override("outline_size",2)
	parent.add_child(node)
	# The default 16px font may have enlarged the label before the font override.
	# Reapply its allocated box once the actual font and parent are known.
	node.size = size
	return node
func button(parent: Node, text: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.size = size
	node.add_theme_font_size_override("font_size",11)
	for i in range(4):
		node.add_theme_stylebox_override(["normal","hover","pressed","disabled"][i],XfsStyle.new("button",i))
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.add_theme_color_override("font_color",Color("003d57"))
	node.add_theme_color_override("font_hover_color",Color("003d57"))
	node.add_theme_color_override("font_pressed_color",Color("5a3700"))
	node.add_theme_color_override("font_disabled_color",Color("535d5f"))
	node.pressed.connect(action)
	parent.add_child(node)
	node.size = size
	return node
func sprite_button(parent: Node, path: String, cell: Vector2, pos: Vector2, action: Callable, normal: int = 0, hover: int = 1, pressed: int = 2, disabled: int = -1, area: Vector2 = Vector2.ZERO, icon_height: float = 0.0) -> TextureButton:
	var node := TextureButton.new()
	node.position = pos
	node.ignore_texture_size = true
	node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	node.size = cell if area==Vector2.ZERO else area
	node.texture_normal = button_texture(path,cell,normal,icon_height,node.size)
	node.texture_hover = button_texture(path,cell,hover,icon_height,node.size)
	node.texture_pressed = button_texture(path,cell,pressed,icon_height,node.size)
	node.texture_disabled = button_texture(path,cell,normal if disabled < 0 else disabled,icon_height,node.size)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
func animated_button(path: String, cell: Vector2, pos: Vector2, text: String, action: Callable, normal: int, hover_end: int, click_start: int, click_end: int, disabled: int, active: int = -1):
	var category := active>=0
	var area := Vector2(62,46) if category else Vector2(82,64)
	var icon_height := 29.0 if category else 47.0
	var node = sprite_button(content,"AnimatedButtons/AvatarShop/"+path,cell,pos,action,normal,0,click_start,disabled,area,icon_height)
	label(node,text,Vector2(0,31 if category else 49),Vector2(area.x,15),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animated.append({"node":node,"path":"AnimatedButtons/AvatarShop/"+path,"cell":cell,"icon_height":icon_height,"normal":normal,"hover_end":hover_end,"click_start":click_start,"click_end":click_end,"disabled":disabled,"active":active,"selected":false,"age":0.0,"state":0})
	track_click(animated.back())
	return node
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
	content = Control.new()
	# Rasterize this scaled UI's glyphs with enough samples for Full HD.
	# Duplicate the font so battle/menu text and caches remain independent.
	shop_font = ThemeDB.fallback_font.duplicate()
	if shop_font is FontFile:
		shop_font.oversampling = 3.0
	content.theme = Theme.new()
	content.theme.default_font = shop_font
	content.size = CANVAS
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	get_viewport().size_changed.connect(fit_viewport)
	fit_viewport()
	wide_background = load_registered_texture("res://assets/hd/shop/wide_background.json")
	xfs_background = load_registered_texture("res://assets/hd/shop/xfs_landscape.json")
	xfs_portraits = load_portrait_atlas("res://assets/hd/shop/xfs_portraits.json")
	empty_slot_portrait = load_registered_texture("res://assets/hd/shop/empty_slot_portrait.json")
	var frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/xfs/shop/catalog.json"))
	if frames is Dictionary and frames.get("version")==1 and frames.get("frames") is Dictionary:
		xfs_frames = frames.frames
	backdrop = TextureRect.new()
	backdrop.texture = xfs_background
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop,0)
	fit_viewport()
	painter = Paint.new()
	painter.shop = self
	content.add_child(painter)
	chrome_labels.append(label(content,"AVATAR",Vector2(35,19),Vector2(107,20),18))
	chrome_labels.append(label(content,"SHOP",Vector2(78,37),Vector2(66,20),18))
	chrome_labels.append(icon(content,category_icon(1),Vector2(17,25),Vector2(19,21)))
	chrome_labels.append(label(content,"MY AVATAR",Vector2(585,7),Vector2(135,22),16))
	chrome_labels.append(icon(content,category_icon(1),Vector2(565,8),Vector2(18,18)))
	label(content,host.profile.nickname,Vector2(171,4),Vector2(175,16),11).clip_text=true
	label(content,"Nível %d" % model.profile.level(),Vector2(344,4),Vector2(75,16),10).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	search = LineEdit.new()
	search.position = Vector2(170,21)
	search.placeholder_text = "Buscar avatar"
	search.add_theme_font_size_override("font_size",10)
	search.add_theme_constant_override("minimum_character_width",1)
	search.expand_to_text_length=false
	var search_style := StyleBoxFlat.new()
	search_style.bg_color = Color("063343")
	search_style.set_content_margin_all(1)
	search.add_theme_stylebox_override("normal",search_style)
	search.add_theme_stylebox_override("focus",search_style)
	search.text_changed.connect(func(text): model.query=text; refresh(model.category,0))
	content.add_child(search)
	search.size = Vector2(245,17)
	balance_label = label(content,"",Vector2(171,42),Vector2(248,14),10)
	balance_label.visible = false
	var charge = classic_button("CASH\nCHARGE",Vector2(472,7),Vector2(66,45),func(): pass)
	charge.disabled = true
	charge.tooltip_text = "Saldo local de teste; recarga com dinheiro real indisponível"
	gender_button = classic_button("♂" if model.profile.gender==0 else "♀",Vector2(718,7),Vector2(26,20),toggle_gender)
	gender_button.tooltip_text = "Alternar gênero do conjunto"
	attributes_button = classic_button("▦",Vector2(746,7),Vector2(32,20),open_attributes)
	attributes_button.tooltip_text = "Atributos do piloto"
	# The preview itself is the toggle; presentation never changes equipment.
	var avatar_toggle = Button.new()
	avatar_toggle.position=Vector2(568,34)
	avatar_toggle.size=Vector2(86,72)
	avatar_toggle.flat=true
	avatar_toggle.tooltip_text="Alternar prévia Avatar / Mobile"
	avatar_toggle.pressed.connect(func(): set_preview_mode(not preview_mobile))
	content.add_child(avatar_toggle)
	preview_buttons=[avatar_toggle,avatar_toggle]
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(569,110)
	scroll.size = Vector2(176,238)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	content.add_child(scroll)
	inventory_rows = VBoxContainer.new()
	inventory_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_rows.add_theme_constant_override("separation",0)
	scroll.add_child(inventory_rows)
	inventory_count=label(content,"",Vector2(568,350),Vector2(176,12),8)
	inventory_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	classic_button("▲",Vector2(755,111),Vector2(26,26),func(): scroll.scroll_vertical-=68)
	classic_button("▼",Vector2(755,323),Vector2(26,26),func(): scroll.scroll_vertical+=68)
	chrome_labels.append(label(content,"EXITEM",Vector2(591,365),Vector2(150,24),19))
	label(content,"Treino offline",Vector2(580,434),Vector2(155,16),10).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var names := ["Cabeça","Corpo","Óculos","Bandeira"]
	for i in range(4):
		var node = classic_button("",Vector2(38+i*53,556),Vector2(49,32),func(): model.selected_key=""; refresh(i,0))
		node.tooltip_text=names[i]
		icon(node,category_icon(i),Vector2(12,7),Vector2(25,18))
		category_buttons.append(node)
	left_button = classic_button("↑",Vector2(513,76),Vector2(22,52),func(): refresh(model.category,model.page-1))
	right_button = classic_button("↓",Vector2(513,484),Vector2(22,52),func(): refresh(model.category,model.page+1))
	page_label = label(content,"",Vector2(263,562),Vector2(78,20),11)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	try_button = classic_button("",Vector2(359,556),Vector2(81,33),try_selected)
	try_caption = label(try_button,"Experimentar",Vector2(3,6),Vector2(75,21),10)
	try_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	try_caption.add_theme_color_override("font_color",Color("003d57"))
	try_caption.add_theme_constant_override("outline_size",0)
	buy_button = classic_button("Comprar",Vector2(448,556),Vector2(81,33),open_buy)
	var sell=classic_button("Vender",Vector2(566,514),Vector2(68,27),func(): pass)
	sell.disabled=true
	sell.tooltip_text="Venda indisponível no catálogo local atual"
	classic_button("Restaurar",Vector2(638,514),Vector2(68,27),func(): model.reset_preview(); refresh(model.category,model.page)).tooltip_text="Restaurar a prévia ao conjunto vestido"
	gift_button=classic_button("Presente",Vector2(710,514),Vector2(68,27),func(): pass)
	gift_button.disabled=true
	gift_button.tooltip_text="Presentes indisponíveis no treino offline"
	classic_button("▯  EXIT",Vector2(566,550),Vector2(107,45),host.show_menu)
	var buddy=classic_button("♟  BUDDY",Vector2(683,550),Vector2(107,45),func(): pass)
	buddy.disabled=true
	buddy.tooltip_text="Amigos e contas ainda indisponíveis no treino offline"
	status_label=label(content,"",Vector2(25,55),Vector2(477,14),9)
	status_label.add_theme_color_override("font_color",Color("ffe999"))
	empty_label=label(content,"Nenhum avatar encontrado",Vector2(38,266),Vector2(460,28),14)
	empty_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	empty_label.visible=false
	build_attributes()
	refresh(0,0)

func classic_button(text: String, pos: Vector2, area: Vector2, action: Callable) -> Button:
	var node = button(content,text,pos,area,action)
	for i in range(4):
		node.add_theme_stylebox_override(["normal","hover","pressed","disabled"][i],XfsStyle.new("button",i))
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.add_theme_font_size_override("font_size",10)
	node.add_theme_color_override("font_color",Color("003d57"))
	node.add_theme_color_override("font_hover_color",Color("003d57"))
	node.add_theme_color_override("font_pressed_color",Color("5a3700"))
	node.add_theme_color_override("font_disabled_color",Color("535d5f"))
	node.size=area
	return node

func xfs_texture(name: String, frame: int = 0) -> Texture2D:
	var entry: Dictionary=xfs_frames.get(name+":"+str(frame),{})
	var path: String=str(entry.get("file",""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not texture_cache.has(path):
		texture_cache[path]=load(path)
	return texture_cache[path]

func fit_viewport() -> void:
	size = get_viewport_rect().size
	var factor := minf(size.x/CANVAS.x,size.y/CANVAS.y)
	content.scale = Vector2.ONE*factor
	content.position = (size-CANVAS*factor)*0.5
	if is_instance_valid(backdrop):
		backdrop.size=size

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

func set_preview_mode(mobile: bool) -> void:
	preview_mobile=mobile
	if is_instance_valid(painter):
		painter.queue_redraw()

func load_registered_texture(manifest: String) -> Texture2D:
	if not FileAccess.file_exists(manifest):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(manifest))
	if not data is Dictionary or data.get("version")!=1:
		return null
	var dimensions = data.get("size")
	if not dimensions is Array or dimensions.size()!=2:
		return null
	for value in dimensions:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or value<=0:
			return null
	var path := str(data.get("file",""))
	if not ResourceLoader.exists(path):
		return null
	var image = load(path)
	if not image is Texture2D or image.get_size()!=Vector2(dimensions[0],dimensions[1]):
		return null
	if data.has("region"):
		var region: Rect2 = avatar_art.hd.rectangle(data.region)
		if not region.has_area() or not Rect2(Vector2.ZERO,image.get_size()).encloses(region):
			return null
		var portrait := AtlasTexture.new()
		portrait.atlas = image
		portrait.region = region
		return portrait
	return image

func portrait_for(item: Dictionary) -> Texture2D:
	if item.get("source")=="xfs":
		# XFS shop portraits are separate assets (often just the helmet), not the
		# equipped character's head. Never replace them with a different crop.
		var migrated: Texture2D=avatar_art.xfs_hd.portrait(item.key) if use_hd else null
		if migrated!=null:
			return migrated
		if use_hd and xfs_portraits.has(item.key):
			return xfs_portraits[item.key]
		return load(item.portrait)
	if use_hd and str(item.key) in ["2:2:0","2:3:0"] and empty_slot_portrait != null:
		return empty_slot_portrait
	var portrait = avatar_art.hd.portrait(avatar_art.hd_key(item.key)) if use_hd else null
	return portrait if portrait != null else load(item.portrait)

func load_portrait_atlas(manifest: String) -> Dictionary:
	var result := {}
	var sheet = load_registered_texture(manifest)
	if sheet==null:
		return result
	var data = JSON.parse_string(FileAccess.get_file_as_string(manifest))
	if not data.get("regions") is Dictionary:
		return result
	for key in data.regions:
		var region: Rect2=avatar_art.hd.rectangle(data.regions[key])
		if not region.has_area() or not Rect2(Vector2.ZERO,sheet.get_size()).encloses(region):
			continue
		var portrait := AtlasTexture.new()
		portrait.atlas=sheet
		portrait.region=region
		result[key]=portrait
	return result

func bonus_description(item: Dictionary) -> String:
	var names := ["Ataque","Vida","Defesa","Regeneração","Atraso do tiro","Atraso do item","Cratera","Gold"]
	var values: Array=item.get("bonuses",[])
	var lines: PackedStringArray=[]
	for i in range(values.size()):
		if int(values[i])!=0:
			lines.append("%s: %+d" % [names[i],int(values[i])])
	return "\n".join(lines) if not lines.is_empty() else "Sem modificadores"

func draw_bonus_labels(parent: Control, item: Dictionary, origin: Vector2, compact: bool = false) -> void:
	var values: Array=item.get("bonuses",[])
	var slot := 0
	for i in range(values.size()):
		if int(values[i])==0:
			continue
		var pos := origin+Vector2(slot*23,0) if compact else origin+Vector2(0,slot*17)
		var image_size := Vector2(9,10) if compact else Vector2(14,13)
		icon(parent,atlas("StaticButtons/AvatarShop/AvatarButton/ButtonIcons",Vector2(26,17),ATTRIBUTE_ICONS[i]),pos,image_size)
		var value_label=label(parent,"%02d" % int(values[i]),pos+Vector2(image_size.x+1,-1),Vector2(14 if compact else 31,13),8 if compact else 10)
		value_label.add_theme_color_override("font_color",Color("ff897b") if int(values[i])<0 else Color("f5ecc2"))
		value_label.add_theme_constant_override("outline_size",1)
		slot+=1

func general_button(path: String, cell: Vector2, pos: Vector2, text: String, action: Callable, normal: int, hover_end: int, click_start: int, click_end: int, disabled: int):
	var area := cell if text.is_empty() else Vector2(cell.x,64)
	var icon_height := 0.0 if text.is_empty() else 47.0
	var node = sprite_button(content,"AnimatedButtons/"+path,cell,pos,action,normal,0,click_start,disabled,area,icon_height)
	label(node,text,Vector2(0,cell.y-12 if text.is_empty() else 49),Vector2(cell.x,15),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animated.append({"node":node,"path":"AnimatedButtons/"+path,"cell":cell,"icon_height":icon_height,"normal":normal,"hover_end":hover_end,"click_start":click_start,"click_end":click_end,"disabled":disabled,"active":-1,"selected":false,"age":0.0,"state":0})
	track_click(animated.back())
	return node

func track_click(entry: Dictionary) -> void:
	entry.click_age = -1.0
	entry.node.pressed.connect(func(): entry.click_age = 0.0)

func toggle_gender() -> void:
	if model.profile.set_gender(1-model.profile.gender):
		model.preview = model.profile.equipped_set()
		model.selected_key = ""
		gender_button.text = "♂" if model.profile.gender==0 else "♀"
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
	for i in range(8):
		var pos := Vector2(16+(i%2)*166,80+int(i/2)*25)
		icon(box,atlas("StaticButtons/AvatarShop/AvatarButton/ButtonIcons",Vector2(26,17),ATTRIBUTE_ICONS[i]),pos+Vector2(0,3),Vector2(17,14)).name = "AttributeIcon%d" % i
		label(box,attr_names[i],pos+Vector2(20,0),Vector2(65,22),10)
		remove_buttons.append(button(box,"−",pos+Vector2(85,0),Vector2(22,22),func(): adjust(i,-1)))
		attribute_labels.append(label(box,"0",pos+Vector2(110,0),Vector2(25,22),11))
		add_buttons.append(button(box,"+",pos+Vector2(135,0),Vector2(22,22),func(): adjust(i,1)))
	attributes_feedback = label(box,"",Vector2(16,178),Vector2(328,16),10)
	button(box,"Salvar",Vector2(92,195),Vector2(90,28),func():
		if model.profile.commit_attributes(model.draft_attributes):
			status_label.text = "Atributos salvos"
			close_attributes()
		else:
			status_label.text = "Falha ao salvar atributos"
			attributes_feedback.text = "Não foi possível salvar. Tente novamente."
		update_attributes()
		painter.queue_redraw()
	).name = "SaveAttributes"
	button(box,"Cancelar",Vector2(192,195),Vector2(90,28),close_attributes).name = "CancelAttributes"

func open_attributes() -> void:
	if is_instance_valid(modal) or attributes_panel.visible:
		return
	model.draft_attributes = model.profile.attributes.duplicate()
	attributes_feedback.text = ""
	block_controls(content,attributes_panel)
	search.editable = false
	update_attributes()
	attributes_panel.visible = true
	content.move_child(attributes_panel,content.get_child_count()-1)

func close_attributes() -> void:
	attributes_panel.visible = false
	model.draft_attributes = model.profile.attributes.duplicate()
	restore_controls()
	update_attributes()

func panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("14253a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color("90acd0")
	style.shadow_size = 1
	return style

func category_icon(category: int) -> AtlasTexture:
	var index: int = [2+model.profile.gender,model.profile.gender,4+model.profile.gender,6][category]
	return atlas("StaticButtons/AvatarShop/AvatarButton/ButtonIcons",Vector2(26,17),index)

func icon(parent: Node, tex: Texture2D, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = tex
	node.position = pos
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = dimensions
	return node

func inventory_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=Color("6ac7df")
	style.border_width_bottom=1
	return style

func update_inventory() -> void:
	for child in inventory_rows.get_children():
		inventory_rows.remove_child(child)
		child.queue_free()
	var count := 0
	for category in range(4):
		for item in model.catalog.inventory_items(model.profile.gender,category):
			if not model.profile.owns(item.key):
				continue
			var row := button(inventory_rows,"",Vector2.ZERO,Vector2(176,17),func(): equip_inventory(item.key))
			row.custom_minimum_size = Vector2(176,17)
			row.name = "Owned_"+str(item.key).replace(":","_")
			row.tooltip_text = "Vestir "+str(item.name)+"\n"+bonus_description(item)
			var equipped: bool = model.profile.equipped_set().get(str(category)) == item.key
			for state in ["normal","hover","pressed","disabled"]:
				row.add_theme_stylebox_override(state,inventory_style(Color("e3a85c") if equipped else (Color("1c99ca") if state in ["normal","disabled"] else Color("44bbe3"))))
			icon(row,category_icon(category),Vector2(8,2),Vector2(16,12))
			var item_label := label(row,str(item.name),Vector2(22,0),Vector2(80 if item.get("source")=="xfs" else 130,17),9)
			item_label.clip_text=true
			item_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			item_label.size=Vector2(80 if item.get("source")=="xfs" else 130,17)
			item_label.add_theme_color_override("font_color",Color("e9ffff"))
			item_label.add_theme_constant_override("outline_size",0)
			if model.profile.equipped_set().get(str(category)) == item.key:
				icon(row,texture("StaticButtons/AvatarShop/AvatarButton/EquipedIndicator"),Vector2(0,1),Vector2(8,14))
				if item.get("source")!="xfs":
					icon(row,texture("StaticButtons/AvatarShop/AvatarButton/OwnedCheck"),Vector2(157,4),Vector2(12,9))
			draw_bonus_labels(row,item,Vector2(104,3),true)
			count += 1
	inventory_count.text = "%d peças" % count
	for i in range(maxi(0,14-count)):
		var empty := Panel.new()
		empty.custom_minimum_size = Vector2(176,17)
		empty.add_theme_stylebox_override("panel",inventory_style(Color("127da8")))
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_rows.add_child(empty)

func equip_inventory(key: String) -> void:
	if model.profile.equip(key):
		model.preview = model.profile.equipped_set()
		model.selected_key = key
		status_label.text = "Avatar vestido e salvo"
		search.text = ""
		model.query = ""
		refresh(int(model.catalog.find(key).category),0)
	else:
		status_label.text = "Não foi possível salvar o avatar"

func switch_tab(inventory: bool) -> void:
	model.inventory = inventory
	model.preview = model.profile.equipped_set()
	model.selected_key = ""
	refresh(model.category,0)
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
func refresh(category: int, page: int) -> void:
	for node in chrome_labels:
		node.visible=use_hd or xfs_texture("store_back")==null
	if is_instance_valid(cards):
		content.remove_child(cards)
		cards.queue_free()
	cards = Control.new()
	content.add_child(cards)
	var rows: Array = model.filter(category,model.query,model.inventory,page)
	empty_label.visible = rows.is_empty()
	for index in range(rows.size()):
		var item: Dictionary = rows[index]
		var pos := GRID_ORIGIN+Vector2(index%3,int(index/3))*GRID_STEP
		var card = button(cards,"",pos,CARD_SIZE,func():
			if model.select(item.key):
				refresh(model.category,model.page)
			else:
				status_label.text = "Não foi possível salvar o avatar"
		)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var frame := 2 if model.selected_key == item.key or state=="pressed" else (1 if state=="hover" else 0)
			var path := "StaticButtons/AvatarShop/AvatarButton/Background"
			var style = CardStyle.new(atlas(path,Vector2(105,83),frame),density(path))
			if not use_hd and xfs_texture("store_avatar",0)!=null:
				var native := StyleBoxTexture.new()
				native.texture=xfs_texture("store_avatar",1 if frame>0 else 0)
				card.add_theme_stylebox_override(state,native)
			else:
				card.add_theme_stylebox_override(state,style)
		card.size = CARD_SIZE
		card.name = "Avatar"+str(index)
		card.tooltip_text = item.name+"\n"+str(item.get("description",""))+"\n"+bonus_description(item)
		icon(card,category_icon(category),Vector2(6,5),Vector2(14,10))
		var name_label=label(card,str(item.name),Vector2(22,3),Vector2(103,16),9)
		name_label.name="AvatarName"
		name_label.clip_text=true
		name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.size=Vector2(103,16)
		if int(item.gender)!=2:
			var badge := ColorRect.new()
			badge.position=Vector2(129,5)
			badge.size=Vector2(25,11)
			badge.color=Color("2351bd") if int(item.gender)==0 else Color("de503a")
			badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(badge)
			var tag=label(badge,"BOY" if int(item.gender)==0 else "GIRL",Vector2.ZERO,Vector2(25,11),7)
			tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var portrait_texture = portrait_for(item)
		var portrait := icon(card,portrait_texture,Vector2(8,25),PORTRAIT_SIZE)
		portrait.name = "Portrait"
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		card.clip_contents = true
		var effect := label(card,"" if item.get("source")=="xfs" else "Cosmético\nsem bônus",Vector2(99,30),Vector2(53,65),8)
		effect.name = "AvatarEffect"
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect.add_theme_color_override("font_color",Color("c3eaf1"))
		effect.add_theme_constant_override("outline_size",0)
		draw_bonus_labels(effect,item,Vector2.ZERO)
		var cash := int(item.get("cash_price",0))
		var gold := int(item.get("gold_price",0))
		var cash_text := format_number(cash)+" CASH" if cash>0 else ""
		var gold_text := format_number(gold)+" GOLD" if gold>0 else ("Somente Cash" if cash>0 else "Básico")
		label(card,cash_text,Vector2(7,112),Vector2(CARD_SIZE.x-14,17),12).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.get_child(card.get_child_count()-1).add_theme_color_override("font_color",CASH_COLOR)
		label(card,gold_text,Vector2(7,130),Vector2(CARD_SIZE.x-14,17),12).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.get_child(card.get_child_count()-1).add_theme_color_override("font_color",GOLD_COLOR)
		var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
		if set_data.get(str(category)) == item.key:
			icon(card,texture("StaticButtons/AvatarShop/AvatarButton/EquipedIndicator"),Vector2(1,64),Vector2(10,17))
		if model.profile.owns(item.key):
			icon(card,texture("StaticButtons/AvatarShop/AvatarButton/OwnedCheck"),Vector2(75,27),Vector2(13,10))
	balance_label.text = "Gold: %d\nCash: %d" % [model.profile.gold,model.profile.cash]
	page_label.text = "%d / %d" % [model.page+1,model.last_page]
	left_button.disabled = model.page == 0
	right_button.disabled = model.page+1 >= model.last_page
	var item: Dictionary = model.catalog.find(model.selected_key)
	var owned: bool = not item.is_empty() and model.profile.owns(model.selected_key)
	var dressed: bool = owned and model.profile.equipped_set().get(str(category)) == model.selected_key and model.preview.get(str(category)) == model.selected_key
	try_caption.text = ("Vestido" if dressed else "Vestir") if owned else "Experimentar"
	try_button.disabled = model.inventory or item.is_empty() or (dressed if owned else model.preview.get(str(category)) == model.selected_key)
	buy_button.disabled = model.inventory or item.is_empty() or model.profile.owns(model.selected_key) or not can_buy(item)
	for i in range(category_buttons.size()):
		category_buttons[i].add_theme_stylebox_override("normal",XfsStyle.new("button",2 if i==category else 0))
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
	block_controls(content)
	search.editable = false
	purchase_key = model.selected_key
	var item: Dictionary = model.catalog.find(purchase_key)
	modal = Control.new()
	modal.size = CANVAS
	content.add_child(modal)
	var center := CANVAS*0.5
	var dim := ColorRect.new()
	dim.color = Color(0,0,0,0.65)
	dim.size = modal.size
	modal.add_child(dim)
	var box := Panel.new()
	box.name = "PurchasePanel"
	box.size = Vector2(313,187)*1.3
	box.position = center-box.size*0.5
	box.add_theme_stylebox_override("panel",XfsStyle.new())
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(box)
	label(modal,"COMPRAR AVATAR",center+Vector2(-180,-110),Vector2(360,25),16).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	icon(modal,portrait_for(item),center+Vector2(-182,-75),Vector2(88,78)).name="PurchasePortrait"
	label(modal,item.name,center+Vector2(-82,-71),Vector2(265,23),16)
	var description=label(modal,bonus_description(item).replace("\n"," · "),center+Vector2(-82,-41),Vector2(265,45),10)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var currencies: Array = ["gold","cash"].filter(func(currency): return int(item.get(currency+"_price",0))>0)
	for index in range(currencies.size()):
		var currency: String = currencies[index]
		var price := int(item.get(currency+"_price",0))
		var balance: int = model.profile.gold if currency == "gold" else model.profile.cash
		var x: float = center.x-70 if currencies.size()==1 else center.x-151+index*162
		label(modal,"%s %s · saldo %s" % [format_number(price),currency.capitalize(),format_number(balance)],Vector2(x-5,center.y+12),Vector2(150,22),10).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var b = button(modal,"Pagar "+currency.capitalize(),Vector2(x,center.y+39),Vector2(140,30),func():
			if not is_instance_valid(modal):
				return
			var result: String = model.confirm_buy(purchase_key,currency)
			close_buy()
			status_label.text = "Compra concluída" if result == "ok" else "Compra não concluída: "+result
			refresh(model.category,model.page)
		)
		for state in range(4):
			b.add_theme_stylebox_override(["normal","hover","pressed","disabled"][state],XfsStyle.new("button",state))
		b.add_theme_color_override("font_color",Color("003d57"))
		b.add_theme_color_override("font_hover_color",Color("003d57"))
		b.disabled = balance < price
		b.name = currency.capitalize()+"Purchase"
	button(modal,"Cancelar",center+Vector2(-62,81),Vector2(124,27),close_buy)

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
	search.editable = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		# Mark handled while still in the tree; show_menu removes this shop.
		get_viewport().set_input_as_handled()
		if is_instance_valid(modal):
			close_buy()
		elif attributes_panel.visible:
			close_attributes()
		else:
			host.show_menu()
func _process(delta: float) -> void:
	elapsed += delta
	for entry in animated:
		var node = entry.node
		var state := 3 if node.disabled else (1 if node.is_hovered() else 0)
		if state==3:
			entry.click_age = -1.0
		elif float(entry.click_age)>=0.0:
			entry.click_age += delta
			var duration: float = (int(entry.click_end)-int(entry.click_start)+1)/animation_fps(entry,2)
			if float(entry.click_age)<duration:
				state = 2
			else:
				entry.click_age = -1.0
				state = 0
		entry.age = 0.0 if state != entry.state else float(entry.age)+delta
		entry.state = state
		var frame := animation_frame(entry,state,entry.click_age if state==2 else entry.age)
		node.texture_normal = button_texture(entry.path,entry.cell,frame,entry.icon_height,node.size)
		node.texture_hover = node.texture_normal
		node.texture_pressed = node.texture_normal
		if state==3:
			node.texture_disabled = node.texture_normal
	painter.queue_redraw()
func animation_fps(entry: Dictionary, state: int) -> float:
	var name: String = entry.path.get_file()
	return (23.0 if state==1 else 25.0) if name=="Exit" else (28.0 if name in ["LeftArrow","RightArrow"] else 30.0)
func animation_frame(entry: Dictionary, state: int, age: float) -> int:
	var name: String = entry.path.get_file()
	if state==3:
		return int(entry.disabled)
	if entry.selected and int(entry.active)>=0:
		return int(entry.active)
	if state in [1,2]:
		var start: int = (1 if name in ["LeftArrow","RightArrow"] else 0) if state==1 else int(entry.click_start)
		var end: int = int(entry.hover_end) if state==1 else int(entry.click_end)
		var fps := animation_fps(entry,state)
		var step := int(maxf(0.0,age)*fps)
		var count := end-start+1
		if state==2:
			# AnimatedButton queues Normal behind Clicked, including Buy's Cycle.
			return start+step if step<count else int(entry.normal)
		if name in ["Buy","Try"]:
			# OpenBound Cycle is ping-pong, with a repeated frame at both ends.
			var phase := step%(2*count)
			return start+(phase if phase<count else 2*count-1-phase)
		return start+step%count
	return int(entry.active) if entry.selected and int(entry.active)>=0 else int(entry.normal)
func format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in range(text.length()):
		if i>0 and (text.length()-i)%3 == 0:
			result += ","
		result += text[i]
	return result

func paint(view: Node2D) -> void:
	if not use_hd and xfs_texture("store_back")!=null:
		view.draw_texture_rect(xfs_texture("store_back"),Rect2(Vector2.ZERO,CANVAS),false)
		if xfs_texture("store_myavatar")!=null:
			view.draw_texture_rect(xfs_texture("store_myavatar"),Rect2(552,104,240,437),false)
	else:
		view.draw_style_box(XfsStyle.new(),Rect2(8,15,538,579))
		view.draw_style_box(XfsStyle.new(),Rect2(154,0,278,59))
		view.draw_style_box(XfsStyle.new("well"),Rect2(162,4,260,52))
		view.draw_style_box(XfsStyle.new(),Rect2(465,0,81,59))
		view.draw_style_box(XfsStyle.new(),Rect2(552,0,240,548))
		view.draw_rect(Rect2(560,5,224,22),Color("06b8d5"))
		view.draw_style_box(XfsStyle.new("well"),Rect2(565,31,214,76))
		view.draw_rect(Rect2(568,34,86,72),Color("008abe"))
		view.draw_style_box(XfsStyle.new("well"),Rect2(567,109,180,240))
		view.draw_style_box(XfsStyle.new("well"),Rect2(567,389,180,121))
		for i in range(7):
			view.draw_rect(Rect2(569,391+i*17,176,16),Color("1688b4") if i%2==0 else Color("209aca"))
		for x in [438,454]:
			view.draw_rect(Rect2(x,0,7,54),Color("005574"))
			view.draw_rect(Rect2(x+2,0,2,54),Color("4bd8e9"))
			view.draw_style_box(XfsStyle.new("button"),Rect2(x-6,18,19,21))
	var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
	if preview_mobile:
		for path in ["InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Background","InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Foreground2"]:
			view.draw_texture_rect_region(texture(path),Rect2(568,34,86,72),preview_region(path))
		var sprite = host.sprite_for(host.vehicle)
		sprite.draw(view,SpritePose.new(Vector2(612,90),44,1,{"frame":sprite.frame_index("idle",elapsed,0,false),"age":elapsed,"avatar_context":{"equipment":set_data,"age":elapsed}}))
	else:
		avatar_art.draw(view,set_data,Transform2D(0,Vector2(-0.95,0.95),0,Vector2(612,91+sin(elapsed*2.3)*0.5)),elapsed,Color.WHITE)
	var values: Array = Attributes.with_equipment(model.profile.attributes,model.catalog.bonuses(set_data))
	var order := [4,7,6,2,1,3,0,5]
	for i in range(8):
		var attribute: int=order[i]
		var pos := Vector2(666+(i%2)*54,38+int(i/2)*18)
		var icon_index: int = ATTRIBUTE_ICONS[attribute]
		draw_region(view,"StaticButtons/AvatarShop/AvatarButton/ButtonIcons",Rect2(pos,Vector2(13,11)),Rect2(Vector2(icon_index%6,int(icon_index/6))*Vector2(26,17),Vector2(26,17)))
		view.draw_string(shop_font,pos+Vector2(17,10),"%02d" % int(values[attribute]),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e8f1dc"))
	for i in range(2):
		var text := ("GOLD : " if i==0 else "CASH : ")+format_number(model.profile.gold if i==0 else model.profile.cash)
		view.draw_string(shop_font,Vector2(172+i*126,54),text,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("80e3e7"))

func draw_region(view: Node2D, path: String, target: Rect2, source: Rect2) -> void:
	var factor := density(path)
	view.draw_texture_rect_region(texture(path),target,Rect2(source.position*factor,source.size*factor))

func preview_region(path: String) -> Rect2:
	var source_size: Vector2 = texture(path).get_size()
	var scale := maxf(86.0/source_size.x,72.0/source_size.y)
	var window := Vector2(86,72)/scale
	return Rect2((source_size-window)*0.5,window)

func block_controls(node: Node, except_node: Node = null) -> void:
	if node == except_node:
		return
	if node is BaseButton:
		blocked.append({"node":node,"disabled":node.disabled})
		node.disabled = true
	for child in node.get_children():
		block_controls(child,except_node)
