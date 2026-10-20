extends RefCounted
## Hit resolution. Match owns the actors and the event queue and calls in.

const Attributes = preload("res://scripts/player_attributes.gd")
const Combat = preload("res://scripts/combat.gd")

static func deal_damage(actors: Array, events: Array, index: int, damage: int, kind: String = "") -> int:
	if damage <= 0:
		return 0
	var absorbed := mini(damage, int(actors[index].shield))
	if absorbed > 0:
		actors[index].shield -= absorbed
		var shield_event := {"type": "shield_damage", "actor": index, "amount": absorbed, "position": actors[index].pos}
		if kind != "":
			shield_event["kind"] = kind
		events.append(shield_event)
	var remaining := damage - absorbed
	if remaining > 0:
		actors[index].hp = maxi(0, int(actors[index].hp) - remaining)
		var hp_event := {"type": "damage", "actor": index, "amount": remaining, "position": actors[index].pos}
		if kind != "":
			hp_event["kind"] = kind
		events.append(hp_event)
	return damage

## Attack and defense scale only the blast. EMP adds the current shield after that,
## so the shield portion is absorbed and is not multiplied again.
static func blast(actors: Array, events: Array, position: Vector2, radius: float, damage: float, emp: float = 0.0, attack: float = 0.0, shooter: int = -1) -> int:
	var dealt := 0
	for index in range(actors.size()):
		if int(actors[index].hp) <= 0:
			continue
		var gap := Combat.box_gap(position, actors[index])
		var hp_damage := 0
		if gap < radius:
			var center := position.distance_to(Combat.box_center(actors[index]))
			hp_damage = Combat.blast_damage(center, damage, radius)
			if shooter >= 0:
				hp_damage = Attributes.damage(hp_damage, Attributes.points(actors[shooter], 0) + int(attack), Attributes.points(actors[index], 2))
			elif attack != 0.0:
				hp_damage = int(hp_damage * (1.0 + attack / 100.0))
		var shield_bonus := int(actors[index].shield) if emp > 0.0 and gap < emp else 0
		dealt += deal_damage(actors, events, index, hp_damage + shield_bonus)
	return dealt
