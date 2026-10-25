extends "res://tests/support/suite.gd"
func run() -> void:
	var Match = load("res://scripts/match.gd")
	var model = Match.new()
	# Nak (ID 3, ADR-074) joins Mage and Bigfoot; the CPU pairs stay 1↔2 and Nak meets Mage.
	var opponents := {1: 2, 2: 1, 3: 1}
	check(model.VEHICLES.size() == 16 and model.VEHICLES[1].name == "Mage" and model.VEHICLES[2].name == "Bigfoot" and model.VEHICLES[3].name == "Nak", "Roster keeps Mage, Bigfoot and Nak and adds the classic mobiles")
	for chosen in [1, 2, 3]:
		model.start(chosen, 1, 42)
		check(model.actors[0].vehicle == chosen and model.actors[1].vehicle == opponents[chosen], "Each mobile meets its fixed CPU opponent")
		check(model.actors[0].hp == (730 if chosen == 1 else 1100), "Stable IDs retain mobile life")
		model.actors[0].turns = 3
		for weapon in [0, 1, 2]:
			model.phase = "aim"
			model.actors[0].special_used = false
			check(model.fire(30, 65, weapon), "Both mobiles retain all three attacks")
			check(model.projectiles.size() == {1: [1, 2, 1], 2: [4, 6, 8], 3: [1, 1, 1]}[chosen][weapon], "Attack uses its own mobile emitter")
	for invalid in [0, -1, 99]:
		model.start(invalid, 1, 42)
		check(model.actors[0].vehicle == 2 and model.actors[1].vehicle == 1, "Removed/invalid ID normalizes to Bigfoot rather than resurrecting a vehicle")
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/roster-test-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	check(view.menu.vehicle_buttons.size() == 16, "Menu displays the full classic roster")
	for button in view.menu.vehicle_buttons:
		check(button.position.x + button.size.x <= view.menu.mobile_popup.size.x and button.position.y + button.size.y <= view.menu.mobile_popup.size.y, "Vehicle button %s fits the mobile popup" % button.text)
	for id in [1, 2, 3]:
		view.show_menu()
		for button in view.menu.vehicle_buttons:
			if button.text == {1: "Mage", 2: "Bigfoot", 3: "Nak"}[id]:
				button.pressed.emit()
		check(view.vehicle == id, "Button slot dispatches stable mobile ID")
		view.opening = 0
		view.start_match()
		check(view.model.actors[0].vehicle == id and view.model.actors[1].vehicle == opponents[id], "Menu selection starts the correct duel")
	view.show_menu()
	# Room settings apply the selected difficulty on Accept (ADR-092).
	for slot in 3:
		view.menu.open_settings()
		view.menu.difficulty_buttons[slot].pressed.emit()
		view.menu.accept_settings()
		check(view.cpu_difficulty == slot, "Difficulty slots stay independent of roster")
	view.select_vehicle(0)
	check(view.vehicle == 2, "Stale selection cannot restore Escaravelho")
	var Rig = load("res://scripts/mobile_rig.gd")
	# Presentation catalog (ADR-081): one look per playable mobile, no id branches.
	var Looks = load("res://scripts/mobile_looks.gd")
	var Mobiles = load("res://scripts/mobiles.gd")
	var looks_ok := true
	for vehicle_id in Mobiles.PLAYABLE:
		var look: Dictionary = Looks.look(vehicle_id)
		looks_ok = looks_ok and not look.is_empty() and ResourceLoader.exists(look.sprite) and view.sprite_for(vehicle_id) != null
		looks_ok = looks_ok and Looks.id_of(look.kind) == vehicle_id
	check(looks_ok and Looks.ids().size() == Mobiles.PLAYABLE.size(), "Every playable mobile has one presentation look and sprite")
	for kind in ["bigfoot", "mage"]:
		var rig = Rig.new(kind)
		var death := float(Mobiles.definition(Looks.id_of(kind)).death)
		check(rig.available() and rig.sample("destroyed", death, 0).alpha == 0.0 and rig.sample("destroyed", death * 0.5, 0).alpha > 0.0, kind + " HD death fades over the catalog death time")
	check(not Rig.new("nak").available() and Looks.using_aura("nak").is_empty(), "Nak keeps the original atlas and has no UsingItem aura")
	for kind in ["bigfoot", "mage"]:
		var rig = Rig.new(kind)
		check(rig.pilot.texture.resource_path.ends_with("pilot_side.png"), "Both mobiles use the occluded side-view master")
		check(rig.pilot.region(0, 0) == Rect2(271, 153, 703, 977), "Occlusion preserves the approved pilot registration frame")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/roster-test-profile.json"))
	finish("ROSTER/SIDE PILOT CHECKS")
