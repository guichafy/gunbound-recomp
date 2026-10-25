extends "res://tests/support/suite.gd"
func run() -> void:
	var catalog=load("res://scripts/avatar_catalog.gd").new()
	var rows: Array=catalog.entries.values().filter(func(row): return row.get("source")=="xfs")
	check(rows.size()==562,"All 562 real XFS records are loaded")
	check(rows.filter(func(row): return row.buyable).size()==479,"All 479 buyable records are available")
	check(catalog.items(0,0).size()==77 and catalog.items(1,0).size()==81,"Both original head catalogs are complete")
	check(catalog.items(1,3).size()==174,"All flags are shared between genders")
	var marine: Dictionary=catalog.find("xfs:0:0:1")
	check(not marine.is_empty(),"XFS IDs have a separate namespace")
	if not marine.is_empty():
		check(marine.gold_price==10000 and marine.cash_price==1000,"Native prices, not old 100/100 placeholders")
		check(marine.bonuses==[0,0,3,0,0,0,0,3],"Marine defense/popularity match DAT")
		check(catalog.find("xfs:1:1:5").bonuses[4]==-3,"Negative native modifiers remain signed")
		check(catalog.find("xfs:0:2:1").name=="Battle Goggle","Old Pilot Goggles ID does not rename Battle Goggle")
		check(catalog.find("xfs:2:3:132").art_available,"Ghost supports its effect-only artwork")
		for row in rows:
			check(ResourceLoader.exists(row.portrait),"Registered portrait: "+row.key)
			if row.buyable:
				check(row.art_available and not row.layers.is_empty(),"Purchasable item has real art: "+row.key)
		var art=load("res://scripts/avatar_art.gd").new(false)
		for gender in [0,1]:
			for row in catalog.items(gender,0):
				if not row.buyable: continue
				var gear: Dictionary=catalog.defaults(gender)
				gear["0"]=row.key
				check(not art.sample(gear,0.5).is_empty(),"Renderable native outfit: "+row.key)
	var path := "res://.tools/xfs-catalog-profile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var p=load("res://scripts/profile.gd").new(path)
	p.gold=1000
	p.cash=1000
	check(p.equipped_set()["0"]=="xfs:0:0:0","New profiles use native defaults")
	if not marine.is_empty():
		check(p.purchase(marine.key,"gold")=="funds","Native price respects existing balance")
		check(p.purchase(marine.key,"cash")=="ok" and p.cash==0,"Cash purchase uses the native price once")
		check(p.equip(marine.key),"Purchased XFS piece can be equipped")
		check(p.has_method("equipment_bonuses"),"Equipment has a model-level stat aggregate")
		if p.has_method("equipment_bonuses"):
			check(p.equipment_bonuses()==marine.bonuses,"Equipped totals match the purchased piece")
		var restored=load("res://scripts/profile.gd").new(path)
		restored.load_profile()
		check(restored.owns(marine.key) and restored.equipped_set()==p.equipped_set(),"XFS purchases/equipment survive reload")
		check(p.purchase("xfs:0:1:61","gold")=="invalid","Non-buyable placeholder cannot be purchased")
		p.cash=10000
		p.path="res://.tools/missing-xfs-profile/profile.json"
		var before: int=p.cash
		check(p.purchase("xfs:0:0:2","cash")=="save" and p.cash==before and not p.owns("xfs:0:0:2"),"XFS failed save rolls back currency and ownership")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check_classic_identity(catalog)
	finish("XFS CATALOG CHECKS")

func check_classic_identity(catalog) -> void:
	var classic: Dictionary = catalog.classic
	check(classic.get("xfs_version")==280 and classic.get("records", []).size()==562, "Classic index keeps every version 280 record")
	check(classic.get("empty_dats")==["ff.dat"] and classic.get("unlisted_graphics")==["ff00001.img","sff00001.img"], "Empty female-flag DAT stays out of the shop")
	var seen := {}
	for row in classic.records:
		var item: Dictionary = catalog.find(str(row.key))
		check(item.get("name")==row.name and item.get("description")==row.description and item.get("gold_price")==row.gold and item.get("cash_price")==row.cash, "Art catalog matches classic "+str(row.key))
		check(int(item.get("slot"))==int(row.slot) and item.get("dat")==row.dat, "Protocol slot attached "+str(row.key))
		var wearers: Array = [0, 1] if int(row.gender)==2 else [int(row.gender)]
		for wearer in wearers:
			var dword := int(catalog.classic_dword(item, wearer))
			var found: Dictionary = catalog.find_classic(dword)
			check(found.get("key")==row.key and catalog.classic_dword(found, wearer)==dword, "Server DWORD round-trip "+str(row.key))
			check(not seen.has(dword) or seen[dword]==row.key, "Classic code belongs to one record "+str(row.key))
			seen[dword] = row.key
	check(int(catalog.classic_dword(catalog.find("xfs:2:3:0"), 0))==0x30000 and int(catalog.classic_dword(catalog.find("xfs:2:3:0"), 1))==0x30000, "Empty flag is the same zero word for both genders")
	check(seen.size()==735, "Every other gendered code and both flag genders stay unique")
	check(catalog.classic_dword(catalog.find("xfs:0:0:1"), 1)==-1, "A male head is not encoded as the female code")
	check(catalog.find_classic(_dword("01000100")).key=="xfs:1:0:1", "Female Space Marine head")
	check(catalog.find_classic(_dword("01000000")).name=="Space Marine" and catalog.find_classic(_dword("01000000")).dat=="fb.dat", "Female Space Marine body")
	check(catalog.find_classic(_dword("01000200")).name=="Battle Goggle", "Female Battle Goggle")
	check(catalog.find_classic(_dword("01800300")).key=="xfs:2:3:1", "Male Blue Flag")
	check(catalog.find_classic(_dword("03800300")).name=="Violet Flag", "Male Violet Flag")
	check(catalog.find_classic(_dword("8F800100")).is_empty(), "Love Cupid is absent from version 280")
	var amigos := {"0":"xfs:0:0:67","1":"xfs:0:1:68","2":"xfs:0:2:36","3":"xfs:2:3:164"}
	check(_same(catalog.encode_equipped(amigos, 0), _bytes("448043802480A480")), "Amigos equipped words are body, head, eye, flag")
	check(catalog.decode_equipped(_bytes("448043802480A480"))==amigos, "Amigos equipped bytes resolve to Rocker, Dizzy and Bazooka")
	check(_same(catalog.encode_equipped(catalog.defaults(0), 0), _bytes("0080008000800000")), "Male default matches /gender m")
	check(_same(catalog.encode_equipped(catalog.defaults(1), 1), _bytes("0000000000000000")), "Female default matches /gender f")
	check(catalog.find("xfs:1:1:71").description.ends_with("까꿍사냥꾼"), "Contest description uses the original Korean code page")

func _dword(text: String) -> int:
	var bytes := _bytes(text)
	return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24)

func _bytes(text: String) -> PackedByteArray:
	var clean := text.replace(" ", "")
	var out := PackedByteArray()
	for index in range(0, clean.length(), 2):
		out.append(clean.substr(index, 2).hex_to_int())
	return out

func _same(left: PackedByteArray, right: PackedByteArray) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if left[index] != right[index]:
			return false
	return true
