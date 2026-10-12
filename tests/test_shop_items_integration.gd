extends SceneTree
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void:
	call_deferred("run")
func fresh(loadout: Array, values: Array):
	var model = Match.new()
	model.start(2,1,42,"","original",null,loadout,values)
	model.weather.wind_force = 0
	model.weather.columns.clear()
	model.weather.queue[0].type = "wind"
	model.wind = Vector2.ZERO
	return model
func run() -> void:
	var values := [[30,0,0,0,10,40,50,0],[0,0,20,0,0,0,0,0]]
	var model = fresh(["power_up"],values)
	check(model.actors[0].items.size()==1 and model.actors[0].attributes[0]==30, "Both loadout and attributes reach actors")
	check(model.use_item(0) and is_equal_approx(float(model.actors[0].ready),12.0), "ItemDelay40: Power Up150 becomes90/7.5")
	check(is_equal_approx(float(model.weapon_rules(0,0).delay),92.4), "AttackDelay10:770 becomes693/7.5 independently")
	for entry in model.initiative_preview(0):
		if entry.actor == 0:
			check(is_equal_approx(float(entry.ready),104.4), "HUD includes reduced item and shot costs")
	check(model.fire(30,45,0), "Item-enhanced attributed shot")
	model.explode(model.actors[1].pos,1,{"damage":200,"weapon":0,"age":1.0,"velocity":Vector2.RIGHT})
	check(model.actors[1].shield==0 and model.actors[1].hp==700, "200 times(1+30+30-20)/100 =280, not chained multipliers")
	check(model.shot_gold.enemy_damage==280, "Gold sees composed damage once")
	model = fresh(["bunge_shot"],values)
	check(model.use_item(0), "Bunge usable with Dig points")
	model.terrain.cells.fill(1)
	model.explode(Vector2(400,200))
	check(not model.terrain.is_solid(Vector2(440,200)) and model.terrain.is_solid(Vector2(446,200)), "Dig50+Bunge25 gives radius43.75, not46.875")
	model = fresh(["energy_up_1"],[[0,50,0,0,0,0,0,0]])
	model.actors[0].hp = 1000
	check(model.use_item(0) and model.actors[0].hp==1198, "Item heals12% of attributed1650 max HP")
	model = fresh(["teleport"],[])
	model.use_item(0)
	model.fire(30,45,0)
	model.terrain.cells.fill(0)
	model.terrain.first_solid_y = 0
	model.actors[1].pos = Vector2(400,190)
	model.land_beacon(Vector2(400,200),Vector2(400,198),{"electric":true,"age":1.0,"influenced":["electricity"]})
	check(model.shot_gold.enemy_damage==30, "Beacon-attached weather damage reaches Gold ledger")
	for mobile in [1,2]:
		for item in ["dual_plus","power_up","bunge_shot"]:
			model = Match.new()
			model.start(mobile,1,42,"","original",null,[item],[[30,0,0,0,10,30,50,0],[0,0,20,0,0,0,0,0]])
			model.weather.columns.clear()
			model.wind = Vector2.ZERO
			check(model.use_item(0), "Item used before copied flight")
			var sim = Snapshot.capture(model)
			Snapshot.arm(sim,0,0,model.shot_shells(0,30,45,0))
			check(model.fire(30,45,0), "Live flight arms the same shells")
			for tick in range(2400):
				if model.phase != "flight":
					break
				model.advance_projectiles(1.0/120.0)
				sim.advance_projectiles(1.0/120.0)
			check(model.terrain.cells==sim.terrain.cells and model.actors[1].hp==sim.actors[1].hp and model.actors[1].shield==sim.actors[1].shield, "Items+attributes prediction equals real flight")
			sim.actors[0].attributes[0] = 0
			check(model.actors[0].attributes[0]==30, "Copied item flight cannot mutate live attributes")
	var view = load("res://scenes/main.tscn").instantiate()
	var path := "res://.tools/shop-items-integration-profile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path.get_basename()+"-options.json"))
	view.profile = load("res://scripts/profile.gd").new(path)
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.profile.xp = 3600
	check(view.profile.commit_attributes([30,0,0,0,10,40,50,0]), "Profile confirms mixed attributes")
	view.options.items = ["power_up"]
	view.profile.purchase("0:0:1","gold")
	view.profile.equip("0:0:1")
	view.show_shop()
	await process_frame
	view.show_menu()
	view.start_match()
	await process_frame
	check(view.model.actors[0].items[0].id=="power_up" and view.model.actors[0].attributes[5]==40 and view.actor_avatars[0]["0"]=="0:0:1", "Scene combines Shop gear, allocated points and selected item")
	check(view.use_item(0) and is_equal_approx(float(view.model.actors[0].ready),12), "Scene use applies ItemDelay")
	view.start_match()
	await process_frame
	check(view.item_bar.buttons.size()==1 and not view.model.actors[0].items[0].used and view.model.actors[0].attributes[5]==40, "Restart keeps loadout/attributes and resets consumption")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path.get_basename()+"-options.json"))
	print("SHOP ITEMS INTEGRATION CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
