extends Control

const EYE_ALERT = preload("uid://bxvxp4vqm6bdw")
const EYE_CAUGHT = preload("uid://b65p4gsyotilm")
const EYE_NORMAL = preload("uid://d3c6tttyvd6p")

enum EnemyVisionState {
	UNDETECTED,
	GUARDS_ARE_ALERTED,
	CAUGHT_BY_GUARD
}

var _player: Player
var _state: EnemyVisionState = EnemyVisionState.UNDETECTED

@onready var _eye_indicator: TextureRect = %EyeIndicator


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	_set_state(EnemyVisionState.UNDETECTED)


func _process(_delta: float) -> void:
	_eye_indicator.visible = not _player.is_casting() and not _player.is_merged()
	var state: EnemyVisionState = _get_vision_state()
	if state != _state:
		_set_state(state)


func _get_vision_state() -> EnemyVisionState:
	var alerted: bool = false
	for guard: Guard in get_tree().get_nodes_in_group("Guard"):
		if guard.has_caught_player():
			return EnemyVisionState.CAUGHT_BY_GUARD
		alerted = alerted or guard.is_alerted()
	return EnemyVisionState.GUARDS_ARE_ALERTED if alerted else EnemyVisionState.UNDETECTED


func _set_state(state: EnemyVisionState) -> void:
	_state = state
	match state:
		EnemyVisionState.UNDETECTED:
			_eye_indicator.texture = EYE_NORMAL
		EnemyVisionState.GUARDS_ARE_ALERTED:
			_eye_indicator.texture = EYE_ALERT
		EnemyVisionState.CAUGHT_BY_GUARD:
			_eye_indicator.texture = EYE_CAUGHT
