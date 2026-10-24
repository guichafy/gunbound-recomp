extends SceneTree
var checks := 0
var failures := 0
const PROFILE := "res://.tools/xfs-equipment-test.json"
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var P=load("res://scripts/profile.gd")
	var A=load("res://scripts/player_attributes.gd")
	var M=load("res://scripts/match.gd")
	var F=load("res://scripts/flight_snapshot.gd")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	var legacy=load("res://tests/legacy_profile.gd").new(PROFILE)
	legacy.gold=12345
	legacy.cash=6789
	legacy.xp=2600
	for key in ["0:0:1","0:1:1","0:2:1","2:3:1"]:
		check(legacy.purchase(key,"gold")=="ok" and legacy.equip(key),"Legacy outfit fixture "+key)
	legacy.owned.append("0:0:138")
	check(legacy.save_profile(),"Save a real version2-compatible outfit")
	var old_balance: int=legacy.gold
	var p=P.new(PROFILE)
	p.load_profile()
	check(p.gold==old_balance and p.cash==6789 and p.xp==2600,"Import preserves balances and progress without another grant")
	check(p.equipped_set()["2"]=="xfs:0:2:2","Pilot Goggles map to XFS ID2, never Battle Goggle ID1")
	check(p.owns("0:0:138") and not p.catalog.find("0:0:138").is_empty(),"Kappa remains owned as a legacy piece")
	var bonus: Array=p.equipment_bonuses()
	check(bonus[0]>0 and bonus[2]>0 and bonus[7]>0,"Real equipment contributes attack, defense and popularity")
	var first: Dictionary = p.snapshot()
	check(p.save_profile(),"Persist migrated keys")
	p.load_profile()
	check(p.snapshot()==first,"Migration is idempotent")
	var base: Array=[10,0,0,0,0,0,0,0]
	var model=M.new()
	model.start(2,1,42,"","original",null,[],[base,[]],[bonus,[]])
	check(model.actors[0].attributes==A.with_equipment(base,bonus),"Match copies effective equipment and pilot modifiers")
	var copied: Array=model.actors[0].attributes.duplicate()
	bonus[0]=49
	check(model.actors[0].attributes==copied,"Changing equipment source cannot change an active match")
	var sim=F.capture(model)
	F.arm(sim,0,0,model.shot_shells(0,30,45,0))
	check(model.fire(30,45,0),"Attributed XFS outfit can fire")
	for tick in range(2400):
		if model.phase!="flight": break
		model.advance_projectiles(1.0/120.0)
		sim.advance_projectiles(1.0/120.0)
	check(model.terrain.cells==sim.terrain.cells and model.actors[1].hp==sim.actors[1].hp and model.actors[1].shield==sim.actors[1].shield,"XFS attributes have identical live and predicted consequences")
	var negative: Array=p.catalog.find("xfs:1:1:5").bonuses
	model.start(1,1,42,"","original",null,[],[],[negative,[]])
	check(model.actors[0].attributes[4]==-3,"Negative delay survives combat snapshot sanitization")
	check(model.weapon_rules(0,0).delay>load("res://scripts/mobiles.gd").weapon(1,0).delay,"Negative delay modifier increases actual shot delay")
	var capped: Array=A.with_equipment([50,0,0,0,0,0,0,0],[21,18,-5,6,0,0,0,18])
	check(capped==[50,18,-5,6,0,0,0,18],"Gear is capped per statistic without spending the pilot point budget")
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=p
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening = 0
	scene.start_match()
	check(scene.model.actors[0].attributes==A.with_equipment(p.attributes,p.equipment_bonuses()),"Actual game scene passes equipped bonuses into battle")
	scene.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("XFS EQUIPMENT CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
