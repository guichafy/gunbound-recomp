extends SceneTree
## Feed independent PE operands into the project's shared damage consumer.
## The launched-shell producer, geometry, attachment and child timing are out of this comparison.

const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Usage: godot --headless --script tests/tools/shot_damage_audit/bridge_probe.gd -- /path/native.json /path/bridge.json")
		quit(2)
		return
	var native = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not native is Dictionary or native.get("schema") != 1:
		printerr("Invalid native matrix")
		quit(2)
		return
	# The shared consumer normally warms on Match initialization.
	var model = Match.new()
	model.start(4, 1, 42, "", "original")
	var initialized := {}
	for entry in native.initializers:
		initialized[Vector3i(int(entry.shooter), int(entry.weapon), int(entry.attack))] = entry
	var counts := {}
	var per_shot := {}
	var examples := []
	var amount_mismatch := 0
	var state_mismatch := 0
	var knight_mismatch := 0
	for row in native.damage.rows:
		var shooter := int(row[0])
		var weapon := int(row[1])
		var target := int(row[2])
		var entry: Dictionary = initialized[Vector3i(shooter, weapon, int(row[3]))]
		var material := int(row[8])
		var actor := {"vehicle": target, "pos": Vector2(200, 200), "tilt": 0.0,
			"attributes": [0, 0, int(row[4]), 0, 0, 0, 0, 0], "native_protection": bool(row[14]),
			"hp": int(row[10]), "shield": int(row[9])}
		var point := Shared.center(actor) - Vector2i(int(row[6]), int(row[7]))
		var data := {"power": int(entry.power[material]), "dimension": int(entry.dimension[material]),
			"aspect": int(entry.aspect[material]), "flags": int(entry.flags), "weather_bonus": int(row[5])}
		var subject := "%d:%d" % [shooter, weapon]
		var stat: Dictionary = per_shot.get(subject, {"rows": 0, "different_amount": 0, "different_hp_shield": 0})
		stat.rows += 1
		var expected_amount := maxi(0, int(row[11]))
		var reported := Shared.apply([actor], [], point, data)
		if reported != expected_amount:
			amount_mismatch += 1
			stat.different_amount += 1
			if target == 15:
				knight_mismatch += 1
		if int(actor.hp) != int(row[12]) or int(actor.shield) != int(row[13]):
			state_mismatch += 1
			stat.different_hp_shield += 1
		if reported != expected_amount or int(actor.hp) != int(row[12]) or int(actor.shield) != int(row[13]):
			var bucket := str(target)
			counts[bucket] = int(counts.get(bucket, 0)) + 1
			if examples.size() < 12 and not examples.any(func(example): return int(example.target) == target):
				examples.append({"shooter": shooter, "weapon": weapon, "target": target,
					"attack": int(row[3]), "defense": int(row[4]), "force": int(row[5]),
					"dx": int(row[6]), "dy": int(row[7]), "expected": expected_amount, "reported": reported,
					"expected_hp": int(row[12]), "hp": int(actor.hp), "expected_shield": int(row[13]), "shield": int(actor.shield)})
		per_shot[subject] = stat
	var report := {"schema": 1, "rows": native.damage.rows.size(), "amount_mismatch": amount_mismatch,
		"state_mismatch": state_mismatch, "knight_amount_mismatch": knight_mismatch,
		"mismatch_per_target": counts, "per_shot": per_shot, "examples": examples}
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	if output == null:
		printerr("Cannot write bridge results")
		quit(2)
		return
	output.store_string(JSON.stringify(report, "  ", true) + "\n")
	output.close()
	print("Bridge comparisons: %d | amount differs: %d | HP/shield differs: %d" % [
		native.damage.rows.size(), amount_mismatch, state_mismatch])
	quit()
