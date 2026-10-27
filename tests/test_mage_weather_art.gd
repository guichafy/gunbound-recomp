extends "res://tests/support/suite.gd"
func run() -> void:
	var path := "res://scripts/mage_weather_art.gd"
	var exists := ResourceLoader.exists(path)
	var quads: Array = load(path).quads({"type":"force","x":100,"native_width":128},0,130) if exists else []
	check(quads.size()==3,"Native column emits64px vertical tiles without scaling their height")
	if not exists:
		finish("MAGE WEATHER ART CHECKS")
		return
	var art = load(path)
	check(quads[0].points==PackedVector2Array([Vector2(36,0),Vector2(163,0),Vector2(163,64),Vector2(36,64)]),"Native render uses half full-width and rightminus1")
	check(quads[0].blend=="mix" and quads[0].color==Color.WHITE,"Force native vertexARGB and alpha blending")
	check(Vector2(quads[0].uv[0]).is_equal_approx(Vector2(0.00001,0.00001)) and Vector2(quads[0].uv[2]).is_equal_approx(Vector2(0.49997,0.24997)),"Firewall UVepsilon and4e-5 shrink")
	for row in [["force",31,-62,"mix"],["force",32,0,"mix"],["electricity",31,-62,"add"],["tornado",63,-378,"mix"],["tornado",64,0,"mix"]]:
		quads=art.quads({"type":row[0],"x":100,"native_width":128},int(row[1]),130)
		check(is_equal_approx(quads[0].points[0].y,float(row[2])),"Native scroll modulo %s tick%d"%[row[0],row[1]])
		check(quads[0].blend==row[3],"Dispatch4508a0 chooses blend by native object family")
		var frame: int=int(row[1])%8
		for quad in quads:
			var epsilon := 0.00001 if row[0]=="force" else 0.0
			var top := float(frame/2)*0.25+(0.00001 if row[0]=="force" else 0.001)
			check(Vector2(quad.uv[0]).is_equal_approx(Vector2(float(frame%2)*0.5+epsilon,top)),"UV frame advances once per vertical segment")
			frame=(frame+1)%8
	quads=art.quads({"type":"electricity","x":-100,"native_width":95},2,80)
	check(quads[0].points[0].x==-147 and quads[0].points[1].x==-54,"Odd fullwidth uses integer truncation")
	check(Vector2(quads[0].uv[2]).is_equal_approx(Vector2(0.5,0.499)),"Electric UV uses0.248height plus0.001offset")
	check(art.quads({"type":"wind","x":0,"native_width":128},0,100).is_empty(),"Only native column families emit quads")
	check(art.quads({"type":"force","x":100,"native_width":128},31,1800)==art.quads({"type":"force","x":100,"native_width":128},31,1800),"Pure geometry freezes with the caller's pausedtick")
	for name in ["FirewallTexture","LightningTexture","TornadoTexture"]:
		var file := "res://assets/openbound/weather/native/%s.png"%name
		var picture := Image.load_from_file(file)
		check(picture!=null and picture.get_size()==Vector2i(256,256),"Original ARGB4444 texture decoded %s"%name)
	finish("MAGE WEATHER ART CHECKS")
