extends RefCounted
const Catalog = preload("res://scripts/avatar_catalog.gd")
var profile
var catalog
var category := 0
var query := ""
var inventory := false
var page := 0
var last_page := 1
var selected_key := ""
var preview: Dictionary = {}
var draft_attributes: Array = []
func _init(player_profile, avatar_catalog = null) -> void:
	profile = player_profile
	catalog = avatar_catalog if avatar_catalog != null else Catalog.new()
	reset_preview()
func reset_preview() -> void:
	preview = profile.equipped_set()
	draft_attributes = profile.attributes.duplicate()
	selected_key = ""
func filter(kind: int, text: String, owned_only: bool, requested: int = 0) -> Array:
	category = clampi(kind,0,3)
	query = text
	inventory = owned_only
	var rows: Array = []
	for item in catalog.items(profile.gender,category):
		if (query.is_empty() or str(item.name).to_lower().contains(query.to_lower())) and (not inventory or profile.owns(item.key)):
			rows.append(item)
	last_page = maxi(1, ceili(rows.size() / 25.0))
	page = clampi(requested,0,last_page-1)
	return rows.slice(page*25,mini(rows.size(),page*25+25))
func select(key: String) -> bool:
	if not catalog.compatible(key,profile.gender):
		return false
	selected_key = key
	if inventory:
		if not profile.equip(key):
			return false
		preview = profile.equipped_set()
	return true
func try_selected() -> bool:
	var item: Dictionary = catalog.find(selected_key)
	if inventory or item.is_empty():
		return false
	if profile.owns(selected_key) and not profile.equip(selected_key):
		return false
	preview[str(int(item.category))] = selected_key
	return true
func confirm_buy(key: String, currency: String) -> String:
	return profile.purchase(key,currency)
