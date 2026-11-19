extends SceneTree
## Historical baseline probe. See docs/sdd/SHOT_DAMAGE_AUDIT.md.

const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Combat = preload("res://scripts/combat.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func _initialize() -> void:
	call_deferred("run")

static func fixture(shooter: int, defender: int, rise: int = 0):
	var model = Match.new()
	model.start(shooter, 1, 42, "", "original", null, [], [], [], 0, defender)
	model.terrain.cells.fill(0)
	model.terrain.native_cells.fill(0)
	for y in range(250, model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	for y in range(500, model.terrain.HEIGHT * 2):
		for x in model.terrain.WIDTH * 2:
			model.terrain.native_cells[y * model.terrain.WIDTH * 2 + x] = 1
	@warning_ignore("integer_division")
	for y in range((500 - rise) / 2, 250):
		for x in range(116, model.terrain.WIDTH):
			model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	for y in range(500 - rise, 500):
		for x in range(232, model.terrain.WIDTH * 2):
			model.terrain.native_cells[y * model.terrain.WIDTH * 2 + x] = 1
	model.terrain.first_solid_y = 500 - rise
	model.actors[0].pos = Vector2(200, 500 - model.stance_of(0))
	model.actors[1].pos = Vector2(500, 500 - rise - model.stance_of(1))
	model.actors[0].turns = 4
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.events.clear()
	return model

static func flight(base, angle: float, power: float, weapon: int, gap: int, prediction: bool = false) -> Dictionary:
	var model = Snapshot.capture(base)
	model.phase = model.PHASE_AIM
	model.active = 0
	model.actors[1].pos.x = 200 + gap
	var hp := int(model.actors[1].hp)
	var shield := int(model.actors[1].shield)
	if prediction:
		Snapshot.arm(model, 0, weapon, model.shot_shells(0, angle, power, weapon))
		model.shot_gold = {}
	else:
		assert(model.fire(angle, power, weapon))
	var trace := []
	var launches := 0
	var tick := 0
	for index in 720:
		tick = index + 1
		model.advance_projectiles(0.05)
		for event in model.events:
			if event.type == "projectile_launch":
				launches += 1
			if event.type == "explosion":
				trace.append(["explosion", tick, [event.position.x, event.position.y], event.get("collided_actor", -1)])
			if event.type in ["damage","shield_damage","fall"] and event.actor == 1:
				trace.append([event.type, tick, event.get("amount", 0), event.get("kind", ""),
					[event.position.x, event.position.y] if event.has("position") else []])
		model.events.clear()
		if model.phase != model.PHASE_FLIGHT:
			break
	var target: Dictionary = model.actors[1]
	var native_center := Shared.center(target)
	var legacy_center := Combat.box_center(target)
	return {
		"target_pos": [target.pos.x, target.pos.y], "target_tilt": target.tilt,
		"native_center_after": [native_center.x, native_center.y],
		"legacy_center_after": [legacy_center.x, legacy_center.y],
		"launches": launches, "hp_lost": hp - int(target.hp),
		"shield_lost": shield - int(target.shield), "trace": trace, "ticks": tick,
		"done": model.phase != model.PHASE_FLIGHT,
	}

func run() -> void:
	for shooter in Mobiles.PLAYABLE:
		var m = fixture(shooter, 4)
		for weapon in 3:
			var limits: Vector2 = m.aim_limits(0, weapon)
			var angle := floorf((limits.x + limits.y) / 2.0)
			var shells: Array = m.shot_shells(0, angle, 50, weapon)
			var trace := flight(m, angle, 50, weapon, 300)
			print("ROSTER ", JSON.stringify({
				"vehicle": shooter, "weapon": weapon, "angle": angle,
				"force_max": Mobiles.force_max(shooter), "min": Mobiles.minimum_power(shooter),
				"base_shells": shells.map(func(shell): return int(shell.damage)),
				"fp": shells.map(func(shell): return [shell.launch_velocity_fp.x, shell.launch_velocity_fp.y]),
				"flight": trace,
			}))
			if not trace.done:
				push_error("Flight did not terminate for %d/%d" % [shooter, weapon])
				quit(2)
				return
	var armor = fixture(4, 2, 22)
	var real := flight(armor, 10.0, 25.0, 0, 50)
	var replay := flight(armor, 10.0, 25.0, 0, 50, true)
	print("REPRO ", JSON.stringify({"real": real, "snapshot": replay, "equal": real == replay}))
	quit(0 if real == replay and real.hp_lost == 626 else 2)
