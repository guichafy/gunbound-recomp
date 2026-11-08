extends Panel
## Scalable front-screen preferences (REQ-55). Native battle menu remains separate.
signal changed
signal cancelled
const I18n = preload("res://scripts/i18n.gd")
const VALUES := ["language", "sfx", "bgm", "scroll", "aiming", "background"]
var options
var ui
var snapshot := {}
var nickname_input: LineEdit
var difficulty_buttons: Array[Button] = []
var weather_buttons: Array[Button] = []
var language: OptionButton
var aiming: OptionButton
var background: CheckBox
var sliders := {}
var value_labels := {}
var feedback: Label
var scroll: ScrollContainer
var accept_button: Button
var cancel_button: Button

func _init(factory, values, nickname: String, accept: Callable, cancel: Callable, difficulty: Callable, weather: Callable) -> void:
	ui = factory
	options = values
	name = "FrontSettings"
	position = Vector2(140,55)
	size = Vector2(1000,690)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel",ui.box(ui.INK,10,ui.STEEL,2))
	ui.label(self,"Configurações",Vector2(32,20),Vector2(860,40),28,ui.CREAM,true)
	ui.label(self,"As mudanças de áudio e idioma têm prévia.",Vector2(32,62),Vector2(910,26),16,ui.MUTED)
	var close: Button = ui.button(self,"×",Vector2(932,20),Vector2(36,36),cancel)
	close.tooltip_text = "Cancelar alterações (ESC)"
	close.focus_mode = Control.FOCUS_ALL
	scroll = ScrollContainer.new()
	scroll.position = Vector2(24,108)
	scroll.size = Vector2(952,448)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var body := Control.new()
	body.custom_minimum_size = Vector2(928,448)
	scroll.add_child(body)
	ui.label(body,"Treino",Vector2(8,0),Vector2(400,28),19,ui.AMBER,true)
	ui.label(body,"Preferências",Vector2(488,0),Vector2(400,28),19,ui.AMBER,true)
	label(body,"Apelido",Vector2(8,44))
	nickname_input = LineEdit.new()
	nickname_input.position = Vector2(8,72)
	nickname_input.size = Vector2(416,40)
	nickname_input.text = nickname
	nickname_input.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nickname_input.max_length = 20
	nickname_input.placeholder_text = I18n.text("Seu apelido")
	style(nickname_input)
	body.add_child(nickname_input)
	label(body,"Dificuldade da CPU",Vector2(8,140))
	var difficulty_group := ButtonGroup.new()
	var difficulties := ["Leve","Normal","Precisa"]
	for index in 3:
		var button := radio(body,difficulties[index],Vector2(8+index*140,170),Vector2(134,40),difficulty_group)
		button.pressed.connect(difficulty.bind(index))
		difficulty_buttons.append(button)
	label(body,"Clima",Vector2(8,238))
	var weather_group := ButtonGroup.new()
	for index in 2:
		var button := radio(body,["Original do mapa","Todos os efeitos"][index],Vector2(8,268+index*48),Vector2(416,40),weather_group)
		button.pressed.connect(weather.bind(["original","all"][index]))
		weather_buttons.append(button)
	var help: Label = ui.label(body,"Idioma dos textos. Imagens serão traduzidas futuramente.",Vector2(8,384),Vector2(416,52),15,ui.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(body,"Idioma",Vector2(488,44))
	language = dropdown(body,Vector2(710,38),["English","Português (Brasil)"])
	language.item_selected.connect(func(index: int):
		options.language = I18n.LOCALES[index]
		I18n.set_locale(options.language)
		changed.emit())
	add_slider(body,"bgm","Música",98,0,100)
	add_slider(body,"sfx","Efeitos sonoros",158,0,100)
	label(body,"Modo de mira",Vector2(488,222))
	aiming = dropdown(body,Vector2(710,216),["Drag","Slice"])
	aiming.item_selected.connect(func(index: int): options.aiming=index; changed.emit())
	add_slider(body,"scroll","Velocidade da câmera",282,0,100)
	background = CheckBox.new()
	background.text = "Exibir fundo"
	background.add_theme_constant_override("h_separation",10)
	background.position = Vector2(488,352)
	background.size = Vector2(416,40)
	style(background)
	body.add_child(background)
	background.toggled.connect(func(value: bool): options.background=value; changed.emit())
	var unavailable: Label = ui.label(self,"Sniper, MIDI, qualidade 3D, Mouse Speed e skins extras indisponíveis.",Vector2(32,560),Vector2(936,40),14,ui.MUTED)
	unavailable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback = ui.label(self,"",Vector2(32,600),Vector2(542,60),15,ui.AMBER)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cancel_button = ui.button(self,"Cancelar",Vector2(592,620),Vector2(150,42),cancel)
	cancel_button.name = "SettingsCancel"
	cancel_button.focus_mode = Control.FOCUS_ALL
	accept_button = ui.button(self,"Salvar alterações",Vector2(758,620),Vector2(210,42),accept,true)
	accept_button.name = "SettingsAccept"
	accept_button.focus_mode = Control.FOCUS_ALL
	visible = false

func label(parent: Control, text: String, at: Vector2) -> void:
	ui.label(parent,text,at,Vector2(220,26),16,ui.CREAM)

func style(control: Control) -> void:
	control.add_theme_font_override("font",ui.font)
	control.add_theme_font_size_override("font_size",17)
	control.add_theme_color_override("font_color",ui.CREAM)
	control.add_theme_stylebox_override("normal",ui.box(Color("1c354e"),4,ui.STEEL,1))
	control.add_theme_stylebox_override("focus",ui.box(Color.TRANSPARENT,4,ui.AMBER,2))

func dropdown(parent: Control, at: Vector2, labels: Array) -> OptionButton:
	var control := OptionButton.new()
	control.position = at
	control.size = Vector2(194,40)
	for text in labels:
		control.add_item(text)
	style(control)
	parent.add_child(control)
	return control

func radio(parent: Control, text: String, at: Vector2, bounds: Vector2, group: ButtonGroup) -> Button:
	var button: Button = ui.button(parent,text,at,bounds,func(): pass)
	button.toggle_mode = true
	button.button_group = group
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("pressed",ui.box(Color("276079"),4,ui.TEAL,2))
	return button

func add_slider(parent: Control, key: String, title: String, y: float, low: int, high: int) -> void:
	label(parent,title,Vector2(488,y))
	var value: Label = ui.label(parent,"",Vector2(842,y),Vector2(62,26),16,ui.AMBER,true)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_labels[key] = value
	var slider: HSlider = ui.slider(parent,Vector2(488,y+30),Vector2(416,22),low,high,options.get(key),func(next: float):
		options.set(key,roundi(next))
		update_values()
		changed.emit())
	slider.focus_mode = Control.FOCUS_ALL
	slider.add_theme_stylebox_override("focus",ui.box(Color.TRANSPARENT,3,ui.AMBER,2))
	sliders[key] = slider

func begin_edit() -> void:
	snapshot.clear()
	for key in VALUES:
		snapshot[key] = options.get(key)
	feedback.text = ""
	language.select(I18n.LOCALES.find(options.language))
	aiming.select(options.aiming)
	background.set_pressed_no_signal(options.background)
	for key in sliders:
		sliders[key].set_value_no_signal(options.get(key))
	update_values()
	scroll.scroll_vertical = 0

func update_values() -> void:
	for key in value_labels:
		value_labels[key].text = "%.2f×" % options.scroll_factor() if key=="scroll" else "%d%%" % options.get(key)

func restore() -> void:
	for key in snapshot:
		options.set(key,snapshot[key])
	changed.emit()

func show_save_error() -> void:
	feedback.text = "Não foi possível salvar as configurações. Tente novamente."

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancelled.emit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSLATION_CHANGED and is_instance_valid(nickname_input):
		nickname_input.placeholder_text = I18n.text("Seu apelido")

func commit() -> void:
	snapshot.clear()
