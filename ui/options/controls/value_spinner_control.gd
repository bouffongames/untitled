@tool
class_name ValueSpinnerControl
extends BaseSpinnerControl

@export var _values: Dictionary[Variant, Variant] = {}:
	set(value):
		_values = value
		_update_value_label()
	get:
		return _values

var _index: int = 0:
	set(value):
		_index = value
		_update_value_label()
	get:
		return _index


func _ready() -> void:
	super._ready()
	_values = _values
	_index = _index


func _set_value(new_value: Variant) -> void:
	if not _values.is_empty():
		if _values.has(new_value):
			_index = _values.keys().find(new_value)


func _get_value() -> Variant:
	if not _values.is_empty():
		return _values[_values.keys()[_index]]
	return ""


func _change_index(increment: int) -> void:
	var new_index: int = wrapi(_index + increment, 0, _values.keys().size())
	if _index != new_index:
		_index = new_index
		value_changed.emit(self, _values.keys()[_index])
