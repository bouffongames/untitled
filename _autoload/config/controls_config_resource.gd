class_name ControlsConfigResource
extends ConfigResource

@export var mouse_sensitivity: float:
	set(value):
		mouse_sensitivity = maxf(0.01, value)
@export var is_horizontal_aim_inverted: bool
@export var is_vertical_aim_inverted: bool
@export var is_run_toggled: bool
@export var is_crouch_toggled: bool
@export var actions: Dictionary[String, InputAction]


func apply() -> void:
	_apply_actions()


func _apply_actions() -> void:
	for action_name: String in actions:
		if not InputMap.has_action(action_name):
			continue

		InputMap.action_erase_events(action_name)

		var input_action: InputAction = actions[action_name]
		var input_code: int = input_action.input_code
		var input_type: InputAction.InputType = input_action.input_type
		if input_type == InputAction.InputType.KEYBOARD:
			var event_key: InputEventKey = InputEventKey.new()
			event_key.keycode = input_code as Key
			InputMap.action_add_event(action_name, event_key)
		elif input_type == InputAction.InputType.MOUSE_BUTTON:
			var event_mouse_button: InputEventMouseButton = InputEventMouseButton.new()
			event_mouse_button.button_index = input_code as MouseButton
			InputMap.action_add_event(action_name, event_mouse_button)
