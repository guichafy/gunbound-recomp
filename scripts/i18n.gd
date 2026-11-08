extends RefCounted
## Presentation-only translations. Never translate IDs, nicknames or chat input.
const English = preload("res://locales/en.gd")
const LOCALES := ["en", "pt_BR"]
static var installed := false

static func normalize(locale) -> String:
	return locale if locale is String and locale in LOCALES else "en"

static func set_locale(locale: String) -> void:
	if not installed:
		var english := Translation.new()
		english.locale = "en"
		for message in English.MESSAGES:
			english.add_message(message, English.MESSAGES[message])
		TranslationServer.add_translation(english)
		# Register source language explicitly so Godot never falls back to English.
		var portuguese := Translation.new()
		portuguese.locale = "pt_BR"
		for message in English.MESSAGES:
			portuguese.add_message(message, message)
		TranslationServer.add_translation(portuguese)
		installed = true
	TranslationServer.set_locale(normalize(locale))

static func text(message: String) -> String:
	return TranslationServer.translate(message)
