extends "res://tests/support/suite.gd"
const JD = preload("res://scripts/jd_effect.gd")

func actor(x: float, vehicle: int = 9, shield: int = 0) -> Dictionary:
	return {"vehicle":vehicle,"pos":Vector2(x,500),"facing":1,"tilt":0.0,"hp":1000,"shield":shield,"attributes":[0,0,0,0,0,0,0,0]}
func effect(weapon: int = 1) -> Dictionary:
	return JD.create({"weapon":weapon,"damage":0},Vector2(500,500),0)

func run() -> void:
	var events: Array = []
	var targets := [actor(470),actor(530)]
	var pull := effect()
	check(JD.step(pull,targets,[],null,events),"T2 remains while it attracts")
	check(targets[0].pos.x == 472 and targets[1].pos.x == 528,"Flat native accumulated200/100 attracts both sides2px")
	check(events.is_empty() and targets[0].hp == 1000,"T2 crystal adds no duplicate primary damage")
	check(pull.pos == Vector2(500,500),"Crystal position stays fixed without gravity")
	var close := [actor(498),actor(502)]
	check(not JD.step(effect(),close,[],null,events),"T2 abs(dx)<=2 ends without jitter")
	check(close[0].pos.x == 498 and close[1].pos.x == 502,"T2 two-pixel deadzone is inclusive")
	var border := [actor(575),actor(574)] # JD bit4: 60+15=75.
	JD.step(effect(),border,[],null,events)
	check(border[0].pos.x == 575 and border[1].pos.x == 572,"Native radius exclusive75 with bit4 expansion")
	var debt_target := actor(530)
	debt_target.tilt = deg_to_rad(50.0) # attraction left: slope −50 -> debt350.
	JD.step(effect(),[debt_target],[],null,events)
	check(debt_target.pos.x == 527 and debt_target.jd_motion_debt == 50,"Slope preserves native quotient and residual")
	var special := effect(2)
	var shielded := [actor(510,9,20)]
	JD.step(special,shielded,[],null,events)
	check(shielded[0].shield == 7 and shielded[0].hp == 1000,"SS14*94/100 truncates13 and reduces shield first")
	JD.step(special,shielded,[],null,events)
	check(shielded[0].shield == 0 and shielded[0].hp == 994,"SS excess6 carries into HP")
	check(shielded[0].pos.x == 514,"SS repels instead of attracting")
	check(JD.ss_damage(actor(510,2)) == 14,"Bigfoot factor100+electric4 yields14 after truncation")
	check(JD.ss_damage(actor(510,4)) == 12,"Armor factor84+electric4 yields12")
	check(JD.ss_damage(actor(510,5)) == 12,"Trico factor92-electric4 yields12")
	check(JD.ss_damage(actor(510,15)) == 0,"Native type14 Knight is immune to SS damage")
	var knight := [actor(510,15)]
	JD.step(effect(2),knight,[],null,events)
	check(knight[0].pos.x == 512 and knight[0].hp == 1000,"Knight immunity does not block repulsion")
	var center := [actor(500)]
	JD.step(effect(2),center,[],null,events)
	check(center[0].hp == 987 and center[0].pos.x == 502,"SS damages centered actor without S2 deadzone; equality chooses right")
	var long_ss := effect(2)
	var durable := [actor(510)]
	var live := true
	for tick in range(22):
		live = JD.step(long_ss,durable,[],null,events)
		check(live == (tick < 21),"SS applies tick before the counter20 gate at tick%d"%tick)
	check(durable[0].hp == 714 and durable[0].pos.x == 554,"Native SS22 ticks produce13*22=286 and44px repulsion")
	var frozen := durable.duplicate(true)
	check(not JD.step(long_ss,durable,[],null,events) and durable == frozen,"Terminal effect never applies damage again")
	var copy := effect(2).duplicate(true)
	var original := copy.duplicate(true)
	JD.step(copy,[actor(510)],[],null,events)
	check(original.ticks == 0 and copy.ticks == 1,"Deep effect snapshot keeps native counters private")
	var mines: Array = [{"pos":Vector2(530,500)}]
	check(JD.step(effect(),[],mines,null,events),"Mine attraction alone keeps T2 alive")
	check(mines[0].pos.x == 528,"T2 attracts nearby mines without ownership changes")
	JD.step(effect(2),[],mines,null,events)
	check(mines[0].jd_detonate,"SS requests native mine detonation")
	# Eight neighbors: independent circle fixture; the diagonal boundary
	# (45,60) is exactly75 for JD, so only the 74px cardinals are in range.
	var neighbors: Array = []
	for point in [Vector2(-74,0),Vector2(74,0),Vector2(0,-74),Vector2(0,74),Vector2(-45,-60),Vector2(45,-60),Vector2(-45,60),Vector2(45,60)]:
		var next := actor(500+point.x)
		next.pos.y += point.y
		neighbors.append(next)
	JD.step(effect(2),neighbors,[],null,events) # SS expanded radius85 includes all8.
	for neighbor in neighbors:
		check(neighbor.hp == 987,"SS tests the complete circular neighborhood")
	var exact_border := actor(585)
	JD.step(effect(2),[exact_border],[],null,events)
	check(exact_border.hp == 1000,"SS JD85px boundary is excluded from damage")
	var defense := actor(510)
	defense.attributes[2] = 50
	check(JD.ss_damage(defense) == 7,"Defense50 bridge is14*(94-40)/100 truncated7")
	defense.attributes[2] = -50
	check(JD.ss_damage(defense) == 18,"Negative Defense50 bridge is14*(94+40)/100 truncated18")
	var mirror := [actor(490),actor(510)]
	JD.step(effect(2),mirror,[],null,events)
	check(mirror[0].pos.x == 488 and mirror[1].pos.x == 512,"SS repulsion mirrors on both sides")
	var terminal_t2 := effect()
	var slow := actor(570)
	# Native residual100 must not move until the next tick.
	slow.tilt = deg_to_rad(-34.1)
	JD.step(terminal_t2,[slow],[],null,events)
	check(slow.pos.x == 570 and slow.jd_motion_debt == 98,"Native subpixel attraction stores98 before moving")
	# Counter boundaries are tested with a reset target still within range.
	terminal_t2 = effect()
	for tick in range(20):
		var still_present := JD.step(terminal_t2,[actor(530)],[],null,events)
		check(still_present == (tick < 19),"T2 applies before counter18 lifetime gate%d"%tick)
	var bits8 := actor(589,2) # r60*1.5=90.
	JD.step(effect(),[bits8],[],null,events)
	check(bits8.pos.x == 587,"Bit8 expands T2 range to90")
	var dead := actor(510)
	dead.hp=0
	check(not JD.step(effect(2),[dead],[],null,events) and dead.pos.x == 510,"Dead actor cannot keep crystal alive")
	finish("JD_EFFECT CHECKS")
