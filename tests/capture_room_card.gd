extends SceneTree
const OUT := "res://docs/room-card-fidelity/"
const PROFILE := "res://.tools/room-contact/capture-profile.json"
var view
func _initialize() -> void:call_deferred("run")
func snap(name: String = "") -> Image:
	view.queue_redraw()
	view.menu.figures.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if not name.is_empty():shot.save_png(OUT+name+".png")
	return shot
func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(view)
	view.scale = Vector2.ONE*1.35
	view.position = Vector2(96,0)
	view.set_process(false)
	view.sound.muted = true
	view.show_menu()
	view.elapsed = 0
	var first := await snap("room-corrected")
	var fixed := [view.menu.player_anchor,view.menu.cpu_anchor]
	var gallery := Image.create(1320,17*260,false,Image.FORMAT_RGBA8)
	for i in 17:
		var id: int = i+1 if i<16 else -2
		view.select_vehicle(id)
		view.select_cpu_vehicle(id)
		var shot := await snap()
		gallery.blit_rect(shot,Rect2i(300,105,1320,260),Vector2i(0,i*260))
	gallery.save_png(OUT+"mobile-gallery.png")
	view.select_vehicle(3)
	view.select_cpu_vehicle(3)
	view.profile.purchase("0:0:1","gold")
	view.profile.equip("0:0:1")
	await snap("room-nak-equipped")
	var variants := {}
	var sequence := Image.create(1440,720,false,Image.FORMAT_RGBA8)
	var stationary := true
	for tick in 24:
		view.elapsed = float(tick)/20.0
		var shot := await snap()
		variants[hash(shot.get_region(Rect2i(310,110,240,180)).get_data())] = true
		sequence.blit_rect(shot,Rect2i(310,110,240,180),Vector2i((tick%6)*240,int(tick/6.0)*180))
		stationary = stationary and fixed==[view.menu.player_anchor,view.menu.cpu_anchor]
	sequence.save_png(OUT+"idle-24-frames.png")
	var held := await snap()
	var held_again := await snap()
	var plate_paths := {}
	var stage: Node = view.menu.figures.get_parent()
	for key in ["PlayerReady","CpuReady","RoomMasterKey","RoomMode","RoomSize","RoomMapSide","RoomDeath","RoomItems"]:
		plate_paths[key] = stage.get_node(key).texture.atlas.resource_path
	var status = view.menu.room_art.status_art
	var catalog: Dictionary = status.catalog.duplicate(true)
	status.catalog = {}
	for key in plate_paths:
		var art_key: String = {"PlayerReady":"room_status","CpuReady":"room_status","RoomMasterKey":"room_master_key","RoomMode":"room_mode","RoomSize":"room_size","RoomMapSide":"room_map_side","RoomDeath":"room_death","RoomItems":"room_items"}[key]
		stage.get_node(key).texture = view.menu.room_art.frame(art_key,3 if key in ["PlayerReady","CpuReady"] else 0)
	await snap("room-native-indicators")
	status.catalog = catalog
	var report := {"size":[first.get_width(),first.get_height()],"roster":17,"anchors_fixed":stationary,"idle_variants":variants.size(),"held_time_identical":held.get_data()==held_again.get_data(),"mobile_names_hidden":not view.menu.player_mobile.visible and not view.menu.cpu_mobile.visible,"indicator_textures":plate_paths}
	var file := FileAccess.open(OUT+"render.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ROOM CARD RENDER ",report)
	view.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(0 if stationary and variants.size()>1 and report.held_time_identical and report.mobile_names_hidden else 1)
