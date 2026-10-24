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
		"burrow": bool(rules.get("burrow", false)), "ghost": bool(rules.get("ghost", false)),
		# Grub SS (SimulateSuperShot_Bullet13) steps the terrain and never calls
		# HitTestMobilesAndJewels, so the shell crosses mobiles.
		"skip_actors": bool(rules.get("skip_actors", false)), "underground": false,
		"flight": str(rules.get("flight", "")), "extra_damage": int(rules.get("extra_damage", 0)),
		"extra_radius": float(rules.get("extra_radius", 0.0)), "transform_at": float(rules.get("transform_at", 0.0)),
		"chain": int(rules.get("chain", 0)), "chain_gap": float(rules.get("chain_gap", 0.1)),
		"chain_step": float(rules.get("chain_step", 20.0)), "bolt": float(rules.get("bolt", 0.0)),
		"bolt_radius": float(rules.get("bolt_radius", 0.0)), "bolt_count": int(rules.get("bolt_count", 1)),
		"chill": int(rules.get("chill", 0)), "crystal_damage": int(rules.get("crystal_damage", 0)),
		"crystal_radius": float(rules.get("crystal_radius", 0.0)),
		"mine_crawl": bool(rules.get("mine_crawl", false)),
		"mine_steps": int(rules.get("mine_steps", 0)),
		"burst": int(rules.get("burst", 0)),
		"burst_spread": float(rules.get("burst_spread", 12.0)),
	}

## Latest spawn time of a salvo (0 for a single shell).
static func last_spawn(shells: Array) -> float:
	var latest := 0.0
	for shell in shells:
		latest = maxf(latest, float(shell.spawn_at))
	return latest
