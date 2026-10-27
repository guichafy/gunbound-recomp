extends SceneTree
## 0.18.7: horn light derived from the HD horn and the classic L profile,
## side by side with the classic sprite and the rejected 0.18.4 bent crescent.
class Gallery extends Node2D:
	var classic=load("res://scripts/avatar_art.gd").new(false)
	var curved=load("res://scripts/avatar_art.gd").new(true)
	var art=load("res://scripts/avatar_art.gd").new(true)
	var gear: Dictionary=art.catalog.defaults(0)
	var age:=0.0
	func _init() -> void:
		gear["0"]="xfs:0:0:71"
		# 0.18.4 registration, kept only as visual evidence of the rejected state.
		var before: Dictionary=curved.xfs_hd.layers["xfs:0:0:71|layer:1"]
		curved.xfs_hd.sheets["batch_005_repair_008"]={"file":"res://assets/hd/avatars/xfs/batch_005_repair_008.png","size":[1295,1214]}
		before.erase("overlay_base")
		before.sheet="batch_005_repair_008"
		before.region=[90,17,1094,1173]
		before.generated_mean_opacity=0.7067312712627392
		before.attachment={"feature":"single profile horn","base_uv":[.17,.32],"effect_uv":[.5,.5],"scale":1}
		before.light_curve=[[0,.49,.2,-.035,.75],[.05,.445,.17,.02,.75],[.15,.295,.11,.1,.65],[.3,.204,.087,.23,.65],[.45,.22,.14,.34,.72],[.6,.39,.22,.46,.5],[.73,.57,.26,.53,.35],[.87,.65,.27,.58,.26],[1,.7,.28,.64,.26]]
	func basis(column: int,row: int) -> Transform2D:
		return Transform2D(0.0 if row==0 else deg_to_rad(-9),Vector2(-6 if row==0 else 2,6 if row==0 else 2),0,Vector2(column*640+320,365 if row==0 else 830))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("008abe"))
		for column in range(3):
			draw_string(ThemeDB.fallback_font,Vector2(column*640+25,40),["Clássico (baixa resolução)","0.18.4: meia-lua curvada","0.18.7: chifre HD + perfil clássico"][column],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
			for row in range(2):
				[classic,curved,art][column].draw(self,gear,basis(column,row),age,Color.WHITE)
			draw_string(ThemeDB.fallback_font,Vector2(column*640+170,930),"Escala da prévia da loja",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var gallery:=Gallery.new()
	root.add_child(gallery)
	assert(gallery.curved.xfs_hd.piece("xfs:0:0:71",1).has("mesh"),"0.18.4 reference really renders the bent crescent")
	assert(not gallery.art.xfs_hd.piece("xfs:0:0:71",1).has("mesh"),"Current renderer uses the derived horn light")
	DirAccess.make_dir_recursive_absolute("res://docs/horn-classic")
	DirAccess.make_dir_recursive_absolute("res://.tools/horn-classic-frames")
	var peak: Image
	var trough: Image
	var paused: PackedByteArray
	for frame in range(162):
		var clock:=65 if frame>=66 and frame<96 else (frame if frame<66 else frame-30)
		gallery.age=clock/60.0
		gallery.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		var image:=root.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		if frame==17:peak=image
		if frame==50:trough=image
		if frame==66:paused=image.get_data()
		elif frame>66 and frame<96:assert(paused==image.get_data(),"Pause freezes the horn light")
		assert(image.save_png("res://.tools/horn-classic-frames/%04d.png" % frame)==OK)
		if frame in [0,17,50,96,161]:assert(image.save_png("res://docs/horn-classic/%04d.png" % frame)==OK)
	var energies:=[]
	var strong_pixels:=[]
	for column in [1,2]:
		var energy:=0.0
		var changed:=0
		for y in range(710,840):
			for x in range(column*640+280,column*640+390):
				var delta:=peak.get_pixel(x,y)-trough.get_pixel(x,y)
				energy+=absf(delta.r)+absf(delta.g)+absf(delta.b)
				if maxf(absf(delta.r),maxf(absf(delta.g),absf(delta.b)))>.06:changed+=1
		energies.append(energy)
		strong_pixels.append(changed)
	var report:={"size":[1920,1080],"frames":162,"fps":60,"pause_frames":30,"shop_scale":2.0,"pulse_energy_curved_new":energies,"visible_animated_pixels_curved_new":strong_pixels}
	var output:=FileAccess.open("res://docs/horn-classic/validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print("HORN CLASSIC GPU: ",JSON.stringify(report))
	assert(strong_pixels[1]>=80,"Horn light visibly animates at the actual shop scale")
	assert(energies[1]>=energies[0]*.65,"Shape fix keeps the previous visible animation")
	quit()
