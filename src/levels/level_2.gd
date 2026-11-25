extends Node3D

@export var player: Player
@export var guards: Array[Guard]
@export var markers: Array[Marker3D]
@export var journal: Journal
@export var door: Door

@export var checkpoint_player_marker: Marker3D
# areas where if the player enters the area it will reset level. only one
# area will only be monitoring and it depends on the state of the level.
@export var guard_area: Area3D
@export var guard_area_2: Area3D


func _ready() -> void:
	player.hud.enable_spells("merge")  # exclude merge spell in case we loaded a checkpoint
	
	# if player gets to close to boundaries reset level
	guard_area.monitoring = true
	guard_area.area_entered.connect(
		func(_area: Area3D) -> void:
			await _alert_guards()
			_reset_level()
	)
	guard_area_2.monitoring = false
	guard_area_2.area_entered.connect(
		func(_area: Area3D) -> void:
			await _alert_guards()
			_reset_level()
	)

	for g: Guard in get_tree().get_nodes_in_group("Guard"):
		g.player_caught.connect(_reset_level)  # reset the level if the player is caught

	if Global.game.merge_spell_learned:
		player.global_position = checkpoint_player_marker.global_position
		player.global_rotation = checkpoint_player_marker.global_rotation

	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
		Global.scene._scene_path = Const.SCENE_LEVEL_02
		_on_scene_changed()

	Global.scene.changed.connect(_on_scene_changed)
	journal.interacted.connect(_on_journal_interacted)
	door.interacted.connect(_on_door_interacted)


func _on_scene_changed() -> void:
	if Global.scene.changed.is_connected(_on_scene_changed):
		Global.scene.changed.disconnect(_on_scene_changed)

	if not Global.game.merge_spell_learned:
		Dialogue.play_from_string("""
		Witch: I need to escape from this dungeon and find my journals!
		""")


func _on_journal_interacted() -> void:
	Global.game.merge_spell_learned = true

	journal.hide()
	Dialogue.play_from_string("""
	You have learned the Merge spell!
	You can now quickly evade guards by merging with the floor.
	Press 'R' to quickly hide and evade chasing guards!
	""")

	await Dialogue.dialogue_ended

	# reset the player if they get to closer to the guards
	guard_area.monitoring = false
	guard_area_2.monitoring = true

	# face alerted guards totruewards the player
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel()
	for guard: Guard in guards:
		tween.tween_property(
				guard,
				"global_rotation_degrees",
				guard.global_rotation_degrees + Vector3(0.0, 180, 0),
				0.233
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(
			func() -> void:
				guard._alert_icon.visible = true
		)
	tween.tween_callback(
		func() -> void:
			guards[0]._alert_sound.play()
			await guards[0]._alert_sound.finished
	)

	# play alerted guard dialogue
	Dialogue.play_from_string("""
	Guard: Stop, you've violated the law!
	""")
	await Dialogue.dialogue_ended

	# hide alert once the dialogue is completed
	for guard: Guard in guards:
		guard._alert_icon.visible = false
		guard.player = player

	# move guards one by one to avoid getting stuck on eachother
	tween = get_tree().create_tween()
	for i: int in [1,2,0,3]:  # order of guards to move in to avoid getting stuck
		tween.tween_callback(
			func() -> void:
			guards[i]._current_state = Guard.States.INVESTIGATE
			guards[i]._navigation_agent_3d.target_position = player.global_position
			guards[i].sleep = false
			await get_tree().create_timer(0.3).timeout
		)

	# stop the player from moving to force them to cast the spell
	player.disabled = true
	await player.merge_started
	player.disabled = false

	# if the player has completed the spell before the guards have finished moving kill the tween
	if tween.is_running():
		tween.kill()

	for i: int in range(guards.size()):  # order of guards to move in
		guards[i]._current_state = Guard.States.SLEEP_MOVE
		guards[i]._navigation_agent_3d.target_position = markers[i].global_position
		guards[i].sleep = false


func _on_door_interacted() -> void:
	Global.scene.change(Const.SCENE_LEVEL_03)


func _alert_guards() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel()
	for guard: Guard in guards:
		tween.tween_callback(
			func() -> void:
				guard._alert_icon.visible = true
		)
	tween.tween_callback(
		func() -> void:
			guards[0]._alert_sound.play()
			await guards[0]._alert_sound.finished
	)
	await get_tree().create_timer(0.5).timeout


func _reset_level() -> void:
	Global.scene.change(Const.SCENE_LEVEL_02)
