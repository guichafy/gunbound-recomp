extends RefCounted
## Test scheduling only. Seed, RNG, simulation and assertions stay in each suite.

static func select(cases: Array, arguments: PackedStringArray) -> Array:
	if arguments.is_empty():
		return cases.duplicate()
	if arguments.size() != 1:
		return []
	var pattern := RegEx.new()
	pattern.compile("^--match-shard=([0-9]+)/([0-9]+)$")
	var found := pattern.search(arguments[0])
	if found == null:
		return []
	var index := int(found.get_string(1))
	var count := int(found.get_string(2))
	if count < 1 or count > cases.size() or index >= count:
		return []
	var selected := []
	for offset in range(index, cases.size(), count):
		selected.append(cases[offset])
	return selected
