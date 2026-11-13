extends SceneTree
const Maps = preload("res://scripts/maps.gd")
const OUT := "res://docs/classic-maps/"
var scene
var viewport: SubViewport
var failures := 0
var records: Array = []
func _initialize() -> void:
	call_deferred("run")
func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	return viewport.get_texture().get_image()
func digest(pixels: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(pixels.get_data())
	return hash.finish().hex_encode()
func run() -> void:
	viewport = SubViewport.new()
	viewport.size=Vector2i(1920,1080)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/maps-implementation/capture-profile.json")
	var game_view := SubViewport.new()
	game_view.size=Vector2i(1728,1080)
	game_view.size_2d_override=Vector2i(1280,800)
	game_view.size_2d_override_stretch=true
	game_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.add_child(game_view)
	var presentation := TextureRect.new()
	presentation.texture=game_view.get_texture()
	presentation.position=Vector2(96,0)
	presentation.size=Vector2(1728,1080)
	viewport.add_child(presentation)
	game_view.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening=0
	scene.match_seed=4500
	for id in Maps.available_ids():
		scene.show_menu()
		scene.select_map(id)
		var room: Image = await picture()
		room.save_png(OUT+id+"-room.png")
		scene.begin_loading()
		var loading: Image = await picture()
		loading.save_png(OUT+id+"-loading.png")
		scene.start_match(scene.loading_player,scene.loading_cpu,scene.loading_spawns)
		var arena: Image = await picture()
		arena.save_png(OUT+id+"-arena.png")
		scene.model.fire(45,30,0)
		for frame in 600:
			scene._process(1.0/60.0)
			await picture()
			if frame>100 and scene.model.phase!="flight":break
		scene.paused=true
		var paused: Image = await picture()
		var expected := digest(paused)
		var hashes: Array = []
		for frame in 30:
			scene._process(1.0/60.0)
			var pixels: Image = await picture()
			var value := digest(pixels)
			hashes.append(value)
			if value!=expected:failures+=1
		paused.save_png(OUT+id+"-shot-paused.png")
		var before_time: float = scene.elapsed
		scene.paused=false
		for frame in 30:
			scene._process(1.0/60.0)
			await picture()
		var resumed: Image = await picture()
		if digest(resumed)==expected or scene.elapsed<=before_time:failures+=1
		var row := {"id":id,"room":digest(room),"loading":digest(loading),"arena":digest(arena),"pause_hashes":hashes,"resume":digest(resumed),"size":[arena.get_width(),arena.get_height()]}
		records.append(row)
		print("CAPTURE MAP ",id," pause30=",hashes.all(func(value):return value==expected))
	var file:=FileAccess.open(OUT+"gpu-proof.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"records":records,"failures":failures},"\t")+"\n")
	scene.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
