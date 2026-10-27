extends "res://tests/support/suite.gd"
const Assets = preload("res://scripts/client_weather_assets.gd")
const Art = preload("res://scripts/weather_art.gd")

func run() -> void:
	for key in Assets.FILES:
		var record: Array = Assets.FILES[key]
		var expected := "res://assets/xfs/"+str(record[0])
		check(Assets.path(key)==expected,"Active shared client texture: %s"%key)
		check(Assets.texture(key)!=null and Assets.texture(key).get_size()==record[2],"Imported native dimensions: %s"%key)
		var fallback := "res://assets/openbound/"+str(record[1])
		check(Assets.path(key,"res://assets/missing-client-weather.png")==fallback,"Missing client file uses proved native import: %s"%key)
		check(Assets.path(key,"res://scripts/weather_art.gd")==fallback,"Non-texture candidate cannot replace native art: %s"%key)
	check(Assets.path("unrecognized").is_empty(),"Unknown texture keys fail closed")
	check(Assets.path("FirewallTexture","res://assets/xfs/thor/ThorBody.png")=="res://assets/openbound/weather/native/FirewallTexture.png","Wrong texture dimensions use native fallback")
	var metadata := Assets.thor_metadata()
	check(not metadata.is_empty() and metadata.sheets.size()==2,"Original Thor body/light EPA metadata loads")
	check(metadata==Assets.thor_metadata("res://assets/missing-thor.json"),"Missing Thor metadata falls back to identical validated native EPA")
	var malformed := "res://.tools/invalid-client-thor.json"
	var file := FileAccess.open(malformed,FileAccess.WRITE)
	file.store_string('{"archive_sha256":"unknown","columns":14}')
	file.close()
	check(metadata==Assets.thor_metadata(malformed),"Changed Thor metadata is rejected before use")
	var altered := metadata.duplicate(true)
	altered.sheets["ThorBody.png"].origin=[0,0]
	file=FileAccess.open(malformed,FileAccess.WRITE)
	file.store_string(JSON.stringify(altered))
	file.close()
	check(metadata==Assets.thor_metadata(malformed),"Wrong native hotspot rejects altered Thor metadata")
	altered=metadata.duplicate(true)
	altered.states.fire.frames[0]=0
	file=FileAccess.open(malformed,FileAccess.WRITE)
	file.store_string(JSON.stringify(altered))
	file.close()
	check(metadata==Assets.thor_metadata(malformed),"Wrong EPA sequence rejects altered Thor metadata")
	DirAccess.remove_absolute(malformed)
	var art := Art.new()
	for type in Art.CLIENT_COLUMNS:
		check(art.sheets[type].resource_path==Assets.path(Art.CLIENT_COLUMNS[type]),"All calendars use the native %s column texture"%type)
	for type in ["weakness","mirror","random"]:
		check(art.sheets[type].resource_path.begins_with("res://assets/openbound/weather/"),"Missing client category remains a declared adapter: %s"%type)
	check(art.thor_sheet.resource_path==Assets.path("ThorBody") and art.thor_light.resource_path==Assets.path("ThorLight"),"Adapter Thor also uses original body and light sheets")
	check(art.thor_laser.resource_path==Assets.path("LaserEffect") and art.lightning.resource_path==Assets.path("Lightning"),"Adapter beams use proved original XTF textures")
	check(art.force_particle.resource_path==Assets.path("CrashTexture") and art.electric_particle==art.force_particle,"Decorative adapter marks share native CrashTexture")
	for frame in [-1,0,7,8,15]:
		check(Art.shell_mark_region("force",frame)==Rect2(posmod(frame,8)*32,64,32,32),"Force selects native CrashTexture row2")
		check(Art.shell_mark_region("electricity",frame)==Rect2(posmod(frame,8)*32,96,32,32),"Electricity selects native CrashTexture row3")
		check(Art.beam_region("thor",frame)==Rect2(posmod(frame,8)*16,0,16,256),"Thor selects first eight of sixteen native LaserEffect strips")
		check(Art.beam_region("lightning",frame)==Rect2(posmod(frame,4)*64,0,64,256),"Lightning selects four native vertical strips")
	var columns = load("res://scripts/mage_weather_art.gd").new()
	for type in columns.TEXTURES:
		check(columns.textures[type].resource_path==Assets.path(columns.TEXTURES[type]),"Approved native column renderer uses relocated texture: %s"%type)
	var thor = load("res://scripts/thor_native_art.gd").new()
	check(thor.meta==metadata,"Approved native Thor renderer retains the exact EPA contract")
	check(thor.textures["ThorBody.png"].diffuse_texture.resource_path==Assets.path("ThorBody"),"Native Thor texture is relocated without repacking changes")
	var beam = load("res://scripts/aduka_beam_art.gd").new()
	check(beam.texture.resource_path==Assets.path("LaserEffect"),"Aduka keeps its proved LaserEffect texture")
	var lightning = load("res://scripts/lightning_beam_art.gd").new()
	check(lightning.texture.resource_path==Assets.path("Lightning"),"Lightning mobile shares the original weather texture")
	finish("CLIENT WEATHER ASSET CHECKS")
