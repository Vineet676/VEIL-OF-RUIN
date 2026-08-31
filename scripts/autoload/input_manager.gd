extends Node

func _ready():
	_register_key("move_left", KEY_A)
	_register_key("move_right", KEY_D)
	_register_key("jump", KEY_SPACE)
	_register_key("dash", KEY_SHIFT)
	_register_key("skill_1", KEY_Q)
	_register_key("interact", KEY_E)
	_register_key("skill_2", KEY_F)
	_register_key("crouch", KEY_S)
	_register_key("slide", KEY_CTRL)
	_register_key("pause", KEY_ESCAPE)
	
	_register_mouse("light_attack", MOUSE_BUTTON_LEFT)
	_register_mouse("parry", MOUSE_BUTTON_RIGHT)

func _register_key(action_name: String, keycode: int):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# Check if this exact key is already bound to avoid duplicates
	var has_event = false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			has_event = true
			break
			
	if not has_event:
		var event = InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)

func _register_mouse(action_name: String, button_index: int):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		
	var has_event = false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			has_event = true
			break
			
	if not has_event:
		var event = InputEventMouseButton.new()
		event.button_index = button_index
		InputMap.action_add_event(action_name, event)
