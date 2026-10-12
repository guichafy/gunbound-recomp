extends Control
## Original 800x600 Shop, fit uniformly into the current viewport.
const Assets := "res://assets/openbound/shop/"
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
var buy_button
var page_label: Label
var left_button
var right_button
var search: LineEdit
var elapsed := 0.0
var texture_cache: Dictionary = {}
var animated: Array = []
var tab_buttons: Array = []
func texture(path: String):
	if not texture_cache.has(path):
		texture_cache[path] = load(Assets + path + ".png")
	return texture_cache[path]
func atlas(path: String, cell: Vector2, frame: int) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = texture(path)
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
	node.texture_normal = atlas(path,cell,normal)
	node.texture_hover = atlas(path,cell,hover)
	node.texture_pressed = atlas(path,cell,pressed)
	node.texture_disabled = atlas(path,cell,normal if disabled < 0 else disabled)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
func animated_button(path: String, cell: Vector2, pos: Vector2, text: String, action: Callable, normal: int, hover_end: int, click_start: int, click_end: int, disabled: int, active: int = -1):
	var node = sprite_button(content,"AnimatedButtons/AvatarShop/"+path,cell,pos,action,normal,0,click_start,disabled)
	label(node,text,Vector2(-5,cell.y-12),Vector2(cell.x+10,15),10).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animated.append({"node":node,"path":"AnimatedButtons/AvatarShop/"+path,"cell":cell,"normal":normal,"hover_end":hover_end,"click_start":click_start,"click_end":click_end,"disabled":disabled,"active":active,"selected":false,"age":0.0,"state":0})
	return node
func setup(owner, shop_model) -> void:
	host = owner
	model = shop_model
	position = Vector2.ZERO
	size = Vector2(1280,800)
	content = Control.new()
	content.position = Vector2(106.6667,0)
	content.scale = Vector2.ONE * (4.0/3.0)
	content.size = Vector2(800,600)
	add_child(content)
	painter = Paint.new()
	painter.shop = self
	content.add_child(painter)
	for index in range(2):
		var tab = sprite_button(content,"StaticButtons/AvatarShop/TabIndex",Vector2(82,30),Vector2(250+index*82,0),func(): switch_tab(index == 1),1,1,0,0)
		label(tab,["Shop","Inventário"][index],Vector2.ZERO,Vector2(82,30),12).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab_buttons.append(tab)
	var names := ["Cabeça","Corpo","Óculos","Bandeira"]
	var specs := [["Hat",Vector2(49,48),0,19,21,32,33,34],["Body",Vector2(49,39),0,19,20,30,31,32],["Goggles",Vector2(49,46),0,19,20,35,36,37],["Flag",Vector2(56,47),0,14,15,44,45,46]]
	for i in range(4):
		var spec: Array = specs[i]
		animated_button(spec[0],spec[1],Vector2(246+i*51,26),names[i],func(): model.selected_key=""; refresh(i,0),spec[2],spec[3],spec[4],spec[5],spec[6],spec[7])
	search = LineEdit.new()
	search.position = Vector2(638,40)
	search.size = Vector2(144,24)
	search.placeholder_text = "Buscar nome"
	search.add_theme_font_size_override("font_size",11)
	search.text_changed.connect(func(text): model.query=text; refresh(model.category,0))
	content.add_child(search)
	label(content,host.profile.nickname,Vector2(12,32),Vector2(202,25),14)
	var gender_button = button(content,["Masculino","Feminino"][model.profile.gender],Vector2(12,152),Vector2(108,21),func(): pass)
	gender_button.pressed.connect(func():
		if model.profile.set_gender(1-model.profile.gender):
			model.reset_preview()
			gender_button.text = ["Masculino","Feminino"][model.profile.gender]
			refresh(model.category,0)
	)
	points_label = label(content,"",Vector2(12,53),Vector2(208,18),10)
	var attr_names := ["Ataque","Vida","Defesa","Regen.","Atraso tiro","Atraso item","Cratera","Gold %"]
	for i in range(8):
		var pos := Vector2(10+(i%2)*107,75+int(i/2)*17)
		label(content,attr_names[i],pos,Vector2(57,17),8)
		remove_buttons.append(button(content,"−",pos+Vector2(58,0),Vector2(15,17),func(): adjust(i,-1)))
		attribute_labels.append(label(content,"0",pos+Vector2(75,0),Vector2(18,17),10))
		add_buttons.append(button(content,"+",pos+Vector2(92,0),Vector2(15,17),func(): adjust(i,1)))
	button(content,"✓",Vector2(130,152),Vector2(37,21),func():
		if model.profile.commit_attributes(model.draft_attributes):
			status_label.text = "Atributos salvos"
		else:
			status_label.text = "Falha ao salvar"
		update_attributes()
	)
	button(content,"↶",Vector2(174,152),Vector2(37,21),func(): model.draft_attributes=model.profile.attributes.duplicate(); update_attributes())
	balance_label = label(content,"",Vector2(12,477),Vector2(202,33),12)
	label(content,"Prévia do avatar",Vector2(12,188),Vector2(190,18),11)
	label(content,"Prévia em batalha",Vector2(12,315),Vector2(190,18),11)
	button(content,"← Menu",Vector2(12,535),Vector2(90,30),host.show_menu)
	left_button = button(content,"◀",Vector2(450,535),Vector2(30,27),func(): refresh(model.category,model.page-1))
	page_label = label(content,"",Vector2(482,535),Vector2(65,27),13)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_button = button(content,"▶",Vector2(549,535),Vector2(30,27),func(): refresh(model.category,model.page+1))
	try_button = animated_button("Try",Vector2(64,72),Vector2(614,524),"Experimentar",try_selected,13,43,45,70,71)
	buy_button = animated_button("Buy",Vector2(64,73),Vector2(679,524),"Comprar",open_buy,0,23,26,45,46)
	label(content,"Presente / recarga indisponíveis",Vector2(250,574),Vector2(300,18),10)
	status_label = label(content,"Saldo de teste · sem dinheiro real",Vector2(12,514),Vector2(400,18),11)
	refresh(0,0)
func switch_tab(inventory: bool) -> void:
	model.inventory = inventory
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
		var pos := Vector2(252+(index%5)*108,83+int(index/5)*86)
		var card = sprite_button(cards,"StaticButtons/AvatarShop/AvatarButton/Background",Vector2(105,83),pos,func():
			if model.select(item.key):
				refresh(model.category,model.page)
		)
		card.name = "Avatar"+str(index)
		card.tooltip_text = item.name
		label(card,str(item.name).left(13),Vector2(7,2),Vector2(92,15),10)
		var portrait := TextureRect.new()
		portrait.texture = load(item.portrait)
		portrait.position = Vector2(9,17)
		portrait.size = Vector2(87,45)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var marker := ""
		var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
		if set_data.get(str(category)) == item.key:
			marker = "● "
		elif model.profile.owns(item.key):
			marker = "✓ "
		label(card,str(int(item.gold_price))+" G",Vector2(22,59),Vector2(78,11),8).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label(card,str(int(item.cash_price))+" C",Vector2(22,70),Vector2(78,11),8).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if not marker.is_empty():
			var mark := TextureRect.new()
			mark.texture = texture("StaticButtons/AvatarShop/AvatarButton/EquipedIndicator" if marker=="● " else "StaticButtons/AvatarShop/AvatarButton/OwnedCheck")
			mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mark.position = Vector2(1,32) if marker=="● " else Vector2(86,18)
			mark.size = Vector2(12,17)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(mark)
		if model.selected_key == item.key:
			card.texture_normal = atlas("StaticButtons/AvatarShop/AvatarButton/Background",Vector2(105,83),2)
	balance_label.text = "Gold: %d\nCash: %d" % [model.profile.gold,model.profile.cash]
	page_label.text = "%d / %d" % [model.page+1,model.last_page]
	left_button.disabled = model.page == 0
	right_button.disabled = model.page+1 >= model.last_page
	var item: Dictionary = model.catalog.find(model.selected_key)
	try_button.disabled = model.inventory or item.is_empty() or model.preview.get(str(category)) == model.selected_key
	buy_button.disabled = model.inventory or item.is_empty() or model.profile.owns(model.selected_key) or not can_buy(item)
	for i in range(4):
		animated[i].selected = i == category
	for i in range(2):
		tab_buttons[i].texture_normal = atlas("StaticButtons/AvatarShop/TabIndex",Vector2(82,30),0 if (i==1)==model.inventory else 1)
	update_attributes()
	painter.queue_redraw()
func can_buy(item: Dictionary) -> bool:
	return (int(item.get("gold_price",0))>0 and model.profile.gold>=int(item.gold_price)) or (int(item.get("cash_price",0))>0 and model.profile.cash>=int(item.cash_price))
func try_selected() -> void:
	model.try_selected()
	refresh(model.category,model.page)
func open_buy() -> void:
	if is_instance_valid(modal) or buy_button.disabled:
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
	box.texture = texture("Popup/Blue/Avatar/Buy")
	box.position = Vector2(640,400)-box.texture.get_size()*0.8
	box.size = box.texture.get_size()*1.6
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(box)
	label(modal,item.name,Vector2(490,256),Vector2(300,35),19).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(modal,"Confirmar compra?",Vector2(490,330),Vector2(300,30),18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for currency in ["gold","cash"]:
		var price := int(item.get(currency+"_price",0))
		if price <= 0:
			continue
		var balance: int = model.profile.gold if currency == "gold" else model.profile.cash
		var x := 500 if currency == "gold" else 650
		label(modal,"%s\n%d → %d" % [currency.capitalize(),balance,balance-price],Vector2(x,378),Vector2(145,60),16)
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
	for entry in blocked:
		if is_instance_valid(entry.node):
			entry.node.disabled = entry.disabled
	blocked.clear()
	search.editable = true
	purchase_key = ""
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		if is_instance_valid(modal):
			close_buy()
		else:
			host.show_menu()
		get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
	elapsed += delta
	for entry in animated:
		var node = entry.node
		var state := 3 if node.disabled else (2 if node.is_pressed() else (1 if node.is_hovered() else 0))
		entry.age = 0.0 if state != entry.state else float(entry.age)+delta
		entry.state = state
		var frame := int(entry.normal)
		if state == 3:
			frame = entry.disabled
		elif state == 2:
			frame = mini(int(entry.click_end),int(entry.click_start)+int(entry.age*30.0))
		elif state == 1:
			frame = int(entry.age*30.0) % (int(entry.hover_end)+1)
		elif entry.selected and int(entry.active)>=0:
			frame = entry.active
		node.texture_normal = atlas(entry.path,entry.cell,frame)
		node.texture_hover = node.texture_normal
		node.texture_pressed = node.texture_normal
	painter.queue_redraw()
func paint(view: Node2D) -> void:
	view.draw_texture(texture("InGame/Scene/AvatarShop/Background"),Vector2.ZERO)
	view.draw_texture(texture("InGame/Scene/AvatarShop/Foreground2" if model.inventory else "InGame/Scene/AvatarShop/Foreground1"),Vector2.ZERO)
	if FileAccess.file_exists("res://scripts/avatar_art.gd"):
		var art = avatar_art
		var set_data: Dictionary = model.profile.equipped_set() if model.inventory else model.preview
		art.draw(view,set_data,Transform2D(0,Vector2(-1.7,1.7),0,Vector2(120,269)),elapsed,Color.WHITE)
		var sprite = host.sprite_for(host.vehicle)
		sprite.draw(view,Vector2(117,436),92,1,0,sprite.frame_index("idle",elapsed,0,false),Color.WHITE,"idle",elapsed,0,false,0,{"equipment":set_data,"age":elapsed})

func block_controls(node: Node) -> void:
	if node is BaseButton:
		blocked.append({"node":node,"disabled":node.disabled})
		node.disabled = true
	for child in node.get_children():
		block_controls(child)
