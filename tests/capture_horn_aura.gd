extends SceneTree
## Historical 0.18.3 fixture, rejected by the user. Current acceptance is capture_horn_curve.gd.
class Gallery extends Node2D:
	var art=load("res://scripts/avatar_art.gd").new()
	var previous=load("res://scripts/avatar_art.gd").new()
	var reference=load("res://scripts/avatar_art.gd").new()
	var gear: Dictionary=art.catalog.defaults(0)
	var age:=0.0
	func _init() -> void:
		gear["0"]="xfs:0:0:71"
		for renderer in [art,previous,reference]:renderer.xfs_hd.layers["xfs:0:0:71|layer:1"].erase("light_curve")
		art.xfs_hd.layers["xfs:0:0:71|layer:1"].draw_behind=true
		art.xfs_hd.layers["xfs:0:0:71|layer:1"].contour_glow={"uv_region":[0,0,.42,.66],"radius":18,"sigma":5.0,"strength":.8}
		previous.xfs_hd.layers["xfs:0:0:71|layer:1"].draw_behind=false
		previous.xfs_hd.layers["xfs:0:0:71|layer:1"].erase("contour_glow")
		reference.xfs_hd.layers["xfs:0:0:71|layer:1"].erase("contour_glow")
		reference.xfs_hd.layers["xfs:0:0:71|layer:1"].native_mean_opacity=0.0
	func basis(column: int,row: int) -> Transform2D:
		return Transform2D(0.0 if row==0 else deg_to_rad(-9),Vector2(-6 if row==0 else 6,6),0,Vector2(column*640+320,row*520+365))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("008abe"))
		for column in range(3):
			draw_string(ThemeDB.fallback_font,Vector2(column*640+25,40),["Antes: luz sobre o ouro","Referencia: ouro sem aura","Agora: aura atras do ouro"][column],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
			for row in range(2):
				[previous,reference,art][column].draw(self,gear,basis(column,row),age,Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var gallery:=Gallery.new()
	root.add_child(gallery)
	DirAccess.make_dir_recursive_absolute("res://docs/horn-aura")
	DirAccess.make_dir_recursive_absolute("res://.tools/horn-aura-frames")
	var head: Dictionary=gallery.art.xfs_hd.piece("xfs:0:0:71",0)
	var source: Image=head.texture.get_image()
	if source.is_compressed():source.decompress()
	var pixels: Array[Vector2i]=[]
	var tolerances: Array[float]=[]
	# Dense gold, eroded to exclude filtered edges. Source alpha is243–254.
	for row in range(2):
		var transform: Transform2D=gallery.basis(1,row)
		for y in range(80,470,2):
			for x in range(120,520,2):
				var screen:=Vector2(640+x,row*520+y)
				var uv: Vector2=(transform.affine_inverse()*screen-head.target.position)/head.target.size
				if uv.x<.02 or uv.x>.4 or uv.y<.02 or uv.y>.64:continue
				var sample:=Vector2i(head.source.position+uv*head.source.size)
				var gold:=source.get_pixelv(sample)
				if gold.g<.25 or gold.g<gold.b*1.2:continue
				var minimum_alpha:=1.0
				for offset in [Vector2i.ZERO,Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]:
					minimum_alpha=minf(minimum_alpha,source.get_pixelv(sample+offset).a)
				if minimum_alpha>=.94:
					pixels.append(Vector2i(screen))
					# Backlight can show only through the source alpha, plus
					# two byte levels for filtering/blending quantization.
					tolerances.append(1.0-minimum_alpha+2.0/255.0)
	assert(pixels.size()>100,"Gold mask covers meaningful anatomy")
	var max_delta:=0.0
	var violations:=0
	var previous_changes:=0
	var energies: Array[float]=[]
	var paused: PackedByteArray
	for frame in range(162):
		var clock:=65 if frame>=66 and frame<96 else (frame if frame<66 else frame-30)
		gallery.age=clock/60.0
		gallery.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		var image:=root.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		for point_index in range(pixels.size()):
			var point: Vector2i=pixels[point_index]
			var expected:=image.get_pixelv(point)
			var actual:=image.get_pixelv(point+Vector2i(640,0))
			var delta:=maxf(absf(expected.r-actual.r),maxf(absf(expected.g-actual.g),absf(expected.b-actual.b)))
			max_delta=maxf(max_delta,delta)
			if delta>tolerances[point_index]:violations+=1
			if frame==17 and expected!=image.get_pixelv(point-Vector2i(640,0)):previous_changes+=1
		if frame in [17,50]:
			var energy:=0.0
			for y in range(95,310):
				for x in range(140,480):
					var expected:=image.get_pixel(x+640,y)
					var actual:=image.get_pixel(x+1280,y)
					energy+=absf(expected.r-actual.r)+absf(expected.g-actual.g)+absf(expected.b-actual.b)
			energies.append(energy)
		if frame==66:paused=image.get_data()
		elif frame>66 and frame<96:assert(paused==image.get_data(),"Pause freezes aura and anatomy")
		assert(image.save_png("res://.tools/horn-aura-frames/%04d.png" % frame)==OK)
		if frame in [0,17,50,96,161]:assert(image.save_png("res://docs/horn-aura/%04d.png" % frame)==OK)
	var report:={"size":[1920,1080],"frames":162,"fps":60,"pause_frames":30,"gold_samples":pixels.size(),"max_gold_channel_delta":max_delta,"source_alpha_bound_violations":violations,"rejected_overlay_changed_samples":previous_changes,"halo_peak_energy":energies[0],"halo_trough_energy":energies[1]}
	var output:=FileAccess.open("res://docs/horn-aura/validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	assert(violations==0,"Backlight can only show through the source alpha; must never overpaint gold")
	assert(previous_changes>100,"Comparison reproduces rejected white overlay")
	assert(energies[0]>energies[1]*1.3 and energies[1]>0,"Aura visibly pulsates and remains visible at trough")
	print("HORN AURA GPU: ",JSON.stringify(report))
	quit()
