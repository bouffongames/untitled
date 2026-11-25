class_name PressureTile
extends Area3D

signal state_changed(pressed: bool)

@export var togglable: bool
@export var _animation_player: AnimationPlayer

var _is_pressed: bool
var _occupants: Array[Node3D]


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_area_entered(area: Area3D) -> void:
	_occupants.append(area)
	_update()


func _on_area_exited(area: Area3D) -> void:
	_occupants.erase(area)
	_update()


func _on_body_entered(body: Node3D) -> void:
	_occupants.append(body)
	_update()


func _on_body_exited(body: Node3D) -> void:
	_occupants.erase(body)
	_update()


func _update() -> void:
	var pressed: bool = _occupants.size() > 0
	if _is_pressed != pressed:
		if _is_pressed and not togglable:
			return
		if pressed:
			_animation_player.play("pressed")
		else:
			_animation_player.play_backwards("pressed")
		_is_pressed = pressed
		state_changed.emit(_is_pressed)
