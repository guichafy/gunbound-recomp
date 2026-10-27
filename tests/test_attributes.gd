extends "res://tests/support/suite.gd"
func run() -> void:
	var A = load("res://scripts/player_attributes.gd")
	var Mobiles = load("res://scripts/mobiles.gd")
	check(A.has_method("damage"), "Combat modifiers exist")
	if failures == 0:
		check(A.damage(200,30,20) == 220, "Attack minus defense")
		check(A.health(760,50) == 1140, "Health")
		check(A.heal(35,10) == 38, "Regeneration truncation")
		check(is_equal_approx(A.delay(770,33),515.0/7.5), "Delay original units")
		check(A.delay(600,50) == 40.0, "ItemDelay contract")
		check(A.crater(25.0,50) == 37.5, "Dig")
		var Match = load("res://scripts/match.gd")
		var F = load("res://scripts/flight_snapshot.gd")
		for mobile in [1,2]:
			for weapon in range(3):
				var m = Match.new()
				var values := [[30,50,0,30,20,0,50,0],[0,0,20,0,0,0,0,0]]
				m.start(mobile,1,42,"","original",null,[],values)
				values[0][1] = 0
				check(m.actors[0].hp == (1095 if mobile == 1 else 1650), "Copied max health")
				check(m.actors[0].attributes[6] == 50, "Dig survives valid 180 point fixture")
				check(m.actors[0].shield == (220 if mobile == 1 else 0), "Shield base")
				m.actors[0].turns = 3
				var sim = F.capture(m)
				F.arm(sim,0,weapon,m.projectile_parameters(0,30,65,weapon))
				check(m.fire(30,65,weapon), "Attributed fire")
				for frame in range(2000):
					if m.phase != "flight":
						break
					m.advance_projectiles(1.0/120.0)
					sim.advance_projectiles(1.0/120.0)
				check(m.actors[1].hp == sim.actors[1].hp and m.actors[0].shield == sim.actors[0].shield, "Live and prediction damage equal")
				check(m.terrain.cells == sim.terrain.cells, "Live and prediction craters equal")
				check(m.weapon_rules(0,weapon).delay < Mobiles.weapon(mobile,weapon).delay, "Shot delay decreased")
				sim.actors[0].attributes[0] = 0
				check(m.actors[0].attributes[0] == 30, "Snapshot attributes isolated")
		var m = Match.new()
		m.start(1,1,42,"","original",null,[],[[0,0,0,50,50,0,0,0]])
		m.actors[0].hp = 500
		m.actors[0].shield = 100
		m.begin_turn()
		check(m.actors[0].shield == 145, "Mage regen 30 times1.5")
		m.weather.calendar.fill(5)
		m.begin_turn()
		check(m.actors[0].hp == 521, "Native Moon gives3% maxHP independently of REGEN50")
		m.start(1,1,42,"","original",null,[],[[30,0,0,0,0,0,0,0],[0,0,20,0,0,0,0,0]])
		m.blast(load("res://scripts/combat.gd").full_hit(m.actors[1], 25.0),25,200,0,0,0)
		check(m.actors[1].hp == 880, "Live damage uses attack minus defense")
		m.start(1,1,42,"","original",null,[],[[0,0,0,0,0,0,50,0]])
		m.terrain.cells.fill(1)
		m.terrain.native_cells = PackedByteArray()
		m.terrain.enable_native()
		m.explode(Vector2(400,200),-1,m.projectile_parameters(0,30,65,0)[0])
		check(not m.terrain.is_solid(Vector2(462,200)) and m.terrain.is_solid(Vector2(466,200)), "Native Mage Dig50 adds25px to diameter66 before aspect143 scanline")
	finish("ATTRIBUTES CHECKS")
