extends SceneTree
## Compara suavização e atlas exato na mesma cena: geometria e máscara dos botões.
const Chrome = preload("res://scripts/classic_chrome.gd")
const EXACT := "res://assets/hd/classic/buttons_4x/"
const OUT := "res://docs/classic-buttons-smoothing/"
const PROFILE := "res://.tools/classic-buttons-smoothing/capture-profile.json"
const STATES := ["texture_normal", "texture_hover", "texture_pressed", "texture_disabled"]
var view

func _initialize() -> void:
	call_deferred("run")

func geometry(node: Node, result: Dictionary) -> void:
	if node is Control:
		result[str(node.get_instance_id())] = [node.get_global_rect(), node.custom_minimum_size, node.mouse_filter]
	for child in node.get_children():
		geometry(child, result)

func use_exact(node: Node, rectangles: Array) -> Array:
	var saved: Array = []
	if node is TextureButton:
		var found := false
		for property in STATES:
			var texture = node.get(property)
			if texture is AtlasTexture and texture.atlas.resource_path.begins_with(Chrome.HD_ROOT):
				found = true
				saved.append([node, property, texture])
				var exact := AtlasTexture.new()
				exact.atlas = load(texture.atlas.resource_path.replace(Chrome.HD_ROOT, EXACT))
				exact.region = texture.region
				node.set(property, exact)
		if found:
			rectangles.append(node.get_global_rect())
	for child in node.get_children():
		saved.append_array(use_exact(child, rectangles))
	return saved

func snap(name: String) -> Image:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT + name + ".png")
	return image

func compare(name: String) -> Dictionary:
	var before: Dictionary = {}
	geometry(view.root, before)
	var smooth: Image = await snap(name + "-smooth")
	var rectangles: Array = []
	var saved := use_exact(view.root, rectangles)
	var exact: Image = await snap(name + "-exact")
	var after: Dictionary = {}
	geometry(view.root, after)
	for item in saved:
		item[0].set(item[1], item[2])
	var bounds: Array = []
	for rect in rectangles:
		bounds.append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
	var same_layout := before == after
	print("SMOOTH RENDER ", name, " | SIZE ", smooth.get_size(), " | SAME_LAYOUT ", same_layout)
	return {"screen": name, "size": [smooth.get_width(), smooth.get_height()], "same_layout_hitboxes": same_layout, "button_rectangles": bounds, "state_textures": saved.size(), "images_differ": smooth.get_data() != exact.get_data()}

func run() -> void:
	root.size = Vector2i(1920, 1080)
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
	var results: Array = [await compare("lobby")]
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
	quit(0 if results.all(func(result): return result.same_layout_hitboxes and result.images_differ) else 1)
