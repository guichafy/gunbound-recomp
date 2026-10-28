extends "res://tests/support/suite.gd"
## Grub ricochet surface angle (0x4a1740) against fixtures produced by running
## the PE routine itself (tests/tools/grub_oracle).
const Physics = preload("res://scripts/classic_ballistics.gd")
const Surface = preload("res://scripts/grub_surface.gd")

func terrain_from(rows: Array, w: int, h: int) -> PackedByteArray:
	var cells := PackedByteArray()
	cells.resize(w * h)
	for y in h:
		var x := 0
		for run in rows[y]:
			if int(run[0]) != 0:
				for i in int(run[1]):
					cells[y * w + x + i] = 1
			x += int(run[1])
	return cells

func run() -> void:
	Physics.warmup()
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/grub_surface_native.json"))
	for fixture in fixtures:
		var w := int(fixture.size[0])
		var h := int(fixture.size[1])
		var cells := terrain_from(fixture.terrain, w, h)
		for query in fixture.queries:
			var got := Surface.angle_at(cells, w, h, int(query[0]), int(query[1]), 0)
			var expected_ok := int(query[2]) == 1
			check(bool(got.ok) == expected_ok and int(got.angle) == int(query[3]), "seed %d contact (%d,%d): ok=%s angle=%d, PE ok=%s angle=%d" % [int(fixture.seed), int(query[0]), int(query[1]), str(got.ok), int(got.angle), str(expected_ok), int(query[3])])
	finish("GRUB SURFACE CHECKS")
