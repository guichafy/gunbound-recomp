extends "res://tests/support/suite.gd"
const Physics = preload("res://scripts/classic_ballistics.gd")

func run() -> void:
	Physics.warmup()
	var path := "res://scripts/mage_spark_art.gd"
	var available := ResourceLoader.exists(path)
	var art = load(path) if available else null
	var q: Dictionary = art.quad({"kind":"force","position":Vector2i(100,200),"tick":0,"angle":0}) if available else {}
	check(not q.is_empty(),"Native Force emits its first CrashTexture quad")
	if not available:
		finish("MAGE SPARK ART CHECKS")
		return
	check(q.points==PackedVector2Array([Vector2(84,184),Vector2(115,184),Vector2(115,215),Vector2(84,215)]),"Size32 uses negative16 and positive15 boundaries")
	check(q.uv==PackedVector2Array([Vector2(0,0.25),Vector2(0.125,0.25),Vector2(0.125,0.375),Vector2(0,0.375)]),"Force uses CrashTexture row2 and TL TR BR BL UV order")
	for kind in ["force","electricity"]:
		for age in 16:
			var effect := {"kind":kind,"position":Vector2i(100,200),"tick":age,"angle":0}
			q=art.quad(effect)
			check(not q.is_empty(),"Native lifetime includes tick%d %s"%[age,kind])
			check(q.blend=="add" and q.texture=="res://assets/xfs/weather/CrashTexture.png","Dispatcher450c20 selects SRCALPHA ONE for both families")
			check(q.color==Color(1,1,1,float(255-16*age)/255.0),"Native alpha byte fades by16 per Animate")
			var v := 0.25 if kind=="force" else 0.375
			check(q.uv==PackedVector2Array([Vector2(float(age/2)/8,v),Vector2(float(age/2)/8+0.125,v),Vector2(float(age/2)/8+0.125,v+0.125),Vector2(float(age/2)/8,v+0.125)]),"Two Animate ticks per atlas frame")
			check(q.points[0]==Vector2(84+age,184+age) and q.points[2]==Vector2(115-age,215-age),"Native shrinking size and asymmetric pixel boundary")
			check(q==art.quad(effect) and effect.angle==0 and effect.tick==age,"Pure quad leaves clock angle and input unchanged")
	for invalid in [{"kind":"tornado","tick":0},{"kind":"force","tick":-1},{"kind":"electricity","tick":16}]:
		check(art.quad(invalid).is_empty(),"Unsupported family or expired age returns no geometry")
	q=art.quad({"kind":"force","position":Vector2i(100,200),"tick":0,"angle":90})
	check(q.points==PackedVector2Array([Vector2(84,216),Vector2(84,185),Vector2(115,185),Vector2(115,216)]),"Native positive90 rotates counterclockwise on screen")
	check(q==art.quad({"kind":"force","position":Vector2i(100,200),"tick":0,"angle":450}),"Angles wrap at360")
	# Expected float32 vertices are inserted from an independent PE-LUT/x87 oracle.
	var expected := PackedVector2Array([Vector2(77.59280395507812,196.85072326660156),Vector2(102.35063934326172,178.19461059570312),Vector2(121.00675201416016,202.95245361328125),Vector2(96.2489013671875,221.6085662841797)])
	q=art.quad({"kind":"electricity","position":Vector2i(100,200),"tick":0,"angle":37})
	check(q.points==expected,"Oblique vertices retain native float32 fractions from LUT54c240")
	for row in [
		[1,[Vector2(83.72319793701172,184.28160095214844),Vector2(114.71855163574219,183.7406463623047),Vector2(115.2594985961914,214.73599243164062),Vector2(84.26415252685547,215.27694702148438)]],
		[179,[Vector2(115.71839904785156,216.27679443359375),Vector2(84.72305297851562,215.73585510253906),Vector2(85.26399993896484,184.74049377441406),Vector2(116.25934600830078,185.2814483642578)]],
		[269,[Vector2(116.27680206298828,184.28160095214844),Vector2(115.73584747314453,215.27694702148438),Vector2(84.7405014038086,214.73599243164062),Vector2(85.28144836425781,183.7406463623047)]]]:
		q=art.quad({"kind":"force","position":Vector2i(100,200),"tick":0,"angle":int(row[0])})
		check(q.points==PackedVector2Array(row[1]),"Independent native float32 oracle angle%d"%row[0])
	q=art.quad({"kind":"electricity","position":Vector2i(100,200),"tick":15,"angle":0})
	check(q.points==PackedVector2Array([Vector2(99,199),Vector2(100,199),Vector2(100,200),Vector2(99,200)]),"Helper consumes current angle without applying six degrees times age again")
	var picture := load("res://assets/xfs/weather/CrashTexture.png") as Texture2D
	check(picture!=null and picture.get_size()==Vector2(256,256),"Imported native CrashTexture is available as an exportable256 square resource")
	finish("MAGE SPARK ART CHECKS")
