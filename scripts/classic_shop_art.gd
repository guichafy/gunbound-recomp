extends RefCounted
## Original Avatar Shop frames (ADR-130). The native catalog owns size and
## pivot; the approved BICUBIC4× derivative only adds texels and falls back
## to the native PNG whenever its record does not match the source frame.
const NATIVE := "res://assets/xfs/shop/catalog.json"
const HD_ROOT := "res://assets/hd/classic/shop_smooth_4x/"
const DENSITY := 4.0
const FONT_CELL := Vector2(8,12)
const FONT_ADVANCE := 6
var frames: Dictionary = {}
var entries: Dictionary = {}
var hd_frames: Dictionary = {}
var hd_root := HD_ROOT
var use_hd := true
var _cache: Dictionary = {}

func _init(native_path: String = NATIVE, hd_directory: String = HD_ROOT) -> void:
	hd_root = hd_directory
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(native_path)) if FileAccess.file_exists(native_path) else null
	if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("frames") is Dictionary:
		frames = parsed.frames
		entries = parsed.get("entries",{}) if parsed.get("entries") is Dictionary else {}
	var catalog := hd_root + "catalog.json"
	var hd = JSON.parse_string(FileAccess.get_file_as_string(catalog)) if FileAccess.file_exists(catalog) else null
	if hd is Dictionary and hd.get("version") == 1 and hd.get("scale") == DENSITY and hd.get("frames") is Dictionary:
		hd_frames = hd.frames

func has(key: String) -> bool:
	return frames.has(key) and native_texture(key) != null

func size(key: String) -> Vector2:
	var value: Array = frames.get(key,{}).get("size",[0,0])
	return Vector2(value[0],value[1])

func pivot(key: String) -> Vector2:
	var value: Array = frames.get(key,{}).get("pivot",[0,0])
	return Vector2(value[0],value[1])

func frame_count(entry: String) -> int:
	return int(entries.get(entry,{}).get("frames",0))

func native_texture(key: String) -> Texture2D:
	var path := str(frames.get(key,{}).get("file",""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var result: Texture2D = _cache[path]
	return result if result != null and result.get_size() == size(key) else null

## Valid only for the exact native frame it was derived from.
func hd_texture(key: String) -> Texture2D:
	var info = hd_frames.get(key)
	var native: Dictionary = frames.get(key,{})
	if not info is Dictionary or not info.get("source") is Dictionary or native.is_empty():
		return null
	if info.source.get("file") != native.get("file") or info.source.get("sha256") != native.get("sha256"):
		return null
	var expected := size(key)*DENSITY
	if info.get("size") != [expected.x,expected.y]:
		return null
	var path := hd_root + str(info.get("file",""))
	if not ResourceLoader.exists(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var result: Texture2D = _cache[path]
	return result if result != null and result.get_size() == expected else null

func texture(key: String) -> Texture2D:
	var derived := hd_texture(key) if use_hd else null
	return derived if derived != null else native_texture(key)

func density(key: String) -> float:
	return DENSITY if use_hd and hd_texture(key) != null else 1.0

## Draws a frame at its native registration: anchor + IMG pivot, native size.
func draw(item: CanvasItem, key: String, at: Vector2, modulate: Color = Color.WHITE) -> void:
	var paint := texture(key)
	if paint != null:
		item.draw_texture_rect(paint,Rect2(at+pivot(key),size(key)),false,modulate)

## font.fnt half-width glyphs: 8×12 cells, fixed 6 px advance (ASCII names).
func draw_text(item: CanvasItem, text: String, at: Vector2, color: Color) -> void:
	var paint := texture("font:0")
	if paint == null:
		return
	var factor := density("font:0")
	for index in range(text.length()):
		var code := text.unicode_at(index)
		var cell := at+Vector2(index*FONT_ADVANCE,0)
		if code < 32 or code > 126:
			# Non-ASCII nickname letters keep a readable system glyph.
			item.draw_string(ThemeDB.fallback_font,cell+Vector2(0,10),text[index],HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
			continue
		var source := Rect2(Vector2(code%16,int(code/16))*FONT_CELL*factor,FONT_CELL*factor)
		item.draw_texture_rect_region(paint,Rect2(cell,FONT_CELL),source,color)

static func text_width(text: String) -> int:
	return text.length()*FONT_ADVANCE

## FUN_004ed9f0: one numfont frame per character from `base`, spaces skipped
## but still advanced; only the first `count` characters are drawn.
static func digits_layout(base: int, text: String, at: Vector2, advance: int, count: int = -1) -> Array:
	var result: Array = []
	var limit := text.length() if count < 0 else mini(count,text.length())
	for index in range(limit):
		if text[index] != " ":
			result.append(["numfont:%d" % (base+text.unicode_at(index)-48),at+Vector2(index*advance,0)])
	return result

## FUN_0044c460: "%8d", digit advance 10, comma advance 4 before every
## three-digit group; the comma is drawn only after the first digit.
static func price_layout(base: int, comma: int, value: int, at: Vector2) -> Array:
	var result: Array = []
	var text := "%8d" % value
	var x := at.x
	var drawn := false
	for index in range(text.length()):
		if (text.length()-index)%3 == 0:
			if drawn:
				result.append(["numfont:%d" % comma,Vector2(x,at.y)])
			x += 4
		if text[index] != " ":
			drawn = true
			result.append(["numfont:%d" % (base+text.unicode_at(index)-48),Vector2(x,at.y)])
		x += 10
	return result

func draw_layout(item: CanvasItem, layout: Array) -> void:
	for entry in layout:
		draw(item,entry[0],entry[1])

func draw_digits(item: CanvasItem, base: int, text: String, at: Vector2, advance: int, count: int = -1) -> void:
	draw_layout(item,digits_layout(base,text,at,advance,count))

func draw_price(item: CanvasItem, base: int, comma: int, value: int, at: Vector2) -> void:
	draw_layout(item,price_layout(base,comma,value,at))
