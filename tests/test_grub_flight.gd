extends "res://tests/support/suite.gd"
## Grub T2 / SS native flight (0x49fd40, 0x486ea0, sweeps 0x49e650 / 0x4857f0):
## every recorded tick comes from running the PE routine in an x86 emulator over
## the same mask (tests/tools/grub_oracle), not from this port.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Flight = preload("res://scripts/grub_flight.gd")

func terrain_from(rows: Array, w: int, h: int) -> PackedByteArray:
	var cells := PackedByteArray()
	cells.resize(w * h)
	for y in h:
		var x := 0
		for run in rows[y]:
			if int(run[0]) != 0:
				for i in int(run[1]):
					cells[y * w + x + i] = 1
			x += int(run[1])
	return cells

func run() -> void:
	Physics.warmup()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/grub_flight_native.json"))
	var masks := {}
	var ticks := 0
	var explosions := 0
	var ricochets := 0
	for scenario in data.scenarios:
		var w := int(scenario.size[0])
		var h := int(scenario.size[1])
		var key := str(int(scenario.seed))
		if not masks.has(key):
			masks[key] = terrain_from(data.terrain[key], w, h)
		var cells: PackedByteArray = masks[key]
		var boxes: Array = scenario.mobiles
		var hit_mobile := func(x: int, y: int) -> bool:
			for box in boxes:
				if x >= int(box[0]) and x <= int(box[2]) and y >= int(box[1]) and y <= int(box[3]):
					return true
			return false
		var init: Dictionary = scenario.init
		var shell := {"fp_pos": Vector2i(int(init.x), int(init.y)), "fp_velocity": Vector2i(int(init.vx), int(init.vy)), "fp_acceleration": Vector2i(int(init.ax), int(init.ay))}
		var kind := int(scenario.kind)
		Flight.begin(shell, kind)
		shell.g_int = Vector2i(int(init.ix), int(init.iy))
		check(int(shell.g_speed) == int(init.speed) and int(shell.g_ctr) == int(init.ctr), "scenario speed cell and counter start equal the spawner's (kind %d)" % kind)
		var tag := "kind %d seed %d shot (%d,%d)@%d/%d" % [kind, int(scenario.seed), int(scenario.shot.x), int(scenario.shot.y), int(scenario.shot.angle), int(scenario.shot.power)]
		for index in scenario.ticks.size():
			var row: Array = scenario.ticks[index].s
			var outcome := Flight.tick(shell, cells, w, h, hit_mobile)
			ticks += 1
			var last: bool = index == scenario.ticks.size() - 1
			if outcome.event == "explode":
				explosions += 1
				check(last and bool(scenario.ticks[index].blast), "%s tick %d: PE detonates here" % [tag, index])
				check(Vector2i(shell.fp_pos) == Vector2i(int(row[0]), int(row[1])) and Vector2i(outcome.position) == Vector2i(int(row[4]), int(row[5])), "%s tick %d: detonation position fp=(%d,%d) int=(%d,%d), PE (%d,%d)/(%d,%d)" % [tag, index, shell.fp_pos.x, shell.fp_pos.y, outcome.position.x, outcome.position.y, int(row[0]), int(row[1]), int(row[4]), int(row[5])])
				break
			if bool(outcome.ricochet):
				ricochets += 1
			Flight.finish_frame(shell)
			var got := [shell.fp_pos.x, shell.fp_pos.y, shell.fp_velocity.x, shell.fp_velocity.y, shell.g_int.x, shell.g_int.y, shell.g_ctr]
			var want := [int(row[0]), int(row[1]), int(row[2]), int(row[3]), int(row[4]), int(row[5]), int(row[6])]
			check(got == want, "%s tick %d: got %s, PE %s" % [tag, index, str(got), str(want)])
			if got != want:
				break
			if outcome.event == "oob":
				check(last and int(row[8]) == 1, "%s tick %d: out-of-map flag" % [tag, index])
				break
			check(not (last and int(scenario.ticks[index].blast)), "%s tick %d: PE detonated but the port kept flying" % [tag, index])
	print("ticks ", ticks, " ricochets ", ricochets, " detonations ", explosions)
	finish("GRUB FLIGHT CHECKS")
