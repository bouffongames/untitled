class_name DoorGate
extends Node3D

@export var _body: StaticBody3D
@export var _open_rotation_degrees: Vector3 = Vector3(0.0, -125.0, 0.0)
@export var _navigation_region: NavigationRegion3D


func open_door() -> void:
	AudioManager.play_sfx("open metal door", 1.0, 1.0,-3.0)
	if is_instance_valid(_body):
		_body.collision_layer = 0
	if is_instance_valid(_navigation_region):
		_navigation_region.bake_navigation_mesh(true)
	var tween: Tween = create_tween()
	tween.tween_property(
			self,
			"rotation_degrees",
			_open_rotation_degrees,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
