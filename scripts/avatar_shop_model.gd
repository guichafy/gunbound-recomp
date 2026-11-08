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
var preview_gender := 0
var draft_attributes: Array = []
func _init(player_profile, avatar_catalog = null) -> void:
	profile = player_profile
	catalog = avatar_catalog if avatar_catalog != null else profile.catalog
	reset_preview()
func reset_preview() -> void:
	preview = profile.equipped_set()
	preview_gender = profile.gender
	draft_attributes = profile.attributes.duplicate()
	selected_key = ""
func filter(kind: int, text: String, owned_only: bool, requested: int = 0) -> Array:
	category = clampi(kind,0,3)
	query = text
	inventory = owned_only
	var rows := filtered_items(category)
	last_page = maxi(1, ceili(rows.size() / 9.0))
	page = clampi(requested,0,last_page-1)
	var visible: Array = rows.slice(page*9,mini(rows.size(),page*9+9))
	if not selected_key.is_empty() and not visible.any(func(item): return item.key==selected_key):
		selected_key = ""
	return visible

func filtered_items(kind: int) -> Array:
	var rows: Array = []
	for item in catalog.shop_items(profile.gender,kind,inventory):
		if not inventory and item.get("source")=="xfs" and not item.get("buyable",false) and not catalog.offline_piece(item):
			continue
		if (query.is_empty() or str(item.name).to_lower().contains(query.to_lower())) and (not inventory or profile.owns(item.key)):
			rows.append(item)
	return rows

## A successful dress can reorder genders. Keep its card in view afterwards.
func page_for(key: String, kind: int) -> int:
	var rows := filtered_items(kind)
	for i in range(rows.size()):
		if rows[i].key==key:
			return i/9
	return 0
func select(key: String) -> bool:
	var item: Dictionary = catalog.find(key)
	if item.is_empty() or (item.get("source")!="xfs" and not catalog.compatible(key,profile.gender)):
		return false
	if inventory:
		if not profile.equip(key,true):
			return false
		preview = profile.equipped_set()
		preview_gender = profile.gender
	selected_key = key
	return true
func try_selected() -> bool:
	var item: Dictionary = catalog.find(selected_key)
	if inventory or item.is_empty():
		return false
	if profile.owns(selected_key):
		if not profile.equip(selected_key,true):
			return false
		preview = profile.equipped_set()
		preview_gender = profile.gender
	elif not catalog.compatible(selected_key,preview_gender):
		preview_gender = int(item.gender)
		preview = profile.equipped_set(preview_gender)
	preview[str(int(item.category))] = selected_key
	return true
func confirm_buy(key: String, currency: String) -> String:
	return profile.purchase(key,currency)
