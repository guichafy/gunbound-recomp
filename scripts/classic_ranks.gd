extends RefCounted
## Thor's Hammer signed protocol codes. Not the OpenBound PlayerRank enum.
## Login adds4 to the WORD (004e04ff); source atlas frame24 is GM20.
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

static func icon(code: int, horizontal: bool = false) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	var cell := Vector2(25, 15) if horizontal else Vector2(15, 25)
	atlas.atlas = load("res://assets/classic/ranks/rank2.png" if horizontal else "res://assets/classic/ranks/rank1.png")
	atlas.region = Rect2(Vector2((normalize(code) + 4) * cell.x, 0), cell)
	return atlas
