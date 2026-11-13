extends "res://tests/support/suite.gd"
const Aux = preload("res://scripts/jewel_aux.gd")
func jewel(at: Vector2i, slope: int = 0, slot: int = 0) -> Dictionary:
	return {"slot":slot,"type":0,"pos":at,"angle":slope,"damage":0,"owner":-1,"removed":false,"drop":false}
func run() -> void:
	var effect := {"pos":Vector2i(100,100),"weapon":1,"owner":1}
	var target := jewel(Vector2i(110,100))
	check(Aux.jd_step(effect,[target]), "T2 jewel counts toward work/retention")
	check(target.pos == Vector2i(108,100) and target.jd_motion_debt == 0, "T2 flat attracts2px with own debt")
	check(target.damage == 0 and target.owner == -1, "T2 motion transfers no damage/author")
	for x in [98,99,100,101,102,160]:
		target = jewel(Vector2i(x,100))
		check(not Aux.jd_step(effect,[target]), "T2 excludes absdx<=2 and exactradius60 x%d" % x)
	target = jewel(Vector2i(110,100),50)
	check(Aux.jd_step(effect,[target]) and target.pos.x == 110 and target.jd_motion_debt == 100, "strict debt>100 waits at100")
	Aux.jd_step(effect,[target])
	check(target.pos.x == 108 and target.jd_motion_debt == 0, "second slope50 tick releases accumulated2px")
	target = jewel(Vector2i(110,100),81)
	check(not Aux.jd_step(effect,[target]) and target.pos.x == 110, "slope81 exceeds80 cutoff")
	target = jewel(Vector2i(110,100),-20)
	Aux.jd_step(effect,[target])
	check(target.pos.x == 108 and target.jd_motion_debt == 40, "raw negative slope uses240debt without facing normalization")
	effect.weapon = 2
	target = jewel(Vector2i(110,100),81)
	check(not Aux.jd_step(effect,[target]), "SS damage alone does not make crystal work")
	check(target.damage == 14 and target.owner == 1, "SS raw14 and author are assigned before slope gate")
	target = jewel(Vector2i(100,100))
	check(Aux.jd_step(effect,[target]) and target.pos.x == 98 and target.damage == 14, "SS equalX repulsesleft and still damages")
	target = jewel(Vector2i(168,100))
	check(not Aux.jd_step(effect,[target]) and target.damage == 0, "SS exactradius68 excludes damage")
	target = jewel(Vector2i(110,100)); target.removed = true
	check(not Aux.jd_step(effect,[target]) and target.damage == 0, "removed objects leave native list")
	var near := jewel(Vector2i(100,219),0,7)
	var exact := jewel(Vector2i(100,220),0,0)
	var inside := jewel(Vector2i(100,100),0,2)
	var source: Array = [near,exact,inside]
	var before := source.duplicate(true)
	var selected: Array = Aux.lightning_targets(source,Vector2i(100,100))
	check(selected == [Vector2i(100,100),Vector2i(100,219)], "SS selectsJewelPOSwithstrict120radius in slot order; noYminus10")
	check(source == before, "Lightning target selection reads private state without mutation")
	for distance in [7,8,9]:
		target = jewel(Vector2i(100+distance,100))
		target.drop = true
		check(Aux.mine_touching([target], Vector2i(100,100)) == (distance < 8), "Raon8pxstrictJeweltrigger includesdrop; distance%d" % distance)
	target = jewel(Vector2i(110,100))
	for _tick in 22:
		Aux.jd_step(effect,[target])
	check(target.damage == 308 and target.pos == Vector2i(154,100), "SS22nativecalls contribute308rawdamage and44pxrepulsion")
	finish("JEWEL AUX CHECKS")
