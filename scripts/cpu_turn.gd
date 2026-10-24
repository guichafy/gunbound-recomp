extends RefCounted
## CPU turn in the scene (REQ-32, ADR-053/070): starts the aim search on a
## worker thread over a snapshot, waits the presentation delay, then fires.
## The plan only appears when the search is done and the wait is over.

const Match = preload("res://scripts/match.gd")
# Pause before the CPU acts on a new turn, and between choosing and firing.
const TURN_WAIT := 1.1
const CHARGE_WAIT := 0.75

var plan: Dictionary = {}
var search: Dictionary = {}
var task := -1
var wait := 0.0

## The CPU has chosen its shot and is charging it on screen.
func charging(model) -> bool:
	return model.phase == Match.PHASE_AIM and model.active == Match.CPU and not plan.is_empty()

## Weapon shown for the CPU: the chosen plan, else `fallback`.
func weapon(fallback: int = 0) -> int:
	return int(plan.get("weapon", fallback))

func begin_turn() -> void:
	plan.clear()
	discard()
	wait = TURN_WAIT

func tick(model, delta: float) -> void:
	if model.phase != Match.PHASE_AIM or model.active != Match.CPU:
		return
	if plan.is_empty() and search.is_empty():
		start(model)
	wait -= delta
	if wait > 0.0:
		return
	if plan.is_empty():
		if WorkerThreadPool.is_task_completed(task):
			WorkerThreadPool.wait_for_task_completion(task)
			task = -1
			plan = model.finish_cpu_plan(search)
			search = {}
			wait = CHARGE_WAIT
	else:
		model.fire(plan.angle, plan.power, plan.weapon)
		plan.clear()

func start(model) -> void:
	search = model.begin_cpu_plan()
	var pending := search
	task = WorkerThreadPool.add_task(func(): Match.search_cpu_plan(pending), false, "CPU aim search")

## A running search only reads its own snapshot; wait for it before dropping it.
func discard() -> void:
	if task >= 0:
		WorkerThreadPool.wait_for_task_completion(task)
		task = -1
	search = {}

func reset() -> void:
	plan.clear()
	discard()
