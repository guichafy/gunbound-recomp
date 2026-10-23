extends RefCounted
## Gold metadata of one shot (GoldRewards inputs), moved out of Match (ADR-081).
## The state stays in Match.shot_gold, a FlightSnapshot field, so the CPU
## prediction keeps its own copy; this script only fills and closes it.

const GoldRewards = preload("res://scripts/gold_rewards.gd")
const Attributes = preload("res://scripts/player_attributes.gd")

## Fresh record when a shot is fired; the HUD angle is the trajectory + 180.
static func begin(model, angle: float, power: float, weapon: int) -> Dictionary:
	var shooter: Dictionary = model.actors[model.active]
	var launch_angle: float = rad_to_deg(model.shot_velocity(model.active, angle, power, weapon).angle()) + 180.0
	return {"enemy_damage": 0, "ally_damage": 0, "enemy_kills": 0, "ally_kills": 0, "angle": fposmod(launch_angle, 360.0),
		"travelled": 0.0, "tornado": false, "mirror": false, "boomer": false, "backward": false,
		"facing": shooter.facing, "start": shooter.pos, "dead": [model.actors[0].hp <= 0, model.actors[1].hp <= 0]}

## Damage dealt by the events after `event_start` (one explosion). Only positive
## hits count; boomer/backward need an enemy hit.
static func collect(model, event_start: int, impact: Vector2, projectile: Dictionary) -> void:
	var gold: Dictionary = model.shot_gold
	if gold.is_empty():
		return
	var any_hit := false
	var enemy_hit := false
	for event in model.events.slice(event_start):
		if event.type in ["damage", "shield_damage"] and not event.get("emp", false) and int(event.amount) > 0:
			var key := "ally_damage" if int(event.actor) == model.shot_actor else "enemy_damage"
			gold[key] += int(event.amount)
			any_hit = true
			enemy_hit = enemy_hit or int(event.actor) != model.shot_actor
	if not any_hit:
		return
	gold.travelled = maxf(float(gold.travelled), float(projectile.get("age", 0)))
	for effect in projectile.get("influenced", []):
		if effect in ["tornado", "mirror"]:
			gold[effect] = true
	if not enemy_hit:
		return
	var dx: float = impact.x - Vector2(gold.start).x
	var angle := float(gold.angle)
	var facing := int(gold.facing)
	gold.boomer = bool(gold.boomer) or (facing == -1 and dx < 0 and angle > 90) or (facing == 1 and dx > 0 and angle < 90)
	gold.backward = bool(gold.backward) or (facing == -1 and dx > 0) or (facing == 1 and dx < 0)

## FinishGoldShot: counts kills once after settling and pays the shooter.
static func finish(model) -> void:
	var gold: Dictionary = model.shot_gold
	if gold.is_empty():
		return
	for index in range(model.actors.size()):
		if not bool(gold.dead[index]) and int(model.actors[index].hp) <= 0:
			gold["ally_kills" if index == model.shot_actor else "enemy_kills"] += 1
	var shooter: Dictionary = model.actors[model.shot_actor]
	shooter.gold_state = GoldRewards.apply_shot(shooter.gold_state, gold, Attributes.points(shooter, Attributes.POPULARITY))
	model.shot_gold = {}

static func player_reward(model, player: int) -> int:
	return int(model.actors[player].gold_state.gold) + GoldRewards.result_bonus(model.winner == player, model.winner == -1)
