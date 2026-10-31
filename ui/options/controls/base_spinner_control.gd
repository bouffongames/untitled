@tool
@abstract class_name BaseSpinnerControl
extends BaseControl

@export var _down_button: Button
@export var _up_button: Button


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		if is_instance_valid(_down_button):
			_down_button.pressed.connect(_on_index_decreased)
		if is_instance_valid(_up_button):
			_up_button.pressed.connect(_on_index_increased)


func _on_disabled() -> void:
	super._on_disabled()
	if is_instance_valid(_down_button):
		_down_button.disabled = disabled
	if is_instance_valid(_up_button):
		_up_button.disabled = disabled


func _on_index_increased() -> void:
	_change_index(1)


func _on_index_decreased() -> void:
	_change_index(-1)


@abstract func _change_index(_increment: int) -> void


func _update_value_label() -> void:
	if is_instance_valid(_value_label):
		_value_label.text = str(value)
