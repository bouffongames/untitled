extends Node3D


@export var door: Door

func _ready() -> void:
	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	door.interacted.connect(_on_door_interacted)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)


func _on_door_interacted() -> void:
	Global.scene.change(Const.SCENE_LEVEL_02)
