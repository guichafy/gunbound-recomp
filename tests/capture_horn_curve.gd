extends SceneTree
class Gallery extends Node2D:
	var art=load("res://scripts/avatar_art.gd").new()
	var original=load("res://scripts/avatar_art.gd").new()
	var dimmed=load("res://scripts/avatar_art.gd").new()
	var gear: Dictionary=art.catalog.defaults(0)
	var age:=0.0
	func _init() -> void:
		gear["0"]="xfs:0:0:71"
		var before: Dictionary=original.xfs_hd.layers["xfs:0:0:71|layer:1"]
		before.draw_behind=false
		before.erase("contour_glow")
		before.erase("light_curve")
		var faint: Dictionary=dimmed.xfs_hd.layers["xfs:0:0:71|layer:1"]
		faint.erase("light_curve")
		faint.draw_behind=true
		faint.contour_glow={"uv_region":[0,0,.42,.66],"radius":18,"sigma":5.0,"strength":.8}
	func basis(column: int,row: int) -> Transform2D:
		return Transform2D(0.0 if row==0 else deg_to_rad(-9),Vector2(-6 if row==0 else 2,6 if row==0 else 2),0,Vector2(column*640+320,365 if row==0 else 830))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("008abe"))
		for column in range(3):
			draw_string(ThemeDB.fallback_font,Vector2(column*640+25,40),["Brilho anterior: curva deslocada","0.18.3: efeito discreto rejeitado","Curva corrigida: brilho preservado"][column],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
			for row in range(2):
				[original,dimmed,art][column].draw(self,gear,basis(column,row),age,Color.WHITE)
			draw_string(ThemeDB.fallback_font,Vector2(column*640+170,930),"Escala da previa da loja",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var gallery:=Gallery.new()
	root.add_child(gallery)
	DirAccess.make_dir_recursive_absolute("res://docs/horn-curve")
	DirAccess.make_dir_recursive_absolute("res://.tools/horn-curve-frames")
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
		elif frame>66 and frame<96:assert(paused==image.get_data(),"Pause freezes the restored shine")
		assert(image.save_png("res://.tools/horn-curve-frames/%04d.png" % frame)==OK)
		if frame in [0,17,50,96,161]:assert(image.save_png("res://docs/horn-curve/%04d.png" % frame)==OK)
	var energies:=[]
	var strong_pixels:=[]
	for column in range(3):
		var energy:=0.0
		var changed:=0
		for y in range(710,840):
			for x in range(column*640+280,column*640+390):
				var delta:=peak.get_pixel(x,y)-trough.get_pixel(x,y)
				energy+=absf(delta.r)+absf(delta.g)+absf(delta.b)
				if maxf(absf(delta.r),maxf(absf(delta.g),absf(delta.b)))>.06:changed+=1
		energies.append(energy)
		strong_pixels.append(changed)
	var report:={"size":[1920,1080],"frames":162,"fps":60,"pause_frames":30,"shop_scale":2.0,"pulse_energy_original_dimmed_corrected":energies,"visible_animated_pixels_original_dimmed_corrected":strong_pixels}
	var output:=FileAccess.open("res://docs/horn-curve/validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print("HORN CURVE GPU: ",JSON.stringify(report))
	assert(strong_pixels[2]>=80,"Restored shine visibly animates at the actual shop scale, including the horn surface")
	assert(energies[2]>=energies[0]*.65,"Correcting curvature must preserve the previous visible animation")
	quit()
