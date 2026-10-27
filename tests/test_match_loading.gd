extends "res://tests/support/suite.gd"

const Loading = preload("res://scripts/match_loading.gd")
const Maps = preload("res://scripts/maps.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Choice = preload("res://scripts/room_choice.gd")
const PROFILE := "res://.tools/match-loading/profile.json"

func run() -> void:
	var x := 148 * Loading.PREVIEW_W / 1800
	check(x == 61 and Loading.column(148, 1800) == x, "Preview column is spawn_x * 748 / map width, truncated")
	check(Loading.column(1673, 1800) == 1673 * 748 / 1800, "Right-side Miramo spawn stays inside the 748 px preview")
	var rows := PackedInt32Array()
	rows.resize(Loading.PREVIEW_W)
	rows.fill(Loading.MASK_H)
	rows[61] = 40
	check(Loading.point(148, 1800, rows) == Vector2(61, 40 + Loading.LABEL_DROP), "Name sits 18 px under the first solid mask pixel")
	check(Loading.point(148, 1800, PackedInt32Array()) == Vector2(61, Loading.EMPTY_MASK_Y), "A missing mask uses the client fallback y=122")
	var catalog_rows := Loading.ground_rows()
	check(catalog_rows.size() == 748 and catalog_rows[61] == 152 and catalog_rows[374] == 128 and catalog_rows[695] == 141, "Miramo mask rows match the extracted load_stage01 scan")
	var rng := RandomNumberGenerator.new()
	var mirror := RandomNumberGenerator.new()
	rng.seed = 42
	mirror.seed = 42
	var map: Dictionary = Maps.get_map(Maps.DEFAULT)
	var rolled: Array = Loading.roll_spawns(rng, map, 1800.0)
	var left: Array = Maps.spawn_points(map, true, 1800.0)
	var right: Array = Maps.spawn_points(map, false, 1800.0)
	var expect_left: Vector2 = left[mirror.randi_range(0, left.size() - 1)]
	var expect_right: Vector2 = right[mirror.randi_range(0, right.size() - 1)]
	check(rolled[0] == expect_left and rolled[1] == expect_right and rng.state == mirror.state, "1×1 spawns use one draw per side, player then CPU")
	check(float(rolled[0].x) < 900.0 and float(rolled[1].x) >= 900.0, "Player spawn stays on the left half and CPU on the right")

	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.opening = 0
	scene.show_menu()
	scene.profile.nickname = "Piloto"
	scene.select_vehicle(1)
	scene.select_cpu_vehicle(4)
	scene.start_match()
	check(scene.screen == "match" and int(scene.model.actors[0].vehicle) == 1 and int(scene.model.actors[1].vehicle) == 4, "Direct start_match still enters combat immediately")
	scene.show_menu()
	scene.opening = 0
	scene.select_vehicle(Choice.RANDOM)
	scene.select_cpu_vehicle(4)
	var before: int = scene.room_rng.state
	scene.menu.stage.get_node("Start").pressed.emit()
	check(scene.screen == "loading" and scene.loading_player in [14, 15] and scene.loading_cpu == 4, "Room Start resolves Random before the match and keeps the CPU pick")
	check(scene.room_rng.state != before, "Random and the two spawn draws happen when the loading screen opens")
	check(scene.menu.loading_title.visible and scene.menu.loading_title.text == str(Mobiles.definition(scene.loading_player).name), "The center card names the rolled mobile")
	check(scene.menu.loading_title.text != "Random" and scene.menu.map_preview.visible and scene.menu.map_preview.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "The center window shows the rolled mobile at its own aspect")
	check(scene.menu.cpu_mobile.visible and scene.menu.cpu_mobile.text == "Armor" and scene.menu.player_mobile.text == scene.menu.loading_title.text, "Both slots name the mobiles that will play")
	var view = scene.menu.stage.get_node("MatchLoading")
	check(view != null and view.get_node("SpawnName0").text == "Piloto" and view.get_node("SpawnName1").text == "CPU", "The map preview labels the player and the CPU")
	var player_spawn := Vector2(scene.loading_spawns[0])
	var cpu_spawn := Vector2(scene.loading_spawns[1])
	var player_mark: Vector2 = Loading.point(int(player_spawn.x), scene.loading_width, catalog_rows)
	var cpu_mark: Vector2 = Loading.point(int(cpu_spawn.x), scene.loading_width, catalog_rows)
	var font: Font = load("res://assets/classic/room/settings/room_text.fnt")
	var player_width := font.get_string_size("Piloto", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	check(is_equal_approx(view.get_node("SpawnName0").position.x, 26 + player_mark.x - player_width * 0.5), "Player name is centered on the mask column")
	check(is_equal_approx(view.get_node("SpawnName1").position.y, 374 + cpu_mark.y), "CPU name uses the mask row plus the 18 px drop")
	var rolled_player: int = scene.loading_player
	var rolled_cpu: int = scene.loading_cpu
	scene.loading_elapsed = 0.0
	scene._process(4.9)
	check(scene.screen == "loading" and view.progress < 1.0, "The screen stays up until the 5 second minimum")
	scene._process(0.2)
	check(scene.screen == "match", "The match starts once the minimum time has elapsed")
	check(int(scene.model.actors[0].vehicle) == rolled_player and int(scene.model.actors[1].vehicle) == rolled_cpu, "Combat uses the mobiles shown on the loading screen")
	check(is_equal_approx(float(scene.model.actors[0].pos.x), player_spawn.x) and is_equal_approx(float(scene.model.actors[1].pos.x), cpu_spawn.x), "Combat spawns are the points marked on the preview")
	check(scene.player_random and not scene.cpu_random, "Leaving for the match does not clear the room's Random choice")
	scene.free()
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("MATCH LOADING CHECKS")
