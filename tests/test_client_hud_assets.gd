extends "res://tests/support/suite.gd"
## REQ-48: native HUD texture selection, validated per-file fallback and
## preserved input geometry. Numerical combat contracts remain test_hud's job.
const ClientHudAssets = preload("res://scripts/client_hud_assets.gd")
const Hud = preload("res://scripts/hud_art.gd")
const OptionsPopup = preload("res://scripts/options_popup.gd")
const Options = preload("res://scripts/options.gd")

func run() -> void:
	var assets := ClientHudAssets.new()
	check(assets.files.size() == 56, "56 client texture records are available")
	for name in assets.files:
		var paint := assets.texture(name)
		check(paint != null, "Validated client texture loads: " + name)
		if paint != null:
			check(paint.resource_path.begins_with(ClientHudAssets.ROOT), "Native HUD never selects GPT or legacy art: " + name)
			var dims: Array = assets.files[name]["size"]
			check(paint.get_size() == Vector2(dims[0],dims[1]), "Native atlas retains the port slot dimensions: " + name)
	var fallback := preload("res://assets/openbound/hud/OptionsRadioButton.png")
	check(assets.texture("unknown.png",fallback) == fallback, "Unmapped artwork returns the supplied preserved sprite")
	check(assets.texture("CompassBackground.png") == null, "Missing compass equivalent is an explicit gap")
	check(assets.texture("CrosshairMageS1Ally.png") == null, "Native thumbnails do not masquerade as separate range wedges")
	for mutation in ["missing", "dimensions", "hash", "path", "record"]:
		var rejected := ClientHudAssets.new()
		var key := "OptionsRadioButton.png"
		match mutation:
			"missing": rejected.files.erase(key)
			"dimensions": rejected.files[key]["size"] = [25,12]
			"hash": rejected.files[key]["rgba_sha256"] = "invalid"
			"path": rejected.files[key]["file"] = "res://assets/hd/hud/OptionsRadioButton.png"
			"record": rejected.files[key] = "invalid"
		check(rejected.texture(key,fallback) == fallback, "Invalid native " + mutation + " falls back per texture")
		check(rejected.has("ActionBar.png"), "Invalid " + mutation + " does not disable unrelated native files")
	var absent := ClientHudAssets.new("res://.tools/hud-catalog-does-not-exist.json")
	check(absent.files.is_empty() and absent.texture("OptionsRadioButton.png",fallback) == fallback, "Missing catalog uses the same preserved fallback")
	var hud := Hud.new()
	for name in hud.textures:
		check(is_equal_approx(hud.density(name),1.0), "No GPT HD texture is active: " + name)
		if assets.has(name):
			check(hud.textures[name] == assets.texture(name), "HudArt uses native resource: " + name)
		else:
			check(hud.textures[name] == hud.originals[name], "HudArt keeps documented native gap: " + name)
	var host := Node.new()
	root.add_child(host)
	for shot in range(3):
		var button := hud.make_button(host,"shot",shot)
		check(button.size.is_equal_approx(Vector2(35,34)*1.6) and (button.position+button.size*0.5).is_equal_approx(Hud.bar_point(Hud.SHOT_OFFSETS[shot])), "Shot hitbox uses native footer " + str(shot))
	for kind in ["options","skip"]:
		var button := hud.make_button(host,kind)
		check(button.size.is_equal_approx(Vector2(40,30)*1.6), "Native header hitbox for " + kind + " hitbox")
	check(hud.strength_rect().is_equal_approx(Rect2(Vector2(390.4,750.4),Vector2(640,35.2))), "Charge interaction aligns with native400x22 frame")
	var options := Options.new("res://.tools/client-hud-options.json")
	var popup := OptionsPopup.new(options)
	host.add_child(popup)
	check(popup.size == Vector2(323,328)*1.6, "Configuration popup retains its size")
	check(popup.accept_button.size.is_equal_approx(Vector2(20,25)*1.6), "Native checkmark retains accept hitbox")
	for name in popup.textures:
		check(popup.textures[name] == assets.texture(name) and is_equal_approx(popup.density(name),1.0), "Options selects validated client art at1x: " + name)
	host.queue_free()
	report("CLIENT HUD ASSETS CHECKS")
	quit(exit_code())
