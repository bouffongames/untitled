@tool
class_name NumberSpinnerControl
extends BaseSpinnerControl

@export var _max_value: int = 1

var _value: int = 0


func _ready() -> void:
	super._ready()
	value = value


func _set_value(new_value: Variant) -> void:
	_value = new_value
	_update_value_label()


func _get_value() -> Variant:
	return _value


func _change_index(increment: int) -> void:
	var new_value: int = clampi(_value + increment, 0, _max_value)
	if value != new_value:
		value = new_value
		value_changed.emit(self, value)
