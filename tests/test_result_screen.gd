extends "res://tests/support/suite.gd"
## REQ-50/ADR-139: result window of the client. Expected numbers are written
## from FUN_004c8890/FUN_004d0260/FUN_004b4100 (RESULT_SCREEN_NATIVE.md) and
## the IMG headers, independently of classic_result.gd's constants.

const Result = preload("res://scripts/classic_result.gd")
const PROFILE := "res://.tools/result-port/test-profile.json"

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
		await process_frame

func frames_of(ops: Array) -> Array:
	var result: Array = []
	for op in ops:
		if op[0] == "frame":
			result.append([op[1],op[2]])
	return result

func finish_match(scene, loser: int) -> void:
	scene.opening = 0
	scene.start_match()
	if loser < 0:
		scene.model.actors[0].hp = 0
		scene.model.actors[1].hp = 0
	else:
		scene.model.actors[loser].hp = 0
	scene.model.check_end()
	scene.consume_events()
	scene.show_result()

func window(scene):
	return scene.overlays.layer.find_child("ResultWindow",true,false) if scene.overlays.is_open() else null

func run() -> void:
	# Catalog: native sizes and IMG pivots of result_back.img (resource 9001).
	var probe = Result.new()
	var art = probe.art
	var expected := {"result_back:0":[Vector2(373,381),Vector2(1,2)],"result_back:1":[Vector2(373,383),Vector2(1,0)],
		"result_back:2":[Vector2(308,47),Vector2(-5,0)],"result_back:3":[Vector2(303,47),Vector2(0,0)],
		"result_back:4":[Vector2(44,38),Vector2(-22,-19)],"b_result_confirm:0":[Vector2(103,45),Vector2.ZERO],
		"numfont:81":[Vector2(4,12),Vector2(2,0)],"numfont:102":[Vector2(8,3),Vector2(0,6)],"numfont:104":[Vector2(11,16),Vector2(3,0)]}
	for key in expected:
		check(art.has(key) and art.size(key) == expected[key][0] and art.pivot(key) == expected[key][1],"Native size/pivot of "+key)
	var missing: Array = []
	for frame in range(80,126)+[224,225]:
		if not art.has("numfont:%d" % frame):
			missing.append(frame)
	check(missing.is_empty(),"numfont frames read by FUN_004d0260 are exported: %s" % str(missing))
	check(art.frame_count("b_result_confirm") == 4 and art.frame_count("result_back") == 5,"Button keeps 4 EPA frames, result_back 5")
	check(art.has("font:0") and not art.use_hd and art.texture("result_back:1") == art.native_texture("result_back:1"),"Native frames only, font.fnt atlas present")
	probe.free()

	# Panels: A (24,48), B (403,48); WIN = frame1 for the winning team.
	check(frames_of(Result.layout([[],[]],0)) == [["result_back:1",Vector2(24,48)],["result_back:0",Vector2(403,48)]],"Team A win: WIN left, LOSE right")
	check(frames_of(Result.layout([[],[]],1)) == [["result_back:0",Vector2(24,48)],["result_back:1",Vector2(403,48)]],"Team B win: LOSE left, WIN right")
	check(frames_of(Result.layout([[],[]],-1)) == [["result_back:0",Vector2(24,48)],["result_back:0",Vector2(403,48)]],"Draw (no team byte 0/1): LOSE on both panels")
	check(Result.row_tops(6) == [151,217,283,349] and Result.row_tops(1) == [151],"Rows from y151, step66, stop above414: at most four")

	# One team A row, written from FUN_004d0260 offsets (bx = 52).
	var row := Result.row_ops(0,151,{"name":"testusername","rank":20,"points":120,"gold":4})
	var want := [["frame","result_back:2",Vector2(52,151)],["rank",20,Vector2(93,168)],
		["text","testusername",Vector2(110,181),Color.BLACK],
		["frame","numfont:81",Vector2(306,159)],["frame","numfont:82",Vector2(315,159)],["frame","numfont:80",Vector2(324,159)],
		["frame","numfont:100",Vector2(333,159)],
		["frame","numfont:107",Vector2(311,177)],["frame","numfont:113",Vector2(326,177)]]
	check(row == want,"Team A row: bar, rank, nickname, '120'P and '    4'G at native offsets\n%s" % str(row))
	# Team B (bx = 431): negative P is red (90+) with '-'102 and P101;
	# '%5d' of -12 is '  -12' with the team B minus 225 and digits 114+.
	row = Result.row_ops(1,217,{"name":"CPU","rank":19,"points":-5,"gold":-12})
	want = [["frame","result_back:3",Vector2(431,217)],["rank",19,Vector2(472,234)],
		["text","CPU",Vector2(489,247),Color.BLACK],
		["frame","numfont:102",Vector2(694,225)],["frame","numfont:95",Vector2(703,225)],["frame","numfont:101",Vector2(712,225)],
		["frame","numfont:225",Vector2(658,243)],["frame","numfont:115",Vector2(674,243)],["frame","numfont:116",Vector2(690,243)],
		["frame","numfont:124",Vector2(705,243)]]
	check(row == want,"Team B row: red negative P and team-B gold font\n%s" % str(row))
	# The loops only read the first 3 / 5 printf characters.
	var digits := frames_of(Result.row_ops(0,151,{"points":1234,"gold":123456}))
	check(digits.slice(1,4) == [["numfont:81",Vector2(306,159)],["numfont:82",Vector2(315,159)],["numfont:83",Vector2(324,159)]],"P '%3d' of 1234 draws only '123'")
	check(digits.slice(5,10).map(func(e): return e[0]) == ["numfont:104","numfont:105","numfont:106","numfont:107","numfont:108"],"G '%5d' of 123456 draws only '12345'")
	check(["numfont:224",Vector2(52+195+48,177)] in frames_of(Result.row_ops(0,151,{"gold":-7})),"Team A gold minus is numfont224 ('   -7')")
	var guild := Result.row_ops(0,151,{"name":"n","guild":"test","guild_rank":3332,"guild_total":3333})
	check(guild[2] == ["text","test[3332/3333]",Vector2(110,167),Color(1,0,0)],"Guild line '%s[%3d/%3d]' in RGB565 0xF800 only when present")
	check(Result.row_ops(0,151,{"name":"n"}).filter(func(e): return e[0] == "text").size() == 1,"No guild: only the nickname is written")

	# Scene: the window replaces the old result card. Headless roots are 64×64.
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/result-port"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	scene.profile.nickname = "testusername"
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	finish_match(scene,1)
	await process_frame
	var view = window(scene)
	check(scene.overlays.kind == "result" and view != null,"Finished match opens the native result window")
	check(view != null and view.scale == Vector2(1.6,1.6) and view.position == Vector2.ZERO,"Window keeps the client's 800-wide coordinates ×1.6")
	check(scene.overlays.layer.mouse_filter == Control.MOUSE_FILTER_STOP and scene.overlays.layer.size == Vector2(1280,800),"Transparent full-screen layer blocks the HUD below")
	check(scene.overlays.layer.find_children("*","ColorRect",true,false).is_empty() and scene.overlays.layer.find_children("*","Button",true,false).is_empty(),"No shade and no REVANCHE/menu buttons: only the OK")
	var teams := Result.training_teams(scene.model,scene.profile,scene.reward,scene.gold_reward)
	check(teams[0][0].name == "testusername" and teams[0][0].points == 120 and teams[0][0].gold == scene.gold_reward and teams[1][0].name == "CPU" and teams[1][0].points == 0,"Player on team A with XP as P; CPU on team B scores 0P")
	check(view != null and frames_of(view.ops)[0] == ["result_back:1",Vector2(24,48)],"Player victory draws WIN on the left")
	var ok: TextureButton = view.ok_button if view != null else null
	check(ok != null and ok.get_global_rect().position.is_equal_approx(Vector2(671,441)*1.6) and ok.size == Vector2(103,45),"OK at (671,441), 103×45")
	check(ok != null and ok.texture_normal == view.art.texture("b_result_confirm:0") and ok.texture_hover == view.art.texture("b_result_confirm:1") and ok.texture_pressed == view.art.texture("b_result_confirm:2") and ok.texture_disabled == view.art.texture("b_result_confirm:3"),"OK uses EPA ready0/mouse1/push2/disable3")
	scene.show_result()
	scene.show_result()
	check(scene.profile.xp == 120,"Reopening the result cannot duplicate the reward")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_key_input(escape)
	check(scene.overlays.kind == "result","ESC does not close the result window")
	scene.show_help()
	scene.close_overlay()
	check(scene.overlays.kind == "result" and window(scene) != null,"Closing help after the match restores the result window")
	await process_frame
	await click(window(scene).ok_button.get_global_rect().get_center())
	await process_frame
	check(scene.screen == "menu" and scene.model.phase == "menu","OK returns to the room")
	finish_match(scene,0)
	view = window(scene)
	check(view != null and frames_of(view.ops)[0] == ["result_back:0",Vector2(24,48)] and frames_of(view.ops).filter(func(e): return e[0] == "result_back:1") == [["result_back:1",Vector2(403,48)]],"CPU victory: LOSE left, WIN right")
	finish_match(scene,-1)
	view = window(scene)
	check(view != null and frames_of(view.ops).filter(func(e): return e[0] == "result_back:1").is_empty(),"Draw: no WIN panel")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	finish("RESULT SCREEN CHECKS")
