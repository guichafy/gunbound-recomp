extends "res://tests/support/suite.gd"
const PATH := "res://.tools/i18n/lobby-settings-profile.json"
func click(point: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
func run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/i18n"))
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PATH)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	await process_frame
	var button: BaseButton = scene.root.find_child("Settings",true,false)
	check(button!=null,"Lobby exposes Settings before Create enters the room")
	if button==null:
		scene.free()
		finish("LOBBY SETTINGS CHECKS")
		return
	var ranking: BaseButton = scene.root.find_child("Ranking",true,false)
	check(button.position==Vector2(163,551) and button.position.y==ranking.position.y and button.get_rect().end.x<ranking.position.x and ranking.disabled,"Settings is immediately left of disabled Ranking")
	scene.lobby.submit_chat("Vida")
	scene.lobby.chat_input.text = "Rascunho"
	var history: Array = scene.lobby.lines.duplicate()
	click(button.get_global_rect().get_center())
	await process_frame
	check(scene.screen=="lobby" and scene.overlays.kind=="settings", "Real click opens preferences over the lobby")
	var panel = scene.overlays.settings_popup
	panel.language.select(1)
	panel.language.item_selected.emit(1)
	panel.sliders.sfx.value = 0
	panel.nickname_input.text = "Changed"
	click(scene.lobby.create_button.get_global_rect().get_center())
	check(scene.screen=="lobby" and scene.overlays.kind=="settings", "Modal blocks Create behind it")
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	await process_frame
	check(scene.screen=="lobby" and not scene.overlays.is_open() and scene.options.language=="en" and scene.options.sfx==100,"ESC cancels language/audio and stays in lobby")
	click(button.get_global_rect().get_center())
	await process_frame
	panel = scene.overlays.settings_popup
	panel.nickname_input.text = "Você"
	panel.difficulty_buttons[2].pressed.emit()
	panel.weather_buttons[1].pressed.emit()
	panel.language.select(1)
	panel.language.item_selected.emit(1)
	click(panel.accept_button.get_global_rect().get_center())
	await process_frame
	check(scene.screen=="lobby" and not scene.overlays.is_open() and scene.profile.nickname=="Você" and scene.cpu_difficulty==2 and scene.weather_mode=="all", "Save applies preferences without entering the room")
	check(scene.root.find_child("PilotName",true,false).text=="Você" and scene.lobby.chat_input.placeholder_text=="Mensagem local", "Lobby refreshes identity and language without translating nickname")
	var saved = load("res://scripts/options.gd").new(scene.options.path)
	saved.load_options()
	check(saved.language=="pt_BR", "Lobby language selection persists")
	check(scene.lobby.lines==history and scene.lobby.chat_input.text=="Rascunho", "Save and cancel preserve chat history and draft")
	click(button.get_global_rect().get_center())
	await process_frame
	panel = scene.overlays.settings_popup
	var options_path: String = scene.options.path
	scene.options.path = "res://.tools/i18n/missing/options.json"
	panel.nickname_input.text = "Unsaved"
	panel.sliders.sfx.value = 0
	click(panel.accept_button.get_global_rect().get_center())
	await process_frame
	check(scene.overlays.kind=="settings" and not panel.feedback.text.is_empty() and scene.profile.nickname=="Você", "Failed lobby save keeps modal open and confirmed profile intact")
	scene.options.path = options_path
	click(panel.cancel_button.get_global_rect().get_center())
	await process_frame
	check(not scene.overlays.is_open() and scene.options.sfx==100, "Cancel after failed lobby save restores audio")
	click(button.get_global_rect().get_center())
	await process_frame
	panel = scene.overlays.settings_popup
	panel.language.select(0)
	panel.language.item_selected.emit(0)
	scene.show_menu()
	await process_frame
	check(scene.options.language=="pt_BR", "Leaving the lobby restores any unconfirmed preview")
	scene.show_lobby()
	await process_frame
	click(scene.lobby.create_button.get_global_rect().get_center())
	await process_frame
	check(scene.screen=="menu" and scene.root.find_child("Settings",true,false)==null,"Create enters room with Settings removed")
	check(scene.menu.cpu_detail.text=="CPU · Precisa" and scene.menu.nickname_input.text=="Você", "Room inherits preferences chosen in the lobby")
	scene.free()
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("LOBBY SETTINGS CHECKS")
