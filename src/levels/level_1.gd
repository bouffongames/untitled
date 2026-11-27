extends Node3D

@export var player: Player
@export var guard: Guard
@export var door: Door
@export var door_gate: DoorGate
@export var key: Interactable


func _ready() -> void:
	# reset to default state
	player.hud.enable_spells()
	key.visible = false
	guard.sleep = true
	player.hud.visible = false

	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		Global.scene._scene_path = Const.SCENE_LEVEL_01
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	Global.scene.restarting.connect(_on_scene_restarting)
	door.interacted.connect(_on_door_interacted)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)

	if not Global.game.intro_completed:
		Dialogue.play_from_string("""
			Guard #1: Ha ha.
			Guard #1: You're not so tough without all your spells.
			Guard #1: Ha ha.
			Guard #2: Stop antagonizing the prisoner.
		""")
		await Dialogue.dialogue_ended
		
		await get_tree().create_timer(0.333).timeout  # small pause in between different dialogues

		Dialogue.play_from_string("""
			Press 'W' and left click on the guard to read the guard's mind to find out how to free yourself from this cell.
		""")
		await Dialogue.dialogue_ended
		player.hud.visible = true  # show spells hud

		await player.thought_read  # wait until the player has read the guard's mind

	player.hud.visible = true
	Global.game.intro_completed = true

	# move guard to patrolling position
	for g: Guard in get_tree().get_nodes_in_group("Guard"):
		g.player = player
		g.player_caught.connect(_reset_level)  # reset the level if the player is caught
	guard.sleep = false
	guard._enter(Guard.States.PATROL)

	# show key
	key.visible = true
	await key.interacted
	key.visible = false
	door_gate.open_door()  # animates the door opening and rebakes the navigation


func _on_scene_restarting() -> void:
	if Global.scene.restarting.is_connected(_on_scene_restarting):
		Global.scene.restarting.disconnect(_on_scene_restarting)

	# reset level state if the player has requested to restart the level
	Global.game.intro_completed = false


func _on_door_interacted() -> void:
	AudioManager.play_sfx("wood_door_next_level")
	Global.scene.change(Const.SCENE_LEVEL_02)


func _reset_level() -> void:
	Global.scene.change(Const.SCENE_LEVEL_01)
