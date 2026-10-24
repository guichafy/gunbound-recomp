extends RefCounted
## The one place that builds a projectile (ADR-081). Shells stay Dictionaries
## for the same reason as actors (FlightSnapshot deep copies).

## A launched-later shell of `weapon`. `rules` are the weapon rules of the
## shooter; `component` numbers the shells of one emission (helix phase).
static func create(position: Vector2, velocity: Vector2, spawn_at: float, rules: Dictionary, weapon: int, component: int) -> Dictionary:
	return {
		"pos": position, "hit_pos": position, "velocity": velocity, "age": 0.0, "trail": [position],
		"helix": float(rules.get("helix", 0)), "phase": float(component) * PI, "spawn_at": spawn_at, "launched": false,
		# Weather state per shell (Projectile.cs): base damage, columns touched, influences.
		"damage": int(rules.damage), "launch_speed": velocity.length(), "inside": {}, "influenced": [],
		"electric": false, "thor": false, "tornado": {},
		"weapon": weapon, "volley": 0, "beacon": false, "wind_scale": float(rules.get("wind_scale", 1.0)),
		# Nak (ADR-074): S2 burrows and resurfaces, SS crosses the terrain.
		"burrow": bool(rules.get("burrow", false)), "ghost": bool(rules.get("ghost", false)), "underground": false,
	}

## Latest spawn time of a salvo (0 for a single shell).
static func last_spawn(shells: Array) -> float:
	var latest := 0.0
	for shell in shells:
		latest = maxf(latest, float(shell.spawn_at))
	return latest
