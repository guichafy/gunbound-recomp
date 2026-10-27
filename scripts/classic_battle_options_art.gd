extends RefCounted
## Exact native RLE frames, validated as one group. ADR-137.
const Client = preload("res://scripts/client_hud_assets.gd")
const FALLBACK := "res://assets/xfs/hud_options_fallback/"
const FRAMES := {
	"NativeOptionsPanel.png": [Vector2i(276,408),1,"83ce14614aee4571450db094a963c47874428ccd0087ed7e5b5442a860e8430a"],
	"NativeOptionRadio.png": [Vector2i(12,12),1,"2fe18f6a43dc817882ada4e939c1a8b648b1ce6bd9aac2fbc163fab406248a1e"],
	"NativeOptionOK.png": [Vector2i(82,33),4,"b7e0f09895b6bfd6215d12da90ca692453ed43cccfca55b4be7a61bd39631717"],
	"NativeOptionQuit.png": [Vector2i(83,34),4,"7ac5607d684ef6cfe178da0a70432b81bd83e4aa5a4c37e35528821780bb118b"],
	"NativeOptionClose.png": [Vector2i(25,23),4,"2b9be9d5419ab94c6325233827ff74ff2ff5f1f58bcb8b66f631b08fa5a1b202"]}
var textures := {}
var using_fallback := false

func _init(client = null) -> void:
	if client == null:
		client = Client.new()
	for name in FRAMES:
		var texture: Texture2D = client.texture(name)
		if not valid(texture,name):
			using_fallback = true
		textures[name] = texture
	if using_fallback:
		for name in FRAMES:
			var path: String = FALLBACK+name
			var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
			textures[name] = texture if valid(texture,name) else null

func valid(texture: Texture2D, name: String) -> bool:
	var spec: Array = FRAMES[name]
	if texture == null or texture.get_size() != Vector2(spec[0].x*spec[1],spec[0].y):
		return false
	var pixels := texture.get_image()
	if pixels == null:
		return false
	if pixels.is_compressed():
		pixels.decompress()
	pixels.convert(Image.FORMAT_RGBA8)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(pixels.get_data())
	return hash.finish().hex_encode() == spec[2]

func draw(canvas: CanvasItem, name: String, position: Vector2, frame: int = 0, tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = textures.get(name)
	if texture == null:
		return
	var cell := Vector2(FRAMES[name][0])
	canvas.draw_texture_rect_region(texture,Rect2(position,cell*1.6),Rect2(Vector2(frame*cell.x,0),cell),tint)
