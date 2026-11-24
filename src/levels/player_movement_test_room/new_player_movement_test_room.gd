extends Node3D


func _ready() -> void:
	for guard: Guard in get_tree().get_nodes_in_group("Guard"):
		guard.player_caught.connect(_reset_level)


func _reset_level() -> void:
	get_tree().reload_current_scene()
