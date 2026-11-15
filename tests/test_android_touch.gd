extends "res://tests/support/suite.gd"
func finger(index: int, pressed: bool, point: Vector2, canceled: bool=false) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index=index; e.pressed=pressed; e.position=point; e.canceled=canceled
	return e
func run() -> void:
	root.size=Vector2i(1280,800)
	var path := "res://scripts/touch_input.gd"
	check(ResourceLoader.exists(path),"Touch ownership router exists")
	if ResourceLoader.exists(path):
		var router = load(path).new()
		var context := {"can_act":true,"overlay":false,"waiting":false,"drag_mode":false,"camera_mode":false,"regions":{"charge":Rect2(0,0,48,48),"camera":Rect2(48,0,48,48)},"world_rect":Rect2(0,64,640,240),"blocked_rects":[],"pixels_per_dp":1.0}
		router.handle(finger(0,true,Vector2(20,20)),context)
		router.handle(finger(1,true,Vector2(60,20)),context)
		router.handle(finger(0,false,Vector2(200,20)),context)
		var commands: Array = router.drain_commands()
		check(commands.size()==2 and commands[0].action=="charge_begin" and commands[1].action=="charge_end","Captured release once; second finger cannot toggle camera")
		router.handle(finger(0,true,Vector2(20,20)),context)
		router.handle(finger(0,false,Vector2(20,20),true),context)
		commands=router.drain_commands()
		check(commands.back().action=="charge_cancel","Canceled gesture never fires")
		context.waiting=true
		router.handle(finger(2,true,Vector2(100,100)),context)
		router.handle(finger(2,false,Vector2(105,100)),context)
		commands=router.drain_commands()
		check(commands.size()==1 and commands[0].action=="respawn","JEWEL tap fires only on release")
		context.waiting=false
		router.handle(finger(0,true,Vector2(20,20)),context)
		router.drain_commands()
		var emulated := InputEventMouseButton.new()
		emulated.device=InputEvent.DEVICE_ID_EMULATION
		emulated.pressed=true
		check(not router.handle(emulated,context),"Router never duplicates emulated mouse")
		router.cancel_all("focus")
		commands=router.drain_commands()
		check(commands[0].action=="charge_cancel","Lost focus cancels captured charge")
		router.handle(finger(0,false,Vector2(20,20)),context)
		check(router.drain_commands().is_empty(),"Old release cannot shoot after cancel")
		context.regions={"move_left":Rect2(0,0,48,48),"move_right":Rect2(48,0,48,48),"charge":Rect2(96,0,48,48)}
		router.handle(finger(0,true,Vector2(20,20)),context)
		router.handle(finger(1,true,Vector2(60,20)),context)
		commands=router.drain_commands()
		check(commands.back().value==0,"Opposite movements cancel")
		router.handle(finger(2,true,Vector2(120,20)),context)
		router.drain_commands()
		check(router.owners.size()==1 and router.held("move")==0,"Charge cancels movement ownership")
		router.cancel_all("test")
		router.drain_commands()
		context.regions.pause=Rect2(144,0,48,48)
		router.handle(finger(0,true,Vector2(120,20)),context)
		router.drain_commands()
		router.handle(finger(1,true,Vector2(165,20)),context)
		commands=router.drain_commands()
		check(commands.any(func(c):return c.action=="pause") and not commands.any(func(c):return c.action=="charge_end"),"PAUSE cancels active Slice without firing")
		router.cancel_all("test")
		router.drain_commands()
		context.camera_mode=true
		router.handle(finger(0,true,Vector2(120,20)),context)
		check(router.drain_commands().is_empty(),"Camera blocks charge")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.android_test=true
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/android-v1/touch-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening=0
	scene.start_match()
	var charge: Vector2=scene.touch_regions().charge.get_center()
	scene._input(finger(0,true,charge))
	check(scene.aim.charging,"Raw touch starts Slice")
	scene.aim.tick(scene,2.99)
	check(scene.model.phase=="aim" and scene.aim.charging,"Slice does not fire at 2.99 seconds")
	scene.aim.tick(scene,0.01)
	check(scene.model.phase=="flight" and not scene.aim.charging and scene.hud.previous_power==100,"Slice auto fires once at three seconds")
	var count: int=scene.model.projectiles.size()
	scene._input(finger(0,false,Vector2(640,780)))
	check(scene.model.projectiles.size()==count,"Release after full Slice cannot add a shot")
	scene.start_match()
	charge=scene.touch_regions().charge.get_center()
	scene._input(finger(0,true,charge))
	scene._input(finger(1,true,scene.touch_regions().weapons.get_center()))
	scene._input(finger(1,false,scene.touch_regions().weapons.get_center()))
	check(scene.touch_selector=="" and scene.aim.weapon==0,"Second finger cannot change weapons during charge")
	scene._input(finger(0,false,Vector2(100,10)))
	check(scene.model.phase=="flight" and not scene.aim.charging,"Slice release outside button fires once")
	scene.start_match()
	scene.options.aiming=0
	scene._input(finger(0,true,Vector2(300,400)))
	check(scene.aim.drag_aiming,"Raw touch world starts Drag")
	var motion := InputEventScreenDrag.new()
	motion.index=0;motion.position=Vector2(620,400);motion.relative=Vector2(320,0)
	scene._input(motion)
	check(is_equal_approx(scene.aim.power,50),"Drag uses shared native logical strength")
	motion.position=Vector2(460,400);motion.relative=Vector2(-160,0)
	scene._input(motion)
	check(is_equal_approx(scene.aim.power,25),"Drag moving backward lowers strength")
	scene._input(finger(0,false,Vector2(640,780),true))
	check(scene.model.phase=="aim" and not scene.aim.charging,"Cancel Drag over HUD produces zero shots")
	scene._input(finger(0,true,scene.touch_regions().camera.get_center()))
	scene._input(finger(0,false,scene.touch_regions().camera.get_center()))
	check(scene.camera_mode,"Camera toggle explicit")
	scene._input(finger(0,true,Vector2(300,400)))
	motion.position=Vector2(350,400);motion.relative=Vector2(50,0)
	scene._input(motion)
	scene._input(finger(0,false,Vector2(350,400)))
	check(scene.model.phase=="aim" and not scene.aim.charging and scene.rig.manual,"Camera in Drag pans without firing")
	scene.cancel_platform_input("test")
	check(scene.touch.owners.is_empty() and scene.touch_move==0 and scene.touch_aim==0,"Cancel clears all held commands")
	scene.start_match()
	scene._input(finger(0,true,scene.touch_regions().charge.get_center()))
	scene._input(finger(1,true,scene.touch_regions().pause.get_center()))
	check(scene.overlays.kind=="options" and not scene.aim.charging,"Second-finger PAUSE cancels active scene charge")
	scene._input(finger(0,false,Vector2(640,400)))
	check(scene.model.phase=="aim","Old charge release after PAUSE cannot shoot")
	await process_frame
	var accept_point: Vector2=scene.overlays.options_popup.accept_button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.device=InputEvent.DEVICE_ID_EMULATION
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed
		event.position=accept_point;event.global_position=accept_point
		root.push_input(event)
	check(scene.overlays.kind=="options","Mouse emulation of consumed gesture cannot click through PAUSE")
	for pressed in [true,false]:
		root.push_input(finger(2,pressed,accept_point))
		var event := InputEventMouseButton.new()
		event.device=InputEvent.DEVICE_ID_EMULATION
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed
		event.position=accept_point;event.global_position=accept_point
		root.push_input(event)
	check(not scene.overlays.is_open(),"New GUI touch preserves native mouse emulation")
	scene.show_menu()
	scene.set_room_mode("jewel")
	scene.start_match()
	scene.model.actors[0].jewel_waiting=true
	scene.model.actors[0].jewel_respawn_turn=-1
	for point in [Vector2(20,20),Vector2(1100,750),Vector2(640,780)]:
		scene._input(finger(0,true,point))
		scene._input(finger(0,false,point))
		check(scene.model.actors[0].jewel_respawn_turn==-1,"JEWEL HUD/panel blocks touch return")
	scene.camera_mode=true
	scene._input(finger(0,true,Vector2(300,400)))
	scene._input(finger(0,false,Vector2(300,400)))
	check(scene.model.actors[0].jewel_respawn_turn==-1,"Camera mode blocks JEWEL tap return")
	scene.camera_mode=false
	scene._input(finger(0,true,Vector2(300,400)))
	scene._input(finger(0,false,Vector2(330,400)))
	check(scene.model.actors[0].jewel_respawn_turn==-1,"JEWEL drag above 12dp cannot select return")
	scene._input(finger(0,true,Vector2(300,400)))
	check(scene.model.actors[0].jewel_respawn_turn==-1,"JEWEL press waits for release")
	scene._input(finger(0,false,Vector2(302,400)))
	check(scene.model.actors[0].jewel_respawn_turn==scene.model.total_turns+2 and not scene.aim.charging,"JEWEL tap chooses return without firing")
	scene.queue_free()
	await process_frame
	report("ANDROID TOUCH CHECKS")
	quit(exit_code())
