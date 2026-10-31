@tool
class_name RebindControl
extends BaseControl

signal rebind_started(target: RebindControl)

@export var _button: Button

var waiting_for_input: bool:
	set(value):
		waiting_for_input = value
		if not waiting_for_input:
			_refresh()

var _action_name: String:
	get():
		if key.contains("."):
			var parts: PackedStringArray = key.split(".")
			return parts[1]
		return key

var _input_action: InputAction


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		if is_instance_valid(_button):
			_button.pressed.connect(_on_pressed)
	_refresh()


func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return

	var event_key: InputEventKey = event as InputEventKey
	if is_instance_valid(event_key):
		if not event_key.pressed or event_key.echo:
			return

		get_viewport().set_input_as_handled()

		if event_key.keycode != KEY_ESCAPE:
			_bind(event_key.keycode, InputAction.InputType.KEYBOARD)

		waiting_for_input = false
		return

	var event_mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if is_instance_valid(event_mouse_button):
		if not event_mouse_button.pressed:
			return

		get_viewport().set_input_as_handled()

		_bind(event_mouse_button.button_index, InputAction.InputType.MOUSE_BUTTON)

		waiting_for_input = false


func _on_pressed() -> void:
	waiting_for_input = true
	_button.text = "press a key"
	_button.release_focus()
	rebind_started.emit(self)


func _set_value(new_value: Variant) -> void:
	_input_action = new_value
	if not InputMap.has_action(_action_name):
		printerr("Action does not exist: ", _action_name)
	_refresh()


func _get_value() -> Variant:
	for event: InputEvent in InputMap.action_get_events(_action_name):
		var event_key: InputEventKey = event as InputEventKey
		if is_instance_valid(event_key):
			_input_action.input_type = InputAction.InputType.KEYBOARD
			_input_action.input_code = event_key.keycode
			return _input_action

		var event_mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if is_instance_valid(event_mouse_button):
			_input_action.input_type = InputAction.InputType.MOUSE_BUTTON
			_input_action.input_code = event_mouse_button.button_index
			return _input_action

	return null


func _bind(input_code: int, input_type: InputAction.InputType) -> void:
	var taken: String = _owner_of(input_code, input_type)

	if not taken.is_empty() and taken != _action_name:
		InputMap.action_erase_events(taken)

	if not InputMap.has_action(_action_name):
		printerr("Action does not exist: ", _action_name)
		return

	InputMap.action_erase_events(_action_name)

	var event: InputEvent

	if input_type == InputAction.InputType.KEYBOARD:
		var event_key: InputEventKey = InputEventKey.new()
		event_key.keycode = input_code as Key
		event = event_key
	else:
		var event_mouse_button: InputEventMouseButton = InputEventMouseButton.new()
		event_mouse_button.button_index = input_code as MouseButton
		event = event_mouse_button

	if _input_action == null:
		_input_action = InputAction.new()
	_input_action.input_code = input_code
	_input_action.input_type = input_type
	InputMap.action_add_event(_action_name, event)

	value_changed.emit(self, _input_action)


func _owner_of(input_code: int, input_type: InputAction.InputType) -> String:
	for action: String in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue

		for event: InputEvent in InputMap.action_get_events(action):
			if input_type == InputAction.InputType.KEYBOARD:
				var event_key: InputEventKey = event as InputEventKey
				if is_instance_valid(event_key) and event_key.keycode == input_code:
					return action

			if input_type == InputAction.InputType.MOUSE_BUTTON:
				var event_mouse_button: InputEventMouseButton = event as InputEventMouseButton
				if (
					is_instance_valid(event_mouse_button)
					and event_mouse_button.button_index == input_code
				):
					return action

	return ""


func _refresh() -> void:
	_button.text = _get_input_text()


func _get_input_text() -> String:
	if _input_action == null or _input_action.input_code == 0:
		return "unbound"

	return _input_action.get_input_code_as_string()
