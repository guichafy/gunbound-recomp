extends RefCounted
## Interface-only sentinel. Never passed to Mobiles/Match as a mobile ID.
const RANDOM := -2
const POOL := [14,15] # Dragon / Knight, by explicit user request.
static func roll(rng: RandomNumberGenerator) -> int:
	return POOL[rng.randi_range(0,POOL.size()-1)]
