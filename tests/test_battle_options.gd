extends "res://tests/support/suite.gd"
## ADR-137: independent native geometry/levels and single offline battle menu.

func key(scene, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	scene._unhandled_key_input(event)

func click(point: Vector2) -> void:
	root.size=Vector2i(1280,800)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position=point
		event.global_position=point
		root.push_input(event)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/battle-menu"))
	for path in ["res://.tools/battle-menu/test-profile.json","res://.tools/battle-menu/test-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/battle-menu/test-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.opening = 0
	scene.start_match()
	key(scene, KEY_ESCAPE)
	var popup = scene.overlays.options_popup
	check(popup.size.is_equal_approx(Vector2(276,408)*1.6), "Native panel keeps276x408, without masking embedded labels")
	check(popup.position.is_equal_approx(Vector2(8,45)*1.6), "Native battle menu is anchored at8,45")
	key(scene, KEY_P)
	check(scene.overlays.kind == "options" and scene.overlays.options_popup == popup, "P cannot replace native options with a second pause menu")
	scene.close_overlay()
	scene.show_pause()
	check(scene.overlays.kind == "options", "Legacy pause API resolves to the same native menu")
	# Same snapshot survives repeated P/Options calls. Native geometry is absolute.
	popup = scene.overlays.options_popup
	check(popup.accept_button.position.is_equal_approx(Vector2(179,363)*1.6) and popup.accept_button.size.is_equal_approx(Vector2(74,26)*1.6), "OK native187,408 and74x26")
	check(popup.cancel_button.position.is_equal_approx(Vector2(240,8)*1.6) and popup.cancel_button.size.is_equal_approx(Vector2(22,20)*1.6), "X native248,53 and22x20")
	check(popup.quit_button.position.is_equal_approx(Vector2(19,363)*1.6) and popup.quit_button.size.is_equal_approx(Vector2(74,26)*1.6), "QUIT native27,408 and74x26")
	check(popup.get_child_count()==6, "Only three native buttons and three unsupported-control regions; no PAUSA/skin/custom labels")
	# Render branch4c9ef9..4c9f15 uses integer division, not exact matching.
	for sample in [[19,-1],[20,0],[29,0],[30,1],[55,3],[70,5],[79,5],[80,-1],[100,-1]]:
		scene.options.scroll=sample[0]
		check(popup.selection_index("scroll")==sample[1] and scene.options.scroll==sample[0], "Legacy scroll%d draws native slot%d without rewriting profile"%[sample[0],sample[1]])
	scene.options.scroll=50
	var before: Dictionary = scene.model.actors[0].duplicate(true)
	var clock: float = scene.model.turn_time
	for frame in 10:
		scene._process(0.1)
	check(scene.model.actors[0]==before and scene.model.turn_time==clock, "Offline menu freezes actors and turn clock")

	# Fixed source input vectors from4b9f64..4ba56b, never the production tables.
	for group in [["scroll",[20,30,40,50,60,70],[[52,174],[85,174],[125,174],[165,174],[205,174],[245,174]]],
		["bgm",[0,80,90,95,98,100],[[100,254],[125,254],[155,254],[185,254],[215,254],[240,254]]],
		["sfx",[0,80,90,95,98,100],[[100,280],[125,280],[155,280],[185,280],[215,280],[240,280]]]]:
		for index in 6:
			popup.pointer_down((Vector2(group[2][index][0],group[2][index][1])-Vector2(8,45))*1.6)
			check(scene.options.get(group[0])==group[1][index], "%s click%d selects native level%d"%[group[0],index,group[1][index]])
	check(scene.sound.volume==1.0 and scene.sound.music_volume==1.0, "Native levels update both audio backends immediately")
	# DirectSound SetVolume callers4eeb10/4eeb30: (value-100)*100 hundredths dB.
	# Fixed independently computed amplitude vectors, not production helpers.
	for sample in [[0,0.0],[1,0.00001122018454301963],[19,0.00008912509381337459],[50,0.0031622776601683794],[80,0.1],[90,0.31622776601683794],[95,0.5623413251903491],[98,0.7943282347242815],[100,1.0]]:
		scene.options.sfx=sample[0]
		scene.options.bgm=sample[0]
		scene.apply_options()
		check(is_equal_approx(scene.sound.volume,sample[1]) and is_equal_approx(scene.sound.music_volume,sample[1]), "Native attenuation for value%d"%sample[0])
		if sample[0]>0:
			check(is_equal_approx(scene.sound.players[0].volume_db,-19.0+sample[0]-100.0) and is_equal_approx(scene.sound.music.volume_db,-19.0+sample[0]-100.0), "Godot preserves native relative dB with existing master gain")
	# Native zero stops already playing effect buffers, not only future calls.
	var voice: AudioStreamPlayer=scene.sound.players[0]
	voice.stream=scene.sound.synthesize("fire")
	voice.play()
	check(voice.playing,"Active effect fixture starts in headless dummy audio")
	scene.options.sfx=0
	scene.apply_options()
	check(not voice.playing,"Native EFFECT0 stops a currently playing effect")
	# Strict boundaries, including holes between adjacent bins.
	for point in [Vector2(39,174),Vector2(65,174),Vector2(105,174),Vector2(145,174),Vector2(185,174),Vector2(225,174),Vector2(265,174),Vector2(52,168),Vector2(52,180)]:
		scene.options.scroll=50
		popup.pointer_down((point-Vector2(8,45))*1.6)
		check(scene.options.scroll==50, "Scroll excludes native boundary"+str(point))
	for point in [Vector2(89,254),Vector2(110,254),Vector2(140,254),Vector2(170,254),Vector2(200,254),Vector2(230,254),Vector2(251,254),Vector2(100,248),Vector2(100,260)]:
		scene.options.bgm=50
		popup.pointer_down((point-Vector2(8,45))*1.6)
		check(scene.options.bgm==50, "BGM excludes native boundary"+str(point))
	popup.pointer_down((Vector2(40,120)-Vector2(8,45))*1.6)
	check(scene.options.aiming==0, "Native shooting2 maps to existing Drag0")
	popup.pointer_down((Vector2(130,120)-Vector2(8,45))*1.6)
	check(scene.options.aiming==1, "Native shooting0 maps to existing Slice1")
	popup.pointer_down((Vector2(220,120)-Vector2(8,45))*1.6)
	check(scene.options.aiming==1, "Sniper cannot silently change the existing shot model")
	popup.pointer_down((Vector2(240,380)-Vector2(8,45))*1.6)
	check(not scene.options.background, "Native OFF changes backdrop")
	popup.pointer_down((Vector2(40,380)-Vector2(8,45))*1.6)
	check(scene.options.background, "Native ON restores backdrop")
	var motion := InputEventMouseMotion.new()
	motion.position=Vector2(300,300)
	motion.relative=Vector2(60,20)
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	popup._gui_input(motion)
	check(popup.position.is_equal_approx(Vector2(8,45)*1.6), "Mouse movement never drags native menu")
	var snapshot: Dictionary = popup.snapshot.duplicate()
	scene.options.sfx=0
	scene.options.scroll=70
	scene.apply_options()
	key(scene,KEY_ESCAPE)
	check(not scene.paused and scene.overlays.layer==null and scene.options.sfx==snapshot.sfx and scene.options.scroll==snapshot.scroll, "ESC cancels changes and resumes")
	check(is_equal_approx(scene.sound.volume,0.0 if snapshot.sfx==0 else pow(10.0,(snapshot.sfx-100.0)/20.0)), "Cancel restores SFX backend too")

	# Real viewport clicks use the same native bounds and buttons.
	scene.show_options()
	popup=scene.overlays.options_popup
	click(Vector2(125,280)*1.6)
	check(scene.options.sfx==80 and is_equal_approx(scene.sound.volume,0.1), "Real click selects EFFECT80")
	click(Vector2(1200,350))
	check(scene.paused and scene.overlays.options_popup==popup and not scene.aim.charging, "Outside click blocks world/HUD and leaves menu open")
	click(Vector2(220,420)*1.6)
	check(not scene.paused and scene.overlays.layer==null, "Real OK click accepts native menu")
	var saved=load("res://scripts/options.gd").new(scene.options.path)
	saved.load_options()
	check(saved.sfx==80, "OK persists selected setting")
	scene.show_options()
	click(Vector2(100,280)*1.6)
	click(Vector2(255,60)*1.6)
	check(scene.options.sfx==80 and not scene.paused and is_equal_approx(scene.sound.volume,0.1), "Real X cancels live EFFECT0 and restores80")
	saved.load_options()
	check(saved.sfx==80, "Cancelled edits never replace persisted options")
	# Native fallback remains native as a group under any catalog failure.
	var Client=load("res://scripts/client_hud_assets.gd")
	var Art=load("res://scripts/classic_battle_options_art.gd")
	var active=Art.new()
	check(not active.using_fallback, "Valid menu selects the active native group")
	for mutation in ["missing","size","hash","path","catalog"]:
		var client=Client.new() if mutation!="catalog" else Client.new("res://.tools/battle-menu/no-catalog.json")
		match mutation:
			"missing": client.files.erase("NativeOptionOK.png")
			"size": client.files["NativeOptionsPanel.png"].size=[300,300]
			"hash": client.files["NativeOptionRadio.png"].rgba_sha256="invalid"
			"path": client.files["NativeOptionQuit.png"].file="res://bad.png"
		var fallback=Art.new(client)
		check(fallback.using_fallback, mutation+" rejects active group")
		for name in active.textures:
			check(fallback.textures[name]!=null and fallback.textures[name].resource_path.begins_with("res://assets/xfs/hud_options_fallback/"), mutation+" native fallback:"+name)
			check(fallback.textures[name].get_image().get_data()==active.textures[name].get_image().get_data(), mutation+" fallback exact native pixels:"+name)
	var xp: int = scene.profile.xp
	var gold: int = scene.profile.gold
	scene.show_options()
	scene.overlays.options_popup.select_radio("sfx",0)
	click(Vector2(60,420)*1.6)
	check(scene.screen=="menu" and scene.model.phase=="menu" and not scene.paused, "Native QUIT leaves training and returns to room")
	check(scene.profile.xp==xp and scene.profile.gold==gold and scene.options.sfx==80, "Abandoning does not reward XP/Gold or commit edits")
	scene.show_menu()
	scene.queue_free()
	await process_frame
	for path in ["res://.tools/battle-menu/test-profile.json","res://.tools/battle-menu/test-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("BATTLE OPTIONS CHECKS")
