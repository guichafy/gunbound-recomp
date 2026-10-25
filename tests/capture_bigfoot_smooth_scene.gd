extends Node
## ADR-104 GPU evidence at the real use scale: room seat (52 px hull) and
## arena (60 px hull) under the project's canvas_items stretch. The window
## of 1920×1080 keeps 1280×800 aspect: 1728×1080 canvas, padded later.
const OUT := "res://docs/bigfoot-smooth-4x/scene/"
const FRAMES := "res://.tools/bigfoot-smooth/scene-frames/"
const Capture = preload("res://tests/capture_bigfoot_smooth.gd")
var scene
var view: SubViewport

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	view = SubViewport.new()
	view.size = Vector2i(1728, 1080)
	view.size_2d_override = Vector2i(1280, 800)
	view.size_2d_override_stretch = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(view)
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/bigfoot-smooth/capture-profile.json")
	view.add_child(scene)
	scene.sound.muted = true
	var smooth = scene.sprites[2]
	var native = Capture.new().native_bigfoot()
	for variant in ["native", "smooth"]:
		scene.sprites[2] = native if variant == "native" else smooth
		scene.show_menu()
		scene.select_vehicle(2)
		await snap("room-%s.png" % variant)
		scene.opening = 0
		scene.match_seed = 1
		scene.start_match()
		for settle in 30:
			await get_tree().process_frame
		await snap("battle-%s.png" % variant)
		for frame in 60:
			scene.model.move_actor(1.0 if frame < 30 else -1.0, 1.0 / 60.0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			view.get_texture().get_image().save_png(FRAMES + "%s-%04d.png" % [variant, frame])
	print("BIGFOOT SMOOTH SCENE GPU: room + battle, 1728x1080 canvas of 1920x1080 window, density=", smooth.density)
	get_tree().quit()

func snap(name: String) -> void:
	for wait in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(OUT + name)
