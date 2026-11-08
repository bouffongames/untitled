extends CharacterBody3D

enum States {
	PATROL,
	INVESTIGATE,
	CAUGHT
}

enum SenseFlags {
	NOTICED,
	CAUGHT
}

@export_range(60.0, 120.0) var fov_degrees := 90.0
@export_range(0.0, 20.0) var max_vision_range := 10.0
@export_range(0.0, 20.0) var near_vision_range := 4.0
@export_flags_3d_physics var vision_obstacle_layer

var _player_instance: Player
var _detection_min_dot_value := 0.0 # set in _ready once
var _current_state: States = States.PATROL

@onready var _eyes: Marker3D = %Eyes

func _ready() -> void:
	_detection_min_dot_value = cos(deg_to_rad(fov_degrees * 0.5))
	_player_instance = get_tree().get_first_node_in_group("Player")


func _physics_process(delta: float) -> void:
	var sense_result := _sense()
	_think(sense_result)


func _sense() -> Dictionary:
	var can_see_player := _can_see(_player_instance.global_position)
	var distance := 0.0

	if can_see_player:
		distance = global_position.distance_to(_player_instance.global_position)

		if distance < near_vision_range:
			return {
				"noticed": false,
				"clear_sight": true
			}
		elif distance < max_vision_range:
			return {
				"noticed": true,
				"clear_sight": false
			}

	return {
		"noticed": false,
		"clear_sight": false
	}


func _think(sense_result) -> void:
	match _current_state:
		States.PATROL:
			if sense_result["noticed"]:
				_enter(States.INVESTIGATE)
			elif sense_result["clear_sight"]:
				_enter(States.CAUGHT)
		States.INVESTIGATE:
			if sense_result["clear_sight"]:
				_enter(States.CAUGHT)
			#elif patrol_timer <= 0.0:
				#_enter(States.PATROL)
		States.CAUGHT:
			return


func _enter(new_state: States) -> void:
	print(States.keys()[_current_state], " -> ", States.keys()[new_state])
	_current_state = new_state


func _can_see(target_pos: Vector3) -> bool:
	var direction_to_target := target_pos - _eyes.global_position
	var normalized_dir := Vector3(direction_to_target.x, 0.0, direction_to_target.z).normalized()
	var distance_to_target := direction_to_target.length()
	var dot_product := _eyes.global_basis.z.dot(normalized_dir)

	if distance_to_target <= max_vision_range and dot_product > _detection_min_dot_value:
		# we only do it if these two are true because the check is expensive
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(
			_eyes.global_position,
			target_pos,
			vision_obstacle_layer
		)

		var result: Dictionary = space_state.intersect_ray(query)

		if result.is_empty():
			return true
		else:
			return false

	return false
