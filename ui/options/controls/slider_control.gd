@tool
class_name SliderControl
extends BaseControl

@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export var step: float = 1.0

var _value: float

@onready var _slider: HSlider = %Slider


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_slider.value_changed.connect(_on_value_changed)
		_slider.step = step
		_slider.min_value = min_value
		_slider.max_value = max_value
		_value = _slider.value
	# force update
	title = title


func _on_disabled() -> void:
	super._on_disabled()
	if is_instance_valid(_slider):
		_slider.editable = not disabled


func _on_value_changed(new_value: float) -> void:
	if value != new_value:
		_set_value(new_value)
		value_changed.emit(self, value)


func _set_value(new_value: Variant) -> void:
	_value = new_value
	if is_instance_valid(_slider):
		_slider.value = _value


func _get_value() -> Variant:
	return _value
