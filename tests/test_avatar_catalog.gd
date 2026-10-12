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
	check(FileAccess.file_exists("res://scripts/avatar_catalog.gd"), "Avatar catalog exists")
	if failures == 0:
		var c = load("res://scripts/avatar_catalog.gd").new()
		check(c.entries.size() == 15, "Source has 15 avatars")
		check(c.items(0, 0).size() == 5 and c.items(1, 0).size() == 1, "Gender catalogs")
		check(c.items(1, 3).size() == 2, "Unisex flag")
		check(c.find("0:0:138").gold_price == 99999999, "Original Kappa price")
		check(c.defaults(0)["0"] != c.defaults(1)["0"], "Gender identity")
		for item in c.entries.values():
			check(ResourceLoader.exists(item.portrait), "Portrait " + item.key)
			if not item.atlas.is_empty():
				var texture = load(item.atlas)
				check(int(texture.get_width() / int(item.frame_size[0])) * ceili(float(texture.get_height()) / float(item.frame_size[1])) >= (11 if item.category == 1 else 22), "Frames " + item.key)
	print("AVATAR CATALOG CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
