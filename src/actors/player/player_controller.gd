extends Node3D

const RAY_LENGTH: float = 1_000.0
const CLICK_POSITION_PARTICLE: PackedScene = preload("uid://7lcjf6g22ofl")

@export var player: Player
@export_flags_3d_physics var interactable_layer: int = 0b1000

var _camera: Camera3D
var _last_interactable: Interactable


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	player.mind_control_started.connect(_on_mind_control_started)
	player.mind_control_ended.connect(_on_mind_control_ended)


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _unhandled_input(event: InputEvent) -> void:
	if player.is_casting():
		return
	if player.is_merged():
		if event.is_action_pressed("exit_spell"):
			get_viewport().set_input_as_handled()
			player.end_merge()
		return
	var controlled_guard: Guard = player.get_mind_controlled_guard()
	if controlled_guard != null:
		_handle_mind_control(event, controlled_guard)
		return
	if _handle_interact(event):
		return  # priority on interact
	_handle_movement(event)


func _handle_mind_control(event: InputEvent, guard: Guard) -> void:
	if event.is_action_pressed("exit_spell"):
		get_viewport().set_input_as_handled()
		player.end_mind_control()
		return

	if not _is_left_click(event):
		return

	var result: Dictionary = _raycast_ground()
	if result.is_empty():
		return
	get_viewport().set_input_as_handled()
	@warning_ignore("unsafe_call_argument")
	_spawn_click_particle(result.position)
	@warning_ignore("unsafe_call_argument")
	guard.move_mind_controlled_to(result.position)


func _on_mind_control_started(guard: Guard, _spell: MindControlSpell) -> void:
	if is_instance_valid(_last_interactable):
		_last_interactable.hide_hover()
		_last_interactable = null
	if _camera is FollowTarget:
		(_camera as FollowTarget).target = guard


func _on_mind_control_ended(_guard: Guard) -> void:
	if _camera is FollowTarget:
		(_camera as FollowTarget).target = player


func _handle_interact(event: InputEvent) -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + _camera.project_ray_normal(mouse_pos) * RAY_LENGTH

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = interactable_layer

	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		# if no interactable was found, hide the hover
		if is_instance_valid(_last_interactable):
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			_last_interactable.hide_hover()
			_last_interactable = null
		return false

	@warning_ignore("unsafe_cast")
	var interactable: Interactable = result.collider as Interactable
	if is_instance_valid(interactable) and interactable.can_interact():
		# show the hover
		_last_interactable = interactable
		_last_interactable.show_hover()
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event == null:
			return false
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		# set the interact target for the player to move to and interact when in proximity
		@warning_ignore("unsafe_call_argument")
		player.set_interact_target(interactable.global_position, interactable)
		return true
	else:
		# if no valid interactable was found, hide the hover
		if is_instance_valid(_last_interactable):
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			_last_interactable.hide_hover()
			_last_interactable = null

	return false


func _handle_movement(event: InputEvent) -> bool:
	if not _is_left_click(event):
		return false

	var result: Dictionary = _raycast_ground()

	if result.is_empty():
		print("Didn't click the ground")
	else:
		print("Clicked the ground at ", result.position)
		@warning_ignore("unsafe_call_argument")
		_spawn_click_particle(result.position)

		if not is_instance_valid(player):
			push_error("Player not found by the player camera")
			return false

		@warning_ignore("unsafe_call_argument")
		player.set_target_position(result.position)
		return true

	return false


func _is_left_click(event: InputEvent) -> bool:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	return mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT


func _raycast_ground() -> Dictionary:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + _camera.project_ray_normal(mouse_pos) * RAY_LENGTH

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mask_bits: int = 1 << 0 # Layer 1 "Ground"
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, mask_bits)
	return space_state.intersect_ray(query)


func _spawn_click_particle(at_position: Vector3) -> void:
	var particle_instance: CPUParticles3D = CLICK_POSITION_PARTICLE.instantiate()
	get_parent().add_child(particle_instance)
	particle_instance.global_position = at_position
	particle_instance.restart()
	particle_instance.finished.connect(func() -> void:
		particle_instance.queue_free()
	)
