@abstract
class_name Character
extends Node3D

signal movement_started(target_position: Vector3)
signal movement_finished

@export var movement_speed: float = 2.0
@export var rotation_speed: float = 8.0
@export var stopping_distance: float = 0.25
@export var interact_distance: float = 10.0

@export var _character_skin: CharacterSkin
@export var _navigation_agent: NavigationAgent3D
@export var _collision_object: CollisionObject3D

var disabled: bool:
	set(value):
		if disabled != value:
			disabled = value
			_finish_movement()

var _is_moving: bool
var _is_interact_active: bool
var _interactable: Interactable


func _ready() -> void:
	_character_skin.idle()


func _physics_process(delta: float) -> void:
	if disabled:
		return

	if _is_moving:
		var distance_to_target: float = global_position.distance_to(_navigation_agent.target_position)
		if distance_to_target <= stopping_distance or _navigation_agent.is_navigation_finished():
			if _is_moving:
				_finish_movement()

	_update_movement(delta)


func get_rid() -> RID:
	return _collision_object.get_rid()


func set_interact_target(target_position: Vector3, target_interactable: Interactable) -> void:
	_is_moving = true
	_is_interact_active = true
	_interactable = target_interactable
	_navigation_agent.target_position = target_position
	_character_skin.move()
	movement_started.emit(target_position)


func set_target_position(target_position: Vector3) -> void:
	_is_moving = true
	_is_interact_active = false
	_interactable = null
	_navigation_agent.target_position = target_position
	_character_skin.move()
	movement_started.emit(target_position)


func stop_movement() -> void:
	_is_interact_active = false
	_interactable = null
	_navigation_agent.target_position = global_position
	if _is_moving:
		_is_moving = false
		_character_skin.idle()
		movement_finished.emit()


func _finish_movement() -> void:
	if not _is_moving:
		return

	_handle_interact()

	_is_moving = false
	_character_skin.idle()
	movement_finished.emit()



func _handle_interact() -> void:
	if is_instance_valid(_interactable):
		var distance_to_target: float = global_position.distance_to(_interactable.global_position)
		if _is_interact_active and distance_to_target <= interact_distance:
			_interactable.interact()
			_interactable = null
	_is_interact_active = false


func _update_movement(delta: float) -> void:
	var next_position: Vector3 = _navigation_agent.get_next_path_position()

	var offset_to_next_position: Vector3 = next_position - global_position
	var distance_to_next_position: float = offset_to_next_position.length()

	if distance_to_next_position <= 0.001:
		return

	var direction: Vector3 = offset_to_next_position / distance_to_next_position
	var step: float = movement_speed * delta

	if step > distance_to_next_position:
		step = distance_to_next_position

	global_position += direction * step

	if direction.length() > 0.01:
		_face_direction(direction)


func _face_direction(direction: Vector3) -> void:
	direction.y = 0.0

	if direction.length() <= 0.01:
		return

	direction = direction.normalized()

	var target_yaw: float = atan2(direction.x, direction.z)
	var weight: float = 1.0 - exp(-rotation_speed * get_physics_process_delta_time())

	rotation.y = lerp_angle(rotation.y, target_yaw, weight)
