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
