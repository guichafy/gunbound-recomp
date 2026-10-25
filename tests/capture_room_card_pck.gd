extends SceneTree
## Run with an absolute --script, --main-pack, --path /private/tmp.
const PROFILE := "/private/tmp/gunbound-room-card-pck-profile.json"
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ",message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	check(not FileAccess.file_exists("res://override.cfg"),"Local override is excluded")
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(path)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	await process_frame
	var panel = scene.menu
	var art = panel.room_art
	check(FileAccess.file_exists("res://assets/classic/room/status/catalog.json") and FileAccess.file_exists(art.STATUS_ROOT+"catalog.json"),"Both room status catalogs are packaged")
	for key in art.status_keys:
		var cell: Vector2 = Vector2(art.records[key].frame_size[0],art.records[key].frame_size[1])
		for index in int(art.records[key].frames):
			var frame: AtlasTexture = art.frame(key,index)
			check(frame.atlas.resource_path.begins_with(art.STATUS_ROOT) and frame.region==Rect2(index*cell.x*4,0,cell.x*4,cell.y*4),"Packaged status HD retains native frame: "+key)
	var catalog: Dictionary = art.status_art.catalog.duplicate(true)
	art.status_art.catalog = {}
	for key in art.status_keys:
		var frame: AtlasTexture = art.frame(key,0)
		check(frame.atlas.resource_path.begins_with("res://assets/classic/room/status/"),"Packaged native fallback: "+key)
	art.status_art.catalog = catalog
	check(panel.player_anchor+Vector2(0,panel.NATIVE_GROUND)==Vector2(105,155),"Packaged player room support point")
	check(panel.cpu_anchor+Vector2(0,panel.NATIVE_GROUND)==Vector2(563,155),"Packaged CPU room support point")
	check(not panel.player_mobile.visible and not panel.cpu_mobile.visible,"Packaged card headers omit mobile names")
	var stage: Node = panel.figures.get_parent()
	for key in ["PlayerReady","CpuReady"]:
		check(stage.get_node(key).mouse_filter==Control.MOUSE_FILTER_IGNORE,"Packaged Ready preserves card click-through")
	scene.select_vehicle(-2)
	scene.select_cpu_vehicle(-2)
	check(scene.player_random and scene.cpu_random and not panel.player_mobile.visible and not panel.cpu_mobile.visible,"Packaged Random preserves presentation and selection")
	scene.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(path)
	print("ROOM CARD PCK CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
