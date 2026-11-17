extends RefCounted
## Shared drawing/hit regions in safe-area dp. Battle bars remain visible.
static func caption_layout(font: Font, caption: String, size: Vector2, maximum: int) -> Dictionary:
	var lines := caption.split("\n")
	var font_size := maxi(1,maximum)
	while font_size>1:
		var fits := font.get_height(font_size)*lines.size()<=size.y-10
		for line in lines:
			fits=fits and font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=size.x-10
		if fits:break
		font_size-=1
	var height := font.get_height(font_size)
	return {"lines":lines,"font_size":font_size,"line_height":height,"baseline":(size.y-height*lines.size())*0.5+font.get_ascent(font_size)}

static func regions(safe_dp: Rect2, _mode: String) -> Dictionary:
	var result := {}
	var origin := safe_dp.position+Vector2(8,48)
	for i in 5:
		result[["move_left","move_right","aim_down","aim_up","flip"][i]]=Rect2(origin+Vector2(i*52,0),Vector2(48,48))
	var right := safe_dp.end.x-8
	for i in 4:
		result[["camera","weapons","items","pause"][i]]=Rect2(Vector2(right-(4-i)*52,origin.y+52),Vector2(48,48))
	result.charge=Rect2(Vector2(right-100,safe_dp.end.y-100),Vector2(96,48))
	result.pass=Rect2(Vector2(right-152,safe_dp.end.y-100),Vector2(48,48))
	return result
static func selection(safe_dp: Rect2, kind: String) -> Dictionary:
	var result := {}
	var count := 3 if kind=="weapon" else 6
	for i in count:
		result[kind+"_"+str(i)]=Rect2(safe_dp.position+Vector2(8+i*52,152),Vector2(48,48))
	return result
