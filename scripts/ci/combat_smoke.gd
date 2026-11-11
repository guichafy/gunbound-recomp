extends RefCounted
## Runs inside the exported release template as well as the source harness.
## No profile, UI input, source-only fixture or manually repaired mask.
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Combat = preload("res://scripts/combat.gd")

static func run(check: Callable) -> int:
	var shots := 0
	for vehicle in Mobiles.PLAYABLE:
		for weapon in 3:
			var model = Match.new()
			# Bigfoot cannot incidentally initialize a native mask for the shooter.
			model.start(vehicle, 1, 42, "miramo_town_a", "original", null, [], [], [], 0, 2,
				[Vector2(448, 1374), Vector2(1515, 1394)])
			var label := "mobile %d weapon %d: " % [vehicle, weapon]
			check.call(model.map_id == "miramo_town_a", label + "packaged Miramo loads")
			if model.map_id != "miramo_town_a":
				continue
			# Independent consumer inventory: guard before entering release's unchecked
			# byte-array reads. Missing ground must fail even without a SCRIPT ERROR.
			if vehicle in [1, 4, 6, 8, 13, 16]:
				var ready: bool = model.terrain.native_cells.size() == 1800 * 1800
				check.call(ready, label + "native terrain ready without Mage opponent")
				if not ready:
					continue
			model.weather.columns.clear()
			model.weather.thor.active = false
			model.wind = Vector2.ZERO
			model.events.clear()
			var fired: bool = model.fire(45.0, 30.0, weapon)
			check.call(fired, label + "shot accepted")
			if not fired:
				continue
			shots += 1
			var armor_shell: Dictionary = model.projectiles[0] if vehicle==4 and weapon==1 else {}
			var armor_identity := false
			var contacts := 0
			var ground_bounces := 0
			var removed := 0
			var first_contact := -1
			for tick in 1000:
				model.advance_projectiles(Combat.STEP)
				for event in model.events:
					if event.type in ["explosion", "mine_plant", "thor", "ricochet"]:
						contacts += 1
						if first_contact < 0:
							first_contact = tick
						removed += int(event.get("removed", 0))
					if event.type == "ricochet" and Vector2(event.position).y < 1700.0:
						ground_bounces += 1
				if not armor_shell.is_empty() and contacts==1 and not model.projectiles.is_empty():
					armor_identity = is_same(armor_shell,model.projectiles[0]) and int(armor_shell.armor_phase)==1
				model.events.clear()
				if model.phase != Match.PHASE_FLIGHT:
					break
			check.call(model.phase == Match.PHASE_SETTLE and model.projectiles.is_empty(), label + "flight completes")
			# Nak SS intentionally crosses terrain and can miss an empty lane.
			if not (vehicle == 3 and weapon == 2):
				check.call(contacts > 0, label + "terrain/effect contact observed")
			if vehicle==4 and weapon==1:
				check.call(contacts==2 and armor_identity, label + "same Armor T2 shell survives first crater and ends after second")
			if vehicle in [6, 13]:
				check.call(first_contact > 5, label + "flies before contact instead of exploding at launch")
				check.call(removed > 0, label + "contact carves real ground")
			if vehicle == 13 and weapon > 0:
				check.call(ground_bounces > 0, label + "ricochets on the platform before the map boundary")
	return shots
