extends Camera3D

@export var target: Node3D
@export var follow_speed: float = 5.0
@export var offset: Vector3 = Vector3(0, 5, 10)
## Jump to target's global position if distance is greater than a certain distance.
@export var jump_distance: float = 2.0


func _process(delta: float) -> void:
	if target == null:
		return
	var desired: Vector3 = target.global_position + offset
	if global_position.distance_squared_to(desired) >= jump_distance:
		global_position = desired
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
