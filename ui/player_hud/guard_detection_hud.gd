extends Control

const EYE_NORMAL = preload("uid://c2bkitm3lytvg")
const EYE_ALERT = preload("uid://twbj12vvq6ba")
const EYE_CAUGHT = preload("uid://twbj12vvq6ba")


enum EnemyVisionState {
	UNDETECTED,
	GUARDS_ARE_ALERTED,
	CAUGHT_BY_GUARD
}

@export_group("Alert Shake")
## How far the eye moves sideways while shaking, in pixels.
@export var _shake_strength: float = 10.0
@export var _shake_duration: float = 0.45
## How many times the eye moves back and forth while shaking.
@export var _shake_count: int = 6

@export_group("Calm Pop")
## Size the eye grows to before shrinking back. 1.3 means 30% bigger.
@export var _pop_grow_scale: float = 1.3
## Size the eye shrinks to before settling at its normal size.
@export var _pop_shrink_scale: float = 0.85
@export var _pop_duration: float = 0.4

var _player: Player
var _state: EnemyVisionState = EnemyVisionState.UNDETECTED
var _tween: Tween
var _shaking: bool = false
var _shake_origin: Vector2

@onready var _eye_indicator: TextureRect = %EyeIndicator


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	_eye_indicator.pivot_offset_ratio = Vector2(0.5, 0.5)
	_set_state(EnemyVisionState.UNDETECTED)


func _process(_delta: float) -> void:
	_eye_indicator.visible = not _player.is_casting() and not _player.is_merged()
	var state: EnemyVisionState = _get_vision_state()
	if state != _state:
		var previous: EnemyVisionState = _state
		_set_state(state)
		_animate_transition(previous, state)


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


func _animate_transition(previous: EnemyVisionState, state: EnemyVisionState) -> void:
	if state == EnemyVisionState.GUARDS_ARE_ALERTED and previous == EnemyVisionState.UNDETECTED:
		_shake()
	elif state == EnemyVisionState.UNDETECTED:
		_pop()


func _shake() -> void:
	_stop_animation()
	_shaking = true
	_shake_origin = _eye_indicator.position
	_tween = create_tween()
	_tween.tween_method(_apply_shake, 0.0, 1.0, _shake_duration)
	_tween.tween_callback(_stop_animation)


func _apply_shake(progress: float) -> void:
	var offset: float = sin(progress * TAU * _shake_count) * _shake_strength * (1.0 - progress)
	_eye_indicator.position = _shake_origin + Vector2(offset, 0.0)


func _pop() -> void:
	_stop_animation()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_eye_indicator, "scale", Vector2.ONE * _pop_grow_scale, _pop_duration * 0.4)
	_tween.tween_property(_eye_indicator, "scale", Vector2.ONE * _pop_shrink_scale, _pop_duration * 0.3)
	_tween.tween_property(_eye_indicator, "scale", Vector2.ONE, _pop_duration * 0.3)


func _stop_animation() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _shaking:
		_eye_indicator.position = _shake_origin
		_shaking = false
	_eye_indicator.scale = Vector2.ONE
