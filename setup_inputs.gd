extends SceneTree

func _init():
	var inputs = {
		"move_left": [KEY_A],
		"move_right": [KEY_D],
		"jump": [KEY_SPACE],
		"dash": [KEY_SHIFT],
		"skill_1": [KEY_Q],
		"interact": [KEY_E],
		"skill_2": [KEY_F],
		"crouch": [KEY_S],
		"slide": [KEY_CTRL],
		"pause": [KEY_ESCAPE]
	}
	
	for action in inputs:
		if not ProjectSettings.has_setting("input/" + action):
			var event_list = []
			for key in inputs[action]:
				var event = InputEventKey.new()
				event.physical_keycode = key
				var dict = {}
				dict["deadzone"] = 0.5
				dict["events"] = [event]
				ProjectSettings.set_setting("input/" + action, dict)
				
	# Mouse inputs
	var mouse_inputs = {
		"light_attack": MOUSE_BUTTON_LEFT,
		"parry": MOUSE_BUTTON_RIGHT
	}
	for action in mouse_inputs:
		if not ProjectSettings.has_setting("input/" + action):
			var event = InputEventMouseButton.new()
			event.button_index = mouse_inputs[action]
			var dict = {}
			dict["deadzone"] = 0.5
			dict["events"] = [event]
			ProjectSettings.set_setting("input/" + action, dict)

	ProjectSettings.save()
	print("Inputs saved successfully!")
	quit()
