extends SceneTree
## Render real do consumidor: mesmos controles/estado, alternando somente atlas4×/nativo.
const Chrome = preload("res://scripts/classic_chrome.gd")
const OUT := "res://docs/classic-buttons-integration/"
const PROFILE := "res://.tools/classic-buttons-hd/capture-profile.json"
const STATES := ["texture_normal", "texture_hover", "texture_pressed", "texture_disabled"]
var view

func _initialize() -> void:
	call_deferred("run")

func native_textures(node: Node) -> Array:
	var saved: Array = []
	if node is TextureButton:
		for property in STATES:
			var texture = node.get(property)
			if texture is AtlasTexture and texture.atlas.resource_path.begins_with(Chrome.HD_ROOT):
				saved.append([node, property, texture])
				var native := AtlasTexture.new()
				native.atlas = load(texture.atlas.resource_path.replace(Chrome.HD_ROOT, Chrome.ROOT))
				native.region = Rect2(texture.region.position / 4.0, texture.region.size / 4.0)
				node.set(property, native)
	for child in node.get_children():
		saved.append_array(native_textures(child))
	return saved

func snap(name: String) -> Image:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT + name + ".png")
	return image

func compare(name: String) -> Dictionary:
	var hd: Image = await snap(name + "-4x")
	var saved := native_textures(view.root)
	var native: Image = await snap(name + "-native")
	for item in saved:
		item[0].set(item[1], item[2])
	var identical := hd.get_size() == native.get_size() and hd.get_data() == native.get_data()
	print("RENDER ", name, " | SIZE ", hd.get_size(), " | IDENTICAL ", identical)
	return {"screen": name, "size": [hd.get_width(), hd.get_height()], "identical_rgba": identical, "replaced_state_textures": saved.size()}

func run() -> void:
	root.size = Vector2i(1920, 1080)
	# O stretch KEEP captura apenas o viewport interno1728×1080. Aqui a
	# mesma transformação do jogo inclui as margens no framebuffer1920×1080.
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(view)
	view.scale = Vector2.ONE * 1.35
	view.position = Vector2(96, 0)
	view.set_process(false)
	view.sound.muted = true
	var results: Array = []
	results.append(await compare("lobby"))
	view.show_menu()
	view.select_vehicle(1)
	view.select_cpu_vehicle(14)
	view.elapsed = 0.0
	results.append(await compare("room"))
	var file := FileAccess.open(OUT + "render.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	view.free()
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(0 if results.all(func(result): return result.identical_rgba) else 1)
