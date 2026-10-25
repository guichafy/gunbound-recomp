extends "res://tests/support/suite.gd"

const Chrome = preload("res://scripts/classic_chrome.gd")
const HD := "res://assets/hd/classic/buttons_smooth_4x/"
const PROFILE := "res://.tools/classic-buttons-hd/test-profile.json"

func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event)

func check_frame(texture: AtlasTexture, region: Rect2, label: String) -> void:
	check(texture.region == region, label)

func test_atlases() -> void:
	var chrome = Chrome.new()
	var records: Dictionary = chrome.manifest.strips
	check(records.size() == 42, "All 42 classic button atlases remain available")
	for key in records:
		var info: Dictionary = records[key]
		var size := Vector2(float(info.frame_size[0]), float(info.frame_size[1]))
		check(chrome.frame_size(key) == size, "%s keeps native logical size" % key)
		var first: AtlasTexture = chrome.frame(key, 0)
		check(first.atlas.resource_path == HD + str(info.file), "%s uses the enlarged imported texture" % key)
		var native: Texture2D = load(Chrome.ROOT + str(info.file))
		var original := native.get_image()
		var enlarged := first.atlas.get_image()
		var expected := Image.load_from_file(HD + str(info.file))
		expected.convert(Image.FORMAT_RGBA8)
		enlarged.convert(Image.FORMAT_RGBA8)
		# Godot repairs RGB under alpha0 during import. Compare visible color
		# and alpha, preserving this legitimate transparent-border repair.
		expected.premultiply_alpha()
		var imported_visible: Image = enlarged.duplicate()
		imported_visible.premultiply_alpha()
		check(imported_visible.get_data() == expected.get_data(), "%s imported visible pixels match the smoothing pipeline without lossy compression" % key)
		for index in int(info.frames):
			check_frame(chrome.frame(key, index), Rect2(index * size.x * 4, 0, size.x * 4, size.y * 4), "%s state %d uses density 4 in source pixels" % [key, index])
			if enlarged.get_size() == original.get_size() * 4:
				var same_alpha := true
				for point in [Vector2i.ZERO, Vector2i(int(size.x) / 2, int(size.y) / 2), Vector2i(size) - Vector2i.ONE]:
					var source_point: Vector2i = point + Vector2i(index * int(size.x), 0)
					same_alpha = same_alpha and is_equal_approx(original.get_pixelv(source_point).a, enlarged.get_pixelv(source_point * 4).a)
				check(same_alpha, "%s state %d preserves alpha/alignment while tones are interpolated" % [key, index])
	var approved := Image.load_from_file("res://docs/exit-restoration-preview/exit-4x-bicubic.png")
	var live_exit: Image = chrome.frame("b_gamelist_exit", 0).atlas.get_image()
	approved.convert(Image.FORMAT_RGBA8)
	live_exit.convert(Image.FORMAT_RGBA8)
	check(live_exit.get_data() == approved.get_data(), "Live EXIT exactly matches the user-approved bicubic preview")
	check(chrome.image("lobby_back").resource_path == "res://assets/hd/classic/lobby_smooth_4x/lobby/back.png", "The lobby background uses independent conservative HD")
	check(chrome.image("room_back").get_size() == Vector2(3200, 2400), "Room background has true4x density")
	var stage := Chrome.mount(root)
	var button: TextureButton = chrome.button(stage, "b_gamelist_create", Vector2(532, 551))
	check(button.position == Vector2(532, 551) and button.size == Vector2(107, 45), "CREATE keeps its position and click rectangle")
	check(button.ignore_texture_size and button.custom_minimum_size == Vector2(107, 45), "The enlarged texture cannot inflate the control minimum")
	check(button.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and button.stretch_mode == TextureButton.STRETCH_SCALE, "Existing filtering and stretch remain")
	check_frame(button.texture_normal, Rect2(0, 0, 428, 180), "Normal uses original state 0")
	check_frame(button.texture_hover, Rect2(428, 0, 428, 180), "Hover uses original state 1")
	check_frame(button.texture_pressed, Rect2(856, 0, 428, 180), "Pressed uses original state 2")
	check_frame(button.texture_disabled, Rect2(1284, 0, 428, 180), "Disabled uses original state 3")
	var filter_button: TextureButton = chrome.button(stage, "b_gamelist_viewall", Vector2(34, 247), 4)
	check_frame(filter_button.texture_normal, Rect2(1296, 0, 324, 132), "Active filter retains state 4")
	check_frame(filter_button.texture_hover, Rect2(1296, 0, 324, 132), "Hover over an active filter retains state 4")
	check_frame(chrome.frame("b_gamelist_create", -10), Rect2(0, 0, 428, 180), "Invalid negative state clamps to normal")
	check_frame(chrome.frame("b_gamelist_create", 99), Rect2(1284, 0, 428, 180), "Out-of-range state clamps at the last source frame")
	stage.free()

func test_fallback() -> void:
	var chrome = Chrome.new()
	var catalog = chrome.get("hd_manifest")
	check(catalog is Dictionary and not catalog.is_empty(), "HD metadata is available to validate registered resources")
	if not catalog is Dictionary:
		return
	var baseline: Dictionary = catalog.duplicate(true)
	for damaged in [{}, {"version": 1, "scale": 3, "buttons": baseline.buttons}, {"version": 1, "scale": 4, "buttons": []}]:
		chrome.set("hd_manifest", damaged)
		var frame: AtlasTexture = chrome.frame("b_gamelist_create", 2)
		check(frame.atlas.resource_path == "res://assets/classic/lobby/b_gamelist_create.png" and frame.region == Rect2(214, 0, 107, 45), "Missing/invalid HD catalog falls back to the native atlas without changing state")
	for field in ["frame_size", "size", "order", "source", "file"]:
		var damaged: Dictionary = baseline.duplicate(true)
		damaged.buttons.b_gamelist_create[field] = null
		chrome.set("hd_manifest", damaged)
		var frame: AtlasTexture = chrome.frame("b_gamelist_create", 1)
		check(frame.atlas.resource_path == "res://assets/classic/lobby/b_gamelist_create.png" and frame.region == Rect2(107, 0, 107, 45), "Invalid %s requests native fallback" % field)
		check(chrome.frame("b_ready_start", 0).atlas.resource_path == HD + "room/b_ready_start.png", "Fallback of one record preserves other valid HD buttons")

func test_screens() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	await process_frame
	var create: TextureButton = scene.lobby.create_button
	check(create.size == Vector2(107, 45) and create.position == Vector2(532, 551), "The real lobby uses the same CREATE hitbox")
	var bounds := create.get_global_rect()
	click(Vector2(bounds.end.x + 1, bounds.get_center().y))
	await process_frame
	check(scene.screen == "lobby", "Click just outside CREATE stays outside its hitbox")
	click(bounds.get_center())
	await process_frame
	check(scene.screen == "menu", "Click inside CREATE opens the room")
	if scene.screen != "menu":
		scene.free()
		return
	check(scene.menu.grid_buttons.size() == 15, "The room offers14common mobiles andRandom")
	for index in scene.menu.grid_buttons.size():
		var button: TextureButton = scene.menu.grid_buttons[index]
		var expected := Vector2(33 + (index % 5) * 66, 396 + int(index / 5.0) * 44)
		check(button.position == expected and button.size == Vector2(63, 44), "Grid button %d retains its native rectangle" % index)
		check(button.texture_normal.atlas.resource_path.begins_with(HD if index<14 else "res://assets/hd/classic/room_reference_4x/"), "Grid button %d uses HD states" % index)
	click(scene.menu.grid_buttons[1].get_global_rect().get_center())
	await process_frame
	check(scene.vehicle == 1 and scene.menu.grid_buttons[1].texture_normal.region.position.x == 1008, "The same grid hitbox selects Mage and retains active state 4")
	var cpu_slot: Button = scene.root.find_child("CpuSlot", true, false)
	click(cpu_slot.get_global_rect().get_center())
	await process_frame
	click(scene.menu.grid_buttons[13].get_global_rect().get_center())
	await process_frame
	check(scene.cpu_vehicle == 16, "CPU selection uses the same slot and Aduka hitboxes")
	scene.free()
	await process_frame
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	test_atlases()
	test_fallback()
	await test_screens()
	finish("CLASSIC BUTTONS HD CHECKS")
