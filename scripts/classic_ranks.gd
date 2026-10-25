extends RefCounted
## Thor's Hammer signed protocol codes. Not the OpenBound PlayerRank enum.
## Login adds4 to the WORD (004e04ff); source atlas frame24 is GM20.
const LobbyArt = preload("res://scripts/classic_lobby_art.gd")
const GM := 20
const CHICK := 19
const TITLES := ["Silver Dragon", "Red Dragon", "Blue Dragon", "Diamond Wand",
	"Ruby Wand", "Sapphire Wand", "Violet Wand", "Golden Battle Axe Plus",
	"Golden Battle Axe", "Silver Battle Axe Plus", "Silver Battle Axe",
	"Battle Axe Plus", "Battle Axe", "Double Gold Axe", "Gold Axe",
	"Double Silver Axe", "Silver Axe", "Double Axe", "Axe", "Double Stone",
	"Stone", "Double Wooden", "Wooden", "Chick", "GM"]

static func valid(value) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= -4 and value <= GM

static func normalize(value) -> int:
	return int(value) if valid(value) else CHICK

static func title(code: int) -> String:
	return TITLES[normalize(code) + 4]

static func description(code: int) -> String:
	return "GM — Administrador do Sistema" if code == GM else title(code)

static func icon(code: int, horizontal: bool = false, use_hd: bool = true) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	var cell := Vector2(25, 15) if horizontal else Vector2(15, 25)
	var key := "rank2" if horizontal else "rank1"
	var record := {"file":"ranks/" + key + ".png", "size":[cell.x * 25,cell.y], "frame_size":[cell.x,cell.y], "frames":25.0}
	var hd: Texture2D = LobbyArt.new().texture(key, record) if use_hd else null
	var density := 4.0 if hd != null else 1.0
	atlas.atlas = hd if hd != null else load("res://assets/classic/ranks/" + key + ".png")
	atlas.region = Rect2(Vector2((normalize(code) + 4) * cell.x, 0) * density, cell * density)
	return atlas
