class_name InputAction
extends Resource

enum InputType {
	KEYBOARD,
	MOUSE_BUTTON,
}

@export var input_code: int
@export var input_type: InputType


func _to_string() -> String:
	return (
		"InputAction(input_code=%s[%s], input_type=%s)"
		% [
			get_input_code_as_string(),
			input_code,
			InputType.keys()[input_type]
		]
	)


func get_input_code_as_string() -> String:
	return _get_input_code_as_string(input_code, input_type)


static func _get_input_code_as_string(code: int, type: InputType) -> String:
	if type == InputType.KEYBOARD:
		return OS.get_keycode_string(code as Key)

	return _get_mouse_button_string(code as MouseButton)


static func _get_mouse_button_string(button_index: MouseButton) -> String:
	var names: Dictionary[int, String] = {
		MOUSE_BUTTON_LEFT: "Left Mouse",
		MOUSE_BUTTON_RIGHT: "Right Mouse",
		MOUSE_BUTTON_MIDDLE: "Middle Mouse",
		MOUSE_BUTTON_WHEEL_UP: "Mouse Wheel Up",
		MOUSE_BUTTON_WHEEL_DOWN: "Mouse Wheel Down",
		MOUSE_BUTTON_WHEEL_LEFT: "Mouse Wheel Left",
		MOUSE_BUTTON_WHEEL_RIGHT: "Mouse Wheel Right",
		MOUSE_BUTTON_XBUTTON1: "Mouse Button 4",
		MOUSE_BUTTON_XBUTTON2: "Mouse Button 5",
	}

	if names.has(button_index):
		return names[button_index]

	return "Mouse Button %d" % button_index
