extends "res://tests/support/suite.gd"
## Classic roster beyond Mage, Bigfoot and Nak. Stats are the characterdata.dat
## rows; shot counts follow the OpenBound emitters where that class exists.

const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const ClassicFlight = preload("res://scripts/classic_flight.gd")

func run() -> void:
	var names := {
		4: "Armor", 5: "Trico", 6: "Boomer", 7: "Raon", 8: "Lightning", 9: "JD",
		10: "ASate", 11: "Ice", 12: "Turtle", 13: "Grub", 14: "Dragon", 15: "Knight", 16: "Aduka",
	}
	var life := {4: 1000, 5: 1050, 6: 1000, 7: 1050, 8: 750, 9: 700, 10: 750, 11: 1200, 12: 960, 13: 1000, 14: 1000, 15: 1000, 16: 1000}
	var delays := {
		4: [770, 960, 1320], 5: [740, 890, 1290], 6: [730, 880, 1280], 7: [750, 900, 1300],
		8: [750, 800, 1300], 9: [740, 830, 1290], 10: [730, 880, 1280], 11: [740, 890, 1290],
		12: [740, 890, 1290], 13: [740, 890, 1290], 14: [800, 950, 1390], 15: [800, 950, 1390],
		16: [760, 910, 1310],
	}
	check(Mobiles.PLAYABLE.size() == 16, "Sixteen classic mobiles are playable")
	for id in names:
		var spec: Dictionary = Mobiles.definition(id)
		check(spec.name == names[id] and int(spec.hp) == int(life[id]), "%s keeps its client life" % names[id])
		check(Mobiles.opponent(id) == 1, "%s trains against Mage" % names[id])
		for weapon in range(3):
			check(int(Mobiles.weapon(id, weapon).cost) == int(delays[id][weapon]), "%s shot %d keeps the client delay" % [names[id], weapon])
	check(int(Mobiles.definition(8).shield) == 300 and int(Mobiles.definition(9).shield) == 250 and int(Mobiles.definition(10).shield) == 200, "Lightning, JD and A.Sate keep their client shields")
	check(int(Mobiles.definition(12).time_delay) == 12, "Turtle spends delay 12 per second")
	check(bool(Mobiles.definition(16).rear), "Aduka aims from the back, like the client angles 130–170")
	check(Mobiles.emission(5, 1).size() == 3, "Trico S2 emits three orbiting shells")
	check(Mobiles.emission(7, 0).size() == 3, "Raon S1 emits three orbiting shells from one source call")
	check(Mobiles.emission(7, 1).size() == 2 and str(Mobiles.weapon(7, 1).flight) == "mine", "Raon S2 is a pair of shells that plant a mine")
	check(Mobiles.emission(12, 1).size() == 2, "Turtle S2 emits the two swinging shells")
	var model = Match.new()
	model.start(4, 1, 3, "")
	check(model.actors[0].vehicle == 4 and model.actors[0].hp == 1000 and model.actors[1].vehicle == 1, "Armor starts at 1000 against Mage")
	model.phase = "aim"
	check(model.fire(40, 50, 2), "Armor SS fires")
	check(model.projectiles.size() == 1 and str(model.projectiles[0].flight) == "open", "Armor SS carries the opening flight")
	model = Match.new()
	model.start(7, 1, 3, "")
	model.phase = "aim"
	model.actors[0].ss_lock = 0
	check(model.fire(30, 40, 1), "Raon S2 fires")
	# Fly until the shells are gone, then a mine should remain.
	for _step in range(800):
		if model.phase != "flight":
			break
		model.advance_projectiles(1.0 / 60.0)
	check(model.mines.size() >= 1, "Raon S2 leaves a mine")
	var mine_model = Match.new()
	mine_model.start(7, 1, 3, "")
	var foe: Vector2 = mine_model.actors[1].pos
	var approach := foe.x - 40.0
	var ground: float = mine_model.terrain.surface_at(approach, foe.y - 80.0)
	mine_model.mines.append({"pos": Vector2(approach, ground - 5.0), "owner": 0, "radius": 21.0, "damage": 200, "weapon": 1, "vehicle": 7})
	mine_model.active = 0
	var before_x := float(mine_model.mines[0].pos.x)
	ClassicFlight.walk_mines(mine_model)
	ClassicFlight.detonate_mines(mine_model)
	check(mine_model.mines.is_empty() or float(mine_model.mines[0].pos.x) > before_x, "Raon mine walks toward the nearer mobile along the ground")
	var bolt_model = Match.new()
	bolt_model.start(8, 1, 3, "")
	var spot: Vector2 = bolt_model.actors[0].pos
	bolt_model.actors[1].pos = spot + Vector2(0, -90)
	var pool_before := int(bolt_model.actors[1].hp) + int(bolt_model.actors[1].shield)
	ClassicFlight.bolts(bolt_model, {"bolt": 95.0, "bolt_extra": 55.0, "bolt_radius": 25.0, "bolt_extra_radius": 25.0, "bolt_count": 1, "bolt_angles": [PI * 0.5]}, spot)
	var pool_after := int(bolt_model.actors[1].hp) + int(bolt_model.actors[1].shield)
	check(pool_after < pool_before, "Lightning beam climbing from the impact reaches the mobile above")
	var aduka = Match.new()
	aduka.start(14, 1, 4, "")
	aduka.phase = "aim"
	aduka.actors[0].ss_lock = 0
	check(aduka.fire(35, 25, 2), "Dragon SS fires")
	for _step in range(900):
		if aduka.projectiles.size() >= 5:
			break
		if aduka.phase != "flight":
			break
		aduka.advance_projectiles(1.0 / 60.0)
	check(aduka.projectiles.size() >= 5, "Dragon SS leaves five child shots at the impact")
	var jd = Match.new()
	jd.start(9, 1, 6, "")
	jd.phase = "aim"
	check(jd.fire(32, 22, 1), "JD S2 fires")
	var saw_crystal := false
	var crystal_fixed := false
	for _step in range(900):
		for effect in jd.battle_effects:
			if str(effect.kind) == "jd_crystal":
				saw_crystal = true
				crystal_fixed = not jd.projectiles.any(func(shell):return bool(shell.get("crystal_body",false)))
		if jd.phase != "flight":
			break
		jd.advance_projectiles(1.0 / 60.0)
	check(saw_crystal and crystal_fixed, "JD S2 spawns its stationary attraction effect rather than a falling zero-power projectile")
	var grub = Match.new()
	grub.start(13, 1, 2, "")
	var Shell = load("res://scripts/shell_state.gd")
	var crossed: Vector2 = grub.actors[0].pos + Vector2(50, 0)
	grub.actors[1].pos = crossed
	grub.actors[1].hp = 1000
	grub.actors[1].shield = 0
	grub.phase = "flight"
	grub.shot_actor = 0
	grub.shot_weapon = 2
	var shell: Dictionary = Shell.create(crossed + Vector2(-40, 0), Vector2(220, 0), 0.0, Mobiles.weapon(13, 2), 2, 0)
	shell.launched = true
	grub.projectiles = [shell]
	grub.advance_projectiles(0.25)
	check(int(grub.actors[1].hp) == 1000 and grub.projectiles.size() == 1, "Grub SS crosses a mobile and keeps flying")
	var raon = Match.new()
	raon.start(7, 1, 2, "")
	var mine_pos := Vector2(raon.actors[0].pos.x + 30.0, raon.actors[0].pos.y)
	raon.actors[1].pos = mine_pos + Vector2(36, 0)
	raon.actors[1].hp = 1050
	raon.actors[1].shield = 0
	raon.mines = [{"pos": mine_pos, "owner": 0, "radius": 21.0, "damage": 400, "weapon": 2, "vehicle": 7,
		"crystal": false, "crawl": true, "dir": 1.0, "steps": 360, "debt": 0.0}]
	ClassicFlight.crawl_mines(raon, 2.0)
	check(raon.mines.is_empty() and int(raon.actors[1].hp) < 1050, "Raon SS mine crawls forward and bursts on the mobile")
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/classic-mobiles-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	var raon_sprite = view.sprite_for(7)
	check(raon_sprite.sheet("Mine.png").states.has("move") and raon_sprite.sheet("MineSS.png").states.has("active") and raon_sprite.sheet("crystal.png").states.has("normal"), "Raon mines and the JD crystal use the original client sheets")
	var ClassicSprite = load("res://scripts/classic_sprite.gd")
	var dormant := {"crystal": false, "crawl": false, "pos": Vector2.ZERO, "steps": 0}
	var far_actor := {"pos": Vector2(200, 0), "hp": 1}
	var near_actor := {"pos": Vector2(40, 0), "hp": 1}
	check(ClassicSprite.placed_state(dormant, [far_actor]) == "normal", "Raon S2 mine stays dormant beyond 90 px")
	check(ClassicSprite.placed_state(dormant, [near_actor]) == "active", "Raon S2 mine wakes inside 90 px")
	check(ClassicSprite.placed_state({"crystal": false, "crawl": true, "steps": 12, "pos": Vector2.ZERO}, []) == "move", "Raon SS mine plays move while it crawls")
	check(ClassicSprite.placed_state({"crystal": true, "pos": Vector2.ZERO}, [near_actor]) == "normal", "JD crystal stays on the normal state the client selects")
	var sprite = view.sprite_for(4)
	check(sprite != null and sprite.texture != null and sprite.meta.poses.has("idle") and int(sprite.meta.tank) == 1, "Armor draws the original tank1 atlas")
	check(sprite.hull_width == 60.0, "Classic mobiles share Trico's pixel scale instead of stretching a narrow frame")
	check(view.sprite_for(14).meta.tank == 14 and view.sprite_for(15).meta.tank == 15 and view.sprite_for(16).meta.tank == 16, "Dragon, Knight and Aduka use tank14, tank15 and tank16")
	check(view.sprite_for(16).rear, "Aduka sprite mirrors against the aim")
	var boomer_sheet: Dictionary = view.sprite_for(6).sheet("Bullet3.png")
	check(str(ClassicSprite.bullet_state(boomer_sheet, 0.2).frames) != "" and ClassicSprite.bullet_state(boomer_sheet, 0.2).frames == boomer_sheet.states.normal, "Boomer SS starts in the normal frames")
	check(ClassicSprite.bullet_state(boomer_sheet, 1.2, "change", 0).frames == boomer_sheet.states.change, "Boomer SS plays the change frames when simulation changes")
	check(ClassicSprite.bullet_state(boomer_sheet, 2.0, "cnormal", 0).frames == boomer_sheet.states.cnormal, "Boomer SS stays on cnormal when simulation opens")
	for spark_index in 12:
		var spark: Vector2 = ClassicSprite.spark_offset(spark_index)
		check(absi(int(spark.x)) <= 4 and absi(int(spark.y)) <= 4, "Dragon spark stays inside the client's -4..+4 scatter")
	if view.screen == "lobby":
		view.show_menu()
	var by_id := {}
	var placed: Array[Rect2] = []
	for button in view.menu.grid_buttons:
		var vehicle_id := int(button.get_meta("vehicle_id"))
		var rect := Rect2(button.position, button.size)
		var clear := true
		for other in placed:
			clear = clear and not rect.intersects(other)
		placed.append(rect)
		by_id[vehicle_id] = button
		check(view.menu.GRID_PANEL.encloses(rect) and clear, "Grid cell %s does not overlap its neighbor" % button.tooltip_text)
	check(view.menu.grid_buttons.size() == 16, "The room grid has one button per playable mobile")
	for id in names:
		check(by_id.has(id) and by_id[id].tooltip_text == names[id], "Menu lists %s" % names[id])
	view.menu.choose_player_side()
	by_id[4].pressed.emit()
	check(view.vehicle == 4 and view.menu.player_mobile.text == "Armor", "Clicking Armor in the grid selects the pilot")
	view.menu.choose_cpu_side()
	by_id[12].pressed.emit()
	check(view.cpu_vehicle == 12 and view.menu.cpu_mobile.text == "Turtle", "Clicking Turtle in the grid selects the CPU")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/classic-mobiles-profile.json"))
	finish("CLASSIC MOBILE CHECKS")
