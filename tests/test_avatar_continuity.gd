extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model = load("res://scripts/match.gd").new()
	model.start(2,1,42,"")
	var art = load("res://scripts/battle_art.gd").new()
	art.reset(model.actors)
	check(art.has_method("presentation"), "Per-actor presentation blends interrupted poses")
	if art.has_method("presentation"):
		for kind in ["bigfoot","mage"]:
			var rig = load("res://scripts/mobile_rig.gd").new(kind)
			art.reset(model.actors)
			var clock := 0.73
			var state: Dictionary = art.motion[0]
			state.pose = "moving"
			state.pose_age = 0.065
			var previous: Dictionary = art.presentation(0,rig,clock,0)
			for pose in ["idle","charging_2","recoil","hurt","moving","recoil","recoil","destroyed"]:
				state.pose = pose
				state.pose_age = 0.0
				var current: Dictionary = art.presentation(0,rig,clock,2)
				check(current.body_offset.distance_to(previous.body_offset) < 0.001, kind+" no body jump at "+pose)
				check(absf(current.pilot_angle-previous.pilot_angle) < 0.001, kind+" no pilot phase reset at "+pose)
				check(absf(current.barrel_angle-previous.barrel_angle) < 0.001, kind+" no barrel snap at "+pose)
				for tick in range(1,4):
					clock += 1.0/60.0
					state.pose_age += 1.0/60.0
					current = art.presentation(0,rig,clock,2)
					check(current.body_offset.distance_to(previous.body_offset) < 1.0, kind+" continuous interrupted body motion")
					previous = current
				var frozen: Dictionary = art.presentation(0,rig,clock,2).duplicate(true)
				check(art.presentation(0,rig,clock,2) == frozen, "Pause freezes pose transition")
			clock += 0.2
			state.pose_age += 0.2
			var settled: Dictionary = art.presentation(0,rig,clock,2)
			check(settled == rig.sample("destroyed",state.pose_age,2,clock), "Transition reaches current pose without modifying its duration")
			art.motion[1].pose = "idle"
			art.motion[1].pose_age = 0.0
			check(art.presentation(1,rig,clock,0).body_offset == Vector2.ZERO, "CPU and player blend independently")
	var path := "res://.tools/avatar-continuity-profile.json"
	var profile = load("res://tests/legacy_profile.gd").new(path)
	var shop = load("res://scripts/avatar_shop_model.gd").new(profile)
	var gear := {"0":"0:0:1","1":"0:1:1","2":"0:2:1","3":"2:3:1"}
	for key in gear.values():
		check(profile.purchase(key,"gold") == "ok", "Purchase category "+key)
		check(shop.select(key) and shop.try_selected(), "Dress owned item directly in Shop "+key)
	check(profile.equipped_set() == gear and shop.preview == gear, "All four dressed categories shown and saved")
	var saved_preview: Dictionary = shop.preview.duplicate(true)
	profile.path = "res://.tools/missing-shop-directory/profile.json"
	shop.select("0:0:0")
	check(not shop.try_selected() and profile.equipped_set() == gear and shop.preview == saved_preview, "Failed dress save rolls back equipment and preview")
	profile.path = path
	var restored = load("res://tests/legacy_profile.gd").new(path)
	restored.load_profile()
	check(restored.equipped_set() == gear, "All categories survive closing profile")
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = restored
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.opening = 0
	view.start_match()
	check(view.actor_avatars[0] == gear, "Fresh scene battle receives persisted four-slot equipment")
	view.opening = 0
	view.start_match()
	check(view.actor_avatars[0] == gear, "Restart keeps equipment")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/avatar-continuity-profile-options.json"))
	print("AVATAR CONTINUITY CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures == 0 else 1)
