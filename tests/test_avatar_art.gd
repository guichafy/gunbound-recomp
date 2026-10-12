extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(FileAccess.file_exists("res://scripts/avatar_art.gd"), "Composed avatar renderer exists")
	if failures == 0:
		var c = load("res://scripts/avatar_catalog.gd").new()
		var art = load("res://scripts/avatar_art.gd").new(false)
		var pieces: Array = art.sample(c.defaults(0),0.0)
		check(pieces.size() == 2 and pieces[0].category == 0 and pieces[1].category == 1, "Source depth")
		check(pieces[0].frame == 11, "Head starts normal11")
		check(art.sample(c.defaults(0),1.0)[0].frame == 21, "10 FPS")
		check(art.sample(c.defaults(0),1.1)[0].frame == 11, "Cycle11")
		var gear: Dictionary = c.defaults(0)
		gear["0"] = "0:0:1"
		gear["2"] = "0:2:1"
		gear["3"] = "2:3:1"
		pieces = art.sample(gear,0.0)
		check(pieces.size() == 4 and pieces[0].category == 3 and pieces[3].category == 1, "Flag/head/goggles/body")
		check(pieces[1].source.position == Vector2(0,28), "Multi-row normal head")
		check(art.sample(c.defaults(1),0.0)[0].source.size.y == 27, "Female mismatched source clamped")
		check(art.sample({"0":"invalid"},0.0).is_empty(), "Missing set cannot partially draw")
	print("AVATAR ART CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
