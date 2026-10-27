extends "res://tests/support/suite.gd"
## Native clock/wind readouts, fractional seconds and physical direction.
const Hud = preload("res://scripts/hud_art.gd")
const Match = preload("res://scripts/match.gd")
func run() -> void:
	var hud := Hud.new()
	var model := Match.new()
	model.start(2,1,42)
	check(hud.has_method("timer_digits"),"Native timer exposes seconds/tenths presentation")
	check(hud.has_method("wind_display"),"Native wind readout uses the physical vector")
	if hud.has_method("timer_digits") and hud.has_method("wind_display"):
		for row in [[30.0,[3,0,0]],[12.7,[1,2,7]],[12.3,[1,2,3]],[9.95,[0,9,9]],[0.09,[0,0,0]],[0.0,[0,0,0]],[-1.0,[0,0,0]]]:
			model.turn_time=row[0]
			check(hud.timer_digits(model)==row[1],"Native floor seconds/tenths "+str(row[0]))
		for force in [0,1,13,26]:
			model.weather.wind_force=force
			for heading in [0,90,180,270]:
				model.weather.wind_angle=heading
				var shown: Dictionary=hud.wind_display(model)
				check(shown.force==force,"Wind force remains exact")
				check(shown.get("digit_right",-1)==(412.0 if force>=10 else 407.0),"Wind digits retain native x390/401 or396")
				if force>0:
					check(Vector2.from_angle(shown.rotation).dot(model.weather.wind_vector().normalized())>0.99999,"Wind ring cardinal agrees with physical acceleration")
		check(hud.native_timer_available() and hud.native_wind_available(),"All native clock/wind components are validated")
		for key in ["NativeTimerDigits.png","NativeTimerFraction.png","NativeTimerDot.png"]:
			var broken := Hud.new()
			broken.client_assets.files.erase(key)
			check(not broken.native_timer_available(),"Clock group falls back as a whole if"+key+"is absent")
		for key in ["NativeWindTexture.png","NativeWindDigits.png","NativeWindLabel.png"]:
			var broken := Hud.new()
			broken.client_assets.files.erase(key)
			check(not broken.native_wind_available(),"Wind group falls back as a whole if"+key+"is absent")
	report("HUD CLOCK WIND CHECKS")
	quit(exit_code())
