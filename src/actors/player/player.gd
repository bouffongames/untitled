class_name Player extends CharacterBody3D

@export var max_movement_speed := 3.0
@export var acceleration := 13
@export var torque := 4.5

@onready var _navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D
@onready var _gobot_skin: Node3D = %GobotSkin

var target_position = null: set = set_target_position

func _physics_process(delta: float) -> void:
	if _navigation_agent_3d.is_navigation_finished():
		_gobot_skin.idle()
		return

	var direction := global_position.direction_to(_navigation_agent_3d.get_next_path_position())
	var skin_rotation = _gobot_skin.rotation.y
	var target_rotation = atan2(direction.x, direction.z)
	var desired_velocity = direction * max_movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	_gobot_skin.move()
	_gobot_skin.rotation.y = rotate_toward(skin_rotation, target_rotation, torque * delta)

	move_and_slide()


func set_target_position(new_value: Vector3) -> void:
	target_position = new_value
	_navigation_agent_3d.target_position = target_position
