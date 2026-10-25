extends "res://tests/support/suite.gd"
## REQ-35..37 in the scene: item bar, queued use, Ignorance lock, room item panel,
## teleport presentation and HD/fallback textures (ITEMS_0_13.md).
func key(scene, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	scene._unhandled_key_input(event)

func run() -> void:
	var Items = load("res://scripts/items.gd")
	var Options = load("res://scripts/options.gd")
	var HudArt = load("res://scripts/hud_art.gd")
	var profile_path := "res://.tools/items-scene-profile.json"
	var options_path := "res://.tools/items-scene-profile-options.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(options_path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(profile_path)
	root.add_child(scene)
	scene.sound.muted = true
	check(scene.options.items == Items.DEFAULT_LOADOUT, "Without a saved file the loadout is Dual, Teleport, Power Up, Energy Up 1")
	if scene.screen == "lobby":
		scene.show_menu()

	# Room panel: icons inside the six painted slots, catalog in the well, save on change.
	scene.menu.nickname_input.text = "Novo Piloto"
	var panel = scene.menu
	check(panel.item_grid_buttons.size() == 11 and panel.item_tab_buttons.is_empty() and panel.catalog_inside_panel() and panel.icons_inside_slots(), "The room lists all11items in one scrollable panel")
	check(panel.item_slot_buttons[0].position == Vector2(524, 365) and panel.item_slot_buttons[0].size == Vector2(71, 31) and panel.item_slot_buttons[0].get_child_count() == 0 and not panel.item_slot_buttons[1].visible and panel.item_slot_buttons[1].texture_normal == null, "Dual is one rectangle over both painted slots, without a second icon")
	check(panel.item_grid_buttons.size() == 11 and panel.catalog_inside_panel(), "Both slot sizes share the same catalog")
	var before: Array = scene.options.items.duplicate()
	panel.item_grid_buttons[0].pressed.emit()
	check(scene.options.items == before, "A full bar ignores new items")
	panel.item_slot_buttons[0].pressed.emit()
	check(scene.options.items == ["teleport", "power_up", "energy_up_1"] and panel.equipped_buttons.size() == 3, "Clicking an equipped slot removes that item")
	for id in ["change_wind","blood"]:
		for button in panel.item_grid_buttons:
			if button.get_meta("item_id")==id:
				button.pressed.emit()
	check(Items.used_slots(scene.options.items) == 6 and scene.options.items.back() == "blood", "Freed slots accept 1-slot items")
	var span: int = Items.slots(str(scene.options.items[0]))
	check(panel.equipped_buttons.size() == scene.options.items.size() and absf(panel.equipped_buttons[1].position.x - panel.equipped_buttons[0].position.x - 36.0 * span) <= 1.0 and panel.equipped_buttons[0].size == Vector2(71, 31) and panel.equipped_buttons[1].size == Vector2(35, 31) and panel.icons_inside_slots(), "A 2-slot piece covers both places, a 1-slot piece covers one, and the next item starts after that span")
	panel.hover_item("dual_plus")
	var line: Dictionary = panel.hover_line()
	check(panel.item_hovered == "dual_plus" and line.name == "Dual+" and line.delay == str(roundi(Items.delay("dual_plus"))) and line.description == Items.definition("dual_plus").description, "Hover keeps the item name, delay and description")
	var reloaded = Options.new(options_path)
	reloaded.load_options()
	check(scene.overlays.layer == null and reloaded.items == ["teleport", "power_up", "energy_up_1", "change_wind", "blood"], "Changing the loadout saves it next to the profile and does not open a modal")
	check(scene.menu.nickname_input.text == "Novo Piloto" and Items.used_slots(scene.options.items) == 6 and panel.filled_slot_count() == 6, "Editing items keeps the typed nickname and the six-slot count")

	# Battle: the bar follows the loadout and EquippedButtonBar spacing.
	scene.options.items = ["dual", "teleport", "power_up", "energy_up_1"]
	scene.select_vehicle(2)
	scene.opening = 0
	# Pinned: a random seed can spawn the mobiles so close that the first Dual
	# shot ends the match before the CPU turn this scenario needs (seed 28).
	scene.match_seed = 1
	scene.start_match()
	await process_frame
	if scene.model.active != 0:
		scene.model.pass_turn()
		scene.consume_events()
	var bar = scene.item_bar
	check(bar.buttons.size() == 4 and bar.visible_slots(scene) == [0, 1, 2, 3], "Four equipped buttons on the action bar")
	var origin: Vector2 = HudArt.bar_point(Vector2(-116, -37)).round()
	check(bar.buttons[0].position == origin and absf(bar.buttons[1].position.x - bar.buttons[0].position.x - 72.0 * 1.6) <= 1.0, "Bar starts at (−116, −37) of the action bar; buttons overlap by 1 px")
	check(bar.buttons[0].size.is_equal_approx(Vector2(73, 36) * 1.6) and bar.buttons[2].size.is_equal_approx(Vector2(37, 36) * 1.6), "2-slot and 1-slot button sizes")
	scene.model.actors[0].turns = 3
	scene.select_weapon(2)
	check(scene.aim.weapon == 2, "SS is selectable before using an item")
	var ready_before := float(scene.model.actors[0].ready)
	bar.buttons[0].pressed.emit()
	scene.consume_events()
	scene.update_hud()
	check(scene.model.actors[0].turn_item == "dual" and is_equal_approx(float(scene.model.actors[0].ready) - ready_before, 80.0), "Clicking Dual uses it and charges 80")
	check(scene.aim.weapon == 1 and scene.weapon_buttons[2].disabled, "DisableSS: the selection moves to shot 2 and SS is disabled")
	check(not bar.buttons[0].visible and not (0 in bar.visible_slots(scene)) and bar.buttons[1].position == origin, "Using Dual removes it from the slot and packs the bar")
	check(bar.buttons[1].disabled and bar.buttons[2].disabled, "The rest of the bar stays disabled for this turn")
	check(scene.art.state_name(scene.model, 0, false) == "using_item", "The mobile plays UsingItem")
	for _step in range(6):
		scene._process(0.1)
	var aura_age := float(scene.art.motion[0].pose_age)
	check(scene.art.motion[0].pose == "using_item" and scene.item_art.using_frame(aura_age) >= 8, "The UsingItem aura keeps playing on the mobile")
	key(scene, KEY_F3)
	check(scene.model.actors[0].items[2].used == false, "One item per turn, also by F-key")

	# Fire, then queue Energy Up 1 on the CPU turn by clicking it.
	scene.aim.angle = 30.0
	scene.aim.power = 40.0
	scene.shoot()
	var queued_checked := false
	for frame in range(1200):
		scene._process(0.05)
		await process_frame
		# This fixture advances simulated time much faster than wall time. Let
		# the real worker finish before advancing another accelerated frame;
		# otherwise machine load can exhaust 1200 frames before the CPU acts.
		while scene.cpu.task>=0 and not WorkerThreadPool.is_task_completed(scene.cpu.task):
			await create_timer(0.005).timeout
		if scene.model.phase == "aim" and scene.model.active == 1 and not queued_checked:
			queued_checked = true
			check(bar.buttons[1].disabled, "After a use the bar stays disabled until the next own turn")
			bar.disabled_until_turn = false
			scene.update_hud()
			bar.buttons[3].pressed.emit()
			check(bar.queued == 3 and not scene.model.actors[0].items[3].used, "On the CPU turn a click only queues the item")
			bar.buttons[3].pressed.emit()
			check(bar.queued == -1, "A second click cancels the queue")
			bar.buttons[3].pressed.emit()
		if queued_checked and scene.model.phase == "aim" and scene.model.active == 0:
			break
	check(queued_checked and scene.model.active == 0, "The turn comes back to the player")
	check(not bar.buttons[0].visible and not bar.buttons[3].visible, "Dual and the queued Energy Up stay off the bar once used")
	check(scene.model.actors[0].items[3].used and scene.model.actors[0].turn_item == "energy_up_1" and bar.removal == 3, "The queued Energy Up 1 is used at the turn start and leaves its slot")
	check(bar.buttons[1].position == origin, "Remaining buttons are packed from the bar start")

	# Ignorance locks the bar with ITEM LOCKED.
	scene.model.actors[0].turn_item = ""
	bar.disabled_until_turn = false
	scene.model.weather.queue[0].type = "ignorance"
	scene.update_hud()
	check(bar.lock_rect.visible and bar.buttons[1].disabled, "Ignorance shows ITEM LOCKED and disables the bar")
	key(scene, KEY_F1)
	check(not scene.model.actors[0].items[1].used, "Locked items ignore F-keys")
	scene.model.weather.queue[0].type = "wind"
	scene.update_hud()
	check(not bar.lock_rect.visible and not bar.buttons[1].disabled, "The bar unlocks with another weather")

	# Teleport presentation: beacon art, sounds and both flames; no slide.
	key(scene, KEY_F1)
	check(scene.model.actors[0].turn_item == "teleport", "F1 presses the first visible button (Teleport)")
	scene.aim.weapon = 1
	scene.aim.angle = 28.0
	scene.aim.power = 30.0
	scene.shoot()
	var teleported := false
	for frame in range(400):
		scene.model.tick(0.05)
		for event in scene.model.events:
			if event.type == "teleport":
				teleported = true
				scene.consume_events()
				check(scene.item_art.flames.size() == 2 and scene.item_art.flames[1].reverse, "Teleport adds Flame1 at the landing and the reversed Flame2 at the start")
				check(Vector2(scene.art.motion[0].pos) == Vector2(event.to), "The mobile appears at the beacon without sliding")
				break
		if teleported:
			break
		scene.consume_events()
	check(teleported, "The beacon teleports the player")
	scene.item_art.tick(1.0)
	check(scene.item_art.flames.is_empty(), "Flames last 19 frames at 30 fps")

	# A match restarted without this loadout (capture tools) keeps the bar safe.
	scene.model.start(2, 1, 4)
	scene.update_hud()
	check(not bar.buttons[0].visible and not bar.buttons[3].visible, "Buttons without an equipped item are hidden")
	bar.press(scene, 2)
	check(scene.model.actors[0].turn_item == "", "Pressing a stale button does nothing")

	# Keyframe sampling and HD textures with fallback.
	var ItemArt = load("res://scripts/item_art.gd")
	check(is_equal_approx(ItemArt.flame_position(0.0, true), 18.0) and is_equal_approx(ItemArt.flame_position(1.0, false), 18.0), "Teleport2 plays Teleport1 backwards")
	var keys: Dictionary = ItemArt.flame_keys(5.0)
	check(keys.first == 2 and keys.second == 3 and is_equal_approx(keys.blend, 0.5), "Frame 5 blends keyframes 4 and 6 half-way")
	var art = ItemArt.new()
	check(art.textures["ItemDual.png"].get_width() == 292 * 3 and is_equal_approx(art.density("ItemDual.png"), 3.0) and is_equal_approx(art.density("MatchStatus.png"), 3.0), "HD item sprites are 3× the originals")
	check(art.textures["TeleportBullet.png"].get_width() == 516 * 2 and art.textures.has("TeleportFlame.png"), "Teleport beacon and flame keyframes are 2× HD")
	check(art.using_frame(0.0) == 0 and art.using_frame(10.0 / 19.0) == 10 and art.using_frame(5.0) == 19, "UsingItem samples 20 frames at 19 fps and holds the last")
	check(art.using_textures["bigfoot"].get_width() == 129 * 5 and art.using_textures["mage"].get_height() == 150 * 4 and is_equal_approx(art.using_density("bigfoot"), 1.0), "Original mobiles use native UsingItem aura sheets")
	check(art.textures["ItemDual.png"].get_image().has_mipmaps(), "HD UI item sprites are imported with mipmaps")
	art.textures = art.originals.duplicate()
	check(is_equal_approx(art.density("MatchStatus.png"), 1.0) and art.button_frame("dual", 3).region == Rect2(219, 0, 73, 36), "Originals keep the Button.cs rectangles")

	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(options_path))
	finish("ITEMS SCENE CHECKS")
