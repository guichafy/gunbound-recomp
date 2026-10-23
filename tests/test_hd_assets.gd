extends "res://tests/support/suite.gd"
func run() -> void:
	check(ResourceLoader.exists("res://scripts/hd_sheet.gd"), "HD atlas renderer exists")
	if not ResourceLoader.exists("res://scripts/hd_sheet.gd"):
		report("HD CHECKS")
		quit(1)
		return
	var Sheet = load("res://scripts/hd_sheet.gd")
	for entry in [["bigfoot", 4, 8], ["mage", 4, 8], ["rider", 4, 2], ["shots", 4, 6], ["effects", 6, 6], ["heroes", 2, 1], ["emp", 1, 1], ["mobile_parts", 3, 2], ["pilot_seated", 1, 1], ["projectile_heads", 3, 2], ["pilot_side", 1, 1]]:
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
	check(sprite.hd_rig.available(), "Bigfoot uses stable articulated HD source in menu and arena")
	check(sprite.hd_rig.sheet.region(0, 0).size.x > 400, "Bigfoot chassis keeps high detail pixels")
	check(sprite.hd_rig.sheet.region(0, 2).size.x > 300, "Wheel has high detail pixels")
	var mage = load("res://scripts/mage_sprite.gd").new()
	check(mage.get("hd_emp") != null, "MageEMP uses a larger dedicated source")
	if mage.get("hd_emp") != null:
		check(mage.hd_emp.region(0, 0).size.x > 520, "MageEMP has enough real pixels for Full HD display")
	check(mage.hd_rig.available(), "Mage uses stable articulated HD source")
	check(mage.hd_rig.sample("charging", 0.5, 2).glow > 0.0, "Mage SS glow remains separate from body")
	check(mage.hd_rig.sample("destroyed", 1.6, 2).alpha == 0.0, "Mage death completes without sprite replacement")
	# Different source padding must not change the original ground/anchor footprint.
	var source := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	source.fill_rect(Rect2i(3, 4, 4, 5), Color.WHITE)
	var texture := ImageTexture.create_from_image(source)
	var sheet = Sheet.new("res://assets/hd/bigfoot.png", 4, 8)
	var rect: Rect2 = sheet.destination(texture, Rect2(0, 0, 10, 10), Rect2(-50, -70, 100, 100))
	check(rect == Rect2(-20, -30, 40, 50), "HD draw preserves original opaque footprint and contact")
	finish("HD CHECKS")
