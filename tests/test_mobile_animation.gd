extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://scripts/mobile_rig.gd"):
		check(false, "Stable articulated HD renderer is available")
		print("ANIMATION CHECKS: ", checks, " | FAILURES: ", failures)
		quit(1)
		return
	var Rig = load("res://scripts/mobile_rig.gd")
	for kind in ["bigfoot", "mage"]:
		var rig = Rig.new(kind)
		check(rig.available(), kind + " loads complete rig and stable pilot")
		var idle: Dictionary = rig.sample("idle", 0.0, 0)
		for pose in ["idle", "moving", "charging", "recoil", "hurt", "destroyed"]:
			for weapon in [0, 1, 2]:
				var previous: Dictionary = rig.sample(pose, 0.0, weapon)
				var stable_body := true
				var stable_pilot := true
				var smooth_body := true
				var smooth_gun := true
				var smooth_seat := true
				var correct_flash := true
				for tick in range(1, 91):
					var age := tick / 60.0
					var current: Dictionary = rig.sample(pose, age, weapon)
					stable_body = stable_body and current.body_size == idle.body_size
					stable_pilot = stable_pilot and current.pilot_size == idle.pilot_size
					smooth_body = smooth_body and current.body_offset.distance_to(previous.body_offset) < 3.0
					smooth_gun = smooth_gun and absf(current.barrel_angle - previous.barrel_angle) < 0.15
					smooth_seat = smooth_seat and current.pilot_anchor.distance_to(previous.pilot_anchor) < 3.0
					correct_flash = correct_flash and (current.flash <= 0.001 if pose != "recoil" else true)
					previous = current
				var label := "%s %s T%d: " % [kind, pose, weapon + 1]
				check(stable_body, label + "body never stretches for effects")
				check(stable_pilot, label + "pilot proportions stay fixed")
				check(smooth_body, label + "continuous body motion including loop seam")
				check(smooth_gun, label + "continuous barrel motion")
				check(smooth_seat, label + "pilot stays on stable seat")
				check(correct_flash, label + "flash only during firing")
		check(rig.sample("moving", 0.25, 0).wheel_angle != rig.sample("moving", 0.5, 0).wheel_angle if kind == "bigfoot" else true, "Driving actually rotates Bigfoot wheels")
		check(rig.sample("recoil", 0.0, 0).body_offset.distance_to(idle.body_offset) < 0.001, "Recoil starts without position jump")
		check(rig.sample("recoil", 1.16, 0).body_offset.distance_to(idle.body_offset) < 0.001, "Recoil returns to idle smoothly")
		check(rig.sample("destroyed", 2.0, 0).alpha == 0.0, "Death finishes without looping or pilot remaining")
		check(rig.sample("idle", 0.7, 0) == rig.sample("idle", 0.7, 0), "Same clock freezes all layers while paused")
		var body_region: Rect2 = rig.sheet.region(0 if kind == "bigfoot" else 1, 0)
		check(body_region.has_area(), "Fixed body source has actual pixels")
		var valid_catalog: bool = rig.sheet.get("catalog_valid") == true
		check(valid_catalog, "Parts have verified custom crop metadata")
		rig.sheet.set("catalog_valid", false)
		check(not rig.available(), "Missing parts metadata falls back instead of clipping pieces")
		rig.sheet.set("catalog_valid", valid_catalog)
		var original = rig.sheet.texture
		rig.sheet.texture = null
		check(not rig.available(), "Incomplete rig falls back as a whole")
		rig.sheet.texture = original
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/animation-test-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.opening = 0
	view.start_match()
	view.model.start(2, 1, 42)
	view.art.reset(view.model.actors)
	view.model.actors[0].pos.x += 12
	view.art.tick(view.model, 0.1)
	var wheel_phase: float = view.art.motion[0].get("wheel_phase", 0.0)
	check(absf(wheel_phase) > 0.1, "Wheel phase follows travel")
	view.art.tick(view.model, 0.5)
	check(is_equal_approx(view.art.motion[0].get("wheel_phase", 0.0), wheel_phase), "Stopping never resets wheel phase")
	view.charging = true
	view.art.tick(view.model, 0.2, true, 2)
	view.art.tick(view.model, 0.2, true, 2)
	check(view.art.motion[0].pose == "charging_2" and view.art.motion[0].pose_age > 0.0, "Charge clock is shared with articulated renderer")
	var snapshot: Dictionary = view.art.motion[0].duplicate(true)
	view.show_pause()
	view._process(0.4)
	check(view.art.motion[0] == snapshot, "Pause freezes visual motion and clock")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/animation-test-profile.json"))
	print("ANIMATION CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
