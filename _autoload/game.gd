class_name Game
extends Node

enum GameState { NONE, PLAYING, PAUSED }

var _state: GameState = GameState.NONE


func set_state(state: GameState) -> void:
	_state = state


func get_state() -> GameState:
	return _state
