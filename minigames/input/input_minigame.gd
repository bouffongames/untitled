class_name InputMinigame
extends Minigame

const NEUTRAL_COLOR: Color = Color(0.741, 0.741, 0.741)
const SUCCESS_COLOR: Color = Color(0.941, 0.933, 0.443)
const FAILURE_COLOR: Color = Color(0.941, 0.443, 0.443, 1.0)

@export var duration: float = 5.0
@export var bonus_duration: float = 1.0
@export var stage_sequence_length: Array[int] = [
	4, 4, 6
]

@export_group("Visual")
@export var _parent_container: Container
@export var _container: Container
@export var _progress_bar: ProgressBar

@export_group("Input")
@export var _template_texture: TextureRect
@export var _icons: Dictionary[Key, Texture2D]

var _current_stage: int
var _seq_idx: int = 0
var _sequence: Array[SequenceEntry]

var _progress_value: float
var _progress_speed: float


func _ready() -> void:
	_template_texture.visible = false
	if visible:
		reset()


func _process(delta: float) -> void:
	if not visible or _is_minigame_finished():
		return

	_progress_value = clampf(_progress_value - (_progress_speed * delta), 0, duration)
	_progress_bar.value = _progress_value

	if _is_minigame_finished():
		_animate_hide()
		failed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible and _is_minigame_finished() or _seq_idx >= _sequence.size():
		return

	var event_key: InputEventKey = event as InputEventKey
	if not is_instance_valid(event_key):
		return
	if not event_key.pressed or event_key.echo:
		return
	if _icons.keys().has(event_key.keycode):
		if _sequence[_seq_idx].value == event_key.keycode:
			var texture: TextureRect = _sequence[_seq_idx].input
			texture.modulate = SUCCESS_COLOR
			_seq_idx += 1
			if _seq_idx >= _sequence.size():
				_complete_stage()
		else:
			# reset
			_seq_idx = 0
			_animate_failure()


func reset() -> void:
	_current_stage = 0
	_progress_bar.max_value = duration
	_progress_value = duration
	_progress_bar.value = duration
	_progress_speed = _progress_bar.max_value / duration

	_rand()
	_animate_show()


func _complete_stage() -> void:
	_current_stage += 1
	_progress_value = _progress_value + bonus_duration
	await get_tree().create_timer(0.333).timeout
	if _is_minigame_finished():
		_animate_hide()
		succeed.emit()
		return
	_rand()


func _is_minigame_finished() -> bool:
	return _progress_bar.value <= 0.0 or _current_stage >= stage_sequence_length.size()


func _rand() -> void:
	_seq_idx = 0
	for seq: SequenceEntry in _sequence:
		seq.input.queue_free()
	_sequence.clear()

	var sequence: Array[Key] = _create_new_sequence()
	for key: Key in sequence:
		var texture: TextureRect = _template_texture.duplicate()
		var entry: SequenceEntry = SequenceEntry.new(texture, key)
		_sequence.append(entry)
		texture.modulate = NEUTRAL_COLOR
		texture.texture = _icons[key]
		texture.visible = true
		_container.add_child(texture)


func _create_new_sequence() -> Array[Key]:
	var sequence: Array[Key] = []
	var num_keys: float = stage_sequence_length[_current_stage]
	for i: int in range(num_keys):
		var new_key: Key = _icons.keys().pick_random()
		if i >= 1:
			if i % 2:
				if randi() % 2:
					new_key = _get_opposite_key(sequence[i - 1])
				else:
					new_key = sequence[i - 1]
		sequence.append(new_key)
	return sequence


#region animations
func _animate_show() -> void:
	var tween: Tween = create_tween()
	visible = true
	_parent_container.modulate = Color(Color.WHITE, 0)
	tween.tween_property(
			_parent_container,
			"modulate",
			Color.WHITE,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_hide() -> void:
	var tween: Tween = create_tween()
	visible = true
	_parent_container.modulate = Color.WHITE
	tween.tween_property(
			_parent_container,
			"modulate",
			Color(Color.WHITE, 0),
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_failure() -> void:
	# for texture: TextureRect in _textures:
	for seq: SequenceEntry in _sequence:
		var texture: TextureRect = seq.input
		var tween: Tween = create_tween()
		texture.modulate = FAILURE_COLOR
		tween.tween_property(
				texture,
				"modulate",
				Color(FAILURE_COLOR, 0.75),
				0.1
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(
				texture,
				"modulate",
				NEUTRAL_COLOR,
				0.1
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#endregion


func _get_opposite_key(key: Key) -> Key:
	match key:
		KEY_UP:
			return KEY_DOWN
		KEY_DOWN:
			return KEY_UP
		KEY_LEFT:
			return KEY_RIGHT
		KEY_RIGHT:
			return KEY_LEFT
		_:
			return KEY_NONE


class SequenceEntry:
	var input: TextureRect
	var value: Key

	func _init(p_input: TextureRect, p_value: Key) -> void:
		input = p_input
		value = p_value
