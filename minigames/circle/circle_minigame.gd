extends Minigame

const WHITE_COLOR: Color = Color.WHITE
const GREEN_COLOR: Color = Color(0.396, 0.816, 0.38)
const RED_COLOR: Color = Color(0.82, 0.384, 0.384)

@export var duration: float = 5.0
@export var speed: float = 1.0
@export var grace_window: float = 0.04
@export var reset_window: float = 0.18

@export var stage_scale_ranges: Array[Vector2] = [
	Vector2(1.0, 1.2),
	Vector2(0.5, 0.6),
	Vector2(0.3, 0.35),
]

@export_group("Visual")
@export var _inner_texture: TextureRect
@export var _outer_texture: TextureRect
@export var _progress_bar: TextureProgressBar

@export_group("Circle")
@export var _thickness_offset: float = 0.08
@export var _outer_start_scale_multiplier: float = 3.0
@export var _max_outer_scale: Vector2 = Vector2(2.0, 2.0)

var _init_outer_scale: Vector2 = Vector2(2.0, 2.0)

var _is_moving: bool
var _current_stage: int

var _progress_value: float
var _progress_speed: float


func _ready() -> void:
	_outer_texture.scale = _init_outer_scale
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
		return

	if not _is_moving:
		return

	_outer_texture.scale.x -= speed * delta
	_outer_texture.scale.y -= speed * delta

	if _is_past_window():
		_is_moving = false
		_animate_failure()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _is_moving or _is_minigame_finished():
		return

	if event.is_action_pressed("ui_accept"):
		_is_moving = false
		if _is_in_window():
			_current_stage += 1
			_animate_success()

			if _current_stage >= stage_scale_ranges.size():
				await get_tree().create_timer(0.233).timeout
				_animate_hide()
				succeed.emit()
		else:
			_animate_failure()


func reset() -> void:
	_is_moving = true
	_current_stage = 0
	_progress_bar.max_value = duration
	_progress_value = duration
	_progress_bar.value = duration
	_progress_speed = _progress_bar.max_value / duration

	_rand()
	_animate_show()


func _complete_stage() -> void:
	_is_moving = true
	if _is_minigame_finished():
		return
	_rand()


func _is_minigame_finished() -> bool:
	return _progress_bar.value <= 0.0 or _current_stage >= stage_scale_ranges.size()


func _rand() -> void:
	var scale_range: Vector2 = stage_scale_ranges[_current_stage]
	var random_scale: float = randf_range(scale_range.x, scale_range.y)
	var new_scale: Vector2 = Vector2.ONE * random_scale
	_init_outer_scale = new_scale * _outer_start_scale_multiplier
	_init_outer_scale.x = clampf(_init_outer_scale.x, 0, _max_outer_scale.x)
	_init_outer_scale.y = clampf(_init_outer_scale.y, 0, _max_outer_scale.y)
	
	_outer_texture.scale = _init_outer_scale
	_inner_texture.scale = new_scale
	_animate_reset()


func _is_in_window() -> bool:
	# positive distance means the outer circle has shrunk inside the inner circle.
	# negative distance means the outer circle is still larger than the inner circle.
	var distance: float = snappedf((_inner_texture.scale - _outer_texture.scale).x, 0.01)
	# the inner ring is visually thicker, so allow the outer ring to shrink slightly
	# past the inner ring's raw scale before counting it as too late.
	return distance >= -grace_window and distance <= (_thickness_offset + grace_window) * _inner_texture.scale.x


func _is_past_window() -> bool:
	# positive distance means the outer circle has shrunk inside the inner circle.
	var distance: float = snappedf((_inner_texture.scale - _outer_texture.scale).x, 0.01)
	# the inner ring is visually thicker, so allow the outer ring to shrink slightly
	# past the inner ring's raw scale before counting it beyond the success window.
	return distance >= (_thickness_offset + reset_window) * _inner_texture.scale.x


#region animations
func _animate_show() -> void:
	var tween: Tween = create_tween()
	visible = true
	modulate = Color(Color.WHITE, 0)
	tween.tween_property(
			self,
			"modulate",
			Color.WHITE,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_hide() -> void:
	var tween: Tween = create_tween()
	visible = true
	self.modulate = Color.WHITE
	tween.tween_property(
			self,
			"modulate",
			Color(Color.WHITE, 0),
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_reset() -> void:
	var tween: Tween = create_tween()
	var current_inner_color: Color = GREEN_COLOR
	var current_outer_color: Color = WHITE_COLOR
	_inner_texture.modulate = Color(current_inner_color, 0)
	_outer_texture.modulate = Color(current_outer_color, 0)

	tween.set_parallel()
	tween.tween_property(
			_inner_texture,
			"modulate",
			current_inner_color,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			_outer_texture,
			"modulate",
			current_outer_color,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



func _animate_success() -> void:
	var tween: Tween = create_tween()
	var current_inner_scale: Vector2 = _inner_texture.scale
	var current_outer_scale: Vector2 = _outer_texture.scale

	tween.set_parallel()
	# scale out
	tween.tween_property(
			_outer_texture,
			"modulate",
			GREEN_COLOR,
			0.133
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			_outer_texture,
			"scale",
			current_outer_scale * 1.4,
			0.666
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
			_inner_texture,
			"scale",
			current_inner_scale * 1.2,
			0.666
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# fade out
	tween.tween_property(
			_outer_texture,
			"modulate",
			Color(GREEN_COLOR, 0),
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.3)
	tween.tween_property(
			_inner_texture,
			"modulate",
			Color(GREEN_COLOR, 0),
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.3)

	tween.chain().tween_callback(_complete_stage)


func _animate_failure() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(
			_outer_texture,
			"modulate",
			RED_COLOR,
			0.333
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			_outer_texture,
			"modulate",
			Color(RED_COLOR, 0),
			0.333
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(
			func() -> void:
				_outer_texture.scale = _init_outer_scale
				_outer_texture.modulate = Color(WHITE_COLOR, 0)
				_is_moving = true
	)
	tween.tween_property(
			_outer_texture,
			"modulate",
			WHITE_COLOR,
			0.666
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#endregion
