extends SceneTree
## Product flow at its1280x800 virtual canvas; separate GPU temporal capture
## covers native art at1920x1080. Uses an isolated profile and muted playback.
const PROFILE:="res://.tools/jewel-capture-profile.json"
const OUT:="res://docs/jewel-implementation/gpu/"
func _initialize() -> void:
	call_deferred("run")
func shot(name:String) -> void:
	for count in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(PROFILE)
	scene.sound=load("res://scripts/sound.gd").new()
	scene.sound.muted=true
	root.add_child(scene)
	scene.set_process(false)
	scene.show_menu()
	scene.set_room_mode("jewel")
	await shot("room-jewel")
	scene.opening=0
	scene.begin_loading()
	await shot("loading-jewel")
	scene._tick_loading(10)
	scene.rig.position=scene.clamp_camera(scene.camera_goal())
	scene.model.jewel_state.scores=[75,25]
	# Place four jewels in the current view for readable product QA; geometry
	# is a capture fixture, not an extra runtime spawn rule.
	scene.model.jewel_state.entities.clear()
	for kind in 4:
		var x:int=int(scene.rig.position.x)+180+kind*180
		scene.model.JewelRules.spawn(scene.model.jewel_state,scene.model.terrain,x,[0,15,40,80][kind])
	scene.update_hud()
	scene.queue_redraw()
	print("FLOW CAMERA ",scene.rig.position," ACTORS ",scene.model.actors[0].pos," / ",scene.model.actors[1].pos," VISUAL ",scene.model.terrain.visual_rect)
	await shot("battle-jewel")
	scene.model.jewel_state.scores=[100,25]
	scene.model.check_end()
	scene.consume_events()
	scene.show_result()
	await shot("result-jewel")
	scene.queue_free()
	await process_frame
	await process_frame
	for path in [PROFILE,"res://.tools/jewel-capture-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("JEWEL FLOW CAPTURES: 4")
	quit(0)
