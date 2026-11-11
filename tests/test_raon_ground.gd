extends "res://tests/support/suite.gd"
## Independent x86 fixtures, including flags after the ground/fall/bounds branch.
const Raon = preload("res://scripts/raon_effect.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const AdukaWeather = preload("res://scripts/aduka_weather.gd")

func fixture_ground(c: Dictionary):
	var terrain = Terrain.new()
	terrain.WIDTH = int(c.width)/2
	terrain.HEIGHT = int(c.height)/2
	terrain.cells.resize(terrain.WIDTH*terrain.HEIGHT)
	terrain.cells.fill(0)
	terrain.native_cells.resize(int(c.width)*int(c.height))
	terrain.native_cells.fill(0)
	for layer in c.layers:
		for y in range(int(layer[0]),int(layer[1])):
			for x in int(c.width):
				terrain.native_cells[y*int(c.width)+x] = 1
	for y in terrain.HEIGHT:
		for x in terrain.WIDTH:
			terrain.cells[y*terrain.WIDTH+x] = terrain.native_cells[(y*2+1)*int(c.width)+x*2+1]
	return terrain

func make_mine(c: Dictionary) -> Dictionary:
	var mine := Raon.create_mine({"weapon":int(c.weapon),"damage":200,"velocity":Vector2.RIGHT},Vector2(c.x,c.y),0,7)
	mine.falling = bool(c.falling)
	mine.fall_speed = int(c.speed)
	return mine

func run() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/raon_ground_native.json"))
	for c in fixture.cases:
		var terrain = fixture_ground(c)
		var mine := make_mine(c)
		for tick in c.ticks:
			for probe in tick.probes:
				check(terrain.native_surface_at(int(probe[0]),int(probe[1])) == int(probe[2]),"Native column probe matches PE")
			Raon.settle(mine,terrain)
			mine.lost = Raon.outside(mine,terrain)
			var tag := "%s weapon%d tick%d" % [c.name,c.weapon,tick.tick]
			check(int(mine.pos.y) == int(tick.y),tag+" y: got%d want%d" % [mine.pos.y,tick.y])
			check(bool(mine.falling) == bool(tick.falling),tag+" falling")
			check(int(mine.fall_speed) == int(tick.speed),tag+" speed")
			check(bool(mine.lost) == bool(tick.lost),tag+" lost")
	test_snapshot_and_clocks(fixture.cases[1])
	for c in fixture.cases:
		if int(c.weapon) == 2 and c.name == "buried_solid30": test_snapshot_and_clocks(c)
	check(not AdukaWeather.active({"vehicle":7}),"Mine ground consumer does not select native Raon projectile contact")
	finish("RAON GROUND CHECKS")

func test_snapshot_and_clocks(c: Dictionary) -> void:
	var model = Match.new()
	model.start(7,1,42,"","original",null,[],[],[],0,12)
	model.terrain = fixture_ground(c)
	model.mines = [make_mine(c)]
	# No nearby actor or queued move: exercise the shared persistent-effect path.
	for actor in model.actors: actor.pos = Vector2(-500,-500)
	var original: Dictionary = model.mines[0].duplicate(true)
	var sim = Snapshot.capture(model)
	var one = Snapshot.capture(model)
	Raon.step_mines(sim.mines,sim.actors,sim.terrain,0.05)
	check(model.mines[0] == original,"Snapshot mine does not mutate live state")
	Raon.step_mines(model.mines,model.actors,model.terrain,0.025)
	check(model.mines[0].pos == original.pos,"Half tick keeps position before fixed step")
	Raon.step_mines(model.mines,model.actors,model.terrain,0.025)
	check(model.mines == sim.mines,"Split tick equals snapshot step")
	var paused: Array = sim.mines.duplicate(true)
	Raon.step_mines(sim.mines,sim.actors,sim.terrain,0.0)
	check(paused == sim.mines,"Pause preserves flags/debt/position")
	Raon.step_mines(sim.mines,sim.actors,sim.terrain,0.1)
	Raon.step_mines(one.mines,one.actors,one.terrain,0.15)
	check(one.mines == sim.mines,"Resume/batched ticks retain the same clocks")
	var live_native: PackedByteArray = model.terrain.native_cells.duplicate()
	var live_coarse: PackedByteArray = model.terrain.cells.duplicate()
	sim.terrain.carve(Vector2(c.x,c.y),40)
	var crater: PackedByteArray = sim.terrain.native_cells.duplicate()
	sim.terrain.enable_native()
	check(sim.terrain.native_cells == crater,"Repeated preparation cannot restore crater pixels")
	check(model.terrain.native_cells == live_native and model.terrain.cells == live_coarse,"Crater in snapshot preserves both live masks")
	check(crater != live_native,"Crater fixture removed native pixels")
	Raon.settle(sim.mines[0],sim.terrain)
	Raon.settle(model.mines[0],model.terrain)
	check(sim.mines[0].pos != model.mines[0].pos or sim.mines[0].falling != model.mines[0].falling,"Crater changes support only in its snapshot")
