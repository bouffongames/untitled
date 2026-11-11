class_name EvadeMinigame
extends Minigame

const OUTER_COLOR: Color = Color(0.661, 0.341, 0.355, 1.0)
const INNER_COLOR: Color = Color(0.48, 0.298, 0.307, 1.0)

@export var speed: float = 150.0
## Duration of the minigame in seconds.
@export var duration: float = 8.0
@export var evade_duration: float = 4.0
@export var invincible_duration: float = 0.5
@export var obstacles: Array[EvadeObstacle] 

@export_category("Visual")
@export var _progress_bar: ProgressBar
@export var _time_limit_progress_bar: ProgressBar

@export_category("Evade")
@export var _outer_radius: float = 106.0
@export var _inner_radius: float = 80.0
@export var _lane_width: float = 22.0

var _player_lane: int
var _player_angle: float = 270.0
var _player_color: Color = Color.WHITE

var _elapsed_time: float = 0.0
var _progress_time: float = 0.0
var _invincible_time: float = 0.0


func _ready() -> void:
	if visible:
		reset()


func _process(delta: float) -> void:
	if not visible or _is_minigame_finished():
		return

	_elapsed_time += delta

	if _invincible_time > 0.0:
		_invincible_time -= delta
	else:
		_progress_time += delta

	_progress_bar.value = _progress_bar.max_value - _progress_time
	_time_limit_progress_bar.value = _time_limit_progress_bar.max_value - _elapsed_time

	for obstacle: EvadeObstacle in obstacles:
		obstacle.angle = fposmod(obstacle.angle - speed * delta, 360.0)

	if _invincible_time <= 0.0:
		_player_color = Color.WHITE
		_check_collision()

	if _progress_bar.value <= 0:
		succeed.emit()
		_animate_hide()
		
	if _time_limit_progress_bar.value <= 0:
		failed.emit()
		_animate_hide()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_minigame_finished():
		return

	if event.is_action_pressed("ui_accept"):
		_player_lane = wrapi(_player_lane + 1, 0, 2)
		queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5

	# lanes
	var outer_color: Color = OUTER_COLOR if _player_lane == 1 else INNER_COLOR
	var inner_color: Color = INNER_COLOR if _player_lane == 1 else OUTER_COLOR
	draw_arc(center, _outer_radius, 0.0, TAU, 128, outer_color, _lane_width, true)
	draw_arc(center, _inner_radius, 0.0, TAU, 128, inner_color, _lane_width, true)

	# obstacles
	for obstacle: EvadeObstacle in obstacles:
		var radius: float = _outer_radius if obstacle.lane == 1 else _inner_radius
		var start_angle: float = deg_to_rad(obstacle.angle - obstacle.arc_size * 0.5)
		var end_angle: float = deg_to_rad(obstacle.angle + obstacle.arc_size * 0.5)
		draw_arc(center, radius, start_angle, end_angle, 24, Color.BLACK, _lane_width, true)

	# player
	var player_radius: float = _outer_radius if _player_lane == 1 else _inner_radius
	var player_pos: Vector2 = center + Vector2.RIGHT.rotated(deg_to_rad(_player_angle)) * player_radius
	draw_circle(player_pos, 8.0, _player_color, true, -1.0, true)


func reset() -> void:
	_player_lane = 1
	_elapsed_time = 0.0
	_progress_time = 0.0
	_progress_bar.max_value = evade_duration
	_progress_bar.value = evade_duration
	_time_limit_progress_bar.max_value = duration
	_time_limit_progress_bar.value = duration
	_animate_show()


func _is_minigame_finished() -> bool:
	return _progress_bar.value <= 0.0 or _time_limit_progress_bar.value <= 0.0


func _check_collision() -> void:
	for obstacle: EvadeObstacle in obstacles:
		if obstacle.lane != _player_lane:
			continue

		if _angle_is_inside_arc(_player_angle, obstacle.angle, obstacle.arc_size):
			_invincible_time = invincible_duration
			_player_color = Color.RED
			return


#region animations
func _animate_show() -> void:
	var tween: Tween = create_tween()
	modulate = Color(Color.WHITE, 0)
	tween.tween_property(
			self,
			"modulate",
			Color.WHITE,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_hide() -> void:
	var tween: Tween = create_tween()
	modulate = Color.WHITE
	tween.tween_property(
			self,
			"modulate",
			Color(Color.WHITE, 0),
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#endregion
