extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(ResourceLoader.exists("res://scripts/hd_sheet.gd"), "HD atlas renderer exists")
	if not ResourceLoader.exists("res://scripts/hd_sheet.gd"):
		print("HD CHECKS: ", checks, " | FAILURES: ", failures)
		quit(1)
		return
	var Sheet = load("res://scripts/hd_sheet.gd")
	for entry in [["bigfoot", 4, 8], ["mage", 4, 8], ["rider", 4, 2], ["shots", 4, 6], ["effects", 6, 6], ["heroes", 2, 1], ["emp", 1, 1]]:
		var sheet = Sheet.new("res://assets/hd/" + entry[0] + ".png", entry[1], entry[2])
		check(sheet.available(), "HD sheet loads: " + entry[0])
		if not sheet.available():
			continue
		var size: Vector2 = sheet.texture.get_size()
		var source: Image = sheet.texture.get_image()
		check(source.detect_alpha() != Image.ALPHA_NONE, "Sheet retains real alpha: " + entry[0])
		for row in range(entry[2]):
			for column in range(entry[1]):
				var region: Rect2 = sheet.region(row, column)
				check(Rect2(Vector2.ZERO, size).encloses(region), "HD frame inside texture: %s %d/%d" % [entry[0], row, column])
		check(sheet.region(-1, 0).size == Vector2.ZERO and sheet.region(0, 99).size == Vector2.ZERO, "Invalid cells do not sample another sprite: " + entry[0])
	var missing = Sheet.new("res://assets/hd/absent.png", 4, 8)
	check(not missing.available(), "Missing derived texture allows original fallback")
	var sprite = load("res://scripts/bigfoot_sprite.gd").new()
	check(sprite.get("hd_heroes") != null, "Large menu uses a separate high detail source")
	check(sprite.hd_sheet.region(0, 0).size.y < 150, "Nearly invisible generated noise does not squash Bigfoot body")
	check(sprite.hd_sheet.region(0, 0).size.x > 100, "Remastered arena body has more actual pixels than original49px")
	for frame in [0, 19, 20, 44, 45, 64, 65, 104, 125, 146, 202, 211, 212, 233, 254, 273, 274, 293, 394, 418]:
		var key: Vector2i = sprite.hd_frame(frame)
		check(key.x >= 0 and key.x < 4 and key.y >= 0 and key.y < 8, "Every Bigfoot state maps to HD: " + str(frame))
	check(sprite.hd_frame(211) == Vector2i(3, 7), "Death reaches last keyframe without looping")
	check(sprite.hd_frame(254) == Vector2i(0, 3), "Bigfoot second shot retains own row")
	var mage = load("res://scripts/mage_sprite.gd").new()
	check(mage.get("hd_emp") != null, "MageEMP uses a larger dedicated source")
	if mage.get("hd_emp") != null:
		check(mage.hd_emp.region(0, 0).size.x > 520, "MageEMP has enough real pixels for Full HD display")
	check(mage.hd_frame(391) == Vector2i(0, 4), "Mage SS has its own blue aura")
	check(mage.hd_frame(203) == Vector2i(3, 7), "Mage death reaches final rubble")
	# Different source padding must not change the original ground/anchor footprint.
	var source := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	source.fill_rect(Rect2i(3, 4, 4, 5), Color.WHITE)
	var texture := ImageTexture.create_from_image(source)
	var sheet = Sheet.new("res://assets/hd/bigfoot.png", 4, 8)
	var rect: Rect2 = sheet.destination(texture, Rect2(0, 0, 10, 10), Rect2(-50, -70, 100, 100))
	check(rect == Rect2(-20, -30, 40, 50), "HD draw preserves original opaque footprint and contact")
	print("HD CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
