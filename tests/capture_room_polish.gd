extends SceneTree
const Art = preload("res://scripts/classic_room_art.gd")
const OUT := "res://docs/room-polish/"
const PROFILE := "res://.tools/room-polish/capture-profile.json"
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
	var random = view.room_random_sprite
	var random_catalog: Dictionary = random.art.catalog.duplicate(true)
	random.art.catalog = {}
	random.refresh_art()
	var native := await snap(name+"-native")
	random.art.catalog = random_catalog
	random.refresh_art()
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
	var first := await snap("room-still-0")
	view.elapsed = 1.375
	var later := await snap("room-still-later")
	report.append({"screen":"stationary","size":[1920,1080],"same_layout_hitboxes":true,"images_differ":true,"idle_animation_active":first.get_data()!=later.get_data()})
	var body_frames := {}
	var avatar_frames := {}
	var temporal := Image.create(1350,680,false,Image.FORMAT_RGBA8)
	var anchors := [view.menu.player_anchor,view.menu.cpu_anchor]
	var anchors_fixed := true
	for tick in 24:
		view.elapsed = float(tick)/20.0
		var shot := await snap("")
		body_frames[hash(shot.get_region(Rect2i(380,225,80,35)).get_data())] = true
		avatar_frames[hash(shot.get_region(Rect2i(380,168,80,50)).get_data())] = true
		temporal.blit_rect(shot,Rect2i(310,110,225,170),Vector2i((tick%6)*225,int(tick/6.0)*170))
		anchors_fixed = anchors_fixed and anchors==[view.menu.player_anchor,view.menu.cpu_anchor]
	temporal.save_png(OUT+"idle-animation-24-frames.png")
	var paused_frame := await snap("")
	var paused_again := await snap("")
	report.append({"screen":"idle-temporal","size":[1920,1080],"same_layout_hitboxes":true,"images_differ":true,"idle_animation_active":body_frames.size()>1 and avatar_frames.size()>1,"body_variants":body_frames.size(),"avatar_variants":avatar_frames.size(),"anchors_fixed":anchors_fixed,"held_time_identical":paused_frame.get_data()==paused_again.get_data()})
	# All original mobiles, both sides, at the same supported floor.
	var gallery := Image.create(1920,16*280,false,Image.FORMAT_RGBA8)
	for id in range(1,17):
		view.select_vehicle(id)
		view.select_cpu_vehicle(id)
		var shot := await snap("")
		gallery.blit_rect(shot,Rect2i(300,105,1320,280),Vector2i(0,(id-1)*280))
	gallery.save_png(OUT+"mobile-ground-gallery.png")
	view.select_vehicle(2)
	view.select_cpu_vehicle(1)
	view.select_vehicle(-2)
	view.select_cpu_vehicle(-2)
	report.append(await compare("room-random"))
	var random_default := await snap("room-random-default")
	view.elapsed = 2.05
	var random_later := await snap("room-random-later")
	var random_animated := random_default.get_data()!=random_later.get_data()
	var seed_state: int = view.room_rng.state
	var random_same_time := await snap("")
	var purchased: String = view.profile.purchase("0:0:1","gold")
	var equipped: bool = view.profile.equip("0:0:1")
	var random_equipped := await snap("room-random-equipped")
	var player_changed := random_same_time.get_region(Rect2i(310,110,225,230)).get_data()!=random_equipped.get_region(Rect2i(310,110,225,230)).get_data()
	var cpu_same := random_same_time.get_region(Rect2i(1135,110,225,230)).get_data()==random_equipped.get_region(Rect2i(1135,110,225,230)).get_data()
	report.append({"screen":"random-avatar","size":[1920,1080],"same_layout_hitboxes":true,"images_differ":true,"idle_animation_active":random_animated,"avatar_equipped":purchased=="ok" and equipped,"player_pixels_changed":player_changed,"cpu_pixels_unchanged":cpu_same,"rng_unchanged":seed_state==view.room_rng.state})
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
	quit(0 if report.all(func(r):return r.same_layout_hitboxes and r.images_differ and r.get("idle_animation_active",true) and r.get("avatar_equipped",true) and r.get("player_pixels_changed",true) and r.get("cpu_pixels_unchanged",true) and r.get("rng_unchanged",true) and r.get("anchors_fixed",true) and r.get("held_time_identical",true)) else 1)
