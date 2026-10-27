extends RefCounted
## Native800px bands, fitted uniformly to the existing1280x800 battle canvas.
## Source HUD is800x600; the port retains its shorter world viewport.
const K := 1.6
const HEADER := Rect2(0,0,1280,64)
const FOOTER := Rect2(0,729.6,1280,70.4)
const WORLD := Rect2(0,64,1280,665.6)
const FOOTER_Y := 456.0
const STRENGTH := Rect2(390.4,750.4,640,35.2)
const ITEM_ORIGIN := Vector2(501,2)
const ITEM_SCALE := Vector2(35.0/36.0,31.0/36.0)
# Modes with a separate life/score model remain outside the offline scope.
const MODE_PANELS := {"solo":"NativeGoldPanel.png", "score":"NativeLifePanel.png", "jewel":"NativeJewelPanel.png"}
static func point(offset: Vector2) -> Vector2:
	return (Vector2(400,FOOTER_Y+22)+offset)*K
static func button_rect(kind: String, index: int = 0) -> Rect2:
	if kind == "shot":
		return Rect2(Vector2(6+index*41,FOOTER_Y+6)*K,Vector2(35,34)*K)
	return Rect2(Vector2(11 if kind=="options" else 750,3)*K,Vector2(40,30)*K)
static func in_world(point: Vector2) -> bool:
	return WORLD.has_point(point)
