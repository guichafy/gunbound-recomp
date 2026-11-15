extends RefCounted
## Platform adaptation only: one safe-area transform, never simulation coordinates.
static func fit(_window_size: Vector2, safe_window: Rect2, canvas_size: Vector2) -> Transform2D:
	if safe_window.size.x<=0 or safe_window.size.y<=0 or canvas_size.x<=0 or canvas_size.y<=0:
		return Transform2D.IDENTITY
	var factor := minf(safe_window.size.x/canvas_size.x,safe_window.size.y/canvas_size.y)
	return Transform2D(Vector2(factor,0),Vector2(0,factor),safe_window.position+(safe_window.size-canvas_size*factor)*0.5)
static func to_canvas(window_point: Vector2, transform: Transform2D) -> Vector2:
	return transform.affine_inverse()*window_point
## Godot's screen transform includes keep-aspect letterboxing; axis ratios do not.
static func safe_canvas(safe_window: Rect2, screen_transform: Transform2D) -> Rect2:
	var inverse := screen_transform.affine_inverse()
	return Rect2(inverse*safe_window.position,safe_window.size*inverse.x.length())
static func dp_scale(screen_transform: Transform2D, dpi: int) -> float:
	return maxf(1.0,float(dpi)/160.0)*screen_transform.affine_inverse().x.length()

## Intersect physical regions before transforming. Android may already resize
## the rendering surface for IME; subtracting its height again shrinks twice.
static func safe_window(display_safe: Rect2, window: Rect2, screen_size: Vector2, keyboard_height: float) -> Rect2:
	if display_safe.size.x<=0 or display_safe.size.y<=0:display_safe=window
	if screen_size.x<=0 or screen_size.y<=0:screen_size=window.end
	var available := Rect2(Vector2.ZERO,screen_size)
	available.size.y=maxf(0.0,screen_size.y-maxf(0.0,keyboard_height))
	var safe := display_safe.intersection(window).intersection(available)
	safe.position-=window.position
	return safe
