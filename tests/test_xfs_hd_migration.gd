extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var art=load("res://scripts/avatar_art.gd").new()
	var catalog=load("res://scripts/avatar_catalog.gd").new()
	check(not art.xfs_hd.layers.is_empty(),"Equipped XFS masters have their own registered catalog")
	var native_art=load("res://scripts/avatar_art.gd").new(false)
	for candidate in catalog.entries.values():
		if candidate.get("source")!="xfs" or int(candidate.category)!=0 or candidate.get("layers",[]).size()!=2:
			continue
		for staring in [false,true]:
			for age in [0.0,0.5,1.1,1.8,2.17]:
				var native_pieces: Array=native_art.sample_xfs(candidate,age,staring)
				check(native_pieces.all(func(p): return p.frame<11 if staring else p.frame>=11),"Head and light use the same native anatomy state: "+candidate.key)
	var material:=Image.create(2,1,false,Image.FORMAT_RGBA8)
	material.set_pixel(0,0,Color.BLACK)
	material.set_pixel(1,0,Color.RED)
	var original_material:=ImageTexture.create_from_image(material)
	var light: Dictionary=art.xfs_hd.light_layer(original_material,Rect2(0,0,2,1),"test:light-transparency")
	var converted: Image=light.paint.diffuse_texture.get_image()
	check(converted.get_pixel(0,0).a==0 and converted.get_pixel(1,0).a>0.99,"Dark light-layer centers reveal the face while emitted color stays visible")
	check(original_material.get_image().get_pixel(0,0).a>0.99,"Light conversion preserves the source image and opaque black accessories")
	for key in art.xfs_hd.layers:
		var entry: Dictionary=art.xfs_hd.layers[key]
		var data: Dictionary=art.xfs_hd.piece(entry.key,int(entry.layer))
		check(not data.is_empty() and data.target.has_area() and data.source.has_area(),"Registered wearable/effect loads at real resolution: "+key)
	var real_items:=0
	var real_layers:=0
	for candidate in catalog.entries.values():
		if candidate.get("source")!="xfs" or candidate.get("layers",[]).is_empty():
			continue
		real_items+=1
		real_layers+=candidate.layers.size()
		check(art.xfs_hd.complete(candidate),"Every real XFS item has all equipped HD layers: "+candidate.key)
		var gender: int=0 if int(candidate.gender)==2 else int(candidate.gender)
		var gear: Dictionary=catalog.defaults(gender)
		gear[str(int(candidate.category))]=candidate.key
		var equipped: Array=art.sample(gear,0.5).filter(func(piece): return int(piece.category)==int(candidate.category))
		check(equipped.size()==candidate.layers.size() and equipped.all(func(piece): return piece.hd and piece.has("xfs_layer")),"Actual equipped renderer has no hidden native/legacy fallback: "+candidate.key)
	check(real_items==550 and real_layers==629,"Coverage retains all 550 real avatars and 629 layers")
	check(art.xfs_hd.portraits.size()==532,"All 532 remaining portraits are registered separately from the 18 previous ones")
	var devil: Dictionary=art.xfs_hd.layers["xfs:0:0:71|layer:1"]
	var devil_light: Dictionary=art.xfs_hd.piece("xfs:0:0:71",1)
	var devil_head: Dictionary=art.xfs_hd.piece("xfs:0:0:71",0)
	check(devil.source_frame>=11 and devil.reference_state=="normal","Great Devil light is sourced from the one-horn profile state")
	check(devil_light.source.size.x/devil_light.source.size.y<1.1,"Great Devil master has one profile crescent, not the two-horn frontal pair")
	check(devil_light.target.end.x<devil_head.target.position.x+devil_head.target.size.x*.55,"Horn light stays in the horn half of the head instead of crossing the hair")
	var attachments:=0
	for candidate in catalog.entries.values():
		if candidate.get("source")!="xfs" or int(candidate.category)!=0 or candidate.get("layers",[]).size()!=2:
			continue
		var entry: Dictionary=art.xfs_hd.layers[candidate.key+"|layer:1"]
		check(entry.get("reference_state")=="normal" and int(entry.source_frame)>=11,"All head effects share the Normal anatomy reference: "+candidate.key)
		check(entry.has("attachment") and not art.xfs_hd.piece(candidate.key,1).is_empty(),"All twenty effects have a measured HD feature attachment: "+candidate.key)
		attachments+=1
	check(attachments==20,"Alignment review covers all twenty animated heads")
	var saved_attachment: Dictionary=devil.attachment.duplicate(true)
	devil.attachment.base_uv=[NAN,.3]
	check(not art.xfs_hd.complete(catalog.find("xfs:0:0:71")),"Invalid anatomical attachment triggers complete native fallback")
	devil.attachment=saved_attachment
	var item: Dictionary=catalog.find("xfs:0:0:4")
	check(art.xfs_hd.complete(item),"Wing Helmet's base and effect both have HD masters")
	var equipment: Dictionary=catalog.defaults(0)
	equipment["0"]=item.key
	var first: Array=art.sample(equipment,0.0).filter(func(piece): return piece.category==0)
	var later: Array=art.sample(equipment,2.17).filter(func(piece): return piece.category==0)
	check(first.size()==2 and first.all(func(piece): return piece.hd and piece.has("xfs_layer")),"Actual equipped renderer consumes both HD layers, not the shop thumbnail")
	check(first.size()==later.size(),"HD animation retains its layer count")
	for i in range(first.size()):
		check(first[i].target==later[i].target and first[i].source==later[i].source,"Master registration and anatomy remain stable across animation clock")
	check(art.xfs_hd.layers[item.key+"|layer:0"].source_name=="mh00004.img","Equipped source is the wearable sprite, not smh catalog artwork")
	var original: Dictionary=art.xfs_hd.layers[item.key+"|layer:1"]
	art.xfs_hd.layers.erase(item.key+"|layer:1")
	check(not art.xfs_hd.complete(item),"Missing effect invalidates the complete equipped item")
	var fallback: Array=art.sample(equipment,0.5).filter(func(piece): return piece.category==0)
	check(fallback.size()==2 and fallback.all(func(piece): return not piece.hd),"Incomplete equipped HD falls back coherently to all native layers")
	art.xfs_hd.layers[item.key+"|layer:1"]=original
	var bad: Dictionary=art.xfs_hd.layers[item.key+"|layer:0"].duplicate(true)
	var saved: Dictionary=art.xfs_hd.layers[item.key+"|layer:0"]
	bad.region=[999999,0,1,1]
	art.xfs_hd.layers[item.key+"|layer:0"]=bad
	check(art.xfs_hd.piece(item.key,0).is_empty(),"Invalid source window is rejected before drawing")
	art.xfs_hd.layers[item.key+"|layer:0"]=saved
	var empty=load("res://scripts/avatar_xfs_hd.gd").new("res://.tools/missing-xfs-hd.json")
	check(not empty.complete(item) and empty.portrait(item.key)==null,"Missing migration metadata preserves original fallback")
	print("XFS HD MIGRATION CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
