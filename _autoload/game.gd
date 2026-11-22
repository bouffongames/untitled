class_name Game
extends Node

enum GameState { NONE, PLAYING, PAUSED }

signal state_changed

var _state: GameState = GameState.NONE

# state
var intro_completed: bool = false


func _ready() -> void:
	state_changed.connect(
		func() -> void: 
			# when returning to main menu, reset state.
			if _state == GameState.NONE:
				_reset_state()
	)


func set_state(state: GameState) -> void:
	if state != _state:
		_state = state
		state_changed.emit()


func get_state() -> GameState:
	return _state


func _reset_state() -> void:
	intro_completed = false
	Dialogue.forcibly_end_dialogue()
