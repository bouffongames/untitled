@tool
extends CPUParticles3D
## Emit based on velocity instead of time.

@export_range(0.001, 100.0, 0.0001) var min_distance: float = 0.1

var previous_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	previous_position = global_position


func _physics_process(delta: float) -> void:
	var velocity: Vector3 = (global_position - previous_position) / delta
	previous_position = global_position

	if velocity.length() >= min_distance:
		emitting = true
	else:
		emitting = false
