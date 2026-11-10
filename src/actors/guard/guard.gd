extends CharacterBody3D

enum States {
	PATROL,
	INVESTIGATE,
	SURVEY,
	CAUGHT
}

@export_category("Vision")
@export_range(60.0, 120.0) var fov_degrees := 90.0
@export_range(0.0, 20.0) var max_vision_range := 10.0
@export_range(0.0, 20.0) var near_vision_range := 4.0
@export_flags_3d_physics var vision_obstacle_layer

@export_category("Navigation & Movement")
@export var max_movement_speed := 3.0
@export var acceleration := 13
@export var torque := 4.5
@export_node_path("Marker3D") var patrolling_points: Array[NodePath]

var _player_instance: Player
var _detection_min_dot_value := 0.0 # set in _ready once
var _current_state: States = States.PATROL
var _target_patrolling_point_index: int = 0

@onready var _eyes: Marker3D = %Eyes
@onready var _navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D
@onready var _body: MeshInstance3D = %Body
@onready var _survey_timer: Timer = %SurveyTimer


func _ready() -> void:
	_navigation_agent_3d.navigation_finished.connect(func() -> void:
		_enter(States.SURVEY)
	)

	_survey_timer.timeout.connect(func() -> void:
		if _current_state == States.SURVEY:
			_enter(States.PATROL)
	)

	var target_position := (get_node(patrolling_points.front()) as Marker3D).global_position
	global_position = Vector3(target_position.x, global_position.y, target_position.z)
	_detection_min_dot_value = cos(deg_to_rad(fov_degrees * 0.5))
	_player_instance = get_tree().get_first_node_in_group("Player")


func _physics_process(delta: float) -> void:
	var sense_result := _sense()
	_think(sense_result)
	_act()


func _act() -> void:
	match _current_state:
		States.PATROL:
			if _navigation_agent_3d.is_navigation_finished():
				_choose_next_position()
				return

			var direction := global_position\
				.direction_to(_navigation_agent_3d.get_next_path_position())
			var body_rotation = _body.global_rotation.y
			var target_rotation = atan2(direction.x, direction.z)
			var desired_velocity = direction * max_movement_speed
			velocity = velocity.move_toward(
				desired_velocity,
				acceleration * get_physics_process_delta_time()
			)
			_body.global_rotation.y = rotate_toward(body_rotation, target_rotation, torque * get_process_delta_time())
			move_and_slide()
		States.SURVEY:
			return


func _choose_next_position() -> void:
	var current_target_pos :=\
		(get_node(patrolling_points[_target_patrolling_point_index]) as Marker3D).global_position
	if global_position.distance_to(current_target_pos) < 1.0:
		_target_patrolling_point_index += 1

		if _target_patrolling_point_index >= patrolling_points.size():
			_target_patrolling_point_index = 0

		_navigation_agent_3d.target_position =\
			(get_node(patrolling_points[_target_patrolling_point_index]) as Marker3D).global_position


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
			get_tree().reload_current_scene()
			return


func _enter(new_state: States) -> void:
	if _current_state == States.SURVEY and new_state != States.PATROL:
		_survey_timer.stop()

	if new_state == States.SURVEY:
		if _survey_timer.time_left == 0:
				_survey_timer.start()

		var tween := create_tween().set_parallel(false)
		tween.tween_property(_body, "global_rotation:y", deg_to_rad(rad_to_deg(_body.global_rotation.y) + 40), _survey_timer.wait_time / 2.0)
		tween.tween_property(_body, "global_rotation:y", deg_to_rad(rad_to_deg(_body.global_rotation.y) - 40), _survey_timer.wait_time / 2.0)
		tween.play()

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
