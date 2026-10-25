extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	var args:=OS.get_cmdline_user_args()
	var destination: String=args[0] if not args.is_empty() else "res://docs/avatar-effects"
	DirAccess.make_dir_recursive_absolute(destination)
	var path:="/private/tmp/avatar-effect-shop-profile.json"
	DirAccess.remove_absolute(path)
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(path)
	scene.profile.gold=1000000000
	scene.profile.cash=1000000000
	assert(scene.profile.purchase("xfs:0:0:71","gold")=="ok")
	assert(scene.profile.equip("xfs:0:0:71"))
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.show_shop()
	await process_frame
	var shop=scene.shop
	var horn: Dictionary=shop.avatar_art.xfs_hd.piece("xfs:0:0:71",1)
	assert(not horn.is_empty() and horn.source.size==shop.avatar_art.xfs_hd.piece("xfs:0:0:71",0).source.size+Vector2(40,40))
	assert(not horn.has("mesh") and horn.effect and not horn.draw_behind)
	shop.set_process(false)
	shop.search.text="Great Devil"
	shop.model.query=shop.search.text
	shop.refresh(0,0)
	var renderers: Array=[shop.avatar_art,scene.sprite_for(scene.vehicle).hd_rig.avatars]
	var energies: Dictionary={}
	var corner: Vector2=shop.painter.get_global_transform()*Vector2(568,34)
	var end: Vector2=shop.painter.get_global_transform()*Vector2(654,106)
	var preview:=Rect2i(corner,end-corner)
	for mobile in [false,true]:
		shop.set_preview_mode(mobile)
		var mode:="mobile" if mobile else "avatar"
		var energy:=[]
		for phase in [17.0/60,50.0/60]:
			shop.elapsed=phase
			shop.painter.queue_redraw()
			await process_frame
			RenderingServer.force_draw()
			var image:=root.get_texture().get_image()
			assert(image.get_size()==Vector2i(1920,1080))
			var label:="peak" if energy.is_empty() else "trough"
			assert(image.save_png(destination+"/shop-%s-%s.png" % [mode,label])==OK)
			if energy.is_empty():assert(image.save_png(destination+"/shop-%s.png" % mode)==OK)
			var opacity:=[]
			for renderer in renderers:
				var entry: Dictionary=renderer.xfs_hd.layers["xfs:0:0:71|layer:1"]
				opacity.append(entry.overlay_base.get("opacity",1.0))
				entry.overlay_base.opacity=0.0
			shop.painter.queue_redraw()
			await process_frame
			RenderingServer.force_draw()
			var reference:=root.get_texture().get_image()
			var amount:=0.0
			for y in range(preview.position.y,preview.end.y):
				for x in range(preview.position.x,preview.end.x):
					var delta:=image.get_pixel(x,y)-reference.get_pixel(x,y)
					amount+=absf(delta.r)+absf(delta.g)+absf(delta.b)
			energy.append(amount)
			for i in range(renderers.size()):renderers[i].xfs_hd.layers["xfs:0:0:71|layer:1"].overlay_base.opacity=opacity[i]
		assert(energy[0]>150 and energy[0]>energy[1]*1.3,"Shine remains visible and animated in the actual "+mode+" shop preview")
		energies[mode]=energy
	var report:=FileAccess.open(destination+"/shop-pulse.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(energies,"\t"))
	report.close()
	DirAccess.remove_absolute(path)
	print("GREAT DEVIL SHOP GPU: actual equipped preview in1920x1080; pulse peak/trough: ",JSON.stringify(energies))
	quit()
