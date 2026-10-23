extends RefCounted
## Closed copy of the state the flight loop reads.
## predict_shot and the CPU snapshot copy only these fields. A new Match field
## stays out of the prediction until it is added here.

const FLIGHT_FIELDS := [
	"terrain", "actors", "wind", "weather",
	"shot_actor", "shot_weapon", "projectiles", "phase",
	"flight_elapsed", "events", "resolve_wait", "shot_gold"
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
	return sim

static func arm(sim, shot_actor: int, shot_weapon: int, shells: Array) -> void:
	sim.shot_gold = {}
	sim.shot_actor = shot_actor
	sim.shot_weapon = shot_weapon
	sim.projectiles = shells
	sim.phase = sim.PHASE_FLIGHT
	sim.flight_elapsed = 0.0
	sim.events = []
	sim.resolve_wait = 0.0
