extends SceneTree
## Directed isolated impact matrix. Full launch and contact are exercised separately.

const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const WeatherSample = preload("res://scripts/aduka_weather.gd")
const Lightning = preload("res://scripts/lightning_combat.gd")
const Attributes = preload("res://scripts/player_attributes.gd")

const WEATHER = ["neutral", "force", "tornado", "electricity", "wind", "thor", "protection", "ignorance"]
const MODIFIERS = ["neutral", "force", "electricity", "thor"]
const STATS = [-50, -1, 0, 1, 25, 49, 50]
const HEADER = ["shooter", "weapon", "target", "weather", "sample", "attack", "defense",
	"dx", "dy", "shell_power", "shell_force", "hp_before", "hp_lost", "shield_before",
	"shield_lost", "reported", "overkill", "explosions", "effects", "mines", "weather_contacts"]

class ContactFixture extends "res://scripts/terrain.gd":
	## Hold the contact and body geometry fixed across isolated impact cases.
	func carve(_point: Vector2, _radius: float) -> int:
		return 0

	func carve_native(_spans: Array[Vector3i]) -> int:
		return 0

var output: FileAccess

func _initialize() -> void:
	call_deferred("run")

func sample(model, actors: Array, thor: Dictionary, weapon: int, weather: String,
		kind: String, attack: int, defense: int, delta: Vector2i) -> void:
	model.actors = actors.duplicate(true)
	model.actors[0].attributes[Attributes.ATTACK] = attack
	model.actors[1].attributes[Attributes.DEFENSE] = defense
	model.shot_weapon = weapon
	model.events.clear()
	model.projectiles.clear()
	model.mines.clear()
	model.battle_effects.clear()
	model.shot_gold = {}
	model.weather.thor = thor.duplicate(true)
	model.weather.thor.active = weather == "thor"
	model.weather.columns.clear()
	model.weather.queue = [{"type": weather}]
	model.wind = Vector2(26, 0) if weather == "wind" else Vector2.ZERO

	var target: Dictionary = model.actors[1]
	var hp := int(target.hp)
	var shield := int(target.shield)
	var impact := Shared.center(target) - delta
	var angle_limit: Vector2 = model.aim_limits(0, weapon)
	var shells: Array = model.shot_shells(0, angle_limit.x, 50, weapon)
	var shell: Dictionary = shells[0]
	model.launch_projectile(shell)
	shell.pos = Vector2(impact)
	if weather in ["force", "tornado", "electricity"]:
		model.weather.add_column(weather, float(impact.x), 1.0)
		if WeatherSample.active(shell):
			# Force uses an extended exposure in this controlled contact fixture.
			var ticks := 20 if weather == "force" else 1
			for tick in ticks:
				WeatherSample.sample(model, shell, impact, false)
		else:
			model.apply_weather_contact(shell)
	var applied_power := int(shell.damage)
	var force := int(shell.get("native_force", 0))
	model.explode(Vector2(impact), -1 if kind in ["edge", "miss"] else 1, shell)
	Lightning.resolve(model)

	var reported := 0
	var overkill := 0
	var explosions := 0
	var weather_contacts := 0
	var remaining := hp
	for event in model.events:
		match str(event.type):
			"explosion":
				explosions += 1
			"weather_hit":
				weather_contacts += 1
			"damage", "shield_damage":
				if int(event.actor) != 1:
					continue
				var amount := int(event.amount)
				reported += amount
				if event.type == "damage":
					overkill += maxi(0, amount - remaining)
					remaining = maxi(0, remaining - amount)
	var row := [actors[0].vehicle, weapon, actors[1].vehicle, weather, kind, attack, defense,
		delta.x, delta.y, applied_power, force, hp, hp - int(target.hp), shield, shield - int(target.shield),
		reported, overkill, explosions, model.battle_effects.size(), model.mines.size(), weather_contacts]
	output.store_csv_line(PackedStringArray(row.map(func(value): return str(value))))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: godot --headless --script tests/tools/shot_damage_audit/impact_probe.gd -- /path/impact.csv")
		quit(2)
		return
	output = FileAccess.open(args[0], FileAccess.WRITE)
	if output == null:
		printerr("Cannot write impact matrix")
		quit(2)
		return
	output.store_csv_line(PackedStringArray(HEADER))
	for shooter in Mobiles.PLAYABLE:
		for defender in Mobiles.PLAYABLE:
			var model = Match.new()
			model.start(shooter, 1, 42, "", "original", null, [], [], [], 0, defender)
			var floor_mask := ContactFixture.new()
			floor_mask.WIDTH = 256
			floor_mask.HEIGHT = 128
			floor_mask.cells.resize(floor_mask.WIDTH * floor_mask.HEIGHT)
			floor_mask.native_cells.resize(floor_mask.WIDTH * floor_mask.HEIGHT * 4)
			floor_mask.first_solid_y = 220
			model.terrain = floor_mask
			model.actors[0].pos = Vector2(90, 140)
			model.actors[1].pos = Vector2(330, 140)
			model.actors[0].tilt = 0.0
			model.actors[1].tilt = 0.0
			var actors: Array = model.actors.duplicate(true)
			var thor: Dictionary = model.weather.thor.duplicate(true)
			thor.pos = Vector2(330, 30)
			for weapon in 3:
				var radius := int(model.weapon_rules(0, weapon).radius)
				for weather in WEATHER:
					for span in [["center", 0], ["inner", 12], ["edge", radius + 10], ["miss", 155]]:
						sample(model, actors, thor, weapon, weather, span[0], 0, 0, Vector2i(0, span[1]))
				for weather in MODIFIERS:
					for attack in STATS:
						for defense in STATS:
							if attack != 0 or defense != 0:
								sample(model, actors, thor, weapon, weather, "stats", attack, defense, Vector2i.ZERO)
	output.close()
	print("Impact matrix written")
	quit()
