@tool
@abstract class_name BaseControl
extends Control

@warning_ignore("unused_signal")
signal value_changed(target: BaseControl, new_value: Variant)

@export var disabled: bool = false:
	set(value):
		disabled = value
		_on_disabled()
	get:
		return disabled

@export var key: String = ""
@export var title: String = "":
	set(value):
		title = value
		if is_instance_valid(_title_label):
			_title_label.text = title
	get:
		return title

@export var _title_label: Label
@warning_ignore("unused_private_class_variable")
@export var _value_label: Label

var value: Variant:
	set(new_value):
		_set_value(new_value)
	get:
		return _get_value()


func _ready() -> void:
	self.disabled = disabled
	title = title


func _on_disabled() -> void:
	for child: Node in get_children():
		var label: Label = child as Label
		if is_instance_valid(label):
			label.theme_type_variation = "DisabledLabel" if disabled else ""


@abstract func _set_value(_new_value: Variant) -> void

@abstract func _get_value() -> Variant
