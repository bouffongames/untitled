extends Node3D

@export var player: Player
@export var journal: Journal
@export var door: Door
@export var pressure_tile: PressureTile
@export var trap: TrapFloor

@export var checkpoint_player_marker: Marker3D


func _ready() -> void:
	player.hud.enable_spells("mind control")  # exclude mind control spell in case we loaded a checkpoint
	
	for g: Guard in get_tree().get_nodes_in_group("Guard"):
		g.player = player
		g.player_caught.connect(_reset_level)  # reset the level if the player is caught

	if Global.game.mind_control_spell_learned:
		player.global_position = checkpoint_player_marker.global_position
		player.global_rotation = checkpoint_player_marker.global_rotation

	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		Global.scene._scene_path = Const.SCENE_LEVEL_03
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	Global.scene.restarting.connect(_on_scene_restarting)
	journal.interacted.connect(_on_journal_interacted)
	door.interacted.connect(_on_door_interacted)
	pressure_tile.state_changed.connect(_on_pressure_tile_state_changed)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)


func _on_scene_restarting() -> void:
	if Global.scene.restarting.is_connected(_on_scene_restarting):
		Global.scene.restarting.disconnect(_on_scene_restarting)

	# reset level state if the player has requested to restart the level
	Global.game.mind_control_spell_learned = false


func _on_journal_interacted() -> void:
	Global.game.mind_control_spell_learned = true

	journal.hide()
	Dialogue.play_from_string("""
	You have learned the Mind Control spell!
	You can now control a guard's movement.
	Press 'Q' to control a guard!
	""")


func _on_door_interacted() -> void:
	# TODO end level or new level?
	AudioManager.play_sfx("wood door next level")
	Global.scene.change(Const.SCENE_MAIN)


func _on_pressure_tile_state_changed(pressed: bool) -> void:
	if pressed:
		trap.disable()  # the trap is permanently disabled


func _reset_level() -> void:
	Global.scene.change(Const.SCENE_LEVEL_03)
