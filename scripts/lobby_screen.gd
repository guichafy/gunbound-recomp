extends RefCounted
## Lobby clássico (ADR-096). A entrada do jogo. Create abre a sala 1×1.
## Não há Buddy, rede nem ranking: JOIN e RANKING ficam desabilitados.
## Rank e GP do cartão são o nível e o XP locais do perfil, não rank de servidor.

const Chrome = preload("res://scripts/classic_chrome.gd")

var create_button: TextureButton
var chrome
var view_all: TextureButton
var waiting: TextureButton
var chat_log: RichTextLabel
var chat_input: LineEdit
var room_filter := "all"
var lines: Array[String] = []
var nickname := "Piloto"

## `info`: version, nickname, level, xp, gold, cash.
## `actions`: create, show_shop, quit.
func build(root: Control, ui, info: Dictionary, actions: Dictionary) -> void:
	chrome = Chrome.new()
	nickname = str(info.nickname)
	var tag: Label = ui.label(root, "TREINO OFFLINE   /   " + str(info.version), Vector2(6, 8), Vector2(96, 150), 11, ui.CREAM, true)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_constant_override("outline_size", 3)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	var stage: Control = Chrome.mount(root)
	chrome.place(stage, "lobby_back", Vector2.ZERO)
	chrome.place(stage, "lobby_buddy_fill", Vector2(163, 551))
	chrome.place(stage, "lobby_chat", Vector2(23, 287))
	chrome.place(stage, "lobby_channel", Vector2(572, 287))
	build_card(stage, ui, info)
	build_filters(stage, ui)
	build_channels(stage)
	build_chat(stage, ui)
	build_roster(stage, ui)
	build_actions(stage, actions)

func build_card(stage: Control, ui, info: Dictionary) -> void:
	# Cartão nativo x=162–418, y=8–48. Rank = level(), GP = xp.
	var name: Label = ui.label(stage, nickname, Vector2(168, 10), Vector2(128, 16), 13, ui.CREAM, true)
	name.clip_text = true
	name.add_theme_constant_override("outline_size", 2)
	name.add_theme_color_override("font_outline_color", ui.INK)
	var rank: Label = ui.label(stage, "Rank %d" % int(info.level), Vector2(298, 10), Vector2(112, 16), 11, ui.CREAM, true)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank.add_theme_constant_override("outline_size", 2)
	rank.add_theme_color_override("font_outline_color", ui.INK)
	var gp: Label = ui.label(stage, "%d GP" % int(info.xp), Vector2(168, 28), Vector2(90, 14), 11, Color("ffe08a"), true)
	gp.add_theme_constant_override("outline_size", 2)
	gp.add_theme_color_override("font_outline_color", ui.INK)
	var money: Label = ui.label(stage, "Gold %d   Cash %d" % [int(info.gold), int(info.cash)], Vector2(250, 28), Vector2(160, 14), 10, ui.CREAM, true)
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money.clip_text = true
	money.add_theme_constant_override("outline_size", 2)
	money.add_theme_color_override("font_outline_color", ui.INK)

func build_filters(stage: Control, _ui) -> void:
	view_all = chrome.button(stage, "b_gamelist_viewall", Vector2(34, 247), 4)
	view_all.tooltip_text = "Mostra o canal local. Não há lista de salas."
	view_all.pressed.connect(func(): choose_filter("all"))
	waiting = chrome.button(stage, "b_gamelist_wait", Vector2(121, 247), 0)
	waiting.tooltip_text = "Não há salas em espera. O canal continua só com você."
	waiting.pressed.connect(func(): choose_filter("waiting"))
	lock(chrome.button(stage, "b_gamelist_prev", Vector2(238, 247)), "Não há lista de salas para folhear.")
	lock(chrome.button(stage, "b_gamelist_next", Vector2(296, 247)), "Não há lista de salas para folhear.")
	lock(chrome.button(stage, "b_gamelist_friend", Vector2(366, 247)), "Amigos ficam de fora neste treino.")
	lock(chrome.button(stage, "b_gamelist_directgo", Vector2(454, 247)), "Ir a uma sala de rede não está disponível.")

func choose_filter(mode: String) -> void:
	room_filter = "waiting" if mode == "waiting" else "all"
	chrome.paint(view_all, "b_gamelist_viewall", 4 if room_filter == "all" else 0)
	chrome.paint(waiting, "b_gamelist_wait", 4 if room_filter == "waiting" else 0)

func build_channels(stage: Control) -> void:
	for index in range(1, 9):
		var key := "b_gamechat_ch%d" % index
		var node: TextureButton = chrome.button(stage, key, Vector2(292 + (index - 1) * 24, 293), 4 if index == 1 else 3)
		node.name = "Channel%d" % index
		if index == 1:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			continue
		lock(node, "Só o canal 1 fica ativo no treino local.")

func build_chat(stage: Control, ui) -> void:
	chat_log = RichTextLabel.new()
	chat_log.position = Vector2(38, 324)
	chat_log.size = Vector2(470, 188)
	chat_log.bbcode_enabled = true
	chat_log.scroll_active = false
	chat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_log.add_theme_font_override("normal_font", ui.font)
	chat_log.add_theme_font_size_override("normal_font_size", 12)
	chat_log.add_theme_color_override("default_color", Color("e7f6ff"))
	stage.add_child(chat_log)
	push_line("[color=#b6ffc8]Treino offline. Este canal é local e não está ligado a um servidor.[/color]")
	chat_input = LineEdit.new()
	chat_input.position = Vector2(40, 518)
	chat_input.size = Vector2(488, 16)
	chat_input.placeholder_text = "Mensagem local"
	chat_input.max_length = 80
	chat_input.focus_mode = Control.FOCUS_CLICK
	chat_input.add_theme_font_override("font", ui.font)
	chat_input.add_theme_font_size_override("font_size", 11)
	chat_input.add_theme_color_override("font_color", Color("e7f6ff"))
	chat_input.add_theme_color_override("font_placeholder_color", Color("7f9aa8"))
	chat_input.add_theme_color_override("caret_color", Color("e7f6ff"))
	var field := StyleBoxFlat.new()
	field.bg_color = Color(0, 48.0 / 255.0, 65.0 / 255.0)
	field.set_content_margin_all(1)
	chat_input.add_theme_stylebox_override("normal", field)
	chat_input.add_theme_stylebox_override("focus", field)
	chat_input.text_submitted.connect(submit_chat)
	stage.add_child(chat_input)

func submit_chat(text: String) -> void:
	var line := text.strip_edges()
	chat_input.text = ""
	if line.is_empty():
		return
	push_line(nickname.replace("[", "") + ": " + line.replace("[", ""))

func push_line(bbcode: String) -> void:
	lines.append(bbcode)
	while lines.size() > 8:
		lines.pop_front()
	chat_log.text = "\n".join(lines)

func build_roster(stage: Control, ui) -> void:
	var who: Label = ui.label(stage, nickname, Vector2(588, 332), Vector2(155, 18), 13, ui.CREAM, true)
	who.clip_text = true
	who.add_theme_constant_override("outline_size", 2)
	who.add_theme_color_override("font_outline_color", ui.INK)

func build_actions(stage: Control, actions: Dictionary) -> void:
	var exit_button: TextureButton = chrome.button(stage, "b_gamelist_exit", Vector2(40, 551))
	exit_button.name = "ExitLobby"
	exit_button.tooltip_text = "Encerra o jogo."
	exit_button.pressed.connect(actions.quit)
	var ranking: TextureButton = chrome.button(stage, "b_gamelist_ranking", Vector2(286, 551))
	ranking.name = "Ranking"
	lock(ranking, "Ranking continua fora do treino offline.")
	var avatar: TextureButton = chrome.button(stage, "b_gamelist_avatar", Vector2(409, 551))
	avatar.name = "Avatar"
	avatar.tooltip_text = "Abre a loja de avatares."
	avatar.pressed.connect(actions.show_shop)
	create_button = chrome.button(stage, "b_gamelist_create", Vector2(532, 551))
	create_button.name = "Create"
	create_button.tooltip_text = "Abre a sala de treino 1×1."
	create_button.pressed.connect(actions.create)
	var join: TextureButton = chrome.button(stage, "b_gamelist_join", Vector2(655, 551))
	join.name = "Join"
	lock(join, "Não há salas de rede. Create abre o treino 1×1.")

func lock(node: TextureButton, tip: String) -> void:
	node.disabled = true
	node.tooltip_text = tip
	node.mouse_default_cursor_shape = Control.CURSOR_ARROW
