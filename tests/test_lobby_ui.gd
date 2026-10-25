extends "res://tests/support/suite.gd"
const Profile = preload("res://scripts/profile.gd")
const Lobby = preload("res://scripts/lobby_screen.gd")
const UI = preload("res://scripts/ui.gd")
const PATH := "res://.tools/lobby-rank/test-profile.json"

func run() -> void:
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var p = Profile.new(PATH)
	check(p.get("rank") == 20, "New local owner is GM20, not level1 or OpenBound GM27")
	var legacy: Dictionary = p.snapshot()
	legacy.erase("rank")
	legacy.xp = 6135
	legacy.nickname = "Veterano"
	legacy.shop.gold = 999681673
	legacy.shop.cash = 999999999
	write_profile(legacy)
	p.load_profile()
	check(p.get("rank") == 20 and p.xp == 6135 and p.gold == 999681673 and p.cash == 999999999, "Legacy migration grants GM without replacing progress/wallet")
	var equipment: Dictionary = p.equipped_set()
	check(p.save_profile(), "Migrated profile saves")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(saved.get("rank") == 20 and saved.version == 4, "Assigned rank persists in version4")
	p = Profile.new(PATH)
	p.load_profile()
	check(p.get("rank") == 20 and p.equipped_set() == equipment, "Reload preserves GM and equipment")
	p.award("rank-award", true)
	check(p.get("rank") == 20 and p.xp == 6255 and p.level() == 32, "GP advances; GM and existing attribute level remain independent")
	if p.get("rank") != null:
		p.rank = -4
		check(p.save_profile(), "Special assigned rank saves")
		var q = Profile.new(PATH)
		q.load_profile()
		check(q.rank == -4, "Signed Silver Dragon survives persistence")
		q.path = "res://.tools/lobby-rank/missing/profile.json"
		check(q.award("failed-rank-save", true) == 0 and q.rank == -4 and q.xp == p.xp, "Failed award restores rank along with progress")
	for invalid in [27, -5, 21, 20.5, "20", null]:
		legacy.rank = invalid
		write_profile(legacy)
		p = Profile.new(PATH)
		p.load_profile()
		check(p.get("rank") == 19, "Invalid explicit rank becomes Chick, never a different convention")
	var rank_path := "res://scripts/classic_ranks.gd"
	check(FileAccess.file_exists(rank_path), "Classic rank catalog exists")
	if FileAccess.file_exists(rank_path):
		var ranks = load(rank_path)
		for code in range(-4, 21):
			var icon: AtlasTexture = ranks.icon(code, false, false)
			check(icon != null and icon.region == Rect2((code + 4) * 15, 0, 15, 25), "Native rank1 frame follows WORD+4")
			icon = ranks.icon(code, true, false)
			check(icon != null and icon.region == Rect2((code + 4) * 25, 0, 25, 15), "Native rank2 frame follows same code")
		check(ranks.title(20) == "GM" and ranks.description(20).contains("Administrador"), "GM identifies Administrator of the System")
		check(ranks.title(19) == "Chick" and ranks.title(-4) == "Silver Dragon", "Catalog follows Thor order")
	var host := Control.new()
	root.add_child(host)
	var lobby = Lobby.new()
	lobby.build(host, UI.new(), {"version":"0.20.5", "nickname":"WWWWWWWWWWWWWWWWWWWW", "level":31,
		"rank":20, "xp":1000000000, "gold":1000000000, "cash":1000000000},
		{"create":func(): pass, "show_shop":func(): pass, "quit":func(): pass})
	await process_frame
	for key in ["PilotName", "PilotRank", "PilotGP", "PilotGold", "PilotCash", "PilotRankIcon"]:
		var node = host.find_child(key, true, false)
		check(node != null, key + " has a dedicated control")
		if node != null:
			check(Rect2(164, 5, 253, 47).encloses(Rect2(node.position, node.size)), key + " fits inside the native card: " + str(Rect2(node.position, node.size)))
	var cash = host.find_child("PilotCash", true, false)
	if cash != null:
		check(cash.text == "Cash 1.000.000.000", "Full wallet value uses readable grouping")
		check(cash.get_theme_font("font").get_string_size(cash.text, HORIZONTAL_ALIGNMENT_LEFT, -1, cash.get_theme_font_size("font_size")).x <= cash.size.x, "Maximum wallet fits without losing digits")
	var rank_label = host.find_child("PilotRank", true, false)
	if rank_label != null:
		check(rank_label.text == "Rank GM", "Card never calls local level31 a classic rank")
	var input_rect := Rect2(lobby.chat_input.global_position, lobby.chat_input.size * lobby.chat_input.get_global_transform().get_scale())
	var stage = host.find_child("ClassicStage", true, false)
	var allowed := Rect2(stage.get_global_transform() * Vector2(39,518), Vector2(501,16) * stage.get_global_transform().get_scale())
	check(allowed.encloses(input_rect), "Resolved LineEdit minimum stays in the native input strip")
	check(lobby.chat_log.scroll_active and lobby.chat_log.mouse_filter != Control.MOUSE_FILTER_IGNORE, "History supports actual scrolling")
	lobby.chat_input.text_submitted.emit("[b]Texto[/b] [color=red]local[/color]")
	check(lobby.chat_log.get_parsed_text().contains("[b]Texto[/b] [color=red]local[/color]"), "Player BBCode is displayed literally")
	check(lobby.chat_input.text.is_empty(), "Enter clears the submitted text")
	for i in range(100):
		lobby.submit_chat("Mensagem %d: " % i + "texto longo ".repeat(8))
	await process_frame
	check(lobby.lines.size() == 64 and lobby.chat_log.get_parsed_text().contains("Mensagem 99:"), "Bounded history retains64messages including newest")
	check(lobby.chat_log.get_v_scroll_bar().max_value > lobby.chat_log.get_v_scroll_bar().page, "Long history has scrollable overflow")
	check(host.find_child("ChannelRankIcon", true, false) != null, "Channel list repeats the assigned rank insignia")
	host.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	await test_input()
	finish("LOBBY UI CHECKS")

func test_input() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = Profile.new(PATH)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	await process_frame
	var input: LineEdit = scene.lobby.chat_input
	click(input.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	check(input.has_focus(), "Click in input strip focuses chat")
	var key := InputEventKey.new()
	key.keycode = KEY_H
	key.physical_keycode = KEY_H
	key.unicode = 104
	key.pressed = true
	root.push_input(key, true)
	key = InputEventKey.new()
	key.keycode = KEY_ENTER
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key, true)
	check(scene.screen == "lobby" and not scene.overlays.is_open(), "Typing H in chat does not open Help")
	check(input.text.is_empty() and scene.lobby.chat_log.get_parsed_text().contains("Piloto: h"), "Actual Enter sends exactly one local message")
	for i in range(70):
		scene.lobby.submit_chat("Mensagem %d" % i)
	await process_frame
	await process_frame
	var bar: VScrollBar = scene.lobby.chat_log.get_v_scroll_bar()
	var bottom := bar.value
	click(scene.lobby.chat_log.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_UP)
	check(bar.value < bottom, "Mouse wheel scrolls chat history")
	click(scene.lobby.create_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await process_frame
	check(scene.screen == "menu" and scene.profile.rank == 20, "CREATE keeps GM assigned in the room")
	scene.show_lobby()
	await process_frame
	check(scene.root.find_child("PilotRank", true, false).text == "Rank GM", "Returning to lobby retains GM")
	scene.free()
	await process_frame
	for path in [PATH, PATH.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func click(at: Vector2, button: int) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = button
		event.pressed = down
		root.push_input(event, true)

func write_profile(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
