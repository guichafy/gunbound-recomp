extends "res://tests/support/suite.gd"
## Active renderer regression: restoring a HD sprite in Game must fail this.
const Classic = preload("res://scripts/classic_sprite.gd")
func run() -> void:
	var sprites: Dictionary = load("res://scripts/game.gd").build_sprites()
	for id in [1,2]:
		var sprite = sprites[id]
		check(sprite is Classic, "Active Mage/Bigfoot uses the native atlas renderer")
		if not sprite is Classic:
			continue
		check(sprite.original_art, "Original mobile bypasses the generated rig")
		check(sprite.texture.resource_path.contains("/original/"), "Active texture is extracted from original client")
		check(sprite.hull_width == 60.0, "One native pixel per world pixel matches classic roster")
		check(sprite.meta.tank == (2 if id == 1 else 5), "Stable ID resolves the correct native tank")
		check(sprite.frame_index("moving",0,0,false) == 20, "Native move begins at original frame")
		check(sprite.frame_index("recoil",0.05,1,false) == (101 if id == 1 else 126), "EPA durations control native recoil")
		var atlas_before: Dictionary = sprite.meta.duplicate(true)
		for weapon in 3:
			var sheet: String = sprite.projectile_sheet({},weapon)
			check(not sprite.sheet(sheet).is_empty() or (id == 1 and weapon < 2), "All original projectiles have a sprite or original laser composition")
		check(sprite.meta == atlas_before, "Presentation does not change imported metadata")
	var mage = sprites[1]
	if mage is Classic:
		check(mage.effect_sheets({"weapon":2}) == ["SSFlame.png"], "Mage SS uses its native secondary impact, absent flame23 stays absent")
		check(mage.sheet("SSFlame.png").entry == "ssflame2.img", "Mage EMP is original")
	var bigfoot = sprites[2]
	if bigfoot is Classic:
		check(bigfoot.sheet("Flame2.png").entry == "flame52.img", "Bigfoot T2 uses its own original impact")
	for id in range(3,17):
		check(sprites.has(id), "Other mobiles remain available: %d" % id)
	finish("ORIGINAL MOBILES CHECKS")
