extends RefCounted
## Give ballistic-only fixtures real support, instead of floating actors.
## Platforms stay local to each actor so they do not block the shot corridor.
static func add(model) -> void:
	for index in model.actors.size():
		var actor: Dictionary = model.actors[index]
		var floor_cell: int = int(actor.pos.y + model.stance_of(index)) / model.terrain.SCALE
		var center: int = int(actor.pos.x) / model.terrain.SCALE
		for y in range(floor_cell, mini(floor_cell+10,model.terrain.HEIGHT)):
			for x in range(maxi(0,center-12),mini(center+13,model.terrain.WIDTH)):
				model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	model.terrain.image = null
	model.terrain.texture = null
	model.terrain.native_cells.clear()
	model.terrain.enable_native()
