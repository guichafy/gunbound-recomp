extends RefCounted
## OpenBound attribute order, caps and modifiers. No scene/profile reads.
const COUNT := 8
static func budget(level: int) -> int:
	return mini(maxi(level - 1, 0) * 10, 180)
static func valid(values: Array, level: int) -> bool:
	if values.size() != COUNT:
		return false
	var total := 0
	for value in values:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != int(value) or int(value) < 0 or int(value) > 50:
			return false
		total += int(value)
	return total <= budget(level)
static func sanitize(values: Array, level: int = 19) -> Array:
	var result: Array = []
	var remaining := budget(level)
	for index in range(COUNT):
		var value = values[index] if index < values.size() else 0
		var points := clampi(int(value), 0, mini(50, remaining)) if (value is int or value is float) and is_finite(float(value)) else 0
		result.append(points)
		remaining -= points
	return result
static func damage(base: int, attack: int, defense: int) -> int:
	return maxi(0, int(base * (1.0 + (attack - defense) / 100.0)))
static func health(base: int, points: int) -> int:
	return int(base * (1.0 + points / 100.0))
static func heal(base: int, points: int) -> int:
	return int(base * (1.0 + points / 100.0))
static func delay(original: int, points: int) -> float:
	return int(original * (1.0 - points / 100.0)) / 7.5
static func crater(base: float, points: int) -> float:
	return base * (1.0 + points / 100.0)
static func points(actor: Dictionary, index: int) -> int:
	var values: Array = actor.get("attributes", [])
	return int(values[index]) if values.size() == COUNT else 0
