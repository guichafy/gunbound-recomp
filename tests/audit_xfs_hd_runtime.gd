extends SceneTree
## Audit actual equipped samples. Missing jobs stay pending, never count as HD.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var art=load("res://scripts/avatar_art.gd").new()
	var catalog=load("res://scripts/avatar_catalog.gd").new()
	var native=JSON.parse_string(FileAccess.get_file_as_string("res://assets/xfs/avatars/catalog.json"))
	var report: Dictionary={"covered":[],"pending":[],"errors":[],"failures":0,"sheet_hashes":{},"renderer_hashes":{},"registrations":{}}
	for group in [art.xfs_hd.layers,art.xfs_hd.portraits]:
		for entry in group.values():
			report.registrations[entry.id]={"sheet":entry.sheet,"region":entry.region,"native_rect":entry.get("native_rect",[]),"effect":entry.get("effect",false),"pulsate":entry.get("pulsate",false),"reference_state":entry.get("reference_state",""),"attachment":entry.get("attachment",{})}
	for path in ["scripts/avatar_art.gd","scripts/avatar_xfs_hd.gd","scripts/mobile_rig.gd","scripts/mage_sprite.gd","scripts/bigfoot_sprite.gd"]:
		report.renderer_hashes[path]=FileAccess.get_sha256("res://"+path)
	for sheet in art.xfs_hd.sheets:
		report.sheet_hashes[sheet]=FileAccess.get_sha256(art.xfs_hd.sheets[sheet].file)
	for row in native.records:
		if row.layers.is_empty():
			continue
		var item: Dictionary=catalog.find(row.key)
		if not art.xfs_hd.complete(item):
			report.pending.append(row.key)
			continue
		var valid:=true
		for gender in ([0,1] if int(row.gender)==2 else [int(row.gender)]):
			var gear: Dictionary=catalog.defaults(gender)
			gear[str(int(row.category))]=row.key
			var first: Array=[]
			for time in [0.0,0.0166667,0.5,1.0,1.5,2.17]:
				for staring in [false,true]:
					var pieces: Array=art.sample(gear,time,staring).filter(func(piece): return int(piece.category)==int(row.category))
					if pieces.size()!=row.layers.size() or not pieces.all(func(piece): return piece.hd and piece.has("xfs_layer") and piece.target.has_area() and piece.source.has_area()):
						valid=false
					if first.is_empty():
						first=pieces
					elif pieces.size()==first.size():
						for i in range(pieces.size()):
							if pieces[i].target!=first[i].target or pieces[i].source!=first[i].source:
								valid=false
		if valid:
			report.covered.append(row.key)
		else:
			report.errors.append(row.key)
			report.failures+=1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/avatar-hd-migration/qa"))
	var output:=FileAccess.open("res://docs/avatar-hd-migration/qa/runtime-audit.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print("HD RUNTIME AUDIT: ",report.covered.size()," equipped records confirmed; ",report.pending.size()," pending; failures ",report.failures)
	quit(0 if report.failures==0 else 1)
