extends SceneTree
const Art = preload("res://scripts/classic_room_art.gd")
const OUT := "res://docs/room-reference/"
const PROFILE := "res://.tools/room-reference/capture-profile.json"
const STATES := ["texture_normal","texture_hover","texture_pressed","texture_disabled"]
var view
func _initialize() -> void:call_deferred("run")
func geometry(node: Node, data: Dictionary) -> void:
	if node is Control:
		data[str(node.get_instance_id())] = [node.get_global_rect(),node.custom_minimum_size,node.mouse_filter]
	for child in node.get_children():geometry(child,data)
func original(texture: Texture2D) -> Texture2D:
	var source: String = texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path
	var prefix := Art.POLISH_ROOT if source.begins_with(Art.POLISH_ROOT) else (Art.REFERENCE_ROOT if source.begins_with(Art.REFERENCE_ROOT) else Art.ROOT)
	if not source.begins_with(prefix):return null
	var relative := source.trim_prefix(prefix)
	var native := "res://assets/openbound/" if relative.begins_with("items/") else "res://assets/classic/"
	var sheet: Texture2D = load(native+relative)
	if texture is AtlasTexture:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(texture.region.position/4,texture.region.size/4)
		return atlas
	return sheet
func use_native(node: Node) -> Array:
	var saved: Array = []
	var properties: Array = STATES if node is TextureButton else (["texture"] if node is TextureRect else [])
	for key in properties:
		var texture = node.get(key)
		if texture is Texture2D:
			var native := original(texture)
			if native != null:
				saved.append([node,key,texture])
				node.set(key,native)
	for child in node.get_children():saved.append_array(use_native(child))
	return saved
func snap(name: String) -> Image:
	view.queue_redraw()
	view.menu.figures.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if not name.is_empty():shot.save_png(OUT+name+".png")
	return shot
func compare(name: String) -> Dictionary:
	for i in 3:await process_frame
	var before := {}
	geometry(view.root,before)
	var hd := await snap(name+"-hd")
	var saved := use_native(view.root)
	var native := await snap(name+"-native")
	var after := {}
	geometry(view.root,after)
	for item in saved:item[0].set(item[1],item[2])
	return {"screen":name,"size":[hd.get_width(),hd.get_height()],"same_layout_hitboxes":before==after,"state_textures":saved.size(),"images_differ":hd.get_data()!=native.get_data()}
func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(view)
	view.scale = Vector2.ONE*1.35
	view.position = Vector2(96,0)
	view.set_process(false)
	view.sound.muted = true
	view.show_menu()
	view.elapsed = 0
	var report: Array = [await compare("room-grid")]
	view.select_vehicle(-2)
	view.select_cpu_vehicle(-2)
	report.append(await compare("room-random"))
	view.menu.item_catalog.scroll_vertical = 10000
	await process_frame
	report.append(await compare("room-items-bottom"))
	view.menu.open_settings()
	await snap("room-settings")
	var file := FileAccess.open(OUT+"render.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ROOM RENDER ",report)
	view.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(0 if report.all(func(r):return r.same_layout_hitboxes and r.images_differ) else 1)
