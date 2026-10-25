extends SceneTree
## Same-scene native/HD comparison, isolated profile, no runtime motion.
const Chrome = preload("res://scripts/classic_chrome.gd")
const Art = preload("res://scripts/classic_lobby_art.gd")
const OUT := "res://docs/lobby-art-hd/"
const PROFILE := "res://.tools/lobby-art-hd/capture-profile.json"
var view

func _initialize() -> void:
	call_deferred("run")

func geometry(node: Node, result: Dictionary) -> void:
	if node is Control:
		result[str(node.get_instance_id())] = [node.get_global_rect(),node.custom_minimum_size,node.mouse_filter]
	for child in node.get_children():
		geometry(child,result)

func snap(name: String) -> Image:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.save_png(OUT + name + ".png")
	return shot

func native_textures(node: Node) -> Array:
	var saved: Array = []
	if node is TextureRect:
		var texture = node.texture
		if texture is AtlasTexture and texture.atlas.resource_path.begins_with(Art.ROOT):
			saved.append([node,texture])
			var original := AtlasTexture.new()
			original.atlas = load(texture.atlas.resource_path.replace(Art.ROOT,"res://assets/classic/"))
			original.region = Rect2(texture.region.position / 4,texture.region.size / 4)
			node.texture = original
		elif texture is Texture2D and texture.resource_path.begins_with(Art.ROOT):
			saved.append([node,texture])
			node.texture = load(texture.resource_path.replace(Art.ROOT,"res://assets/classic/"))
	for child in node.get_children():
		saved.append_array(native_textures(child))
	return saved

func compare(name: String) -> Dictionary:
	# Let fonts, wrapping and minimum-size notifications settle before measuring.
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var before := {}
	geometry(view.root,before)
	var hd := await snap(name + "-hd")
	var saved := native_textures(view.root)
	var original := await snap(name + "-native")
	var after := {}
	geometry(view.root,after)
	for item in saved:
		item[0].texture = item[1]
	return {"screen":name,"same_layout_hitboxes":before == after,"changed_textures":saved.size(),"images_differ":hd.get_data()!=original.get_data(),"size":[hd.get_width(),hd.get_height()]}

func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/lobby-art-hd/"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(view)
	view.scale = Vector2.ONE * 1.35
	view.position = Vector2(96,0)
	view.set_process(false)
	view.sound.muted = true
	var report: Array = [await compare("lobby")]
	view.profile.nickname = "WWWWWWWWWWWWWWWWWWWW"
	view.profile.xp = 1000000000
	view.profile.gold = 1000000000
	view.profile.cash = 1000000000
	view.show_lobby()
	for i in range(80):
		view.lobby.submit_chat("Mensagem%02d: [b]texto literal[/b]." % i)
	report.append(await compare("stress"))
	view.show_menu()
	report.append(await compare("room"))
	var file := FileAccess.open(OUT + "render.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("LOBBY ART RENDER ",report)
	view.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(0 if report.all(func(r): return r.same_layout_hitboxes) and report[0].changed_textures == 6 and report[0].images_differ and report[2].changed_textures == 0 and not report[2].images_differ else 1)
