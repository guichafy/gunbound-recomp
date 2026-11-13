extends "res://tests/support/suite.gd"
const Model = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Contact = preload("res://scripts/aduka_combat.gd")
const JewelCombat = preload("res://scripts/jewel_combat.gd")

func fixture(vehicle: int = 2):
	var model = Model.new()
	model.start(vehicle,1,46,"","original",null,[],[],[],0,-1,[],"jewel")
	model.wind=Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active=false
	model.events.clear()
	return model

func run() -> void:
	var model = fixture()
	model.jewel_state.entities.clear()
	model.JewelRules.spawn(model.jewel_state,model.terrain,500,40)
	var entity: Dictionary=model.jewel_state.entities[0]
	entity.pos=Vector2i(500,200)
	check(Contact.point_contact(Vector2i(490,180),model.terrain,[],false,true,model).get("jewel",-1)==0,"Native inclusive JEWEL contact")
	check(Contact.point_contact(Vector2i(489,180),model.terrain,[],false,true,model).is_empty(),"Outside JEWEL contact")
	var ray := Contact.projectile_contact(Vector2i(450,190),Vector2i(550,190),model.terrain,[],{},model)
	check(ray.get("jewel",-1)==0 and Vector2(ray.position).x==490,"Native coarse/fine JEWEL contact kind")
	var copied = Snapshot.capture(model)
	var shell: Dictionary=model.projectile_parameters(0,30,50,0)[0]
	JewelCombat.impact(copied,Vector2(500,190),shell,model.BigfootCombat.parameters(shell,model.actors[0]))
	check(copied.jewel_state.entities[0].damage==86,"Native blast reaches jewel without mobile defense")
	check(entity.damage==0,"Copied blast does not mutate live jewel")
	JewelCombat.shock(model,Vector2i(500,200),40)
	check(entity.damage==0 and entity.owner==-1 and entity.pose=="shock","Shock does not credit blast damage")
	# A Nak S2 sweeps a jewel before the ground in the same tick. Jewel hits
	# retain actor=-1 for the existing API but are not subterranean entry.
	var nak=fixture(3)
	nak.terrain.cells.fill(0)
	nak.terrain.native_cells.fill(0)
	nak.terrain.cells[100*nak.terrain.WIDTH+65]=1
	nak.terrain.native_cells[200*1280+130]=1
	nak.jewel_state.entities.clear()
	nak.JewelRules.spawn(nak.jewel_state,nak.terrain,130,40,true)
	nak.jewel_state.entities[0].pos=Vector2i(120,210)
	nak.jewel_state.entities[0].drop=false
	var shot: Dictionary=nak.projectile_parameters(0,30,50,1)[0]
	shot.launched=true
	shot.age=0.2
	shot.spawn_at=0.0
	shot.hit_pos=Vector2(100,200)
	nak.Physics.seed(shot,Vector2i(100,200)*256,Vector2i(30,0)*256,Vector2i.ZERO)
	nak.projectiles=[shot]
	nak.shot_actor=0
	nak.shot_weapon=1
	nak.phase=nak.PHASE_FLIGHT
	nak.advance_projectiles(0.05)
	check(not bool(shot.get("underground",false)),"Jewel contact never starts Nak underground state")
	check(nak.events.any(func(event):return event.type=="explosion"),"Nak explodes on jewel before terrain")
	# All48 native weapon families execute and predict with one dispatcher.
	for vehicle in Model.PLAYABLE_VEHICLES:
		for weapon in 3:
			model=fixture(vehicle)
			var before: Dictionary=model.jewel_state.duplicate(true)
			var actual_shells: Array=model.shot_shells(0,35,55,weapon)
			var simulation=Snapshot.capture(model)
			Snapshot.arm(simulation,0,weapon,actual_shells)
			check(model.fire(35,55,weapon),"Legal JEWEL shot %d/%d" % [vehicle,weapon])
			for frame in 1000:
				if model.phase!=Model.PHASE_FLIGHT and simulation.phase!=Model.PHASE_FLIGHT:break
				model.advance_projectiles(0.05)
				simulation.advance_projectiles(0.05)
			check(model.phase!=Model.PHASE_FLIGHT and simulation.phase!=Model.PHASE_FLIGHT,"Full salvo and children resolved %d/%d" % [vehicle,weapon])
			check(model.jewel_state==simulation.jewel_state,"Live/predicted objective state identical %d/%d" % [vehicle,weapon])
			simulation.actors[0].ss_lock=model.actors[0].ss_lock # fire reserves SS; snapshot is already armed.
			check(model.terrain.cells==simulation.terrain.cells and model.actors==simulation.actors,"Live/predicted terrain and pilots identical %d/%d" % [vehicle,weapon])
			check(before.scores==[0,0],"Before-state remains private")
	# Dual / Dual+ and teleport retain their full emission semantics in JEWEL.
	for item in ["dual","dual_plus","teleport","thunder"]:
		model=fixture(1)
		model.actors[0].turn_item=item
		var outcome: Dictionary=model.predict_shot(0,35,55,0)
		check(outcome.has("jewel_scores") and outcome.has("jewel_damage"),"Item full-volley objective outcome "+item)
		check(model.jewel_state.scores==[0,0],"Prediction item does not spend/score live state")
	# CPU target is a jewel, and its worker never reads the live model.
	model=fixture()
	model.active=1
	var baseline: Dictionary=model.jewel_state.duplicate(true)
	var plan: Dictionary=model.begin_cpu_plan()
	check(plan.target!=model.actors[0].pos,"CPU targets JEWEL instead of pilot HP")
	plan.best_score=INF
	model.score_cpu_shot(plan,35,55)
	check(is_finite(float(plan.best_score)),"CPU evaluates full objective outcome")
	check(model.jewel_state==baseline,"CPU worker leaves live objective unchanged")
	model.finish_cpu_plan(plan)
	# Delayed bunge after last shell: the full objective prediction must include
	# the same idle physics while leaving turn counter and RNG untouched.
	model=fixture(4)
	model.jewel_state.entities.clear()
	model.JewelRules.spawn(model.jewel_state,model.terrain,500,40)
	var falling: Dictionary=model.jewel_state.entities[0]
	falling.pos=Vector2i(-20,int(model.terrain.world_size().y)-100)
	falling.owner=0
	falling.pose="damage"
	model.actors[0].pos=Vector2(model.terrain.world_size().x-20,100)
	model.actors[0].facing=1
	var predicted: Dictionary=model.predict_shot(0,0,100,0)
	check(predicted.jewel_scores==[5,0],"Prediction credits delayed void after final shell")
	check(model.jewel_state.scores==[0,0] and model.total_turns==1,"Delayed prediction neither scores live model nor advances turns")
	model.fire(0,100,0)
	for frame in 200:
		if model.phase!=Model.PHASE_FLIGHT:break
		model.advance_projectiles(0.05)
	for frame in 20:model.tick(0.05)
	check(model.jewel_state.scores==predicted.jewel_scores,"Delayed bunge prediction matches real idle ticks")
	var jd=load("res://scripts/jd_effect.gd")
	var crystal: Dictionary=jd.create({"weapon":2},Vector2(500,400),0)
	var jewel: Dictionary={"slot":0,"pos":Vector2i(510,400),"angle":0,"damage":0,"removed":false}
	var mine: Dictionary={"pos":Vector2(510,400)}
	jd.step(crystal,[],[mine],null,[],[jewel])
	check(jewel.damage==14 and bool(mine.get("jd_detonate",false)),"JD processes jewel and mine in the same tick")
	finish("JEWEL INTEGRATION CHECKS")
