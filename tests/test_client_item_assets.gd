extends "res://tests/support/suite.gd"

func run() -> void:
	var ItemArt = load("res://scripts/item_art.gd")
	var art = ItemArt.new()
	check(art.textures["ItemDual.png"].resource_path == "res://assets/xfs/items/ItemDual.png", "Dual uses the client extraction")
	check(art.textures["TeleportBullet.png"].resource_path == "res://assets/xfs/items/TeleportBullet.png", "Beacon uses the client extraction")
	check(not art.textures.has("TeleportFlame.png"), "No generated HD flame stays active")
	var fallback = ItemArt.new("res://.tools/missing-client-items/")
	for name in art.textures:
		check(fallback.textures[name] == fallback.originals[name], "Missing native asset falls back: " + name)
	check(ItemArt.client_texture("res://assets/xfs/maps/mos/background.png", Vector2(73, 36), art.originals["ItemDual.png"]) == art.originals["ItemDual.png"], "Invalid dimensions fall back without changing the UI window")
	for id in load("res://scripts/items.gd").ORDER:
		for frame in range(4):
			check(art.button_frame(id, frame).region.size == Vector2(art.button_width(id), 36), "Client button keeps logical rectangle: %s/%d" % [id, frame])
	check(art.region("MatchStatus.png", Rect2(0, 0, 217, 35)).region == Rect2(0, 0, 217, 38), "Locked banner uses the entire native raster")
	check(art.using_textures["bigfoot"].diffuse_texture.resource_path.begins_with(ItemArt.ORIGINALS), "Unproven UsingItem aura remains a declared original adaptation")
	finish("CLIENT ITEM ASSETS CHECKS")
