@abstract class_name ConfigResource
extends Resource

signal saved

var _window: Window
var _default_values: Dictionary[String, Variant]


func set_window(window: Window) -> void:
	_window = window


func get_window() -> Window:
	return _window


func set_default_values(default_values: Dictionary[String, Variant]) -> void:
	_default_values = default_values


@abstract func apply() -> void


func save() -> void:
	saved.emit()


func reset_to_default() -> void:
	for prop_name: String in _default_values:
		var value: Variant = _default_values[prop_name]
		match typeof(value):
			TYPE_ARRAY, TYPE_DICTIONARY:
				@warning_ignore("unsafe_method_access")
				value = value.duplicate_deep()
			TYPE_OBJECT:
				if value is Resource:
					@warning_ignore("unsafe_method_access")
					value = value.duplicate(true)
		set_value(prop_name, value)


func set_value(key: String, value: Variant) -> void:
	if key.contains("."):
		_set_nested_value(key, value)
		return

	if has_property(key):
		return set(key, value)
	printerr("Could not find property with key: " + key)


func get_value(key: String) -> Variant:
	if key.contains("."):
		return _get_nested_value(key)

	if has_property(key):
		return get(key)
	printerr("Could not find property with key: " + key)
	return null


func has_property(property_name: String) -> bool:
	for prop: Dictionary in get_property_list():
		if prop.usage & PROPERTY_USAGE_STORAGE != 0:
			if prop.name == property_name:
				return true
	return false


func _set_nested_value(key: String, value: Variant) -> void:
	var parts: PackedStringArray = key.split(".")

	if parts.size() != 2 or parts[0].is_empty() or parts[1].is_empty():
		printerr("Not supported: " + key)
		return

	var property_name: String = parts[0]
	var nested_key: String = parts[1]

	if not has_property(property_name):
		printerr("Could not find property with key: " + key)
		return

	var property_value: Variant = get(property_name)
	if property_value is not Dictionary:
		printerr("Not a dictionary: " + key)
		return

	var dict: Dictionary = property_value
	if value == null:
		dict.erase(nested_key)
	else:
		dict.set(nested_key, value)


func _get_nested_value(key: String) -> Variant:
	var parts: PackedStringArray = key.split(".")

	if parts.size() != 2 or parts[0].is_empty() or parts[1].is_empty():
		printerr("Not supported: " + key)
		return

	var property_name: String = parts[0]
	var nested_key: String = parts[1]

	if not has_property(property_name):
		printerr("Could not find property with key: " + key)
		return null

	var property_value: Variant = get(property_name)
	if property_value is not Dictionary:
		printerr("Not a dictionary: " + key)
		return null

	var dict: Dictionary = property_value
	return dict.get(nested_key)
