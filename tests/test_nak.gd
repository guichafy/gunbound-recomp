extends SceneTree
## Nak (ID 3, REQ-43, ADR-074): catalog, S2 burrow, SS ghost, shared prediction, frames.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", description)

func shell(model, weapon: int, at: Vector2, velocity: Vector2) -> Dictionary:
	var rules: Dictionary = Mobiles.weapon(3, weapon)
	return {"pos": at, "hit_pos": at, "velocity": velocity, "age": 1.0, "trail": [at], "helix": 0.0, "phase": 0.0,
		"spawn_at": 0.0, "launched": true, "damage": int(rules.damage), "launch_speed": velocity.length(), "inside": {},
		"influenced": [], "electric": false, "thor": false, "tornado": {}, "weapon": weapon, "volley": 0, "beacon": false,
		"wind_scale": 1.0, "burrow": bool(rules.get("burrow", false)), "ghost": bool(rules.get("ghost", false)), "underground": false}

## Runs one shell with the live flight loop; returns every event it produced.
func fly(model, projectile: Dictionary) -> Array:
	model.projectiles = [projectile]
	model.phase = "flight"
	model.shot_actor = Match.PLAYER
	model.shot_weapon = int(projectile.weapon)
	model.flight_elapsed = 0.0
	model.events.clear()
	var log: Array = []
	for _frame in range(2400):
		model.advance_projectiles(Combat.STEP)
		log.append_array(model.events)
		model.events.clear()
		if model.phase != "flight":
			break
	return log

func first(events: Array, type: String) -> Dictionary:
	for event in events:
		if event.type == type:
			return event
	return {}

func _initialize() -> void:
	var nak: Dictionary = Mobiles.definition(3)
	check(Mobiles.PLAYABLE == [1, 2, 3] and nak.name == "Nak", "Nak joins the roster with stable ID 3")
	check(int(nak.hp) == 1100 and int(nak.shield) == 0 and int(nak.protection) == 35 and not bool(nak.bionic), "MobileMetadata: 1100 HP, no shield, Steel")
	check(is_equal_approx(float(nak.beacon_delay), 0.0), "Base Mobile beacon interaction time")
	for weapon in range(3):
		check(Mobiles.aim_limits(3, weapon) == Vector2(10, 50), "AimPresets keep 10–50 for shot %d" % weapon)
	# characterdata base [28] + shot [30/31/32] (ADR-076), not the fork's 760/910/1310 row.
	var delays := [770.0, 920.0, 1320.0]
	var power := [[200.0, 30.0], [350.0, 35.0], [360.0, 35.0]]
	for weapon in range(3):
		var rules: Dictionary = Mobiles.weapon(3, weapon)
		check(is_equal_approx(float(rules.delay), delays[weapon] / 7.5), "Original delay for shot %d" % weapon)
		check(float(rules.damage) == power[weapon][0] and float(rules.radius) == power[weapon][1], "characterdata power and radius for shot %d" % weapon)
		check(float(rules.get("wind_scale", 1.0)) == 1.0, "Original shots share the common wind influence")
	check(bool(Mobiles.weapon(3, 1).get("burrow", false)) and bool(Mobiles.weapon(3, 2).get("ghost", false)), "S2 burrows and SS ghosts")
	check(Mobiles.opponent(3) == 1 and Mobiles.opponent(1) == 2 and Mobiles.opponent(2) == 1, "CPU pairs: 1↔2 unchanged, Nak meets Mage")
	check(is_equal_approx(Combat.BURROW_GRAVITY, 2.0) and is_equal_approx(Combat.BURROW_ENTRY_DAMPING, 0.5), "Underground: twice the gravity upward, half the vertical speed")

	# S2: dives into the procedural ground, curves back up and explodes where it surfaces.
	var model = Match.new()
	model.start(3, 1, 11, "")
	model.wind = Vector2.ZERO
	var x := 640.0
	var top: float = model.terrain.surface_at(x)
	model.actors[0].pos = Vector2(80, model.terrain.surface_at(80) - 25.0)
	model.actors[1].pos = Vector2(1200, model.terrain.surface_at(1200) - 25.0)
	var dive := shell(model, 1, Vector2(x, top - 40.0), Vector2(120, 260))
	var events := fly(model, dive)
	var burrow := first(events, "burrow")
	var blast := first(events, "explosion")
	check(not burrow.is_empty(), "S2 enters the ground instead of exploding on contact")
	check(not blast.is_empty(), "Buried S2 explodes")
	if not burrow.is_empty() and not blast.is_empty():
		var exit: Vector2 = blast.position
		check(exit.x > Vector2(burrow.position).x + 10.0, "S2 travels underground along its heading")
		check(not model.terrain.is_solid(exit), "S2 explodes on the first free pixel")
		check(exit.y < Vector2(burrow.position).y + 1.0 or absf(exit.y - model.terrain.surface_at(exit.x)) < 4.0, "S2 resurfaces near the ground line")
	# Entering halves the vertical speed (vy at contact × 0.5).
	model.start(3, 1, 11, "")
	model.wind = Vector2.ZERO
	var probe := shell(model, 1, Vector2(x, top - 2.0), Vector2(0, 300))
	model.projectiles = [probe]
	model.phase = "flight"
	model.shot_actor = Match.PLAYER
	model.events.clear()
	var entered := false
	for _frame in range(30):
		model.advance_projectiles(Combat.STEP)
		if bool(probe.underground):
			entered = true
			break
	check(entered and float(probe.velocity.y) < 160.0 and float(probe.velocity.y) > 140.0, "Entry halves vy (got %.1f)" % float(probe.velocity.y))
	model.advance_projectiles(Combat.STEP)
	check(float(probe.velocity.y) < 150.0, "Underground gravity pulls upward")

	# SS: crosses the terrain and only stops on a mobile.
	model.start(3, 1, 12, "")
	model.wind = Vector2.ZERO
	var target: Dictionary = model.actors[1]
	var center: Vector2 = Combat.box_center(target)
	var start := center + Vector2(0, 160)
	check(model.terrain.is_solid(start), "SS fixture starts buried under the target")
	var ghost := shell(model, 2, start, Vector2(0, -400))
	events = fly(model, ghost)
	blast = first(events, "explosion")
	check(not blast.is_empty() and int(blast.collided_actor) == 1, "SS passes through the ground and hits the mobile above")
	model.start(3, 1, 12, "")
	model.wind = Vector2.ZERO
	var deep := Vector2(640, model.terrain.surface_at(640) + 40.0)
	events = fly(model, shell(model, 2, deep, Vector2(0, 300)))
	check(first(events, "explosion").is_empty() and not first(events, "miss").is_empty(), "SS without a mobile in its path leaves the map")

	# The CPU prediction runs the same loop: identical impact for S2 and SS.
	for weapon in [1, 2]:
		model.start(3, 1, 20 + weapon, "")
		model.wind = Vector2(12, 0)
		var predicted: Dictionary = model.predict_shot(0, 35.0, 70.0, weapon)
		model.fire(35.0, 70.0, weapon)
		var live: Dictionary = {}
		for _frame in range(2400):
			model.advance_projectiles(Combat.STEP)
			for event in model.events:
				if event.type in ["explosion", "miss"] and live.is_empty():
					live = event
			model.events.clear()
			if model.phase != "flight":
				break
		check(not predicted.is_empty() and not live.is_empty() and Vector2(predicted.position).is_equal_approx(Vector2(live.position)), "Prediction matches the live shot %d" % weapon)

	# Teleport beacon keeps its ground rule even when fired as S2.
	model.start(3, 1, 13, "")
	model.actors[0].turn_item = "teleport"
	var beacon: Dictionary = model.shot_shells(0, 40, 60, 1)[0]
	check(bool(beacon.beacon) and not bool(beacon.burrow) and not bool(beacon.ghost), "Beacon never burrows or ghosts")

	# Original frames: tank3.epa states, bubble idle, mirrored tail aim.
	var sprite = load("res://scripts/nak_sprite.gd").new()
	check(sprite.texture.get_size() == Vector2(74 * 20, 57 * 20), "Atlas holds 392 frames in 20 columns")
	check(sprite.rider_offsets.size() == 392 and sprite.rider_offset(0) == Vector2(-9, -23) + sprite.RIDER_ADJUST, "RiderPivot covers every frame, with the fork registration offset")
	for pose in sprite.SEQUENCES:
		var sequence: Array = sprite.SEQUENCES[pose]
		check(int(sequence[0]) >= 0 and int(sequence[1]) <= 391 and int(sequence[0]) <= int(sequence[1]), "Sequence %s inside the atlas" % pose)
	var states: Dictionary = sprite.sheet("CharacterSpritesheet.png").states
	check(Array(states.fire1).front() == 98 and Array(states.bfire1).front() == 193 and Array(states.dead).front() == 173, "Flipbook follows tank3.epa")
	check(sprite.frame_index("idle", 0.0, 0, false) == 0 and sprite.frame_index("idle", 5.5, 0, false) == 311, "Idle blows a bubble once per cycle")
	check(sprite.frame_index("idle", 5.5, 0, true) == sprite.frame_index("idle_low", 5.5, 0, true), "Low health idle skips the bubble")
	check(sprite.effect_capacity(0) == 11 and sprite.effect_capacity(2) == 25, "Original impact lengths")
	check(sprite.shoot_sounds.size() == 3 and sprite.blast_sounds.size() == 3, "Original Nak sounds")
	print("NAK CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
