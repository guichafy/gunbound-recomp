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
	if not ResourceLoader.exists("res://scripts/projectile_art.gd"):
		check(false, "Continuous projectile renderer exists")
		print("PILOT/SHOTS CHECKS: ", checks, " | FAILURES: ", failures)
		quit(1)
		return
	var Art = load("res://scripts/projectile_art.gd")
	var art = Art.new()
	for kind in ["bigfoot", "mage"]:
		check(art.available(kind), "All three constant heads load: " + kind)
		for weapon in [0, 1, 2]:
			for velocity in [Vector2(100, -80), Vector2(-100, 80)]:
				var shot := {"pos": Vector2(250, 150), "hit_pos": Vector2(255, 156), "velocity": velocity, "age": 0.0, "phase": PI, "trail": [Vector2(230, 150), Vector2(240, 153)], "launched": true}
				var baseline: Dictionary = art.sample(kind, weapon, shot)
				var previous: Dictionary = baseline
				var fixed_shape := true
				var smooth_flame := true
				var correct_direction := true
				for tick in range(1, 181):
					shot.age = tick / 120.0
					var before: Dictionary = shot.duplicate(true)
					var state: Dictionary = art.sample(kind, weapon, shot)
					fixed_shape = fixed_shape and state.body_rect == baseline.body_rect and state.source == baseline.source
					smooth_flame = smooth_flame and absf(state.flame_length - previous.flame_length) < 3.0
					correct_direction = correct_direction and Vector2.from_angle(state.rotation).dot(velocity.normalized()) > 0.9999
					if tick == 1:
						check(before == shot, "Renderer does not mutate flight state")
					previous = state
				var label := "%s T%d facing%.0f: " % [kind, weapon + 1, signf(velocity.x)]
				check(fixed_shape, label + "head identity and dimensions never change at phase/loop")
				check(smooth_flame, label + "flame evolves continuously")
				check(correct_direction, label + "head points with flight velocity")
				check(baseline.position == shot.hit_pos and baseline.body_rect.get_center().is_zero_approx(), label + "head is centered on real collider")
				if kind == "bigfoot" and weapon != 1:
					check((baseline.flame_tip - baseline.position).dot(velocity) < 0, label + "flame trails behind the bomb")
				check(art.sample(kind, weapon, shot) == art.sample(kind, weapon, shot), label + "same clock freezes every visual layer")
		for duration in [0.6666667, 1.0]:
			var before: Dictionary = art.effect_sample(0.0, duration)
			var smooth_radius := true
			var smooth_alpha := true
			for tick in range(1, 121):
				var current: Dictionary = art.effect_sample(tick * duration / 120.0, duration)
				smooth_radius = smooth_radius and absf(current.scale - before.scale) < 0.04
				smooth_alpha = smooth_alpha and absf(current.alpha - before.alpha) < 0.05
				before = current
			check(smooth_radius and smooth_alpha, "Explosion envelope is continuous and stays centered")
			check(art.effect_sample(duration, duration).alpha == 0.0, "Explosion vanishes at original duration")
			var left: Dictionary = art.effect_sample(duration * 0.4 - 0.00001, duration)
			var right: Dictionary = art.effect_sample(duration * 0.4 + 0.00001, duration)
			check(left.second == right.first and left.blend > 0.999 and right.blend < 0.001, "Explosion phase seam crossfades without pop")
	var Rig = load("res://scripts/mobile_rig.gd")
	for kind in ["bigfoot", "mage"]:
		var rig = Rig.new(kind)
		check(rig.pilot.columns == 1 and rig.pilot.rows == 1, "Pilot is one connected seated figure")
		var frame: Rect2 = rig.pilot.region(0, 0)
		var state: Dictionary = rig.sample("idle", 0.0, 0)
		check(is_equal_approx(state.pilot_size.x / state.pilot_size.y, frame.size.x / frame.size.y), "Pilot preserves source anatomy/aspect")
		check((state.pilot_rect.position + state.pilot_size * Vector2(0.78, 0.88)).is_zero_approx(), "Pilot hips touch seat anchor")
		var first: Dictionary = rig.sample("charging", 0.5, 2)
		var next: Dictionary = rig.sample("charging", 0.501, 2)
		check(first.pilot_size == next.pilot_size and first.pilot_sway.distance_to(next.pilot_sway) < 0.01, "Pilot animation has stable size and smooth motion")
	# Verify live pause and pending salvos use the same visual clock.
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/pilot-shots-test-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.start_match()
	view.shoot()
	view._process(0.05)
	var projectiles: Array = view.model.projectiles.duplicate(true)
	var effects: Array = view.effects.duplicate(true)
	view.show_pause()
	view._process(0.2)
	check(view.model.projectiles == projectiles and view.effects == effects, "Pause freezes projectile and impact animation clocks")
	var flame_region: Rect2 = art.flames.components.t1_flame
	art.flames.components.t1_flame = Rect2()
	check(not art.available("bigfoot"), "Empty flame cutout falls back rather than silently losing flame")
	art.flames.components.t1_flame = flame_region
	var texture = art.sheet.texture
	art.sheet.texture = null
	check(not art.available("bigfoot") and not art.available("mage"), "Missing HD heads allow original fallback")
	art.sheet.texture = texture
	var Bigfoot = load("res://scripts/bigfoot_sprite.gd")
	var Mage = load("res://scripts/mage_sprite.gd")
	var bigfoot = Bigfoot.new()
	var mage = Mage.new()
	# Expired effects exercise validation without requiring a drawing context.
	var expired := {"age": 1.0, "pos": Vector2.ZERO}
	bigfoot.hd_effects.catalog_valid = false
	check(not art.draw_effect(null, expired, bigfoot.hd_effects, 0, Vector2(100, 100), 1.0), "Invalid impact metadata uses original fallback")
	mage.hd_emp.catalog_valid = false
	check(not art.draw_effect(null, expired, mage.hd_effects, 0, Vector2(100, 100), 1.0, Vector2.ZERO, mage.hd_emp), "Invalid EMP metadata uses original fallback")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/pilot-shots-test-profile.json"))
	print("PILOT/SHOTS CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
