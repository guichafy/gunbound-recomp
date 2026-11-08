extends SceneTree
const OUT := "res://docs/settings-i18n/"
const PROFILE := "res://.tools/i18n/capture-profile.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/i18n"))
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	view.options = load("res://scripts/options.gd").new(PROFILE+"-options.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	for locale in ["en","pt_BR"]:
		view.options.language = locale
		view.apply_options()
		view.show_lobby()
		if locale=="en":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"lobby-settings-entry.png")
		view.show_lobby_settings()
		view.overlays.settings_popup.nickname_input.text = "WWWWWWWWWWWWWWWWWWWW"
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"settings-"+locale+".png")
	root.size = Vector2i(960,600)
	view.scale = Vector2.ONE*0.75
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"settings-pt_BR-960.png")
	view.free()
	await process_frame
	for path in [PROFILE,PROFILE+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
