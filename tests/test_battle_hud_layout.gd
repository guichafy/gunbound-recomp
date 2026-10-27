extends "res://tests/support/suite.gd"
## User references: options/items/Gold above, weapons/charge/move below.
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed
		event.position=point
		event.global_position=point
		root.push_input(event)

func run() -> void:
	root.size = Vector2i(1280,800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/hud-layout/test-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.opening = 0
	scene.options.items = ["dual","teleport","power_up","energy_up_1"]
	scene.start_match()
	check(scene.options_button.position.is_equal_approx(Vector2(11,3)*1.6), "Options uses the client's header position11,3")
	check(scene.options_button.size.is_equal_approx(Vector2(40,30)*1.6), "Options uses native40x30 hitbox")
	check(scene.pass_button.position.is_equal_approx(Vector2(750,3)*1.6), "Skip is at the right of the header")
	for i in 3:
		check(scene.weapon_buttons[i].position.is_equal_approx(Vector2(6+i*41,462)*1.6), "Weapon"+str(i)+" is in native footer")
		check(scene.weapon_buttons[i].size.is_equal_approx(Vector2(35,34)*1.6), "Native shot35x34")
	check(scene.item_bar.buttons[0].position.is_equal_approx(Vector2(501,2)*1.6), "Items are in header at501,2")
	check(scene.item_bar.buttons[-1].position.y < 64, "Last item remains in header")
	check(scene.item_bar.lock_rect.position.y < 64, "Item lock overlays header tray")
	check(scene.hud.strength_rect().is_equal_approx(Rect2(Vector2(244,469)*1.6,Vector2(400,22)*1.6)), "Charge aligns with full native footer frame")
	check(scene.hud.has_method("move_bar_sample"),"MOVE exposes the native footer composition")
	if scene.hud.has_method("move_bar_sample"):
		for expanded in [false,true]:
			for fraction in [0.0,0.5,1.0]:
				var sample: Dictionary=scene.hud.move_bar_sample(fraction,expanded)
				var height := 26.0 if expanded else 16.0
				var top := 474.0 if expanded else 484.0
				check(sample.frame==Rect2(Vector2(169,top)*1.6,Vector2(485,height)*1.6),"MOVE frame retains native169,574+pivot inside footer")
				var pixels := 1.0 if fraction==0.0 else (201.0 if fraction==0.5 else 400.0)
				check(sample.fill==Rect2(Vector2(244,483)*1.6,Vector2(pixels,12)*1.6),"Native inclusive clip and400x12fill")
				check(scene.hud.Layout.FOOTER.encloses(sample.frame) and scene.hud.Layout.FOOTER.encloses(sample.fill),"MOVE never floats above footer")
		check(not scene.hud.move_active,"MOVE begins hidden")
		scene.hud.update_movement(true)
		check(scene.hud.move_active and not scene.hud.move_expanded,"Entry uses native compact stage0")
		scene.hud.update_movement(true)
		check(scene.hud.move_expanded,"Next presentation update expands to frame6")
		scene.hud.update_movement(false)
		check(not scene.hud.move_active,"Release hides native flag1")
	for y in [2.0,40.0,735.0,799.0]:
		scene.dragging = false
		var event := InputEventMouseButton.new()
		event.position = Vector2(640,y)
		event.button_index = MOUSE_BUTTON_RIGHT
		event.pressed = true
		scene._unhandled_input(event)
		check(not scene.dragging, "Header/footer cannot start pan y"+str(y))
	check(scene.item_bar.lock_rect.size.is_equal_approx(Vector2(217,38)*1.6),"Native lock banner retains aspect217x38")
	for type in ["force","tornado","electricity","wind","thor","protection","ignorance","weakness","mirror","random"]:
		var normal: Dictionary=scene.hud.current_weather_art(type)
		check(normal.texture!=null and normal.source.size.x>0,"Current weather visible "+type)
	scene.hud.client_assets.files.erase("NativeWeather.png")
	scene.hud.client_assets._cache.erase("NativeWeather.png")
	for type in ["force","tornado","wind","ignorance","mirror"]:
		var fallback: Dictionary=scene.hud.current_weather_art(type)
		check(fallback.texture!=null and fallback.source.size==Vector2(22,22),"Failed native current icon keeps fallback "+type)
	await process_frame
	click(scene.weapon_buttons[1].get_global_rect().get_center())
	check(scene.aim.weapon==1,"Real viewport click selectsS2 in footer")
	click(scene.weapon_buttons[2].get_global_rect().get_center())
	check(scene.aim.weapon==2,"Real viewport click selectsSS in footer")
	click(scene.weapon_buttons[0].get_global_rect().get_center())
	check(scene.aim.weapon==0,"Real viewport click selectsS1 in footer")
	click(scene.options_button.get_global_rect().get_center())
	check(scene.overlays.kind=="options","Real viewport click opensOptions in header")
	scene.close_overlay()
	var power: float=scene.aim.power
	click(scene.hud.strength_rect().position+Vector2(320,5))
	check(absf(scene.hud.selector_x-40)<0.01 and scene.aim.power==power,"Real viewport click moves reference without firing")
	scene.options.aiming=0
	for point in [Vector2(640,20),Vector2(1160,780)]:
		scene.dragging=false
		click(point)
		check(not scene.aim.charging and not scene.dragging,"GUI bars block left Drag and pan at"+str(point))
	click(scene.item_bar.buttons[0].get_global_rect().get_center())
	check(scene.model.actors[0].items[0].used and not scene.item_bar.buttons[0].visible,"Real viewport click consumes header item once")
	var active: int=scene.model.active
	click(scene.pass_button.get_global_rect().get_center())
	check(scene.model.active!=active or scene.model.phase!=scene.model.PHASE_AIM,"Real viewport click passes once in header")
	scene.queue_free()
	await process_frame
	for path in ["res://.tools/hud-layout/test-profile.json","res://.tools/hud-layout/test-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	report("BATTLE HUD LAYOUT CHECKS")
	quit(exit_code())
