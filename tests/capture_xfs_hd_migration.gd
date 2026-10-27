extends SceneTree
const SpritePose = preload("res://scripts/sprite_pose.gd")
class Gallery extends Node2D:
	var entries: Array=[]
	var native_textures: Dictionary={}
	var art=load("res://scripts/avatar_art.gd").new(true)
	var catalog=load("res://scripts/avatar_catalog.gd").new()
	var sprites=[load("res://scripts/mage_sprite.gd").new(),load("res://scripts/bigfoot_sprite.gd").new()]
	var age := 0.0
	var sample_mode := 0
	func fit_texture(texture: Texture2D, source: Rect2, box: Rect2) -> void:
		var fitted:=source.size*minf(box.size.x/source.size.x,box.size.y/source.size.y)
		draw_texture_rect_region(texture,Rect2(box.get_center()-fitted*0.5,fitted),source)
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("182b40"))
		var font:=ThemeDB.fallback_font
		for number in range(entries.size()):
			var entry: Dictionary=entries[number]
			var origin:=Vector2(number%4,int(number/4))*Vector2(480,135)
			draw_rect(Rect2(origin,Vector2(479,134)),Color("223a4d"))
			draw_string(font,origin+Vector2(5,13),entry.id,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
			if not native_textures.has(entry.original):
				native_textures[entry.original]=load(entry.original)
			var native: Texture2D=native_textures[entry.original]
			var original_rect:=Rect2(Vector2.ZERO,native.get_size())
			if entry.role!="portrait":
				original_rect=Rect2(entry.source_region[0],entry.source_region[1],entry.source_region[2],entry.source_region[3])
			fit_texture(native,original_rect,Rect2(origin+Vector2(5,23),Vector2(75,100)))
			var data: Dictionary=art.xfs_hd.registered(entry) if entry.role=="portrait" else art.xfs_hd.piece(entry.key,int(entry.layer))
			if not data.is_empty():
				fit_texture(data.paint,data.source,Rect2(origin+Vector2(90,23),Vector2(85,100)))
			var item: Dictionary=catalog.find(entry.key)
			var gender: int=0 if int(item.gender)==2 else int(item.gender)
			var gear: Dictionary=catalog.defaults(gender)
			gear[str(int(item.category))]=item.key
			var pieces: Array=art.sample(gear,age)
			var bounds:=Rect2()
			for piece in pieces:
				bounds=piece.target if not bounds.has_area() else bounds.merge(piece.target)
			var scale:=minf(90.0/bounds.size.x,100.0/bounds.size.y)
			var center:=origin+Vector2(245,73)
			var transform:=Transform2D(0,Vector2(-scale,scale),0,center-Vector2(-bounds.get_center().x,bounds.get_center().y)*scale)
			art.draw(self,gear,transform,age,Color.WHITE)
			var sprite=sprites[sample_mode%2]
			var facing:=1 if sample_mode<2 else -1
			sprite.draw(self,SpritePose.new(origin+Vector2(379,75),82,facing,{"rotation":deg_to_rad(10*facing),"age":age,"avatar_context":{"equipment":gear,"age":age}}))
			draw_string(font,origin+Vector2(5,130),"Fonte   |   HD   |   Vestido   |   Mobile",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("a7d1e3"))
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	var batch: String=args[0] if not args.is_empty() else "batch_001"
	var meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hd/avatars/xfs/catalog.json"))
	var jobs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hd/avatars/xfs/source/jobs.json"))
	var gallery:=Gallery.new()
	for job in jobs.jobs:
		if job.id!=batch:
			continue
		for variant in job.variants:
			var entry=meta.portraits.get(variant.key) if variant.role=="portrait" else meta.layers.get(variant.id)
			assert(entry is Dictionary,"Unregistered component: "+variant.id)
			gallery.entries.append(entry)
	gallery.entries.sort_custom(func(a,b): return int(a.cell[1])*4+int(a.cell[0])<int(b.cell[1])*4+int(b.cell[0]))
	assert(not gallery.entries.is_empty(),"No registered batch: "+batch)
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.add_child(gallery)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/avatar-hd-migration/qa"))
	for frame in [0,30,60,90]:
		gallery.age=frame/60.0
		gallery.sample_mode=frame/30
		gallery.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		assert(root.get_texture().get_image().save_png("res://docs/avatar-hd-migration/qa/%s-%03d.png" % [batch,frame])==OK)
	var components:=[]
	for entry in gallery.entries:
		components.append({"id":entry.id,"sheet_hash":meta.sheets[entry.sheet].sha256,"registration":{"sheet":entry.sheet,"region":entry.region,"native_rect":entry.get("native_rect",[]),"effect":entry.get("effect",false),"pulsate":entry.get("pulsate",false),"reference_state":entry.get("reference_state",""),"attachment":entry.get("attachment",{}),"draw_behind":entry.get("draw_behind",false),"contour_glow":entry.get("contour_glow",{}),"light_curve":entry.get("light_curve",[]),"overlay_base":entry.get("overlay_base",{})}})
	var report:=FileAccess.open("res://docs/avatar-hd-migration/qa/"+batch+".json",FileAccess.WRITE)
	var hashes: Dictionary={}
	for path in ["scripts/avatar_art.gd","scripts/avatar_xfs_hd.gd","scripts/avatar_contour_glow.gd","scripts/mobile_rig.gd","scripts/mage_sprite.gd","scripts/bigfoot_sprite.gd"]:
		hashes[path]=FileAccess.get_sha256("res://"+path)
	report.store_string(JSON.stringify({"batch":batch,"size":[1920,1080],"frames":[0,30,60,90],"mobiles":["Mage direita","Bigfoot direita","Mage esquerda","Bigfoot esquerda"],"components":components,"renderer_hashes":hashes},"\t"))
	report.close()
	var count: int=gallery.entries.size()
	gallery.queue_free()
	await process_frame
	print("HD MIGRATION GPU: ",batch," / ",count," components / original, HD, equipped, Mage+Bigfoot / 1920x1080")
	quit()
