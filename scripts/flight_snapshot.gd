extends RefCounted
## Closed copy of the state the flight loop reads.
## capture copies persistent state (including placed mines); arm initializes
## the proposed shot and derives its presentation volleys from its own shells.
## A new Match field stays out of prediction until explicitly handled here.

const FLIGHT_FIELDS := [
	"terrain", "actors", "wind", "weather",
	"shot_actor", "shot_weapon", "projectiles", "phase",
	"flight_elapsed", "events", "resolve_wait", "shot_gold", "mines", "volleys", "battle_effects", "satellites", "spark_tick"
]

static func capture(source):
	# get_script() avoids load() here: the CPU search calls this from a worker,
	# and loading a script off the main thread deadlocks the resource loader.
	var sim = source.get_script().new()
	sim.terrain = source.terrain.collision_copy()
	sim.actors = source.actors.duplicate(true)
	sim.shot_gold = source.shot_gold.duplicate(true)
	sim.wind = source.wind
	sim.weather = source.weather.copy()
	sim.spark_tick=source.spark_tick
	sim.mines = source.mines.duplicate(true)
	sim.battle_effects = source.battle_effects.duplicate(true)
	sim.satellites = source.satellites.duplicate(true)
	return sim

static func arm(sim, shot_actor: int, shot_weapon: int, shells: Array) -> void:
	sim.shot_gold = {}
	sim.shot_actor = shot_actor
	sim.shot_weapon = shot_weapon
	sim.projectiles = shells
	sim.volleys = sim.second_volley(shells)
	sim.phase = sim.PHASE_FLIGHT
	sim.flight_elapsed = 0.0
	sim.events = []
	sim.resolve_wait = 0.0
