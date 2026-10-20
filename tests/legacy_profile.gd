extends "res://scripts/profile.gd"
## Explicit C# fixture for regression tests of the previous catalog and save rules.
## Production and XFS integration tests use Profile directly.
func _init(save_path: String) -> void:
	super(save_path,load("res://scripts/avatar_catalog.gd").legacy())
