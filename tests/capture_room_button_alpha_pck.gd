extends SceneTree
## Run with an absolute --script, --main-pack, --path /private/tmp.
const PROFILE := "/private/tmp/gunbound-footer-alpha-pck-profile.json"
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
	check(panel.cpu_detail.text=="CPU · Normal" and panel.cpu_detail.position==Vector2(503,172),"Packaged CPU card difficulty")
	panel.open_settings()
	panel.choose_difficulty(2)
	panel.accept_settings()
	check(panel.cpu_detail.text=="CPU · Precisa","Packaged CPU difficulty updates on accept")
	var start: TextureButton = stage.get_node("Start")
	check(start.size==Vector2(107,45) and start.position.y==552,"Packaged START matches footer standard")
	for property in ["texture_normal","texture_hover","texture_pressed","texture_disabled"]:
		check(start.get(property).atlas.resource_path.ends_with("room/settings/room_footer_shell_clear.png"),"Packaged alpha-clean shell state"+property)
	for name in ["Start","Settings"]:
		var button: TextureButton = stage.get_node(name)
		for texture in [button.texture_normal,button.texture_hover,button.texture_pressed,button.texture_disabled]:
			var image: Image = texture.get_image()
			check(image.get_pixel(0,0).a==0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a==0,"Packaged shell really has transparent outside corners")
	for texture in start.lettering_frames:
		check(texture.atlas.resource_path.ends_with("room/b_ready_startgame.png"),"Packaged START lettering retains original source")
	for index in 8:
		var base: TextureRect = stage.get_node("WeatherBase%d"%index)
		check(base.texture.get_image().get_pixel(0,0)==Color8(238,153,65),"Packaged weather base remains orange")
	check(stage.get_node("Settings").text=="SETTINGS" and stage.get_node("Start").text=="START","Packaged buttons keep captions and native lettering sources")
	check(panel.settings_font.get_font_name()=="GunBound Classic ASCII","Packaged modal uses native bitmap font")
	check(panel.settings_popup.get_node("SettingsAccept").texture_normal.atlas.resource_path.begins_with(art.SETTINGS_ROOT),"Packaged native OK")
	for key in art.settings_keys:
		var count: int = art.records[key].frames
		for i in count:
			check(art.frame(key,i).atlas.resource_path.begins_with(art.SETTINGS_ROOT),"Packaged settings frame"+key+str(i))
	var settings_catalog: Dictionary = art.settings_art.catalog.duplicate(true)
	art.settings_art.catalog = {}
	for key in art.settings_keys:check(art.frame(key,0).atlas.resource_path.begins_with("res://assets/classic/room/settings/"),"Packaged settings fallback"+key)
	art.settings_art.catalog = settings_catalog
	for word in stage.get_node("Settings").word_frames:
		check(word.get_image().get_pixel(0,0).a==0,"Packaged word keeps transparent corners")
	scene.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(path)
	print("FOOTER ALPHA PCK CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
