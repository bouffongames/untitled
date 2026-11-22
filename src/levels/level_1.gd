extends Node3D

@export var player: Player
@export var guard: Guard
@export var door: Door
@export var door_gate: DoorGate
@export var key: Interactable


func _ready() -> void:
	# reset to default state
	key.visible = false
	guard.sleep = true
	player.hud.visible = false

	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	door.interacted.connect(_on_door_interacted)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)

	if not Global.game.intro_completed:
		Dialogue.play_from_string("""
			Guard 1: Ha ha.
			Guard 1: You're not so tough without all your spells.
			Guard 1: Ha ha.
			Guard 2: Stop antagonizing the prisoner.
		""")
		await Dialogue.dialogue_ended
		
		await get_tree().create_timer(0.333).timeout  # small pause in between different dialogues

		Dialogue.play_from_string("""
			Cat: I should use my mind reading spell on the guard to find the missing key.
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


func _on_door_interacted() -> void:
	Global.scene.change(Const.SCENE_LEVEL_02)


func _reset_level() -> void:
	Global.scene.change(Const.SCENE_LEVEL_01)
