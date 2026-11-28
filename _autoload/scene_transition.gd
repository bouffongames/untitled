class_name Transition
extends Control

signal finished

@export var duration: float = 1.0
@export var color_rect: ColorRect

var _material: ShaderMaterial

# do not change, these are dynamic values. 
var _target: float
var _progress: float
var _progress_speed: float
var _is_active: bool

var _max_progress: float


func _ready() -> void:
	_material = color_rect.material as ShaderMaterial
	_max_progress = _material.get_shader_parameter("progress_bias").x + 1
	visible = false


func _process(delta: float) -> void:
	if not _is_active:
		return

	_progress = move_toward(_progress, _target, _progress_speed * delta)
	_material.set_shader_parameter("progress", _progress)

	if is_equal_approx(_progress, _target):
		_is_active = false
		if is_equal_approx(_progress, _max_progress):
			visible = false
		finished.emit()


func enter() -> void:
	_target = 0.0
	_progress = _max_progress
	_progress_speed = _max_progress / max(duration, 0.001)
	_is_active = true
	_material.set_shader_parameter("invert", false)
	visible = true


func exit() -> void:
	_progress = 0.0
	_target = _max_progress
	_progress_speed = _max_progress / max(duration, 0.001)
	_is_active = true
	_material.set_shader_parameter("invert", false)
