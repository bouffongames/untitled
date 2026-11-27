class_name Guard
extends CharacterBody3D

enum States {
	PATROL,
	INVESTIGATE,
	SURVEY,
	CAUGHT,
	SPELLBOUND,
	STUNNED,
	MIND_CONTROLLED,
	FIGHTING,
	SLEEP_MOVE,
}

signal mind_control_ended
signal player_caught

var _last_step_index: int = 0

@onready var guard_steps: AudioStreamPlayer3D = $GuardSteps

@export var sleep: bool
@export var player: Player

@export_group("Bob Visual")
@export var visual_pivot: Node3D
@export var bob_frequency: float = 8.0
@export var bob_height: float = 0.08
@export var bob_weight: float = 8.0
@export var lean_amount: float = 0.08
@export var lean_weight: float = 10.0

@export_category("Vision")
@export_range(60.0, 120.0) var fov_degrees := 90.0
@export_range(0.0, 20.0) var max_vision_range := 10.0
@export_range(0.0, 20.0) var near_vision_range := 4.0
@export_range(0.5, 3.0) var alert_pause_time := 1.5
@export_flags_3d_physics var vision_obstacle_layer

@export_category("Read Mind")
## Thoughts the player reads with the Read Mind spell, one per cast, in order. Wraps back to the first after the last.
@export var thoughts: Array[Thought] = []

@export_category("Navigation & Movement")
@export var max_movement_speed := 3.0
@export var acceleration := 13
@export var torque := 4.5
@export_node_path("Marker3D") var patrolling_points: Array[NodePath]

var _detection_min_dot_value := 0.0 # set in _ready once
var _current_state: States = States.PATROL
var _target_patrolling_point_index: int = 0
var _survey_tween: Tween
var _spell_cast_position: Vector3
var confusion_particle_scene: PackedScene = preload("uid://doae8cmaql5b0")
var _confusion_sparkles: CPUParticles3D
var anger_particle_scene: PackedScene = preload("res://vfx/anger_particles/anger_particles.tscn")
var _anger_particles: CPUParticles3D
var _stun_duration := 0.0
var _alert_after_stun := true
var _mind_control_spell: MindControlSpell
var _next_thought_index := 0
var _anger_spell: AngerSpell
var _fight_focus_point: Vector3
var _vision_range_scale := 1.0

# bob visual
var bob_time: float = 0.0
var initial_visual_pivot_position: Vector3
var initial_visual_pivot_rotation: Vector3

@onready var _eyes: Marker3D = %Eyes
@onready var _navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D
@onready var _body: MeshInstance3D = %Body
@onready var _survey_timer: Timer = %SurveyTimer
@onready var _stun_timer: Timer = %StunTimer
@onready var _mind_control_timer: Timer = %MindControlTimer
@onready var _fight_timer: Timer = %FightTimer
@onready var _alert_icon: Sprite3D = %AlertIcon
@onready var _alert_sound: AudioStreamPlayer = %AlertSound


func _ready() -> void:
	# it's always zero but if it changes it should continue to work as expected
	initial_visual_pivot_position = visual_pivot.position
	initial_visual_pivot_rotation = visual_pivot.rotation

	_alert_icon.visible = false
	_navigation_agent_3d.navigation_finished.connect(func() -> void:
		if _current_state != States.MIND_CONTROLLED:
			_enter(States.SURVEY)
	)

	_survey_timer.timeout.connect(func() -> void:
		if _current_state == States.SURVEY:
			_enter(States.PATROL)
	)

	_stun_timer.timeout.connect(func() -> void:
		if _current_state == States.STUNNED:
			_enter(States.INVESTIGATE if _alert_after_stun else States.PATROL)
	)

	_mind_control_timer.timeout.connect(end_mind_control)

	_fight_timer.timeout.connect(func() -> void:
		if _current_state == States.FIGHTING:
			_enter(States.PATROL)
	)

	if not sleep:
		var target_position := (get_node(patrolling_points.front()) as Marker3D).global_position
		global_position = Vector3(target_position.x, global_position.y, target_position.z)
		_detection_min_dot_value = cos(deg_to_rad(fov_degrees * 0.5))


func _physics_process(delta: float) -> void:
	if sleep:
		return

	var sense_result := _sense()
	_think(sense_result)
	_act()


func _act() -> void:
	match _current_state:
		States.SLEEP_MOVE:
			if _navigation_agent_3d.is_navigation_finished():
				sleep = true
				return

			_move_along_path()
		States.PATROL:
			if _navigation_agent_3d.is_navigation_finished():
				_choose_next_position()
				return

			_move_along_path()
		States.SURVEY:
			# survey rotation happens in tween, need to update bob while surveying.
			_update_visual_bob(true)
			return
		States.INVESTIGATE:
			if _navigation_agent_3d.is_navigation_finished():
				_enter(States.SURVEY)
				return

			_move_along_path()
		States.MIND_CONTROLLED:
			_move_mind_controlled()
		States.FIGHTING:
			_face_fight_focus_point()
			_update_visual_bob(true)


func _move_along_path() -> void:
	var direction := global_position\
		.direction_to(_navigation_agent_3d.get_next_path_position())
	var body_rotation = global_rotation.y
	var target_rotation = atan2(direction.x, direction.z)
	var desired_velocity = direction * max_movement_speed
	velocity = velocity.move_toward(
		desired_velocity,
		acceleration * get_physics_process_delta_time()
	)
	global_rotation.y = rotate_toward(body_rotation, target_rotation, torque * get_process_delta_time())
	move_and_slide()

	var moving: bool = velocity.length_squared() > 0.01
	_update_visual_bob(moving)


func _face_fight_focus_point() -> void:
	var offset := _fight_focus_point - global_position
	if Vector2(offset.x, offset.z).length() <= 0.01:
		return
	var target_rotation := atan2(offset.x, offset.z)
	global_rotation.y = rotate_toward(global_rotation.y, target_rotation, torque * get_physics_process_delta_time())


func _move_mind_controlled() -> void:
	var offset_to_target := _navigation_agent_3d.target_position - global_position
	offset_to_target.y = 0.0
	var offset_to_next := _navigation_agent_3d.get_next_path_position() - global_position
	var flat_direction := Vector3(offset_to_next.x, 0.0, offset_to_next.z)
	if offset_to_target.length() <= player.stopping_distance or flat_direction.length() <= 0.01:
		velocity = Vector3.ZERO
		return

	velocity = offset_to_next.normalized() * max_movement_speed * _mind_control_spell.speed_multiplier
	var weight := 1.0 - exp(-player.rotation_speed * get_physics_process_delta_time())
	global_rotation.y = lerp_angle(global_rotation.y, atan2(flat_direction.x, flat_direction.z), weight)
	move_and_slide()

	var moving: bool = velocity.length_squared() > 0.01
	_update_visual_bob(moving)


func _update_visual_bob(active: bool) -> void:
	var delta: float = get_physics_process_delta_time()
	if not is_instance_valid(visual_pivot):
		return

	var target_y: float = initial_visual_pivot_position.y
	var target_lean: float = 0.0

	if active:
		bob_time += delta * bob_frequency
		target_y += absf(sin(bob_time)) * bob_height
		target_lean = sin(bob_time) * lean_amount
		
		var step_index: int = int(bob_time / PI)
		if step_index != _last_step_index:
			_last_step_index = step_index
			guard_steps.play()
		
	else:
		bob_time = 0.0

	visual_pivot.position.y = lerpf(
			visual_pivot.position.y,
			target_y,
			bob_weight * delta
	)
	visual_pivot.rotation.z = lerpf(
			visual_pivot.rotation.z,
			initial_visual_pivot_rotation.z + target_lean,
			lean_weight * delta
	)


func _choose_next_position() -> void:
	var current_target_pos :=\
		(get_node(patrolling_points[_target_patrolling_point_index]) as Marker3D).global_position
	if global_position.distance_to(current_target_pos) <= _navigation_agent_3d.target_desired_distance + 0.05:
		_target_patrolling_point_index += 1

		if _target_patrolling_point_index >= patrolling_points.size():
			_target_patrolling_point_index = 0

		_navigation_agent_3d.target_position =\
			(get_node(patrolling_points[_target_patrolling_point_index]) as Marker3D).global_position


func _sense() -> Dictionary:
	if not is_instance_valid(player):
		return {
			"noticed": false,
			"clear_sight": false
		}

	var can_see_player := not player.is_merged() and _can_see(player.global_position)
	var distance := 0.0

	if can_see_player:
		distance = global_position.distance_to(player.global_position)

		if distance < near_vision_range * _vision_range_scale:
			return {
				"noticed": false,
				"clear_sight": true
			}
		elif distance < max_vision_range * _vision_range_scale:
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
		States.PATROL, States.FIGHTING:
			if sense_result["clear_sight"]:
				_enter(States.CAUGHT)
			elif sense_result["noticed"]:
				_enter(States.INVESTIGATE)
		States.INVESTIGATE:
			if sense_result["clear_sight"]:
				_enter(States.CAUGHT)
			elif sense_result["noticed"]:
				# keep adjusting the target position until the guard no longer sees the player
				_navigation_agent_3d.target_position = player.global_position
			
		States.CAUGHT:
			player_caught.emit()
			sleep = true
			#get_tree().reload_current_scene()
			return
		States.SURVEY:
			if sense_result["noticed"]:
				_survey_tween.kill()
				_enter(States.INVESTIGATE)


func _enter(new_state: States) -> void:
	if sleep:
		return

	if new_state != States.SURVEY:
		_survey_timer.stop()
		_update_visual_bob(false)  # reset bob

	if new_state != States.MIND_CONTROLLED:
		_mind_control_timer.stop()

	if new_state != States.FIGHTING:
		_fight_timer.stop()
		_update_visual_bob(false)  # reset bob
		_vision_range_scale = 1.0

	if new_state == States.STUNNED:
		_confusion_sparkles = confusion_particle_scene.instantiate() as CPUParticles3D
		add_child(_confusion_sparkles)
		_confusion_sparkles.position.y = 2.15
	elif _current_state == States.STUNNED:
		_confusion_sparkles.queue_free()
		_confusion_sparkles = null

	if new_state == States.FIGHTING and _anger_particles == null:
		_anger_particles = anger_particle_scene.instantiate() as CPUParticles3D
		add_child(_anger_particles)
		_anger_particles.position.y = 2.15
	elif new_state != States.FIGHTING and _anger_particles != null:
		_anger_particles.queue_free()
		_anger_particles = null

	if new_state == States.SURVEY:
		if _survey_timer.time_left == 0:
				_survey_timer.start()

		if _survey_tween != null:
			_survey_tween.kill()
			_survey_tween = null

		_survey_tween = create_tween().set_parallel(false)
		_survey_tween.tween_property(self, "global_rotation:y", deg_to_rad(rad_to_deg(self.global_rotation.y) + 40), _survey_timer.wait_time / 2.0)
		_survey_tween.tween_property(self, "global_rotation:y", deg_to_rad(rad_to_deg(self.global_rotation.y) - 40), _survey_timer.wait_time / 2.0)
		_survey_tween.play()
	elif new_state == States.INVESTIGATE:
		var target_position := _spell_cast_position if _current_state == States.STUNNED else player.global_position
		_current_state = new_state
		_make_alert_icon_visible()
		_navigation_agent_3d.target_position = target_position

		set_physics_process(false)
		await get_tree().create_timer(alert_pause_time).timeout
		set_physics_process(true)
		if _current_state != States.INVESTIGATE:
			return

	elif new_state == States.SPELLBOUND:
		_spell_cast_position = player.global_position
		_freeze()

	elif new_state == States.STUNNED:
		_freeze()
		_stun_timer.start(_stun_duration)

	elif new_state == States.MIND_CONTROLLED:
		_freeze()
		_navigation_agent_3d.target_position = global_position
		_mind_control_timer.start(_mind_control_spell.control_duration)

	elif new_state == States.FIGHTING:
		_freeze()
		_vision_range_scale = 1.0 - _anger_spell.vision_reduction
		_fight_timer.start(_anger_spell.fight_duration)

	elif new_state == States.PATROL:
		var target_pos := (get_node(patrolling_points[_target_patrolling_point_index]) as Marker3D).global_position
		_navigation_agent_3d.target_position = target_pos

	_current_state = new_state


func enter_spellbound() -> void:
	_enter(States.SPELLBOUND)


func exit_spellbound() -> void:
	_enter(States.PATROL)


func stun(duration: float, alert: bool) -> void:
	_stun_duration = duration
	_alert_after_stun = alert
	_enter(States.STUNNED)


func start_mind_control(spell: MindControlSpell) -> void:
	_mind_control_spell = spell
	_enter(States.MIND_CONTROLLED)


func move_mind_controlled_to(target_position: Vector3) -> void:
	if _current_state != States.MIND_CONTROLLED:
		return
	_navigation_agent_3d.target_position = target_position


func end_mind_control() -> void:
	if _current_state != States.MIND_CONTROLLED:
		return
	stun(_mind_control_spell.release_stun_duration, false)
	mind_control_ended.emit()


func start_fight(spell: AngerSpell, focus_point: Vector3) -> void:
	_anger_spell = spell
	_fight_focus_point = focus_point
	_enter(States.FIGHTING)


func is_fighting() -> bool:
	return _current_state == States.FIGHTING


func read_next_thought() -> Thought:
	if thoughts.is_empty():
		return null
	var thought: Thought = thoughts[_next_thought_index % thoughts.size()]
	_next_thought_index = (_next_thought_index + 1) % thoughts.size()
	return thought


func get_mind_control_time_left() -> float:
	return _mind_control_timer.time_left


func is_mind_controlled() -> bool:
	return _current_state == States.MIND_CONTROLLED


func _freeze() -> void:
	if _survey_tween != null:
		_survey_tween.kill()
		_survey_tween = null
	velocity = Vector3.ZERO


func _can_see(target_pos: Vector3) -> bool:
	var direction_to_target := target_pos - _eyes.global_position
	var normalized_dir := Vector3(direction_to_target.x, 0.0, direction_to_target.z).normalized()
	var distance_to_target := direction_to_target.length()
	var dot_product := _eyes.global_basis.z.dot(normalized_dir)

	if distance_to_target <= max_vision_range * _vision_range_scale and dot_product > _detection_min_dot_value:
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


func _make_alert_icon_visible() -> void:
	_alert_icon.visible = true
	_alert_sound.play()
	await get_tree().create_timer(1.5).timeout
	_alert_icon.visible = false
