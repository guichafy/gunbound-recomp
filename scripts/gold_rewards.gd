extends RefCounted
## Literal 1x1 GameClientProvider Gold flow; local XP remains separate.
static func apply_shot(state: Dictionary, shot: Dictionary, popularity: int) -> Dictionary:
	var result := state.duplicate(true)
	var enemy := int(shot.get("enemy_damage",0))
	var ally := int(shot.get("ally_damage",0))
	var kills := int(shot.get("enemy_kills",0))
	var suicides := int(shot.get("ally_kills",0))
	if enemy == 0 and ally == 0 and kills == 0 and suicides == 0:
		return result
	var delta := kills*30-suicides*50-(10 if ally>30 else 0)
	if enemy != 0 or kills > 0:
		var angle := float(shot.get("angle",0))
		var travelled := float(shot.get("travelled",0))
		if angle >= 70 and angle <= 120:
			delta += 10 if travelled>4 else (5 if travelled>2.5 else 0)
		for key in ["tornado","mirror"]:
			if shot.get(key,false):
				delta += 10
		if shot.get("boomer",false):
			delta += 10
		if shot.get("backward",false):
			delta += 5
		delta += 15 if enemy>500 else (10 if enemy>250 else (5 if enemy>150 else 0))
		var previous := int(result.get("enemy_damage",0))
		if previous<1000 and previous+enemy>=1000:
			delta += 10
		# The source's next else-if repeats the1000 condition, so2000 is unreachable.
		elif previous<3000 and previous+enemy>=3000:
			delta += 30
	result.enemy_damage = int(result.get("enemy_damage",0))+enemy
	result.gold = int((int(result.get("gold",0))+delta)*(1.0+popularity/100.0))
	return result
static func result_bonus(victory: bool, draw: bool) -> int:
	return 0 if draw else (4 if victory else 1)
