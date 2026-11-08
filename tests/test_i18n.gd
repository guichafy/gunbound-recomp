extends "res://tests/support/suite.gd"
const Options = preload("res://scripts/options.gd")
const PATH := "res://.tools/i18n/options.json"

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/i18n"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var options = Options.new(PATH)
	check(options.get("language") == "en", "New preferences default to English")
	var store = load("res://scripts/json_store.gd")
	store.write_atomic(PATH, {"sfx":80, "aiming":0})
	options.load_options()
	check(options.get("language") == "en" and options.sfx==80 and options.aiming==0, "Old preferences keep values and default to English")
	if not FileAccess.file_exists("res://scripts/i18n.gd"):
		check(false, "Runtime translation service exists")
		finish("I18N CHECKS")
		return
	var i18n = load("res://scripts/i18n.gd")
	i18n.set_locale("en")
	check(i18n.text("Dificuldade da CPU")=="CPU difficulty", "English text is translated")
	check(i18n.text("%s · atraso %d") % ["Laser",42]=="Laser · delay 42", "Formatting occurs after translation")
	check(i18n.text("Personal name 123")=="Personal name 123", "Unknown names remain intact")
	var mobiles = load("res://scripts/mobiles.gd")
	for id in mobiles.PLAYABLE:
		var summary: String = mobiles.definition(id).summary
		check(i18n.text(summary)!=summary, "Mobile summary is translated: %d" % id)
		for weapon in mobiles.definition(id).weapons:
			if weapon.name not in ["Laser","EMP","Mini Nak","SS"]:
				check(i18n.text(weapon.name)!=weapon.name, "Weapon name translated: "+weapon.name)
	var format := RegEx.new()
	format.compile("%[-+0-9.]*[dsf]")
	var catalog = load("res://locales/en.gd").MESSAGES
	for message in catalog:
		var original := []
		var translated := []
		for token in format.search_all(message): original.append(token.get_string())
		for token in format.search_all(catalog[message]): translated.append(token.get_string())
		check(original==translated, "Translation preserves placeholders: "+message)
	i18n.set_locale("pt_BR")
	check(i18n.text("Dificuldade da CPU")=="Dificuldade da CPU", "Portuguese restores original text")
	options.language = "pt_BR"
	check(options.save_options(), "Locale saves with preferences")
	var loaded = Options.new(PATH)
	loaded.load_options()
	check(loaded.language=="pt_BR" and loaded.sfx==80, "Locale and audio survive reload")
	for invalid in ["xx", "", 42, null, ["en"]]:
		store.write_atomic(PATH, {"language":invalid})
		loaded = Options.new(PATH)
		loaded.load_options()
		check(loaded.language=="en", "Invalid stored locale defaults to English: "+str(invalid))
	i18n.set_locale("xx")
	check(TranslationServer.get_locale()=="en", "Invalid runtime locale defaults to English")
	i18n.set_locale("pt_BR")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	finish("I18N CHECKS")
