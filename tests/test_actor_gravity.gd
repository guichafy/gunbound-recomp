extends "res://tests/support/suite.gd"
## Regression for unsupported actors remaining suspended until PHASE_SETTLE.
## Flat mask, real projectile contacts/craters; expected support read from mask.
const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Shell = preload("res://scripts/shell_state.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Art = preload("res://scripts/battle_art.gd")
const FLOOR := 400.0

func fixture(vehicle: int = 2):
	var model = Match.new()
	model.start(vehicle, 1, 42, "", "original", null, [], [], [], Match.PLAYER, vehicle)
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.image = null
	model.terrain.texture = null
	model.terrain.cells.fill(0)
	for y in range(int(FLOOR) / 2, 320):
		for x in range(30, model.terrain.WIDTH - 30):
			model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	for index in range(2):
		model.actors[index].pos = Vector2(300 + index * 400, FLOOR - model.stance_of(index))
	model.terrain.native_cells.clear()
	model.stamp_tilt()
	model.events.clear()
	return model

func shell(at: Vector2, delay: float = 0.0) -> Dictionary:
	# A harmless blast still removes real terrain. All other motion is real.
	return Shell.create(at, Vector2(0, 200), delay, {"damage":0, "radius":45.0}, 0, 0)

func arm(model, at: Vector2) -> void:
	Snapshot.arm(model, 0, 0, [shell(at), shell(Vector2(100, 100), 2.0)])

func on_floor(model, index: int) -> bool:
	var actor: Dictionary = model.actors[index]
	return is_equal_approx(actor.pos.y + model.stance_of(index), model.terrain.surface_at(actor.pos.x, actor.pos.y + 10.0))

func run() -> void:
	crater_during_salvo()
	pending_emission_follows_owner()
	roster_and_both_actors()
	last_shell_and_void()
	snapshot_and_delta_parity()
	persistent_effect_ticks()
	finish("ACTOR GRAVITY CHECKS")

func crater_during_salvo() -> void:
	var model = fixture()
	var before: Vector2 = model.actors[1].pos
	var hp := int(model.actors[1].hp)
	arm(model, Vector2(700, FLOOR - 1))
	model.tick(Combat.STEP)
	check(model.events.any(func(e): return e.type == "explosion" and e.removed > 0), "Real shell opens a crater")
	check(model.phase == Match.PHASE_FLIGHT and model.projectiles.size() == 1, "Delayed shell keeps the salvo in flight")
	check(model.actors[1].pos.y > before.y and on_floor(model, 1), "Target falls in the first impact tick, before the delayed shot")
	check(int(model.actors[1].hp) == hp, "Short fall adds no damage")
	var landed: Vector2 = model.actors[1].pos
	model.projectiles.append(shell(Vector2(700, landed.y + model.stance_of(1) - 1), model.flight_elapsed))
	model.tick(Combat.STEP)
	check(model.actors[1].pos.y > landed.y and on_floor(model, 1), "Next impact lowers support again within the same salvo")
	# Later collision must follow the new body, not the suspended old position.
	var center := Combat.box_center(model.actors[1])
	var hit := Combat.trace_actors(center - Vector2(80,0), center + Vector2(80,0), model.actors, 0)
	check(not hit.is_empty() and int(hit.actor) == 1, "Later collision sees the fallen body")
	var hp_before := int(model.actors[1].hp)
	var incoming := Shell.create(center-Vector2(0,80),Vector2(0,1600),model.flight_elapsed,{"damage":70,"radius":24.0},0,0)
	model.events.clear()
	model.projectiles.append(incoming)
	model.tick(Combat.STEP)
	check(model.events.any(func(e): return e.type == "explosion" and e.collided_actor == 1), "A later real shell hits the fallen target")
	var hp_after := int(model.actors[1].hp)
	check(hp_after < hp_before, "The later shell damages the fallen target")
	model.tick(Combat.STEP)
	check(int(model.actors[1].hp) == hp_after, "Subsequent gravity ticks do not duplicate impact damage")
	var stable: Vector2 = model.actors[1].pos
	model.wind = Vector2(35,0)
	model.tick(Combat.STEP)
	check(model.actors[1].pos == stable, "Supported actor does not drift on subsequent ticks")
	model.settle_actors()
	check(model.actors[1].pos == stable, "Final accommodation is idempotent")
	var art := Art.new()
	art.reset([model.actors[0], {"vehicle":2, "pos":before}])
	art.tick(model, 1.0/60.0)
	check(float(art.motion[1].pos.y) > before.y and float(art.motion[1].pos.y) < stable.y, "View starts smoothing the fall while salvo is active")

func roster_and_both_actors() -> void:
	for vehicle in range(1,17):
		var model = fixture(vehicle)
		arm(model, Vector2(100,100))
		for index in range(2):
			model.terrain.carve(Vector2(model.actors[index].pos.x,FLOOR),40.0)
		model.tick(Combat.STEP)
		for index in range(2):
			check(model.actors[index].pos.y > FLOOR - model.stance_of(index) and on_floor(model,index), "Mobile %d actor %d reacts during flight" % [vehicle,index])

func last_shell_and_void() -> void:
	var model = fixture()
	Snapshot.arm(model, 0, 0, [shell(Vector2(700,FLOOR-1))])
	model.tick(Combat.STEP)
	check(model.phase == Match.PHASE_SETTLE and on_floor(model,1) and model.actors[1].pos.y > FLOOR-model.stance_of(1), "Last impact accommodates before the settle delay")
	model = fixture()
	arm(model, Vector2(100,100))
	for y in range(model.terrain.HEIGHT):
		for x in range(320,380):
			model.terrain.cells[y * model.terrain.WIDTH + x] = 0
	model.tick(Combat.STEP)
	check(int(model.actors[1].hp) == 0, "Loss of all support eliminates during flight")
	check(model.events.filter(func(e): return e.type == "fall").size() == 1, "Void emits fall once")
	check(model.phase == Match.PHASE_FLIGHT and not model.projectiles.is_empty(), "Remaining salvo continues before result")
	model.tick(Combat.STEP)
	check(model.events.filter(func(e): return e.type == "fall").size() == 1, "Dead actor cannot fall twice")

func snapshot_and_delta_parity() -> void:
	var live = fixture(6)
	live.wind = Vector2(35,0)
	var original: Vector2 = live.actors[1].pos
	var cells: PackedByteArray = live.terrain.cells.duplicate()
	var sim = Snapshot.capture(live)
	arm(sim, Vector2(700,FLOOR-1))
	var split = Snapshot.capture(live)
	arm(split, Vector2(700,FLOOR-1))
	sim.advance_projectiles(Combat.STEP)
	split.advance_projectiles(Combat.STEP*0.5)
	check(split.actors[1].pos == original, "Fractional tick does not apply gravity early")
	split.advance_projectiles(Combat.STEP*0.5)
	check(sim.actors == split.actors and sim.terrain.cells == split.terrain.cells, "Split deltas produce identical fall and crater")
	check(sim.actors[1].pos.y > original.y and sim.actors[1].pos.x != original.x, "Snapshot applies falling and Boomer wind")
	check(live.actors[1].pos == original and live.terrain.cells == cells and live.events.is_empty(), "Prediction leaves live actors, mask and events intact")
	arm(live, Vector2(700,FLOOR-1))
	live.tick(Combat.STEP)
	check(live.actors == sim.actors and live.terrain.cells == sim.terrain.cells, "Real tick and prediction share gravity")

func persistent_effect_ticks() -> void:
	for phase in [Match.PHASE_AIM,Match.PHASE_MINES,Match.PHASE_SETTLE]:
		var model = fixture()
		model.phase = phase
		model.resolve_wait = 1.0
		model.terrain.carve(Vector2(700,FLOOR),40)
		model.tick(Combat.STEP)
		check(model.actors[1].pos.y > FLOOR-model.stance_of(1) and on_floor(model,1), "Persistent-effect tick accommodates in " + phase)

func pending_emission_follows_owner() -> void:
	var model = fixture()
	check(model.fire(65,70,1), "Bigfoot T2 fires before owner loses support")
	var sim = Snapshot.capture(model)
	Snapshot.arm(sim,0,1,model.projectiles.duplicate(true))
	var origin: Vector2 = model.actors[0].pos
	var initial: Vector2 = model.projectiles[0].pos
	for copy in [model,sim]:
		copy.terrain.carve(Vector2(300,FLOOR),60)
	var launched := false
	for tick in 12:
		model.tick(Combat.STEP)
		sim.advance_projectiles(Combat.STEP)
		for projectile in model.projectiles:
			if bool(projectile.launched):
				var offset: Vector2 = model.actors[0].pos-origin
				check(offset.y > 0, "Owner has fallen before delayed emission")
				check(Vector2(projectile.trail[0]).is_equal_approx(initial+offset), "Delayed emission follows fallen owner instead of spawning in air")
				check(projectile.previous_draw_pos == initial+offset and projectile.previous_hit_pos == initial+offset, "Launch interpolation starts at translated muzzle")
				launched = true
				break
		check(model.actors == sim.actors and model.projectiles == sim.projectiles, "Real and predicted pending emission agree at tick %d" % tick)
		if launched: break
	check(launched, "Delayed emission is exercised")
