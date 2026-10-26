extends RefCounted
## The 13 Thor's Hammer mobiles that join Mage (1), Bigfoot (2) and Nak (3).
## Numbers are the decoded characterdata.dat row (client id = tank index - 1):
## life [22], shield [23], shield regen [24], time factor [29], delay [28]+[30/31/32],
## aim [4]/[3] (and the same pairs at [10]/[9] and [16]/[15]), power [44]/[57]/[70]
## and radius half of [47]/[60]/[73]. Same reading as Nak (ADR-074/076).
## Godot ids stay clear of 0 and of 1–3.

const IDS := [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

static func shot(label: String, damage: float, radius: float, cost: int, extra: Dictionary = {}) -> Dictionary:
	var rules := {"name": label, "damage": damage, "radius": radius, "cost": cost, "count": 1, "color": Color("f2d48a")}
	rules.merge(extra)
	return rules

static func orbit(offset: Vector2, spin: float, phase: float) -> Dictionary:
	return {"spawn": 0.0, "angle": 0.0, "power": 0.0, "orbit": offset, "spin": spin, "phase": phase}

static func definitions() -> Dictionary:
	return {
		4: _body("Armor", "armor", 1000, 0, 0, 10, false, Vector2(30, 40), 25.0, 0.1, true,
			[shot("Tiro 1", 280, 34, 770),
			shot("Tiro 2", 236, 28, 960),
			shot("SS", 280, 35, 1320, {"flight": "open", "transform_at": 2.0, "extra_damage": 50, "extra_radius": 25.0})],
			[Vector2(10, 55), Vector2(10, 50), Vector2(10, 50)],
			"1000 de vida · SS abre no ar."),
		5: _body("Trico", "trico", 1050, 0, 0, 10, true, Vector2(40, 33), 25.0, 0.7, false,
			[shot("Tiro 1", 200, 35, 740),
			shot("Tiro 2", 150, 24, 890, {"shells": [orbit(Vector2(35, 0), PI, 1.0), orbit(Vector2.ZERO, PI, 1.0), orbit(Vector2(-35, 0), PI, 1.0)]}),
			shot("SS", 256, 60, 1290, {"flight": "chain", "chain": 8, "chain_gap": 0.1, "chain_step": 20.0})],
			[Vector2(10, 50), Vector2(10, 50), Vector2(20, 40)],
			"1050 de vida · S2 em três órbitas · SS em leque."),
		6: _body("Boomer", "boomer", 1000, 0, 0, 10, true, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 254, 24, 730, {"boomer": true, "shells": [{"spawn": 0.4, "angle": 0.0, "power": 0.0}]}),
			shot("Tiro 2", 118, 21, 880, {"boomer": true, "shells": [{"spawn": 0.4, "angle": 0.0, "power": 0.0}, {"spawn": 0.5, "angle": 0.0, "power": 0.0}, {"spawn": 0.6, "angle": 0.0, "power": 0.0}, {"spawn": 0.7, "angle": 0.0, "power": 0.0}]}),
			shot("SS", 350, 23, 1280, {"boomer": true, "boomer_ss": true, "boomer_diameter": 46, "shells": [{"spawn": 0.4, "angle": 0.0, "power": 0.0}]})],
			[Vector2(10, 90), Vector2(10, 90), Vector2(10, 90)],
			"1000 de vida · mira larga 10–90°."),
		7: _body("Raon", "raon", 1050, 0, 0, 10, false, Vector2(30, 38), 20.0, 0.7, true,
			[shot("Tiro 1", 90, 27, 750, {"flight":"raon_orbit","shells": [{"spawn":0.0,"angle":0.0,"power":0.0,"raon_component":0},{"spawn":0.0,"angle":0.0,"power":0.0,"raon_component":1},{"spawn":0.0,"angle":0.0,"power":0.0,"raon_component":2}]}),
			# Mobile06_MainAction: S2 is P+15/P−15 at one angle, SS is P+15 (ADR-116).
			# SimulateShot_Bullet7n_9s_7p_9p never calls HitTestMobilesAndJewels.
			shot("Tiro 2", 0, 0, 900, {"flight": "mine", "mine_damage":200,"mine_radius":21.0,"skip_actors":true,"shells": [{"spawn": 0.0, "angle": 0.0, "power": 0.0, "native_power": 15}, {"spawn": 0.0, "angle": 0.0, "power": 0.0, "native_power": -15}]}),
			shot("SS", 0, 0, 1300, {"flight": "mine", "mine_damage":400,"mine_radius":21.0,"mine_crawl":true,"skip_actors":true,"shells": [{"spawn": 0.0, "angle": 0.0, "power": 0.0, "native_power": 15}]})],
			[Vector2(10, 50), Vector2(10, 50), Vector2(10, 50)],
			"1050 de vida · S2 e SS plantam mina."),
		8: _body("Lightning", "lightning", 750, 300, 20, 10, false, Vector2(41, 30), 23.0, 0.0, true,
			[shot("Tiro 1", 230, 27, 750, {"bolt": 95.0, "bolt_extra": 55.0, "bolt_radius": 25.0, "bolt_extra_radius": 25.0, "bolt_angles": [PI * 0.5]}),
			shot("Tiro 2", 240, 20, 800, {"bolt": 100.0, "bolt_extra": 35.0, "bolt_radius": 25.0, "bolt_extra_radius": 25.0, "bolt_count": 4, "bolt_angles": [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]}),
			shot("SS", 230, 20, 1300, {"bolt": 95.0, "bolt_extra": 55.0, "bolt_radius": 25.0, "bolt_extra_radius": 25.0, "bolt_count": -1, "bolt_reach": 100.0})],
			[Vector2(18, 40), Vector2(18, 40), Vector2(23, 35)],
			"750 de vida · 300 de escudo · raio no impacto."),
		9: _body("JD", "jd", 700, 250, 30, 10, false, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 180, 32, 740),
			# JD's specialized crystal animation applies attraction/SS repulsion;
			# it is a stationary model effect, not a falling common projectile.
			shot("Tiro 2", 240, 27, 830, {"flight": "crystal"}),
			# Slots [70..72] are 0. DetonateSuperShot_Bullet9 spawns the same kind of crystal.
			shot("SS", 0, 15, 1290, {"flight": "crystal"})],
			[Vector2(15, 55), Vector2(15, 55), Vector2(15, 55)],
			"700 de vida · 250 de escudo."),
		10: _body("ASate", "asate", 750, 200, 30, 10, false, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 0, 27, 730, {"flight":"asate_guide","child_damage":190}), shot("Tiro 2", 0, 23, 880, {"flight":"asate_guide","child_damage":160}), shot("SS", 0, 22, 1280, {"flight":"asate_guide","child_damage":140})],
			[Vector2(20, 60), Vector2(20, 60), Vector2(25, 55)],
			"750 de vida · 200 de escudo."),
		11: _body("Ice", "ice", 1200, 0, 0, 10, true, Vector2(40, 33), 25.0, 0.7, false,
			[shot("Tiro 1", 220, 33, 740),
			shot("Tiro 2", 310, 28, 890, {"chill": -5}),
			shot("SS", 350, 30, 1290)],
			[Vector2(20, 70), Vector2(20, 70), Vector2(30, 60)],
			"1200 de vida · S2 reduz a defesa."),
		12: _body("Turtle", "turtle", 960, 0, 0, 12, true, Vector2(38, 33), 23.0, 0.0, false,
			[shot("Tiro 1", 230, 28, 740),
			shot("Tiro 2", 224, 23, 890, {"flight":"turtle_wave", "shells":[{"spawn":0.0,"angle":0.0,"power":0.0,"wave_phase":0},{"spawn":0.0,"angle":0.0,"power":0.0,"wave_phase":180}]}),
			shot("SS", 300, 23, 1290, {"flight": "open", "transform_at": 2.2, "transform_ticks": 44, "transform_hold": 0.5, "extra_damage": 0, "extra_radius": 23.0, "burst": 6, "burst_spread": 12.0})],
			[Vector2(25, 50), Vector2(25, 50), Vector2(25, 50)],
			"960 de vida · o tempo gasto pesa 12."),
		13: _body("Grub", "grub", 1000, 0, 0, 10, true, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 190, 25, 740), shot("Tiro 2", 94, 19, 890),
			shot("SS", 26, 18, 1290, {"skip_actors": true})],
			[Vector2(30, 60), Vector2(30, 60), Vector2(30, 60)],
			"1000 de vida · biônico."),
		# tank14.img is the Dragon. Bullet14's SS spawns the five children.
		14: _body("Dragon", "dragon", 1000, 0, 0, 10, false, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 290, 29, 800), shot("Tiro 2", 200, 27, 950),
			shot("SS", 160, 27, 1390, {"flight": "split", "burst": 5, "burst_spread": 18.0})],
			[Vector2(30, 60), Vector2(30, 60), Vector2(30, 60)],
			"1000 de vida · atraso alto."),
		# tank15.img is the Knight. The client simulates it with the common shell.
		15: _body("Knight", "knight", 1000, 0, 0, 10, false, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 136, 24, 800), shot("Tiro 2", 128, 20, 950), shot("SS", 126, 20, 1390)],
			[Vector2(10, 80), Vector2(10, 80), Vector2(10, 80)],
			"1000 de vida · mira 10–80°."),
		# tank16.img is the Aduka. It aims 130–170°, so the art faces the other way.
		# Power slots [57..82] of this row are 0.
		16: _body("Aduka", "aduka", 1000, 0, 0, 10, false, Vector2(40, 34), 25.0, 0.0, false,
			[shot("Tiro 1", 152, 32, 760), shot("Tiro 2", 0, 0, 910, {"flight":"aduka"}), shot("SS", 0, 0, 1310, {"flight":"aduka"})],
			[Vector2(10, 50), Vector2(10, 50), Vector2(10, 50)],
			"1000 de vida · atira pelas costas.", true),
	}

static func _body(label: String, kind: String, hp: int, shield: int, shield_regen: int, time_delay: int, bionic: bool, box: Vector2, stance: float, beacon: float, smoke: bool, weapons: Array, aims: Array, summary: String, rear: bool = false) -> Dictionary:
	return {
		"name": label, "kind": kind, "hp": hp, "move": 90.0, "delay": 0.0, "time_delay": time_delay,
		"color": Color("f2d48a"), "shield": shield, "shield_regen": shield_regen, "hp_regen": 10 if bionic else 0,
		"protection": 70 if bionic else 35, "box": box, "box_offset": Vector2(0, 10 if stance >= 23.0 else 0),
		"stance": stance, "beacon_delay": beacon, "smoke": smoke, "bionic": bionic, "rear": rear,
		"weapons": weapons, "aim_limits": aims, "spread_after_clamp": false, "generic_trail": false,
		"shot_sound_on": "fire", "death": 1.15, "hurt": 1.05, "special": 2, "summary": summary,
	}

static func emission(rules: Dictionary) -> Array:
	if rules.has("shells"):
		var shells: Array = rules.shells.duplicate(true)
		for shell in shells:
			shell.flight = str(rules.get("flight", ""))
		return shells
	return [{"spawn": 0.0, "angle": 0.0, "power": 0.0}]
