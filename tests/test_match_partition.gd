extends "res://tests/support/suite.gd"

const Partition = preload("res://tests/support/match_partition.gd")

func _initialize() -> void:
	for count in [13, 16]:
		var cases := range(count)
		check(Partition.select(cases, PackedStringArray()) == cases, "sem argumentos mantém todo inventário")
		for shards in [1, 2, 3, 4]:
			var combined := []
			for index in range(shards):
				var selected: Array = Partition.select(cases, PackedStringArray(["--match-shard=%d/%d" % [index, shards]]))
				check(not selected.is_empty(), "grupo contém partidas")
				for value in selected:
					check(not combined.has(value), "partida não repete entre grupos")
					combined.append(value)
			combined.sort()
			check(combined == cases, "união mantém todas as partidas")
	for argument in ["--match-shard=0/0", "--match-shard=2/2", "--match-shard=-1/2", "--match-shard=0/17", "--match-shard=wat", "--match-shard=a/2"]:
		check(Partition.select(range(13), PackedStringArray([argument])).is_empty(), "argumento inválido rejeitado")
	check(Partition.select(range(13), PackedStringArray(["--match-shard=0/2", "--match-shard=1/2"])).is_empty(), "argumento duplicado rejeitado")
	finish("MATCH PARTITION CHECKS")
