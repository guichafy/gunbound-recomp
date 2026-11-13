extends RefCounted
## Native consumers omitted by the original offline actors/mines-only helpers.
## docs/jewel-implementation/lifecycle/AUXILIARIES.md. No turn clocks, render,
## terrain collision or crystal TTL here: the common scheduler owns them.
static func _int32(value: int) -> int:
	var wrapped := value & 0xffffffff
	return wrapped - 0x100000000 if wrapped >= 0x80000000 else wrapped

static func _live(entity: Dictionary) -> bool:
	return not bool(entity.get("removed", false)) and int(entity.get("slot", -1)) >= 0 and int(entity.get("slot", -1)) < 8

static func _within(at: Vector2i, center: Vector2i, radius: int) -> bool:
	var dx := _int32(at.x - center.x)
	var dy := _int32(at.y - center.y)
	return _int32(_int32(dx * dx) + _int32(dy * dy)) < _int32(radius * radius)

## Applies one JD tick and returns the additional native 'working' flag.
## Caller must OR this with actor/mine work BEFORE applying the crystal's
## post-effect counter gate (T2 <=18, SS <=20). Does not advance effect.ticks.
static func jd_step(effect: Dictionary, entities: Array) -> bool:
	var repulse := int(effect.weapon) == 2
	var radius := 68 if repulse else 60
	var center := Vector2i(effect.pos)
	var working := false
	for entity in entities:
		if not _live(entity):
			continue
		var at := Vector2i(entity.pos)
		if not _within(at, center, radius):
			continue
		# Jewel branch 490361..4903a1 reads JD[82] directly: no per-mobile
		# factor, Defense or PowerUp. It does not invoke the damage pose.
		if repulse:
			entity.damage = _int32(int(entity.get("damage", 0)) + 14)
			entity.owner = int(effect.get("owner", 255)) & 255
		elif absi(center.x - at.x) <= 2:
			continue
		var slope := int(entity.get("angle", 0))
		if slope > 80:
			continue
		working = true
		var debt := _int32(int(entity.get("jd_motion_debt", 0)) + (100 - slope) * 2)
		if debt > 100:
			# Native compares center with Jewel X; equalX SS takes subtract.
			var direction := 1 if (center.x < at.x if repulse else center.x > at.x) else -1
			at.x += direction * int(debt / 100)
			debt %= 100
			entity.pos = at
		entity.jd_motion_debt = debt
	return working

## 4837e0's second eight-slot loop calls425c90, which tests Jewel coordinates
## directly (unlike actor425ac0, there is no Y-10). Each chosen X receives
## the existing vertical ground ray/T1 blast and SS shock parameters.
static func lightning_targets(entities: Array, impact: Vector2i, radius: int = 120) -> Array:
	var targets: Array = []
	for slot in 8:
		for entity in entities:
			if not _live(entity) or int(entity.slot) != slot:
				continue
			var at := Vector2i(entity.pos)
			if _within(at, impact, radius):
				targets.append(at)
			break
	return targets

## AnimateMine498b60 and AnimateSuperMine4921e0 both detonate on a Jewel
## anchor strictly within8px, including a falling/drop Jewel and any author.
static func mine_touching(entities: Array, position: Vector2i, radius: int = 8) -> bool:
	for entity in entities:
		if _live(entity) and _within(Vector2i(entity.pos), position, radius):
			return true
	return false
