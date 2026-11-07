class_name Player extends CharacterBody3D

@onready var _navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D

var target_position = null: set = set_target_position

func _physics_process(delta: float) -> void:
	if _navigation_agent_3d.is_navigation_finished():
		return

	var direction := global_position.direction_to(_navigation_agent_3d.get_next_path_position())
	velocity = direction * 2
	move_and_slide()


func set_target_position(new_value: Vector3) -> void:
	target_position = new_value
	_navigation_agent_3d.target_position = target_position
