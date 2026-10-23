extends "res://tests/support/suite.gd"
## REQ-32: the CPU aim search runs on a worker thread over a snapshot, gives the
## same plan as the one-shot search and never blocks the battle frame.


## Player vehicle 2 → CPU Mage; player vehicle 1 → CPU Bigfoot (bomb salvos).
func cpu_model(seed_value: int, vehicle: int = 2, special: bool = false):
	var model = load("res://scripts/match.gd").new()
	model.start(vehicle, 1, seed_value)
	if model.active == 0:
		model.pass_turn()
	if special:
		model.actors[model.active].turns = 3
	return model

func run() -> void:
	var Match = load("res://scripts/match.gd")
	# Same plan: one-shot, split steps and a worker thread from the same RNG state.
	var cases := [[3, 2, false], [17, 2, true], [42, 1, false], [8, 1, true], [23, 1, true]]
	var weapons := {}
	for entry in cases:
		var seed_value: int = entry[0]
		var model = cpu_model(seed_value, entry[1], entry[2])
		var state: int = model.rng.state
		var direct: Dictionary = model.choose_cpu_shot()
		model.rng.state = state
		var plan: Dictionary = model.begin_cpu_plan()
		Match.search_cpu_plan(plan)
		var split: Dictionary = model.finish_cpu_plan(plan)
		model.rng.state = state
		var threaded_plan: Dictionary = model.begin_cpu_plan()
		var task := WorkerThreadPool.add_task(func(): Match.search_cpu_plan(threaded_plan))
		WorkerThreadPool.wait_for_task_completion(task)
		var threaded: Dictionary = model.finish_cpu_plan(threaded_plan)
		weapons["%d-%d" % [model.actors[model.active].vehicle, direct.weapon]] = true
		check(direct == split and direct == threaded, "CPU %s seed %d: split and threaded searches give the one-shot plan %s" % [Match.VEHICLES[model.actors[model.active].vehicle].name, seed_value, direct])
		check(threaded_plan.snapshot == null, "Finishing a plan releases its snapshot")

	check(weapons.has("2-2") or weapons.has("2-1"), "A CPU Bigfoot salvo plan is covered (%s)" % [weapons.keys()])
	print("CPU plans covered (vehicle-weapon): ", weapons.keys())

	# The search reads only its snapshot: later changes to the live match do not leak in.
	var live = cpu_model(5)
	var live_state: int = live.rng.state
	var expected: Dictionary = live.choose_cpu_shot()
	live.rng.state = live_state
	var isolated: Dictionary = live.begin_cpu_plan()
	var target_before: Vector2 = live.actors[1 - live.active].pos
	live.actors[1 - live.active].pos += Vector2(300, 0)
	live.wind = Vector2(35, 0)
	Match.search_cpu_plan(isolated)
	live.actors[1 - live.active].pos = target_before
	check(live.finish_cpu_plan(isolated) == expected, "The snapshot isolates the search from the live match")

	# Scene: the CPU turn starts the worker; a frame stays far below the old 90–314 ms.
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/performance-test-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.select_vehicle(2)
	scene.opening = 0
	scene.start_match()
	if scene.model.active == 0:
		scene.model.pass_turn()
		scene.consume_events()
	var worst := 0
	var fired := false
	var started_at := Time.get_ticks_msec()
	var first_task := -2
	for frame in range(600):
		var before := Time.get_ticks_usec()
		scene._process(1.0 / 60.0)
		worst = maxi(worst, Time.get_ticks_usec() - before)
		if first_task == -2:
			first_task = scene.cpu.task
			check(first_task >= 0 and scene.cpu.plan.is_empty(), "The CPU turn starts the search on a worker thread")
		if scene.model.phase != "aim" or scene.model.active != 1:
			fired = true
			break
		OS.delay_msec(4)
	check(fired, "The CPU still fires after the threaded search")
	check(worst < 40000, "No battle frame runs the CPU search (worst %.1f ms)" % (worst / 1000.0))
	check(scene.cpu.task == -1 and scene.cpu.search.is_empty(), "The finished search is collected")
	check(Time.get_ticks_msec() - started_at < 15000, "The CPU fires well before the turn timer")

	# Restarting during a search waits for the worker and drops it.
	scene.opening = 0
	scene.start_match()
	if scene.model.active == 0:
		scene.model.pass_turn()
		scene.consume_events()
	scene._process(1.0 / 60.0)
	check(scene.cpu.task >= 0, "A new CPU turn starts a new search")
	scene.opening = 0
	scene.start_match()
	check(scene.cpu.task == -1 and scene.cpu.search.is_empty() and scene.cpu.plan.is_empty(), "Restarting drops a running search safely")
	scene.show_menu()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/performance-test-profile.json"))
	report("PERFORMANCE CHECKS")
	scene.queue_free()
	quit(exit_code())
