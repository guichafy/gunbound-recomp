extends SceneTree
## Nak 0.15 GPU evidence (REQ-43): 1920×1080 stills and a 60 fps sequence in
## docs/nak, with an isolated profile. Original Thor's Hammer frames, no HD yet.
const Combat = preload("res://scripts/combat.gd")
const OUT := "res://docs/nak/"
var view

func _initialize() -> void:
	call_deferred("run")

func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func step(seconds: float) -> void:
	var left := seconds
	while left > 0.0001:
		view._process(minf(left, 1.0 / 60.0))
		left -= 1.0 / 60.0

## Places one shell of the Nak and lets the live loop fly it for `seconds`.
func launch(weapon: int, angle: float, power: float) -> void:
	view.model.phase = "aim"
	view.model.active = 0
	view.model.fire(angle, power, weapon)
	view.consume_events()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "frames"))
	root.size = Vector2i(1920, 1080)
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/nak-capture-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(3)
	await snap("menu")
	view.start_match()
	view.model.start(3, 1, 42)
	view.model.wind = Vector2.ZERO
	view.art.reset(view.model.actors)
	view.consume_events()
	view.update_hud()
	step(0.2)
	await snap("arena")
	# Idle bubble (emotion1) near the end of the 6 s idle cycle.
	view.art.motion[0].pose_age = 5.45
	await snap("bubble")
	# 60 fps sequence: idle → bubble → walk → charge → S1 recoil.
	var index := 0
	for frame in range(150):
		if frame == 60:
			view.model.move_actor(1, 0.4)
		if frame == 90:
			view.charging = true
		if frame == 125:
			view.charging = false
			launch(0, 35.0, 55.0)
		step(1.0 / 60.0)
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "frames/%03d.png" % index)
		index += 1
	await snap("s1-flight")
	for _i in range(240):
		if view.model.phase != "flight":
			break
		step(1.0 / 60.0)
	await snap("s1-impact")
	# S2: burrows and resurfaces.
	view.model.start(3, 1, 43)
	view.model.wind = Vector2.ZERO
	view.art.reset(view.model.actors)
	# 35°/70: enters near x 1186 and resurfaces ~280 px later, past the Mage.
	launch(1, 35.0, 70.0)
	var buried := false
	for _i in range(600):
		step(1.0 / 60.0)
		if view.model.projectiles.size() > 0 and bool(view.model.projectiles[0].get("underground", false)) and not buried:
			buried = true
			step(0.25)
			await snap("s2-underground")
		if view.model.phase != "flight":
			break
	step(0.12)
	await snap("s2-impact")
	# SS: the mini Nak crosses the ground.
	view.model.start(3, 1, 44)
	view.model.wind = Vector2.ZERO
	view.art.reset(view.model.actors)
	# 10°/36 crosses the ground and stops on the Mage.
	launch(2, 10.0, 36.0)
	step(0.4)
	await snap("ss-flight")
	for _i in range(900):
		if view.model.phase != "flight":
			break
		step(1.0 / 60.0)
	step(0.2)
	await snap("ss-impact")
	print("NAK GPU CAPTURES: ", root.get_texture().get_image().get_size(), " frames=", index, " buried=", buried)
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/nak-capture-profile.json"))
	quit()
