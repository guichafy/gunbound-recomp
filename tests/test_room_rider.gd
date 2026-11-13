extends "res://tests/support/suite.gd"
## Regression: room/loading must send the CPU's default equipment through the
## same assembled-avatar path as battle, including Random. Drawing is recorded
## at the renderer boundary because headless canvases cannot expose GPU pixels.
const Looks = preload("res://scripts/mobile_looks.gd")
const Choice = preload("res://scripts/room_choice.gd")
const PROFILE := "res://.tools/room-rider/test-profile.json"
class Recorder extends RefCounted:
	var requests: Array = []
	func frame_index(_pose, _age, _weapon, _low): return 0
	func draw(_canvas, request): requests.append(request)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE.get_base_dir()))
	for path in [PROFILE, PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	var saved: Dictionary = scene.sprites.duplicate()
	var saved_random = scene.room_random_sprite
	var recorder := Recorder.new()
	for id in Looks.ids(): scene.sprites[id] = recorder
	scene.room_random_sprite = recorder
	var defaults: Dictionary = scene.profile.catalog.defaults(0)
	for gender in [0, 1]:
		scene.profile.gender = gender
		# Use a non-default owned head to distinguish A from CPU.
		var equipment: Dictionary = scene.profile.catalog.defaults(gender)
		equipment["0"] = scene.profile.catalog.key_for(gender, 0, 1)
		scene.profile.equipped[str(gender)] = equipment
		for screen in ["menu", "loading"]:
			scene.screen = screen
			for id in Looks.ids() + [Choice.RANDOM]:
				scene.vehicle = id
				scene.cpu_vehicle = id
				scene.player_random = id == Choice.RANDOM
				scene.cpu_random = id == Choice.RANDOM
				scene.loading_player = 2 if id == Choice.RANDOM else id
				scene.loading_cpu = 2 if id == Choice.RANDOM else id
				scene.elapsed = 0.35
				recorder.requests.clear()
				scene.draw_room_figures(scene.menu.figures)
				check(recorder.requests.size() == 2, "Both room slots drawn")
				var a = recorder.requests[0]
				var b = recorder.requests[1]
				check(a.avatar_context.get("equipment", {}) == equipment, "A keeps equipped set %s/%d" % [screen,id])
				check(b.avatar_context.get("equipment", {}) == defaults, "B uses battle default composition %s/%d" % [screen,id])
				check(b.avatar_context.get("age", -1) == scene.elapsed, "B uses paused scene clock")
				check(a.pos == scene.menu.player_anchor.round() and b.pos == scene.menu.cpu_anchor.round(), "Slot anchors unchanged")
				var actual_id: int = 2 if screen == "loading" and id == Choice.RANDOM else id
				var direction := int(Looks.look(actual_id).get("room_facing", 1))
				check(a.facing == direction and b.facing == -direction, "Room facing preserved")
	scene.sprites = saved
	scene.room_random_sprite = saved_random
	scene.screen = "menu"
	scene.select_vehicle(2)
	scene.select_cpu_vehicle(3)
	scene.opening = 0
	scene.start_match()
	check(scene.actor_avatars[0] == scene.profile.equipped_set() and scene.actor_avatars[1] == defaults, "Battle equipment contract unchanged")
	var playbacks := audio_playbacks(scene.sound)
	scene.free()
	await await_audio_release(playbacks)
	for path in [PROFILE, PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("ROOM RIDER CHECKS")
