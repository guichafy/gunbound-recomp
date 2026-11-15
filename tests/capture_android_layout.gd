extends SceneTree
## Desktop GPU evidence with simulated Android insets; not physical Android QA.
var scene
const OUT := "res://.tools/android-v1/captures/"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.android_test=true
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/android-v1/capture-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening=0
	for size in [Vector2i(1280,800),Vector2i(1280,720),Vector2i(1600,720),Vector2i(1024,768)]:
		root.size=size
		await process_frame
		for right_notch in [false,true]:
			var safe := Rect2(Vector2(0 if right_notch else 48,8),Vector2(size)-Vector2(48,24))
			scene.platform_safe=safe
			scene.platform_pixels_per_dp=2.0
			scene.presentation=scene.PlatformLayout.fit(Vector2(size),safe,Vector2(1280,800))
			scene.transform=scene.presentation
			for mode in ["solo","jewel"]:
				scene.room_mode=mode
				scene.start_match()
				scene.touch_selector="weapon"
				scene.touch_layer.queue_redraw()
				scene.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var file := "%dx%d-%s-%s.png" % [size.x,size.y,"right" if right_notch else "left",mode]
				root.get_texture().get_image().save_png(OUT+file)
	scene.queue_free()
	await process_frame
	print("ANDROID LAYOUT GPU: 16 simulated frames")
	quit()
