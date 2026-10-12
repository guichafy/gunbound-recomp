extends RefCounted
## Hit resolution. Match owns the actors and the event queue and calls in.

const Combat = preload("res://scripts/combat.gd")

static func deal_damage(actors: Array, events: Array, index: int, damage: int) -> int:
	if damage <= 0:
		return 0
	var absorbed := mini(damage, int(actors[index].shield))
	if absorbed > 0:
		actors[index].shield -= absorbed
		events.append({"type": "shield_damage", "actor": index, "amount": absorbed, "position": actors[index].pos})
	var remaining := damage - absorbed
	if remaining > 0:
		actors[index].hp = maxi(0, int(actors[index].hp) - remaining)
		events.append({"type": "damage", "actor": index, "amount": remaining, "position": actors[index].pos})
	return damage

static func blast(actors: Array, events: Array, position: Vector2, radius: float, damage: float, emp: float = 0.0) -> int:
	var dealt := 0
	for index in range(actors.size()):
		if int(actors[index].hp) <= 0:
			continue
		var distance := position.distance_to(actors[index].pos)
		if emp > 0 and distance <= emp + 22.0 and int(actors[index].shield) > 0:
			events.append({"type": "shield_damage", "actor": index, "amount": actors[index].shield, "position": actors[index].pos})
			actors[index].shield = 0
		dealt += deal_damage(actors, events, index, Combat.damage_at(distance, damage, radius))
	return dealt
