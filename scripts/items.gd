extends RefCounted
## OpenBound battle items (Item.cs, NetworkObjectParameters.cs, Language.cs).
## Catalog only: match.gd applies the rules, the HUD and the menu read it.
## Copyright (C) 2020, Carlos H.M.S.; reference logic GPL-3.0-or-later.

# Item.ItemPresets order: 2-slot items first, then 1-slot items.
const ORDER := ["dual", "dual_plus", "thunder", "energy_up_2", "team_teleport", "teleport",
	"blood", "bunge_shot", "power_up", "change_wind", "energy_up_1"]
const MAX_SLOTS := 6
# Same conversion as Mage/Bigfoot delays (MAGE_0_4.md): original units ÷ 7.5.
# Costs are the delay column of the original itemdata.dat (ADR-075); Teleport,
# Dual+, Energy Up 2, Change Wind and Bunge Shot differ from the C# constants.
const DELAY_SCALE := 7.5
# Parameter.TextColorItem*.
const CATEGORY_COLORS := {"red": Color8(156, 56, 16), "green": Color8(98, 149, 74),
	"blue": Color8(82, 121, 164), "purple": Color8(131, 105, 131)}
const DEFAULT_LOADOUT := ["dual", "teleport", "power_up", "energy_up_1"]
# InGameItem*Value; Bionic armour adds the Extra value (neither mobile is Bionic).
const ENERGY_UP_1 := 12.0
const ENERGY_UP_2 := 30.0
const ENERGY_UP_EXTRA := 3.0
const BLOOD_ATTACK := 33.0
const BLOOD_HEALTH := 8.0
const POWER_UP_ATTACK := 30.0
const BUNGE_SHOT_DIG := 25.0
const CHANGE_WIND_DEGREES := 180
# TeleportationBeacon: mass 10 against the 14 of every shell (Combat.SHELL_MASS;
# speed is force × 100 / mass) and wind influence 0.
const BEACON_SPEED := 14.0 / 10.0
const BEACON_WIND := 0.0
# Mobile.ShootWithModifiers: the second shot starts 1 s after the last spawn.
const DUAL_WAIT := 1.0

const DEFINITIONS := {
	"dual": {"name": "Dual", "file": "Dual", "slots": 2, "category": "red", "cost": 600, "turn": true,
		"description": "A mobile shoots two of the same primary projectiles.\nYou will not be able to use SS this turn. Effects\nare dismissed when the turn is over."},
	"dual_plus": {"name": "Dual+", "file": "DualPlus", "slots": 2, "category": "red", "cost": 250, "turn": true,
		"description": "A mobile shoots two different primary projectiles,\nthe first is always the one you have selected. You\nwill not be able to use SS this turn. Effects are\ndismissed when the turn is over."},
	"thunder": {"name": "Thunder", "file": "Thunder", "slots": 2, "category": "red", "cost": 200, "turn": true,
		"description": "Embodies thunder property on each fired shot. Does\nnot stack with weather's thunder. You will not be\nable to use SS this turn. Effects are dismissed\nwhen the turn is over."},
	"energy_up_2": {"name": "Energy Up 2", "file": "EnergyUp2", "slots": 2, "category": "green", "cost": 300, "turn": false,
		"description": "Recovers 30% of the mobile's maximum energy. Does\nnot replenish shield. Bionic mobiles receive an\nextra 3% of health at no extra cost."},
	"team_teleport": {"name": "Team Teleport", "file": "TeamTeleport", "slots": 2, "category": "purple", "cost": 50, "turn": false,
		"description": "Switches position with the most wounded teammate\n(Remaining energy), excluding yourself. Shields are\nnot accounted for."},
	"teleport": {"name": "Teleport", "file": "Teleport", "slots": 2, "category": "purple", "cost": 100, "turn": true,
		"description": "Turns the projectile into a Teleportation beacon.\nThe mobile is teleported to the position where the\nbeacon has hit the floor. Effects are dismissed\nwhen the turn is over."},
	"blood": {"name": "Blood", "file": "Blood", "slots": 1, "category": "red", "cost": 0, "turn": true,
		"description": "Exchanges 8% of mobile's energy for an extra 33%\nprojectile power. This item can not set user's\nenergy to 0. You will not be able to use SS this\nturn. Effects are dismissed when the turn is over."},
	"bunge_shot": {"name": "Bunge Shot", "file": "BungeShot", "slots": 1, "category": "red", "cost": 50, "turn": true,
		"description": "Increases the explosion's area of influence by 25%.\nNot increasing damage but destroying more land."},
	"power_up": {"name": "Power Up", "file": "PowerUp", "slots": 1, "category": "red", "cost": 150, "turn": true,
		"description": "Increases a projectile destructible power. Adds 30%\nmore damage into the next projectile."},
	"change_wind": {"name": "Change Wind", "file": "ChangeWind", "slots": 1, "category": "blue", "cost": 150, "turn": false,
		"description": "Instantly changes the wind to it's opposite\ndirection."},
	"energy_up_1": {"name": "Energy Up 1", "file": "EnergyUp1", "slots": 1, "category": "green", "cost": 100, "turn": false,
		"description": "Recovers 12% of the mobile's maximum energy. Does\nnot replenish shield. Bionic mobiles receive an\nextra 3% of health at no extra cost."},
}

static func has_id(id: String) -> bool:
	return DEFINITIONS.has(id)

static func definition(id: String) -> Dictionary:
	return DEFINITIONS[id]

static func slots(id: String) -> int:
	return int(DEFINITIONS[id].slots)

## MatchManager.ComputePlayerItem with the allocated ItemDelay, in prototype delay units.
static func delay(id: String, reduction: int = 0) -> float:
	return int(int(DEFINITIONS[id].cost)*(1.0-reduction/100.0)) / DELAY_SCALE

static func color(id: String) -> Color:
	return CATEGORY_COLORS[DEFINITIONS[id].category]

## Owner.Attack added for the turn (Projectile.CalculateDamage multiplier).
static func attack(id: String) -> float:
	return POWER_UP_ATTACK if id == "power_up" else (BLOOD_ATTACK if id == "blood" else 0.0)

## Owner.Dig added for the turn (crater radius multiplier).
static func dig(id: String) -> float:
	return BUNGE_SHOT_DIG if id == "bunge_shot" else 0.0

static func used_slots(loadout: Array) -> int:
	var total := 0
	for id in loadout:
		total += slots(id)
	return total

## EquippedButtonBar.AddItemIntoBarAction: unknown ids dropped, 6 slots at most.
static func sanitize(loadout: Array) -> Array:
	var result: Array = []
	var total := 0
	for id in loadout:
		if not id is String or not has_id(id):
			continue
		if total + slots(id) > MAX_SLOTS:
			continue
		result.append(id)
		total += slots(id)
	return result
