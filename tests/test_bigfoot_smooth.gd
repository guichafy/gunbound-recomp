extends "res://tests/support/suite.gd"
## ADR-115: Bigfoot draws its native sheets at4× density. Only source
## rectangles change; geometry, pivots and the other mobiles stay native.
const Classic = preload("res://scripts/classic_sprite.gd")
const SmoothArt = preload("res://scripts/mobile_smooth_art.gd")
const HD := "res://assets/hd/classic/mobiles_smooth_4x/bigfoot"
const NATIVE := "res://assets/openbound/bigfoot/original"
const SHEETS := ["Bullet1.png", "Bullet1Light.png", "Bullet2.png", "Bullet3.png", "Bullet3Light.png", "Flame1.png", "Flame2.png", "Flame3.png"]

func run() -> void:
	var sprites: Dictionary = load("res://scripts/game.gd").build_sprites()
	var bigfoot = sprites[2]
	var meta: Dictionary = bigfoot.meta
	check(bigfoot.texture.resource_path == HD + "/CharacterSpritesheet.png", "Bigfoot body uses the4x derivative")
	check(bigfoot.texture.get_size() == Vector2(1720, 1560) * 4 and bigfoot.density == 4.0, "Body atlas has true4x pixels")
	check(bigfoot.cell == Vector2(meta.cell[0], meta.cell[1]) and bigfoot.pivot == Vector2(meta.origin[0], meta.origin[1]), "Cell and pivot stay native")
	check(bigfoot.contact_y == float(meta.origin[1]) + float(meta.contact_feet) and bigfoot.hull_width == 60.0, "Contact and battle hull stay native")
	for index in [0, 25, 211, 257, 276, 441]:
		var native := Rect2(Vector2(index % 20, int(index / 20)) * bigfoot.cell, bigfoot.cell)
		check(bigfoot.frame_rect(index) == Rect2(native.position * 4, native.size * 4), "Body frame %d samples the same cell at4x" % index)
	for name in SHEETS:
		var info: Dictionary = meta.sheets[name]
		var cell := Vector2(info.cell[0], info.cell[1])
		var texture: Texture2D = bigfoot._optional_cached(name).diffuse_texture
		var native: Texture2D = load(NATIVE + "/" + name)
		check(texture.resource_path == HD + "/" + name and texture.get_size() == native.get_size() * 4, name + " uses its4x derivative")
		var last := int(info.frames) - 1
		var parts: Array = bigfoot.cell_frame(name, last)
		var columns := int(info.columns)
		var source := Rect2(Vector2(last % columns, int(last / columns)) * cell, cell)
		check(parts[0] == Rect2(source.position * 4, source.size * 4), name + " source rectangle scales by density")
		check(parts[1] == Rect2(-Vector2(info.origin[0], info.origin[1]), cell), name + " destination and origin stay native")
	check(bigfoot.projectile_sheet({}, 1) == "Bullet2.png" and bigfoot.effect_sheets({"weapon": 1}) == ["Flame2.png"], "Shot and impact selection unchanged")
	check(bigfoot.rider_offset(254) == Vector2(meta.rider[254][0], meta.rider[254][1]), "Rider pivot stays native")
	for id in sprites:
		if id == 2 or not sprites[id] is Classic:
			continue
		var other = sprites[id]
		check(other.density == 1.0 and other.sheet_density.is_empty() and not other.texture.resource_path.contains("mobiles_smooth_4x"), "Mobile %d stays native" % id)
	check_imports()
	check_fallback(bigfoot)
	finish("BIGFOOT SMOOTH CHECKS")

## The imported textures carry the PNG pixels without lossy compression.
## The native import parameters are reused, so fix_alpha_border may recolor
## pixels below alpha 20, exactly as it does on the native sheets.
func check_imports() -> void:
	for name in SHEETS + [SmoothArt.ATLAS]:
		var imported: Image = load(HD + "/" + name).get_image()
		var png := Image.load_from_file(HD + "/" + name)
		imported.convert(Image.FORMAT_RGBA8)
		png.convert(Image.FORMAT_RGBA8)
		check(imported.get_size() == png.get_size() and imported_matches(imported.get_data(), png.get_data()), name + " imports without visible loss")

func imported_matches(imported: PackedByteArray, png: PackedByteArray) -> bool:
	if imported == png:
		return true
	if imported.size() != png.size():
		return false
	for index in range(0, png.size(), 4):
		if png[index + 3] != imported[index + 3]:
			return false
		if png[index + 3] >= 20 and (png[index] != imported[index] or png[index + 1] != imported[index + 1] or png[index + 2] != imported[index + 2]):
			return false
	return true

func check_fallback(bigfoot) -> void:
	var meta: Dictionary = bigfoot.meta
	var native := {SmoothArt.ATLAS: load(NATIVE + "/CharacterSpritesheet.png")}
	for name in SHEETS:
		native[name] = load(NATIVE + "/" + name)
	var catalog: Dictionary = SmoothArt.read_catalog(HD)
	check(SmoothArt.validated(HD, catalog, "bigfoot", NATIVE, meta, native).size() == 9, "Valid catalog replaces all nine sheets")
	check(SmoothArt.load_sheets("", "bigfoot", NATIVE, meta, native).is_empty(), "No smooth root keeps native sheets")
	check(SmoothArt.load_sheets("res://.tools/missing-smooth", "bigfoot", NATIVE, meta, native).is_empty(), "Missing catalog keeps native sheets")
	check(SmoothArt.validated(HD, catalog, "mage", "res://assets/openbound/mage/original", meta, native).is_empty(), "Catalog of another mobile is refused")
	var damaged: Dictionary = catalog.duplicate(true)
	damaged.scale = 3
	check(SmoothArt.validated(HD, damaged, "bigfoot", NATIVE, meta, native).is_empty(), "Wrong scale is refused")
	damaged = catalog.duplicate(true)
	damaged.frames_json.sha256 = "0"
	check(SmoothArt.validated(HD, damaged, "bigfoot", NATIVE, meta, native).is_empty(), "Catalog of other native metadata is refused")
	damaged = catalog.duplicate(true)
	damaged.sheets[SmoothArt.ATLAS].size = [1720, 1560]
	damaged.sheets["Flame2.png"].source.record = {}
	var partial: Dictionary = SmoothArt.validated(HD, damaged, "bigfoot", NATIVE, meta, native)
	check(not partial.has(SmoothArt.ATLAS) and not partial.has("Flame2.png") and partial.size() == 7, "Invalid sheets fall back individually")
	damaged = catalog.duplicate(true)
	damaged.sheets["Bullet2.png"].columns = 4
	check(not SmoothArt.validated(HD, damaged, "bigfoot", NATIVE, meta, native).has("Bullet2.png"), "Wrong grid is refused")
	# A sprite without validated sheets keeps every rectangle at density 1.
	var plain = Classic.new()
	plain.setup("bigfoot")
	plain.texture = native[SmoothArt.ATLAS]
	plain.density = 1.0
	plain.sheet_density = {}
	plain.placed = {}
	plain.load_smooth("res://.tools/missing-smooth")
	check(plain.texture.resource_path == NATIVE + "/CharacterSpritesheet.png" and plain.frame_rect(25) == Rect2(Vector2(5, 1) * plain.cell, plain.cell), "Fallback body samples native pixels")
	check(plain.cell_frame("Flame2.png", 7)[0] == Rect2(Vector2(1, 1) * Vector2(52, 49), Vector2(52, 49)), "Fallback flame samples native pixels")
	check(plain._optional_cached("Flame2.png").diffuse_texture.resource_path == NATIVE + "/Flame2.png", "Fallback flame texture is native")
