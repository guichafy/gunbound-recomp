extends RefCounted
## Start menu (REQ-02, REQ-36): nickname, mobile, difficulty, weather, items,
## Shop and help. Built from plain data and callbacks; it never reads the scene.

const Mobiles = preload("res://scripts/mobiles.gd")
const DIFFICULTIES := ["Leve", "Normal", "Precisa"]

var ui
var nickname_input: LineEdit
var vehicle_buttons: Array[Button] = []
var vehicle_info: Label
var items_button: Button
var difficulty_buttons: Array[Button] = []

## `info`: version, nickname, difficulty, weather_label, items_label, level, xp, wins.
## `actions`: select_vehicle(id), select_difficulty(index), toggle_weather() -> label,
## show_items, start, show_shop, show_help.
func build(root: Control, factory, info: Dictionary, actions: Dictionary) -> void:
	ui = factory
	var tag: Label = ui.label(root, "TREINO DE ARTILHARIA   /   " + str(info.version), Vector2(80, 74), Vector2(530, 24), 14, ui.TEAL, true)
	tag.add_theme_constant_override("outline_size", 2)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	var title: Label = ui.label(root, "GUNBOUND\nRECOMP", Vector2(74, 130), Vector2(650, 235), 80, ui.CREAM, true)
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.1, 0.16, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 5)
	ui.label(root, "Mire. Sinta o vento. Faça a cratera.", Vector2(80, 390), Vector2(630, 38), 23)
	ui.label(root, "Um duelo contra a máquina, nas alturas.", Vector2(80, 430), Vector2(630, 28), 17, Color("d7e8e6"))
	ui.label(root, "ARTILHARIA POR TURNOS · TREINO OFFLINE 1×1", Vector2(80, 753), Vector2(720, 22), 12, Color("c4d6d5"), true)
	var card: Panel = ui.panel(root, Vector2(800, 112), Vector2(420, 620), Color("112b38"), 22)
	ui.label(card, "Preparar treino", Vector2(28, 25), Vector2(364, 44), 30, ui.CREAM, true)
	ui.label(card, "Uma arena. Você e a máquina.", Vector2(28, 73), Vector2(364, 24), 16, ui.MUTED)
	ui.label(card, "SEU APELIDO", Vector2(28, 115), Vector2(364, 22), 12, ui.TEAL, true)
	nickname_input = LineEdit.new()
	nickname_input.position = Vector2(28, 144)
	nickname_input.size = Vector2(364, 47)
	nickname_input.text = info.nickname
	nickname_input.max_length = 20
	nickname_input.placeholder_text = "Como devemos chamar você?"
	nickname_input.add_theme_font_override("font", ui.font)
	nickname_input.add_theme_font_size_override("font_size", 19)
	nickname_input.add_theme_color_override("font_color", ui.CREAM)
	nickname_input.add_theme_color_override("caret_color", ui.TEAL)
	nickname_input.add_theme_stylebox_override("normal", ui.box(Color("203e4b"), 8, Color("49636c")))
	nickname_input.add_theme_stylebox_override("focus", ui.box(Color("203e4b"), 8, ui.TEAL, 2))
	card.add_child(nickname_input)
	ui.label(card, "ESCOLHA SEU VEÍCULO", Vector2(28, 206), Vector2(364, 18), 12, ui.TEAL, true)
	vehicle_buttons.clear()
	# Four columns keep every classic mobile inside the 364 px card.
	for slot in range(Mobiles.PLAYABLE.size()):
		var id: int = Mobiles.PLAYABLE[slot]
		var column := slot % 4
		var row := int(slot / 4)
		var button: Button = ui.button(card, Mobiles.definition(id).name, Vector2(28 + column * 92, 228 + row * 32), Vector2(86, 28), func(): actions.select_vehicle.call(id))
		button.add_theme_font_size_override("font_size", 11)
		vehicle_buttons.append(button)
	vehicle_info = ui.label(card, "", Vector2(28, 360), Vector2(364, 36), 13, ui.MUTED)
	ui.label(card, "DIFICULDADE DA MÁQUINA", Vector2(28, 400), Vector2(364, 18), 12, ui.TEAL, true)
	difficulty_buttons.clear()
	for index in range(DIFFICULTIES.size()):
		var button: Button = ui.button(card, DIFFICULTIES[index], Vector2(28 + index * 124, 422), Vector2(116, 36), func():
			actions.select_difficulty.call(index)
			highlight(difficulty_buttons, index)
		)
		difficulty_buttons.append(button)
		if index == int(info.difficulty):
			button.add_theme_stylebox_override("normal", selected_box(true))
	var weather_button: Button = ui.button(card, info.weather_label, Vector2(28, 466), Vector2(240, 32), func(): pass)
	weather_button.add_theme_font_size_override("font_size", 14)
	weather_button.tooltip_text = "Original: pesos do mapa (Miramo A não tem Thor, Espelho nem Fraqueza).\nTodos: pesos iguais para todos os climas, Thor incluído."
	weather_button.pressed.connect(func(): weather_button.text = actions.toggle_weather.call())
	# PopupSelectItem (REQ-36): the six equipped slots used in every match.
	items_button = ui.button(card, info.items_label, Vector2(276, 466), Vector2(116, 32), actions.show_items)
	items_button.add_theme_font_size_override("font_size", 14)
	items_button.tooltip_text = "Escolher os itens da barra F1–F6 (Select Item)"
	ui.button(card, "INICIAR TREINO    →", Vector2(28, 508), Vector2(364, 48), actions.start, true)
	ui.label(card, "NÍVEL %d    ·    %d XP    ·    %d VITÓRIAS" % [info.level, info.xp, info.wins], Vector2(28, 564), Vector2(364, 22), 12, ui.MUTED, true)
	ui.button(root, "Shop de avatar", Vector2(810, 754), Vector2(200, 30), actions.show_shop)
	ui.button(root, "Como jogar", Vector2(1030, 754), Vector2(190, 30), actions.show_help)

## Marks the chosen mobile and describes it.
func show_vehicle(id: int) -> void:
	highlight(vehicle_buttons, Mobiles.PLAYABLE.find(id))
	var data: Dictionary = Mobiles.definition(id)
	vehicle_info.text = "%d de vida · %d de movimento\n%s" % [data.hp, int(data.move), str(data.summary)]

func highlight(buttons: Array[Button], chosen: int) -> void:
	for j in range(buttons.size()):
		buttons[j].add_theme_stylebox_override("normal", selected_box(j == chosen))

func selected_box(selected: bool) -> StyleBoxFlat:
	return ui.box(Color("32666b") if selected else Color("24444e"), 9, ui.TEAL if selected else Color("47626a"))
