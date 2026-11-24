extends Node3D

@export var journal: Journal
@export var door: Door
@export var trap: TrapFloor


func _ready() -> void:
	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		Global.scene._scene_path = Const.SCENE_LEVEL_03
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	journal.interacted.connect(_on_journal_interacted)
	door.interacted.connect(_on_door_interacted)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)


func _on_journal_interacted() -> void:
	journal.hide()
	# TODO


func _on_door_interacted() -> void:
	# TODO
	pass
