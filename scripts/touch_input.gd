extends RefCounted
## Raw-touch ownership. It never reads Match, terrain or RNG.
var owners := {}
var commands: Array[Dictionary] = []
func emit_command(action: String, value: Variant=null) -> void:
	commands.append({"action":action,"value":value})
func drain_commands() -> Array[Dictionary]:
	var result := commands
	commands=[]
	return result
func cancel_all(_reason: String) -> void:
	for owner in owners.values():
		if owner.action=="charge":emit_command("charge_cancel")
		if owner.action=="drag":emit_command("drag_cancel")
	owners.clear()
	emit_command("move",0)
	emit_command("aim",0)
func busy() -> bool:
	for owner in owners.values():
		if owner.action in ["charge","drag"]:return true
	return false
func held(axis: String) -> int:
	var value := 0
	for owner in owners.values():
		if owner.action==axis+"_left" or owner.action==axis+"_down":value-=1
		if owner.action==axis+"_right" or owner.action==axis+"_up":value+=1
	return clampi(value,-1,1)
func handle(event: InputEvent, context: Dictionary) -> bool:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return false
	var index: int = event.index
	if event is InputEventScreenTouch and event.pressed:
		if context.get("overlay",false):return false
		if owners.has(index):return true
		var action := ""
		for key in context.regions:
			if context.regions[key].has_point(event.position):action=key;break
		if action=="":
			if not context.world_rect.has_point(event.position):return false
			for box in context.get("blocked_rects",[]):
				if box.has_point(event.position):return false
			action="pan" if context.get("camera_mode",false) else ("respawn" if context.get("waiting",false) else ("drag" if context.get("drag_mode",false) and context.get("can_act",false) else "pan"))
		if action=="pause":
			cancel_all("pause")
			emit_command("pause")
			return true
		if busy():return true
		if action in ["charge","drag"]:
			if not context.get("can_act",false) or context.get("camera_mode",false):return true
			for key in owners.keys():
				if owners[key].action=="pan" or owners[key].action.begins_with("move_") or owners[key].action.begins_with("aim_"):owners.erase(key)
		if action in ["move_left","move_right","aim_up","aim_down","flip","pass"] or action.begins_with("weapon_"):
			if not context.get("can_act",false):return true
		owners[index]={"action":action,"start":event.position,"distance":0.0}
		if action=="charge":emit_command("charge_begin")
		elif action=="drag":emit_command("drag_begin",event.position.x)
		elif action.begins_with("move_"):emit_command("move",held("move"))
		elif action.begins_with("aim_"):emit_command("aim",held("aim"))
		return true
	if not owners.has(index):return false
	var owner: Dictionary = owners[index]
	owner.distance=maxf(owner.distance,event.position.distance_to(owner.start))
	if event is InputEventScreenDrag:
		if owner.action=="drag":emit_command("drag_update",Vector2(event.position.x,event.relative.x))
		elif owner.action=="pan" and not busy():emit_command("pan",event.relative)
		return true
	owners.erase(index)
	if event.canceled:
		if owner.action in ["charge","drag"]:emit_command(owner.action+"_cancel")
	elif owner.action in ["charge","drag"]:emit_command(owner.action+"_end")
	elif owner.action=="respawn":
		if owner.distance<=12.0*context.get("pixels_per_dp",1.0):emit_command("respawn",event.position)
	elif not owner.action in ["pan","move_left","move_right","aim_up","aim_down"]:
		if context.regions.has(owner.action) and context.regions[owner.action].has_point(event.position):emit_command(owner.action)
	if owner.action.begins_with("move_"):emit_command("move",held("move"))
	if owner.action.begins_with("aim_"):emit_command("aim",held("aim"))
	return true
