extends "res://tests/support/suite.gd"
const Hud = preload("res://scripts/hud_art.gd")
const Layout = preload("res://scripts/battle_hud_layout.gd")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/jewel-hud-review"))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/jewel-hud-review/test-profile.json")
	scene.sound = load("res://scripts/sound.gd").new()
	scene.sound.muted = true
	root.add_child(scene)
	scene.set_process(false)
	scene.room_mode = "jewel"
	scene.opening = 0
	scene.start_match()
	var hud = scene.hud
	check(hud.has_method("jewel_panel_sample"), "JEWEL exposes the actual footer draw geometry")
	if hud.has_method("jewel_panel_sample"):
		for local_team in 2:
			scene.model.jewel_state.teams = [local_team,1-local_team]
			for score in [0,5,10,75,99,100,124]:
				scene.model.jewel_state.scores = [score,25]
				var sample: Dictionary = hud.jewel_panel_sample(scene.model)
				check(sample.texture == ["NativeJewelPanel.png","NativeJewelPanelB.png"][local_team], "Native panel follows local team")
				check(sample.rect.is_equal_approx(Rect2(1064,721.6,216,78.4)), "Native665,551 minus100 and uniform1.6 fit")
				check(not sample.rect.intersects(Layout.HEADER) and not sample.rect.intersects(Layout.STRENGTH), "Score does not cover header or charge")
				check(sample.rect.end.is_equal_approx(Vector2(1280,800)), "Panel is flush with bottom right without clipping")
				for layer in sample.layers:
					check(sample.rect.encloses(layer.box), "Every registered score glyph fits the panel")
					check(layer.box.size.is_equal_approx(layer.source.size*1.6), "Glyphs keep native aspect and global scale only")
					check(is_equal_approx(layer.anchor.y,750.4), "Digits use native569 minus100")
					var column: int = 0 if layer.team==local_team else 1
					var base: int = 692+column*57
					var expected := []
					if int(layer.value)>=10: expected.append(float(base)*1.6)
					expected.append(float(base+20)*1.6)
					if int(layer.value)>=100: expected.append(float(base-(8 if column==0 else 7))*1.6)
					check(expected.any(func(x): return is_equal_approx(x,layer.anchor.x)), "Native20px advance and narrow hundreds marker")
				check(sample.layers.size()==(3 if score>=100 else (2 if score>=10 else 1))+2, "Each score emits its visible native digits")
	# The panel begins5nativepx above the footer. That painted area must not
	# accept a shot, camera pan or waiting-pilot return selection.
	scene.model.jewel_state.teams=[0,1]
	scene.options.aiming=0
	var at := Vector2(1100,725)
	for button in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		scene.dragging=false
		var event := InputEventMouseButton.new()
		event.position=at
		event.button_index=button
		event.pressed=true
		scene._unhandled_input(event)
		check(not scene.aim.charging and not scene.dragging,"Score overhang blocks Drag/pan")
		scene.aim.charging=false
	scene.model.actors[0].jewel_waiting=true
	scene.model.actors[0].jewel_respawn_turn=-1
	var click := InputEventMouseButton.new()
	click.position=at
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	scene._unhandled_input(click)
	check(scene.model.actors[0].jewel_respawn_turn==-1,"Score overhang cannot select a respawn")
	for button in [scene.move_left,scene.move_right,scene.flip_button,scene.fire_button]:
		check(not button.get_rect().intersects(Rect2(1064,721.6,216,78.4)),"Touch extras do not overlap score")
	scene.show_menu()
	scene.room_mode="solo"
	scene.start_match()
	if hud.has_method("jewel_panel_sample"):
		check(hud.jewel_panel_sample(scene.model).is_empty(),"SOLO has no JEWEL panel")
	click.button_index=MOUSE_BUTTON_RIGHT
	scene._unhandled_input(click)
	check(scene.dragging,"SOLO retains its world area above the footer")
	scene.queue_free()
	await process_frame
	await process_frame
	for path in ["res://.tools/jewel-hud-review/test-profile.json","res://.tools/jewel-hud-review/test-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("JEWEL HUD CHECKS")
