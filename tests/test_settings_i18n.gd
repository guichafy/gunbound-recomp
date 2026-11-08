extends "res://tests/support/suite.gd"
const PATH := "res://.tools/i18n/scene-profile.json"
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/i18n"))
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PATH)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	check(scene.menu.portrait.tooltip_text.contains("health") and not scene.menu.portrait.tooltip_text.contains("vida"), "English room translates formatted mobile statistics")
	check(scene.menu.item_tip("dual").contains("Delay"), "English room translates formatted item hints")
	check(scene.weather_label()=="Weather: map default", "English weather caption translates its components")
	check(scene.menu.status_line.text.contains("Selecting"), "English selection status is translated")
	scene.menu.open_settings()
	var panel = scene.menu.settings_popup
	check(panel.has_method("begin_edit"), "Settings exposes full preference editor")
	if not panel.has_method("begin_edit"):
		scene.free()
		finish("SETTINGS I18N CHECKS")
		return
	check(scene.menu.player_name.auto_translate_mode==Node.AUTO_TRANSLATE_MODE_DISABLED and scene.menu.nickname_input.auto_translate_mode==Node.AUTO_TRANSLATE_MODE_DISABLED, "Player names and nickname input never auto-translate")
	var vehicle: int = scene.vehicle
	var balance: int = scene.profile.gold
	var old_name: String = scene.profile.nickname
	panel.language.select(1)
	panel.language.item_selected.emit(1)
	panel.sliders.sfx.value = 80
	panel.aiming.select(0)
	panel.aiming.item_selected.emit(0)
	check(scene.menu.nickname_input.placeholder_text=="Seu apelido", "Language preview refreshes nickname placeholder without translating player text")
	check(scene.options.language=="pt_BR" and TranslationServer.get_locale()=="pt_BR", "Language previews without restart")
	check(scene.options.sfx==80 and is_equal_approx(scene.sound.volume,0.1), "Audio previews immediately")
	scene.menu.nickname_input.text = "Você Piloto"
	scene.menu.choose_difficulty(2)
	scene.menu.cancel_popup()
	check(scene.options.language=="en" and TranslationServer.get_locale()=="en" and scene.options.sfx==100 and scene.options.aiming==1, "Cancel restores all preferences and language")
	check(scene.profile.nickname==old_name and scene.cpu_difficulty==1, "Cancel discards training draft")
	scene.menu.open_settings()
	panel.language.select(1)
	panel.language.item_selected.emit(1)
	panel.sliders.bgm.value = 90
	scene.menu.nickname_input.text = "Você Piloto"
	scene.menu.choose_difficulty(2)
	scene.menu.choose_weather("all")
	scene.menu.accept_settings()
	check(not scene.menu.popup_open() and scene.options.language=="pt_BR", "Save confirms and closes editor")
	var saved = load("res://scripts/options.gd").new(scene.options.path)
	saved.load_options()
	check(saved.language=="pt_BR" and saved.bgm==90, "Save persists language and audio")
	var item_order := ["dual","dual_plus","energy_up_2","energy_up_1","blood","change_wind","team_teleport","bunge_shot","power_up","teleport","thunder"]
	for index in item_order.size():
		check(scene.menu.item_grid_buttons[index].tooltip_text==scene.menu.item_tip(item_order[index]), "Locale refresh preserves the item hint matching its button: "+item_order[index])
	check(scene.profile.nickname=="Você Piloto" and scene.cpu_difficulty==2 and scene.weather_mode=="all", "Save confirms training and preserves user text")
	check(scene.vehicle==vehicle and scene.profile.gold==balance and scene.options.items.size()==4, "Settings preserves mobile, balance and loadout")
	scene.menu.open_settings()
	var path: String = scene.options.path
	scene.options.path = "res://.tools/i18n/missing/options.json"
	panel.sliders.sfx.value = 0
	scene.menu.nickname_input.text = "Uncommitted"
	scene.menu.choose_difficulty(0)
	scene.menu.accept_settings()
	check(scene.menu.popup_open() and not panel.feedback.text.is_empty(), "Write failure keeps editor open with feedback")
	check(scene.profile.nickname=="Você Piloto" and scene.cpu_difficulty==2, "Failed preferences save rolls back profile and training draft")
	var persisted = load("res://scripts/profile.gd").new(PATH)
	persisted.load_profile()
	check(persisted.nickname=="Você Piloto", "Failed preferences save leaves saved nickname intact")
	scene.options.path = path
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	scene._unhandled_key_input(event)
	check(not scene.menu.popup_open() and scene.options.sfx==100 and scene.screen=="menu", "ESC rolls back failed save without leaving room")
	scene.menu.open_settings()
	var profile_path: String = scene.profile.path
	scene.profile.path = "res://.tools/i18n/missing/profile.json"
	scene.menu.nickname_input.text = "Unsaved profile"
	panel.sliders.bgm.value = 0
	scene.menu.accept_settings()
	check(scene.menu.popup_open() and scene.profile.nickname=="Você Piloto", "Profile write failure keeps editor open and restores nickname")
	saved.load_options()
	check(saved.bgm==90, "Profile write failure never saves preview preferences")
	scene.profile.path = profile_path
	scene.menu.cancel_popup()
	check(scene.options.bgm==90, "Cancelling failed profile save restores live music")
	scene.show_lobby()
	check(scene.lobby.chat_log.auto_translate_mode==Node.AUTO_TRANSLATE_MODE_DISABLED and scene.lobby.chat_input.auto_translate_mode==Node.AUTO_TRANSLATE_MODE_DISABLED, "Player chat never auto-translates")
	scene.free()
	for file in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	finish("SETTINGS I18N CHECKS")
