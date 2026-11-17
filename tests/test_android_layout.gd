extends "res://tests/support/suite.gd"
func run() -> void:
	root.size=Vector2i(1280,800)
	check(ProjectSettings.get_setting("display/window/stretch/aspect.android", "") == "expand","Android canvas expands so safe-area touch controls cannot fall into clipped keep-aspect margins")
	var path := "res://scripts/platform_layout.gd"
	check(ResourceLoader.exists(path), "Android uniform safe-area layout exists")
	if ResourceLoader.exists(path):
		var layout = load(path)
		for size in [Vector2(1280,800),Vector2(1920,1080),Vector2(2400,1080),Vector2(1024,768)]:
			var safe := Rect2(Vector2(32,8),size-Vector2(64,24))
			var fit: Transform2D = layout.fit(size,safe,Vector2(1280,800))
			for point in [Vector2.ZERO,Vector2(640,400),Vector2(1280,800)]:
				check(layout.to_canvas(fit*point,fit).distance_to(point)<0.01,"Safe transform round trip")
			check(is_equal_approx(fit.x.length(),fit.y.length()),"Uniform scale")
		check(layout.has_method("safe_canvas"),"Safe display rect accounts for screen letterboxing")
		if layout.has_method("safe_canvas"):
			var screen_transform := Transform2D(Vector2(1.35,0),Vector2(0,1.35),Vector2(96,0))
			var safe_canvas: Rect2=layout.safe_canvas(Rect2(48,0,1872,1080),screen_transform)
			check((screen_transform*safe_canvas.position).distance_to(Vector2(48,0))<0.01,"Safe inverse includes letterbox offset")
			var dp_scale: float=layout.dp_scale(screen_transform,480)
			check(absf(48*dp_scale*screen_transform.x.length()/3.0-48)<0.01,"48dp stays 48dp through keep aspect")
		check(layout.fit(Vector2.ZERO,Rect2(),Vector2(1280,800))==Transform2D.IDENTITY,"Zero safe area stays finite")
		check(layout.has_method("safe_window"),"IME overlap is intersected once with the actual window")
		if layout.has_method("safe_window"):
			var display := Rect2(136,0,2264,1080)
			var screen_size := Vector2(2400,1080)
			var full: Rect2=layout.safe_window(display,Rect2(0,0,2400,1080),screen_size,390)
			var resized: Rect2=layout.safe_window(display,Rect2(0,0,2400,690),screen_size,390)
			check(full==Rect2(136,0,2264,690),"Keyboard excludes physical overlap")
			check(resized==full,"Already resized Android surface does not subtract IME twice")
			check(layout.safe_window(display,Rect2(0,0,2400,1080),screen_size,0)==display,"Hiding IME restores full safe display")
	var controls_path := "res://scripts/touch_controls.gd"
	check(ResourceLoader.exists(controls_path),"Touch controls exist")
	if ResourceLoader.exists(controls_path):
		var controls=load(controls_path)
		check(controls.has_method("caption_layout"),"Touch captions fit their complete text at 160dpi")
		if controls.has_method("caption_layout"):
			var font: Font=ThemeDB.fallback_font
			for caption in ["CAMERA","CAMERA\nON","CÂMERA\nATIVA","PAUSE","PAUSA","PASSAR"]:
				var label: Dictionary=controls.caption_layout(font,caption,Vector2(48,48),18)
				check("\n".join(label.lines)==caption,"Caption text is preserved")
				for line in label.lines:
					check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x<=38,"Full touch caption fits 48dp: "+caption)
				check(label.line_height*label.lines.size()<=38,"Two-line camera label stays inside touch target")
		for width in [640,800]:
			var safe := Rect2(0,0,width,360)
			var regions: Dictionary = load(controls_path).regions(safe,"jewel")
			for key in regions:
				check(regions[key].size.x>=48 and regions[key].size.y>=48,"48dp target "+key)
				check(safe.encloses(regions[key]),"Safe target "+key)
				for other in regions:
					if key!=other: check(not regions[key].intersects(regions[other]),"Targets separated")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.android_test=true
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/android-v1/layout-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	var original_size: Vector2i=root.content_scale_size
	var original_mode: int=root.content_scale_mode
	var original_factor: float=root.content_scale_factor
	for i in 10:
		scene.show_shop()
		check(scene.shop.content.scale.x==scene.shop.content.scale.y,"Android shop uniform scale")
		check(scene.shop.gender_button.size.y>=96 and scene.shop.attributes_button.size.y>=96,"Shop auxiliary actions have 48dp targets")
		if scene.shop.android_tools.visible:
			scene.shop.android_tools.pressed.emit()
			check(scene.shop.gender_button.visible and scene.shop.attributes_button.visible,"Compact shop drawer reveals both actions")
		scene.leave_shop()
		await process_frame
		check(root.content_scale_size==original_size and root.content_scale_mode==original_mode and root.content_scale_factor==original_factor,"Shop restores canvas on every exit")
	scene.queue_free()
	await process_frame
	report("ANDROID LAYOUT CHECKS")
	quit(exit_code())
