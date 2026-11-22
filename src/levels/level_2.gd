extends Node3D


@export var journal: Journal
@export var door: Door


func _ready() -> void:
	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	journal.interacted.connect(_on_journal_interacted)
	door.interacted.connect(_on_door_interacted)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)
	Dialogue.play_from_string("""
	Cat: I need to escape from this dungeon and find my journals!
	""")


func _on_journal_interacted() -> void:
	journal.hide()
	Dialogue.play_from_string("""
	You learned the Merge spell!
	You can now quickly evade guard's by merging with the floor.
	Press 'Q' to quickly hide and evade chasing guards!
	""")
		
	await Dialogue.dialogue_ended
	
	# TODO have the guards turn around (alerted)
	Dialogue.play_from_string("""
	Guard: Stop, you've violated the law!
	""")
	# TODO guard chases the player (move the guards one by one to avoid getting stuck in the doorway)
	# TODO the guards walk pass the player if hidden
	# TODO if the player does not press Q the level resets when the guards catch the player.


func _on_door_interacted() -> void:
	Global.scene.change(Const.SCENE_LEVEL_03)
