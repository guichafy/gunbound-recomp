extends RefCounted
## Lobby clássico (ADR-096). A entrada do jogo. Create abre a sala 1×1.
## Patente atribuída do cliente Thor; GP usa a progressão local (ADR-102).
## Não há Buddy, rede nem classificação competitiva.

const Chrome = preload("res://scripts/classic_chrome.gd")
const Ranks = preload("res://scripts/classic_ranks.gd")
const CHAT_LIMIT := 64

var create_button: TextureButton
var chrome
var view_all: TextureButton
var waiting: TextureButton
var chat_log: RichTextLabel
var chat_input: LineEdit
var room_filter := "all"
var lines: Array[String] = []
var nickname := "Piloto"
var rank_code := Ranks.GM

## `info`: version, nickname, rank, xp, gold, cash.
## `actions`: create, show_shop, quit.
func build(root: Control, ui, info: Dictionary, actions: Dictionary) -> void:
	chrome = Chrome.new()
	nickname = str(info.nickname)
	rank_code = Ranks.normalize(info.get("rank", Ranks.GM))
	var tag: Label = ui.label(root, "TREINO OFFLINE\n/   " + str(info.version), Vector2(6, 8), Vector2(96, 42), 10, ui.CREAM, true)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_constant_override("outline_size", 3)
	tag.add_theme_color_override("font_outline_color", ui.INK)
	tag.size = Vector2(96, 42)
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
	# Insígnia172,9 comprovada no render nativo; três linhas no mesmo cartão.
	rank_icon(stage, "PilotRankIcon", Vector2(172, 9), false)
	card_label(stage, ui, "PilotName", nickname, Vector2(191, 6), Vector2(139, 16), 12, ui.CREAM)
	var rank: Label = card_label(stage, ui, "PilotRank", "Rank " + Ranks.title(rank_code), Vector2(333, 7), Vector2(80, 14), 10, ui.CREAM)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank.tooltip_text = Ranks.description(rank_code)
	card_label(stage, ui, "PilotGP", grouped(int(info.xp)) + " GP", Vector2(191, 23), Vector2(222, 13), 10, Color("ffe08a"))
	card_label(stage, ui, "PilotGold", "Gold " + grouped(int(info.gold)), Vector2(169, 38), Vector2(119, 13), 9, Color("ffe08a"))
	var cash: Label = card_label(stage, ui, "PilotCash", "Cash " + grouped(int(info.cash)), Vector2(291, 38), Vector2(122, 13), 9, Color("b6ffc8"))
	cash.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func card_label(stage: Control, ui, key: String, text: String, at: Vector2, bounds: Vector2, font_size: int, color: Color) -> Label:
	var label: Label = ui.label(stage, text, at, bounds, font_size, color, true)
	label.name = key
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = text
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", ui.INK)
	# ui.label define size antes do tema: recalcular após fonte e clipping.
	label.size = bounds
	return label

static func grouped(value: int) -> String:
	var digits := str(maxi(0, value))
	var result := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += "."
		result += digits[index]
	return result

func rank_icon(stage: Control, key: String, at: Vector2, horizontal: bool) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = key
	icon.texture = Ranks.icon(rank_code, horizontal)
	icon.position = at
	icon.size = icon.texture.get_size()
	icon.tooltip_text = Ranks.description(rank_code)
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	stage.add_child(icon)
	return icon

func build_filters(stage: Control, _ui) -> void:
	view_all = chrome.button(stage, "b_gamelist_viewall", Vector2(42, 246), 4)
	view_all.tooltip_text = "Mostra o canal local. Não há lista de salas."
	view_all.pressed.connect(func(): choose_filter("all"))
	waiting = chrome.button(stage, "b_gamelist_wait", Vector2(131, 246), 0)
	waiting.tooltip_text = "Não há salas em espera. O canal continua só com você."
	waiting.pressed.connect(func(): choose_filter("waiting"))
	lock(chrome.button(stage, "b_gamelist_prev", Vector2(242, 246)), "Não há lista de salas para folhear.")
	lock(chrome.button(stage, "b_gamelist_next", Vector2(292, 246)), "Não há lista de salas para folhear.")
	lock(chrome.button(stage, "b_gamelist_friend", Vector2(371, 246)), "Amigos ficam de fora neste treino.")
	lock(chrome.button(stage, "b_gamelist_directgo", Vector2(460, 246)), "Ir a uma sala de rede não está disponível.")

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
	chat_log.name = "LocalChatHistory"
	chat_log.position = Vector2(42, 324)
	chat_log.size = Vector2(477, 188)
	chat_log.bbcode_enabled = true
	chat_log.scroll_active = true
	chat_log.scroll_following = true
	chat_log.mouse_filter = Control.MOUSE_FILTER_STOP
	chat_log.clip_contents = true
	chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_log.add_theme_font_override("normal_font", ui.font)
	chat_log.add_theme_font_size_override("normal_font_size", 11)
	chat_log.add_theme_color_override("default_color", Color("e7f6ff"))
	stage.add_child(chat_log)
	push_line("[color=#b6ffc8]Treino offline — canal local.[/color]")
	chat_input = LineEdit.new()
	chat_input.name = "LocalChatInput"
	chat_input.position = Vector2(42, 518)
	chat_input.placeholder_text = "Mensagem local"
	chat_input.max_length = 80
	chat_input.focus_mode = Control.FOCUS_CLICK
	chat_input.add_theme_font_override("font", ui.font)
	chat_input.add_theme_font_size_override("font_size", 10)
	chat_input.add_theme_color_override("font_color", Color("e7f6ff"))
	chat_input.add_theme_color_override("font_placeholder_color", Color("7f9aa8"))
	chat_input.add_theme_color_override("caret_color", Color("e7f6ff"))
	# O tema padrão impunha altura mínima e um retângulo opaco fora da faixa.
	var field := StyleBoxEmpty.new()
	chat_input.add_theme_stylebox_override("normal", field)
	chat_input.add_theme_stylebox_override("focus", field)
	chat_input.add_theme_stylebox_override("read_only", field)
	chat_input.text_submitted.connect(submit_chat)
	stage.add_child(chat_input)
	chat_input.size = Vector2(493, 16)

func submit_chat(text: String) -> void:
	var line := text.strip_edges().replace("\n", " ").replace("\r", " ").left(chat_input.max_length)
	chat_input.text = ""
	if line.is_empty():
		return
	push_line((nickname + ": " + line).replace("[", "[lb]"))

func push_line(bbcode: String) -> void:
	lines.append(bbcode)
	while lines.size() > CHAT_LIMIT:
		lines.pop_front()
	chat_log.text = "\n".join(lines)

func build_roster(stage: Control, ui) -> void:
	rank_icon(stage, "ChannelRankIcon", Vector2(589, 333), true)
	var who: Label = ui.label(stage, nickname, Vector2(618, 331), Vector2(128, 18), 12, ui.CREAM, true)
	who.name = "ChannelPilotName"
	who.clip_text = true
	who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	who.tooltip_text = nickname + " · " + Ranks.description(rank_code)
	who.mouse_filter = Control.MOUSE_FILTER_PASS
	who.add_theme_constant_override("outline_size", 2)
	who.add_theme_color_override("font_outline_color", ui.INK)
	who.size = Vector2(128, 18)

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
