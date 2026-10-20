extends Control
## Original 800x600 Shop, fit uniformly into the current viewport.
const Assets := "res://assets/openbound/shop/"
const ShopHD = preload("res://scripts/shop_hd.gd")
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
var attributes_feedback: Label
const CARD_SIZE := Vector2(166,147)
const PORTRAIT_SIZE := Vector2(126,66)
const CASH_COLOR := Color("8bddff")
const GOLD_COLOR := Color("ffe34e")
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
	return node
func button(parent: Node, text: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.size = size
	node.add_theme_font_size_override("font_size",11)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("344971") if state=="normal" else (Color("21304b") if state=="disabled" else Color("587baa"))
		style.border_color = Color("a5bde1")
		style.set_border_width_all(1)
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		node.add_theme_stylebox_override(state,style)
	node.pressed.connect(action)
	parent.add_child(node)
	node.size = size
	return node
func sprite_button(parent: Node, path: String, cell: Vector2, pos: Vector2, action: Callable, normal: int = 0, hover: int = 1, pressed: int = 2, disabled: int = -1) -> TextureButton:
	var node := TextureButton.new()
	node.position = pos
	node.ignore_texture_size = true
	node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	node.size = cell
	node.texture_normal = atlas(path,cell,normal)
	node.texture_hover = atlas(path,cell,hover)
	node.texture_pressed = atlas(path,cell,pressed)
	node.texture_disabled = atlas(path,cell,normal if disabled < 0 else disabled)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
func animated_button(path: String, cell: Vector2, pos: Vector2, text: String, action: Callable, normal: int, hover_end: int, click_start: int, click_end: int, disabled: int, active: int = -1):
	var node = sprite_button(content,"AnimatedButtons/AvatarShop/"+path,cell,pos,action,normal,0,click_start,disabled)
	label(node,text,Vector2(-5,cell.y-15),Vector2(cell.x+10,15),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animated.append({"node":node,"path":"AnimatedButtons/AvatarShop/"+path,"cell":cell,"normal":normal,"hover_end":hover_end,"click_start":click_start,"click_end":click_end,"disabled":disabled,"active":active,"selected":false,"age":0.0,"state":0})
	track_click(animated.back())
	return node
func setup(owner, shop_model) -> void:
	host = owner
	model = shop_model
	size = Vector2(1280,800)
	content = Control.new()
	content.position = Vector2(106.6667,0)
	content.scale = Vector2.ONE * (4.0/3.0)
	content.size = Vector2(800,600)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	painter = Paint.new()
	painter.shop = self
	content.add_child(painter)
	label(content,"Avatar Shop",Vector2(430,-2),Vector2(200,26),19).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(content,"Meu Avatar",Vector2(8,179),Vector2(215,24),16)
	for index in range(2):
		var tab = button(content,["Normal","Inventário"][index],Vector2(10+index*91,205),Vector2(90,20),func(): switch_tab(index == 1))
		tab_buttons.append(tab)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12,230)
	scroll.size = Vector2(214,246)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	inventory_rows = VBoxContainer.new()
	inventory_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_rows.add_theme_constant_override("separation",2)
	scroll.add_child(inventory_rows)
	var names := ["Cabeça","Corpo","Óculos","Bandeira"]
	var specs := [["Hat",Vector2(49,48),0,19,21,32,33,34],["Body",Vector2(49,39),0,19,20,30,31,32],["Goggles",Vector2(49,46),0,19,20,35,36,37],["Flag",Vector2(56,47),0,14,15,44,45,46]]
	for i in range(4):
		var spec: Array = specs[i]
		animated_button(spec[0],spec[1],Vector2(290+i*55,478),names[i],func(): model.selected_key=""; refresh(i,0),spec[2],spec[3],spec[4],spec[5],spec[6],spec[7])
	search = LineEdit.new()
	search.position = Vector2(675,3)
	search.size = Vector2(105,21)
	search.placeholder_text = "Buscar nome"
	search.add_theme_font_size_override("font_size",9)
	var search_style := StyleBoxFlat.new()
	search_style.bg_color = Color("344971")
	search_style.border_color = Color("96b6d8")
	search_style.set_border_width_all(1)
	search_style.content_margin_left = 4
	search_style.content_margin_right = 4
	search_style.content_margin_top = 1
	search_style.content_margin_bottom = 1
	search.add_theme_stylebox_override("normal",search_style)
	search.add_theme_stylebox_override("focus",search_style)
	search.text_changed.connect(func(text): model.query=text; refresh(model.category,0))
	content.add_child(search)
	search.size = Vector2(105,21)
	label(content,host.profile.nickname,Vector2(16,9),Vector2(155,17),11)
	balance_label = label(content,"",Vector2(75,140),Vector2(136,30),11)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance_label.visible = false # Individual colors in the painted compact balance.
	general_button("Exit",Vector2(66,66),Vector2(9,528),"Sair",host.show_menu,0,22,13,38,39)
	gender_button = button(content,["Masculino","Feminino"][model.profile.gender],Vector2(82,551),Vector2(105,22),toggle_gender)
	attributes_button = button(content,"Atributos",Vector2(13,489),Vector2(99,23),open_attributes)
	label(content,"Nível %d" % model.profile.level(),Vector2(125,492),Vector2(98,20),11)
	left_button = general_button("LeftArrow",Vector2(46,42),Vector2(521,480),"",func(): refresh(model.category,model.page-1),0,19,20,30,31)
	right_button = general_button("RightArrow",Vector2(46,42),Vector2(572,480),"",func(): refresh(model.category,model.page+1),0,19,20,30,31)
	page_label = label(content,"",Vector2(624,491),Vector2(68,20),11)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gift_button = animated_button("Gift",Vector2(64,69),Vector2(590,526),"Presente",func(): pass,0,14,31,62,71)
	gift_button.disabled = true
	gift_button.tooltip_text = "Presentes indisponíveis no treino offline"
	buy_button = animated_button("Buy",Vector2(64,73),Vector2(655,526),"Comprar",open_buy,0,23,26,45,46)
	try_button = animated_button("Try",Vector2(64,72),Vector2(720,526),"Experimentar",try_selected,13,43,45,70,71)
	try_caption = try_button.get_child(0)
	status_label = label(content,"Saldo de teste · sem dinheiro real",Vector2(260,558),Vector2(315,30),10)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_attributes()
	refresh(0,0)

func general_button(path: String, cell: Vector2, pos: Vector2, text: String, action: Callable, normal: int, hover_end: int, click_start: int, click_end: int, disabled: int):
	var node = sprite_button(content,"AnimatedButtons/"+path,cell,pos,action,normal,0,click_start,disabled)
	label(node,text,Vector2(0,cell.y-12),Vector2(cell.x,15),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animated.append({"node":node,"path":"AnimatedButtons/"+path,"cell":cell,"normal":normal,"hover_end":hover_end,"click_start":click_start,"click_end":click_end,"disabled":disabled,"active":-1,"selected":false,"age":0.0,"state":0})
	track_click(animated.back())
	return node

func track_click(entry: Dictionary) -> void:
	entry.click_age = -1.0
	entry.node.pressed.connect(func(): entry.click_age = 0.0)

func toggle_gender() -> void:
	if model.profile.set_gender(1-model.profile.gender):
		model.preview = model.profile.equipped_set()
		model.selected_key = ""
		gender_button.text = ["Masculino","Feminino"][model.profile.gender]
		refresh(model.category,0)
	else:
		status_label.text = "Não foi possível salvar o gênero"

func build_attributes() -> void:
	attributes_panel = Control.new()
	attributes_panel.size = Vector2(800,600)
	attributes_panel.visible = false
	content.add_child(attributes_panel)
	var dim := ColorRect.new()
	dim.color = Color(0,0,0,0.65)
	dim.size = attributes_panel.size
	attributes_panel.add_child(dim)
	var box := Panel.new()
	box.position = Vector2(220,180)
	box.size = Vector2(360,245)
	box.add_theme_stylebox_override("panel",panel_style(Color("435d85")))
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

func update_inventory() -> void:
	for child in inventory_rows.get_children():
		inventory_rows.remove_child(child)
		child.queue_free()
	var count := 0
	for category in range(4):
		for item in model.catalog.items(model.profile.gender,category):
			if not model.profile.owns(item.key):
				continue
			var row := button(inventory_rows,"",Vector2.ZERO,Vector2(196,29),func(): equip_inventory(item.key))
			row.custom_minimum_size = Vector2(196,29)
			row.name = "Owned_"+str(item.key).replace(":","_")
			row.tooltip_text = "Vestir "+str(item.name)
			for state in ["normal","hover","pressed","disabled"]:
				row.add_theme_stylebox_override(state,panel_style(Color("aebdd3") if state in ["normal","disabled"] else Color("d1e2f0")))
			icon(row,category_icon(category),Vector2(10,3),Vector2(20,14))
			label(row,str(item.name),Vector2(32,3),Vector2(142,21),10).add_theme_color_override("font_color",Color("def2ff"))
			if model.profile.equipped_set().get(str(category)) == item.key:
				icon(row,texture("StaticButtons/AvatarShop/AvatarButton/EquipedIndicator"),Vector2(0,6),Vector2(10,17))
				icon(row,texture("StaticButtons/AvatarShop/AvatarButton/OwnedCheck"),Vector2(176,8),Vector2(14,10))
			count += 1
	for i in range(maxi(0,8-count)):
		var empty := Panel.new()
		empty.custom_minimum_size = Vector2(196,29)
		empty.add_theme_stylebox_override("panel",panel_style(Color("aebdd3")))
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
	if is_instance_valid(cards):
		content.remove_child(cards)
		cards.queue_free()
	cards = Control.new()
	content.add_child(cards)
	var rows: Array = model.filter(category,model.query,model.inventory,page)
	for index in range(rows.size()):
		var item: Dictionary = rows[index]
		var pos := Vector2(260+(index%3)*175,26+int(index/3)*152)
		var card = button(cards,"",pos,CARD_SIZE,func():
			if model.select(item.key):
				refresh(model.category,model.page)
		)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var frame := 2 if model.selected_key == item.key or state=="pressed" else (1 if state=="hover" else 0)
			var path := "StaticButtons/AvatarShop/AvatarButton/Background"
			var style = CardStyle.new(atlas(path,Vector2(105,83),frame),density(path))
			card.add_theme_stylebox_override(state,style)
		card.size = CARD_SIZE
		card.name = "Avatar"+str(index)
		card.tooltip_text = item.name+"\nEste avatar muda a aparência, sem bônus de combate.\nMelhorias de combate são definidas em Atributos."
		icon(card,category_icon(category),Vector2(5,2),Vector2(16,12))
		label(card,str(item.name).left(20),Vector2(24,2),Vector2(137,16),11)
		var portrait_texture = avatar_art.hd.portrait(item.key)
		if portrait_texture == null:
			portrait_texture = load(item.portrait)
		var portrait := icon(card,portrait_texture,Vector2(20,26),PORTRAIT_SIZE)
		portrait.name = "Portrait"
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		card.clip_contents = true
		var effect := label(card,"Cosmético · sem bônus",Vector2(13,94),Vector2(140,13),9)
		effect.name = "AvatarEffect"
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect.add_theme_color_override("font_color",Color("395070"))
		effect.add_theme_constant_override("outline_size",0)
		var cash := int(item.get("cash_price",0))
		var gold := int(item.get("gold_price",0))
		var cash_text := format_number(cash)+"  Cash" if cash>0 else ""
		var gold_text := format_number(gold)+"  Gold" if gold>0 else ("Somente Cash" if cash>0 else "Básico")
		label(card,cash_text,Vector2(10,114),Vector2(143,14),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.get_child(card.get_child_count()-1).add_theme_color_override("font_color",CASH_COLOR)
		label(card,gold_text,Vector2(10,128),Vector2(143,14),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.get_child(card.get_child_count()-1).add_theme_color_override("font_color",GOLD_COLOR)
		var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
		if set_data.get(str(category)) == item.key:
			icon(card,texture("StaticButtons/AvatarShop/AvatarButton/EquipedIndicator"),Vector2(1,64),Vector2(10,17))
		if model.profile.owns(item.key):
			icon(card,texture("StaticButtons/AvatarShop/AvatarButton/OwnedCheck"),Vector2(140,23),Vector2(17,13))
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
	for i in range(4):
		animated[i].selected = i == category
	for i in range(2):
		tab_buttons[i].disabled = (i==1)==model.inventory
	update_inventory()
	update_attributes()
	painter.queue_redraw()
func can_buy(item: Dictionary) -> bool:
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
	modal.size = Vector2(1280,800)
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0,0,0,0.65)
	dim.size = modal.size
	modal.add_child(dim)
	var box := TextureRect.new()
	box.name = "PurchasePanel"
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.texture = texture("Popup/Blue/Avatar/Buy")
	box.position = Vector2(640,400)-Vector2(228,286)*0.8
	box.size = Vector2(228,286)*1.6
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(box)
	label(modal,item.name,Vector2(490,220),Vector2(300,28),17).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait_texture = avatar_art.hd.portrait(purchase_key)
	if portrait_texture == null:
		portrait_texture = load(item.portrait)
	icon(modal,portrait_texture,Vector2(582,252),Vector2(116,72)).name = "PurchasePortrait"
	label(modal,["Cabeça","Corpo","Óculos","Bandeira"][int(item.category)]+" · cosmético, sem bônus",Vector2(490,321),Vector2(300,20),12).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(modal,"Confirmar compra?",Vector2(490,343),Vector2(300,26),17).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var currencies: Array = ["gold","cash"].filter(func(currency): return int(item.get(currency+"_price",0))>0)
	for index in range(currencies.size()):
		var currency: String = currencies[index]
		var price := int(item.get(currency+"_price",0))
		if price <= 0:
			continue
		var balance: int = model.profile.gold if currency == "gold" else model.profile.cash
		var x := 570 if currencies.size()==1 else 495+index*150
		var color := GOLD_COLOR if currency=="gold" else CASH_COLOR
		label(modal,"%s · %s\n%s → %s" % [currency.capitalize(),format_number(price),format_number(balance),format_number(balance-price)],Vector2(x,378),Vector2(145,60),14).add_theme_color_override("font_color",color)
		var b = button(modal,"Pagar "+currency.capitalize(),Vector2(x,455),Vector2(140,35),func():
			if not is_instance_valid(modal):
				return
			var result: String = model.confirm_buy(purchase_key,currency)
			close_buy()
			status_label.text = "Compra concluída" if result == "ok" else "Compra não concluída: "+result
			refresh(model.category,model.page)
		)
		b.disabled = balance < price
		b.name = currency.capitalize()+"Purchase"
	button(modal,"Cancelar",Vector2(630,512),Vector2(150,32),close_buy)
func close_buy() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
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
		if is_instance_valid(modal):
			close_buy()
		elif attributes_panel.visible:
			close_attributes()
		else:
			host.show_menu()
		get_viewport().set_input_as_handled()
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
		node.texture_normal = atlas(entry.path,entry.cell,frame)
		node.texture_hover = node.texture_normal
		node.texture_pressed = node.texture_normal
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
	# Reuse only the source's sky/divider/city; its baked 5x5 pane is superseded.
	view.draw_rect(Rect2(0,0,225,600),Color("b2c6e0"))
	draw_region(view,"InGame/Scene/AvatarShop/Background",Rect2(0,520,225,80),Rect2(0,520,225,80))
	draw_region(view,"InGame/Scene/AvatarShop/Background",Rect2(225,0,20,600),Rect2(225,0,20,600))
	view.draw_rect(Rect2(245,0,555,600),Color("4e90cf"))
	# Crisp code-native sky; raster city and divider are registered HD derivatives.
	view.draw_rect(Rect2(245,0,555,480),Color("4e90cf"))
	draw_region(view,"InGame/Scene/AvatarShop/Background",Rect2(245,520,555,80),Rect2(245,520,555,80))
	view.draw_style_box(panel_style(Color("43577e")),Rect2(8,203,224,317))
	view.draw_style_box(panel_style(Color("8daccc")),Rect2(8,5,211,171))
	view.draw_texture_rect(texture("InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Background"),Rect2(13,10,201,100),false)
	view.draw_texture_rect(texture("InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Foreground2"),Rect2(13,10,201,100),false)
	var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
	var sprite = host.sprite_for(host.vehicle)
	sprite.draw(view,Vector2(118,81),66,1,0,sprite.frame_index("idle",elapsed,0,false),Color.WHITE,"idle",elapsed,0,false,0,{"equipment":set_data,"age":elapsed})
	var font := ThemeDB.fallback_font
	var values: Array = model.profile.attributes
	for i in range(8):
		var pos := Vector2(40+(i%4)*43,112+int(i/4)*15)
		var icon_index: int = ATTRIBUTE_ICONS[i]
		draw_region(view,"StaticButtons/AvatarShop/AvatarButton/ButtonIcons",Rect2(pos,Vector2(16,11)),Rect2(Vector2(icon_index%6,int(icon_index/6))*Vector2(26,17),Vector2(26,17)))
		view.draw_string_outline(font,pos+Vector2(16,10),"%02d" % int(values[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,9,1,Color.BLACK)
		view.draw_string(font,pos+Vector2(16,10),"%02d" % int(values[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color.WHITE)
	for i in range(2):
		var text := format_number(model.profile.cash if i==0 else model.profile.gold)+("  Cash" if i==0 else "  Gold")
		var pos := Vector2(211-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x,153+i*14)
		view.draw_string_outline(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,2,Color("213148"))
		view.draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,CASH_COLOR if i==0 else GOLD_COLOR)

func draw_region(view: Node2D, path: String, target: Rect2, source: Rect2) -> void:
	var factor := density(path)
	view.draw_texture_rect_region(texture(path),target,Rect2(source.position*factor,source.size*factor))

func block_controls(node: Node, except_node: Node = null) -> void:
	if node == except_node:
		return
	if node is BaseButton:
		blocked.append({"node":node,"disabled":node.disabled})
		node.disabled = true
	for child in node.get_children():
		block_controls(child,except_node)
