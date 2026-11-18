extends Node3D


func _ready() -> void:
	if Global.game.get_state() == Game.GameState.NONE:
		Global.game.set_state(Game.GameState.PLAYING)
