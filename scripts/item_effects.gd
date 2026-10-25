extends RefCounted
## Item effects (Mobile.UseItem, Mobile.ShootWithModifiers), keyed by the
## "effect" and "shot" kinds of the Items catalog (ADR-081). Match validates the
## use, charges the delay and owns the state; a new item of an existing kind is
## only catalog data. Runs on the CPU snapshot too: no loads, no live state.

const Items = preload("res://scripts/items.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const ShellState = preload("res://scripts/shell_state.gd")

## Instant effect on use. Fills `event` with what the presentation shows.
static func apply_instant(model, actor: Dictionary, rules: Dictionary, event: Dictionary) -> void:
	match str(rules.get("effect", "")):
		"heal":
			# Mobile.Heal: percentage of the base health; shield untouched.
			var percent := float(rules.heal_percent)
			if bool(Mobiles.definition(int(actor.vehicle)).bionic):
				percent += Items.ENERGY_UP_EXTRA
			var before := int(actor.hp)
			actor.hp = mini(int(actor.max_hp), before + int(minf(float(actor.max_hp), float(actor.max_hp) * percent / 100.0)))
			event["amount"] = int(actor.hp) - before
		"health_cost":
			# Blood: energy for attack; it never brings the mobile to 0.
			var before := int(actor.hp)
			actor.hp = maxi(1, int(float(actor.hp) - float(actor.max_hp) * float(rules.health_cost) / 100.0))
			event["amount"] = int(actor.hp) - before
		"turn_wind":
			model.weather.wind_angle = posmod(int(model.weather.wind_angle) + int(rules.wind_degrees), 360)
			model.wind = model.weather.wind_vector()
			event["wind_angle"] = model.weather.wind_angle

## The shells of a shot under this turn's item. `shells` are the plain shot.
static func modify_shells(model, index: int, angle: float, power: float, weapon: int, rules: Dictionary, shells: Array) -> Array:
	match str(rules.get("shot", "")):
		"second_volley":
			# InteractionTime (1 + last spawn of the first shot), then each SpawnTime.
			# Dual repeats the weapon; Dual+ fires S2 after S1, S1 after anything else.
			var second := weapon if not bool(rules.get("mixed", false)) else (1 if weapon == 0 else 0)
			var first_end := ShellState.last_spawn(shells)
			for shell in model.projectile_parameters(index, angle, power, second):
				shell.pose_start_at = Items.DUAL_WAIT + first_end
				shell.spawn_at = float(shell.spawn_at) + float(shell.pose_start_at)
				shell.volley = 1
				shells.append(shell)
		"beacon":
			# TeleportationBeacon replaces the shot: one shell, mass 10, no wind.
			var beacon: Dictionary = shells[0]
			var velocity: Vector2 = model.shot_velocity(index, angle, power, weapon) * Items.BEACON_SPEED
			var initial: Vector2 = model.muzzle(index, angle, weapon)
			beacon.erase("launch_velocity_fp")
			beacon.fp_ready = false
			beacon.boomer = false
			beacon.boomer_ss = false
			beacon.merge({"pos": initial, "hit_pos": initial, "velocity": velocity, "trail": [initial], "helix": 0.0, "phase": 0.0,
				"spawn_at": float(Mobiles.definition(int(model.actors[index].vehicle)).beacon_delay), "damage": 0, "launch_speed": velocity.length(), "beacon": true, "wind_scale": Items.BEACON_WIND, "burrow": false, "ghost": false, "flight": ""}, true)
			shells = [beacon]
		"electric":
			# An invisible Electricity column of scale 1000 around the mobile:
			# every shell is electric once, and the weather column does not stack.
			for shell in shells:
				shell.electric = true
				shell.influenced.append("electricity")
	return shells
