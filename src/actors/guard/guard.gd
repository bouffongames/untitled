extends CharacterBody3D

enum States {
	PATROL,
	INVESTIGATE,
	CAUGHT
}

@export_range(60.0, 120.0) var fov_degrees := 90.0
@export_range(0.0, 20.0) var max_vision_range := 10.0
@export_range(0.0, 20.0) var near_vision_range := 4.0

var _player_instance: Player
var _detection_min_dot_value := 0.0 # set in _ready once
var _current_state: States = States.PATROL


func _ready() -> void:
	_detection_min_dot_value = cos(deg_to_rad(fov_degrees * 0.5))
	_player_instance = get_tree().get_first_node_in_group("Player")


func _physics_process(delta: float) -> void:
	var sense_result := _sense()
	_think(sense_result)


func _sense() -> Dictionary:
	var fake_key = "L"
	match fake_key:
		"N":
			return {
				"noticed": true,
				"clear_sight": false
			}
		"C":
			return {
				"noticed": false,
				"clear_sight": true
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
