extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(FileAccess.file_exists("res://scripts/avatar_hd.gd"), "HD avatar renderer catalog exists")
	if failures == 0:
		var H = load("res://scripts/avatar_hd.gd")
		var hd = H.new()
		check(hd.pieces.size() == 13, "All visible source pieces remastered")
		for key in hd.pieces:
			var first: Dictionary = hd.piece(key,0)
			check(not first.is_empty() and first.source.has_area(), "Valid HD source "+key)
			check(first.source.size.x >= first.native.size.x*4 and first.source.size.y >= first.native.size.y*4, "At least4x native pixel density "+key)
			for frame in [0,10,11,21]:
				var region: Dictionary = hd.piece(key,frame)
				check(is_equal_approx(region.source.size.x/region.source.size.y,region.native.size.x/region.native.size.y), "HD piece preserves intrinsic aspect")
				check(region.native.size == first.native.size, "Stable size through original frame timing")
		var c = load("res://scripts/avatar_catalog.gd").new()
		var native = load("res://scripts/avatar_art.gd").new(false)
		var art = load("res://scripts/avatar_art.gd").new()
		var set_data: Dictionary = c.defaults(0)
		var pieces: Array = art.sample(set_data,0.0)
		check(pieces[0].hd and pieces[1].hd, "Default rider uses HD")
		check(pieces[0].frame == 11 and pieces[1].frame == 0, "Original frame clock retained")
		check(hd.piece("2:2:0",0).is_empty(), "No Goggles stays empty")
		art.hd = H.new("res://.tools/missing-avatar-hd.json")
		var fallback: Array = art.sample(set_data,0.0)
		var original: Array = native.sample(set_data,0.0)
		check(not fallback[0].hd and fallback[0].target == original[0].target, "Missing HD falls back at original pivot")
		check(hd.portrait("0:0:1") is AtlasTexture, "Shop portrait shares HD piece")
		var saved: Dictionary = hd.pieces["0:0:1"].duplicate(true)
		hd.pieces["0:0:1"].offsets[11] = ["invalid",0]
		check(hd.piece("0:0:1",11).is_empty(), "Invalid offset must fall back")
		hd.pieces["0:0:1"] = saved
		hd.pieces["0:0:1"].region = [-1,0,5,5]
		check(hd.piece("0:0:1",11).is_empty(), "Outside texture region must fall back")
	print("AVATAR HD CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures == 0 else 1)
