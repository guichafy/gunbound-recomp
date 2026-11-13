extends RefCounted
## JEWEL native numeric contracts: docs/jewel-implementation/{damage,lifecycle}.
## Private CRT stream is an offline adaptation (native CRT also feeds UI/cell keys).
## The caller owns terrain and deep-copies this complete state for prediction.
const Physics = preload("res://scripts/classic_ballistics.gd")
const POINTS := [25,10,5,-5]
const RESISTANCE := [300,200,100,100]
const STEP := 0.05
static var pose_data: Dictionary = {}

static func warmup() -> void:
	if not pose_data.is_empty():
		return
	Physics.warmup()
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/xfs/jewel/catalog.json"))
	for kind in 4:
		var states := {}
		for entry in catalog.sheets["jewel%d" % (kind+1)].epa:
			var total := 0
			for duration in entry.durations:
				total+=int(duration)
			states[str(entry.name)]={"ticks":total,"loop":int(entry.flag)==1}
		pose_data[kind]=states

static func create(_terrain, seed: int) -> Dictionary:
	warmup()
	return {"entities":[],"scores":[0,0],"rng":seed&0xffffffff,"turn":0,
		"finished":false,"winner":-1,"clock":0.0,"events":[],"teams":[0,1],"terrain_owner":-1}

static func random_value(state: Dictionary) -> int:
	state.rng = (int(state.rng)*214013+2531011)&0xffffffff
	return (int(state.rng)>>16)&32767

static func initial(terrain, seed: int) -> Dictionary:
	var state := create(terrain,seed)
	for _attempt in 6:
		var x := random_value(state)%int(terrain.world_size().x)
		var roll := random_value(state)%100
		spawn(state,terrain,x,roll)
	return state

static func spawn(state: Dictionary, terrain, x: int, roll: int, dropping: bool = false) -> bool:
	if bool(state.finished):
		return false
	var free := -1
	for slot in 8:
		var used := false
		for entity in state.entities:
			if int(entity.slot)==slot and not bool(entity.removed):
				used=true
				break
		if not used:
			free=slot
			break
	if free<0:
		return false
	var y := 0
	if not dropping:
		y=int(terrain.native_surface_at(x,0))
		if y>9000:
			return false
		y+=1
	var kind := 0 if roll<15 else (1 if roll<40 else (2 if roll<80 else 3))
	var entity := {"slot":free,"type":kind,"pos":Vector2i(x,y),"damage":0,
		"resistance":RESISTANCE[kind],"owner":-1,"drop":dropping,"removed":false,
		"age":0.0,"drift":0,"pose":"drop" if dropping else "normal","pose_age":0.0,"pose_tick":0,"angle":0.0,"fall":0}
	for index in state.entities.size():
		if int(state.entities[index].slot)==free:
			state.entities[index]=entity
			return true
	state.entities.append(entity)
	return true

static func established(state: Dictionary) -> int:
	var count := 0
	for entity in state.entities:
		if not bool(entity.removed) and not bool(entity.drop):
			count+=1
	return count

static func next_turn(state: Dictionary, terrain) -> void:
	if bool(state.finished):
		return
	state.turn=int(state.turn)+1
	if established(state)>=6:
		return
	# Native replacement order is roll then X, inverse of initial pairs.
	var roll := random_value(state)%100
	var x := random_value(state)%int(terrain.world_size().x)
	spawn(state,terrain,x,roll,true)

static func hit(state: Dictionary, point: Vector2i) -> int:
	for entity in state.entities:
		if bool(entity.removed):
			continue
		var pos := Vector2i(entity.pos)
		if point.x>=pos.x-10 and point.x<=pos.x+10 and point.y>=pos.y-20 and point.y<=pos.y:
			return int(entity.slot)
	return -1

static func int32(value: int) -> int:
	var wrapped := value&0xffffffff
	return wrapped-0x100000000 if wrapped>=0x80000000 else wrapped

static func blast(state: Dictionary, impact: Vector2i, shot: Dictionary) -> void:
	if bool(state.finished) or bool(state.get("blocked",false)):
		return
	var material := int(shot.get("material",0))
	if material<0 or material>2:
		return
	var scale := int(shot.get("scale",100))
	assert(scale!=0,"Native final IDIV requires nonzero percentage scale")
	var radius := Physics.quot(int(shot.dimension[material]),2)+10
	var aspect := maxi(1,int(shot.aspect[material]))
	for entity in state.entities:
		if bool(entity.removed):
			continue
		var pos := Vector2i(entity.pos)
		var dx := Physics.quot(int32(scale*(pos.x-impact.x)),aspect)
		var dy := int32(pos.y-10-impact.y)
		var square := int32(int32(dx*dx)+int32(dy*dy))
		var amount := 0
		if square<int32(radius*radius):
			var falloff := int((float(radius)-sqrt(float(square)))*1000.0/float(radius))
			amount=Physics.quot(int32(int(shot.power[material])*falloff),1000)
		amount=Physics.quot(int32(amount*int(shot.get("percent",100))),scale)
		var factor := scale+int(shot.get("bonus",0))+Physics.quot(int(shot.get("force",0)),2)
		amount=Physics.quot(int32(factor*amount),scale)
		if amount>0:
			entity.damage=int32(int(entity.damage)+amount)
			entity.owner=int(shot.get("owner",255))&255
			entity.pose="damage"
			entity.pose_age=0.0
			entity.pose_tick=0

static func tick(state: Dictionary, terrain, dt: float) -> void:
	if bool(state.finished) or dt<=0.0:
		return
	state.clock=float(state.clock)+dt
	while float(state.clock)+0.0000001>=STEP:
		state.clock=maxf(0.0,float(state.clock)-STEP)
		step(state,terrain)
		if bool(state.finished):
			break

static func set_pose(entity: Dictionary, pose: String) -> void:
	entity.pose=pose
	entity.pose_age=0.0
	entity.pose_tick=0

static func advance_pose(entity: Dictionary) -> void:
	entity.pose_tick=int(entity.pose_tick)+1
	var data: Dictionary=pose_data[int(entity.type)][str(entity.pose)]
	if int(entity.pose_tick)>=int(data.ticks):
		if bool(data.loop):
			entity.pose_tick=0
		else:
			set_pose(entity,"normal")
	entity.pose_age=float(entity.pose_tick)*STEP

static func surface_angle(entity: Dictionary, terrain) -> int:
	if bool(entity.drop):
		return 0
	var pos := Vector2i(entity.pos)
	var center := int(terrain.native_surface_at(pos.x,pos.y-10))
	var left := int(terrain.native_surface_at(pos.x-10,pos.y-10))
	var right := int(terrain.native_surface_at(pos.x+10,pos.y-10))
	var cutoff := center+20
	if left>cutoff:
		if right>cutoff:
			left=center
			right=center
		elif right<cutoff:
			left=2*center-right
	if right>cutoff and left<cutoff:
		right=2*center-left
	var x := 20
	var y := right-left
	while x < -127 or x > 128 or y < -127 or y > 128:
		x=Physics.quot(x,2)
		y=Physics.quot(y,2)
	return Physics.angles.decode_s16(2*(x+127+256*(y+127)))

static func step(state: Dictionary, terrain) -> void:
	var size := Vector2i(terrain.world_size())
	for entity in state.entities:
		if bool(entity.removed):
			continue
		entity.age=float(entity.age)+STEP
		var pos := Vector2i(entity.pos)
		var fall := int(entity.fall)
		var floor_y := int(terrain.native_surface_at(pos.x,pos.y-15))
		var supported := pos.y+fall>=floor_y and pos.x>0 and pos.x<size.x
		if supported:
			if fall<5:
				pos.y=floor_y
				if str(entity.pose)=="drop":
					set_pose(entity,"normal")
				entity.fall=0
				entity.drift=0
				if bool(entity.drop):
					entity.drop=false
			else:
				# 479eae: bounce by the PREVIOUS fall speed, restart speed1.
				pos.y=floor_y-fall
				entity.fall=1
				entity.drift=0
				if bool(entity.drop) and floor_y<size.y:
					entity.drop=false
		else:
			if str(entity.pose)=="normal":
				set_pose(entity,"drop")
				entity.owner=int(state.get("terrain_owner",-1))
			entity.fall=fall+1
			pos.y+=int(entity.fall)
			if bool(entity.drop):
				var wind := int(state.get("wind",0))
				var direction := int(state.get("wind_angle",0))
				var component := int(Physics.s(posmod(direction+90,360))*wind)
				entity.drift=int32(int(entity.drift)+3*component)
				pos.x+=Physics.quot(int(entity.drift),100)
				entity.drift=int(entity.drift)-Physics.quot(int(entity.drift),100)*100
		entity.pos=pos
		entity.angle=surface_angle(entity,terrain)
		advance_pose(entity)
		if pos.y>size.y or int(entity.damage)>=int(entity.resistance):
			remove(state,entity)

static func remove(state: Dictionary, entity: Dictionary) -> void:
	if bool(entity.removed):
		return
	entity.removed=true
	var removal_event := {"type":"jewel_removed","position":Vector2(entity.pos),"slot":int(entity.slot),
		"kind":int(entity.type),"owner":int(entity.owner),"drop":bool(entity.drop),
		"effect":int(entity.damage)>=int(entity.resistance),"sound":not bool(entity.drop)}
	state.events.append(removal_event)
	if bool(entity.drop) or bool(state.finished):
		return
	var owner := int(entity.owner)
	var teams: Array=state.get("teams",[0,1])
	if owner<0 or owner>=teams.size():
		return
	var team := int(teams[owner])
	if team<0 or team>1:
		return
	var before := int(state.scores[team])
	state.scores[team]=maxi(0,before+POINTS[int(entity.type)])
	state.events.append({"type":"jewel_score","position":Vector2(entity.pos),"owner":owner,"team":team,
		"value":POINTS[int(entity.type)],"delta":int(state.scores[team])-before,"score":int(state.scores[team])})
	if int(state.scores[team])>=100:
		#479ba0 threshold path jumps past sound/Jflame creation.
		removal_event.effect=false
		removal_event.sound=false
		state.finished=true
		state.winner=1 if int(state.scores[1])>int(state.scores[0]) else 0
