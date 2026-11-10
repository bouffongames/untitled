class_name DialMinigame
extends Minigame

const FAILURE_COLOR: Color = Color(0.941, 0.443, 0.443, 1.0)

@export var duration: float = 5.0
@export var speed: float = 60.0
@export var initial_sequence: Array[int] = [0, 1, 2, 3]

@export_group("Visual")
@export var _root: Control

@export var _arrow_texture: TextureRect
@export var _sequence_arrow_texture: TextureRect

@export var _letter_texture: TextureRect
@export var _sequence_container: Container
@export var _completed_sequence_container: Container

@export var _progress_bar: ProgressBar

@export_group("Dial")
@export var _radius: float = 105.0
@export var _dial_parent: Control
@export var _dial_pip_texture: DPITexture
@export var _pip_textures: Array[DPITexture]

var _is_anim_locked: bool
var _sequence: Array[int]
var _pips: Array[Pip]

var _progress_value: float
var _progress_speed: float

func _ready() -> void:
	_create_pips()
	if visible:
		reset()


func _process(delta: float) -> void:
	if not visible or _is_minigame_finished():
		return

	_progress_value = clampf(_progress_value - (_progress_speed * delta), 0, duration)
	_progress_bar.value = _progress_value

	_dial_parent.rotation_degrees = fposmod(_dial_parent.rotation_degrees + speed * delta, 360.0)

	for p: Pip in _pips:
		#p.letter.rotation_degrees = -p.angle - dial_parent.rotation_degrees

		if _angle_is_inside_arc(0, _dial_parent.rotation_degrees + p.angle, p.arc_size):
			_letter_texture.texture = p.letter.texture

	_sequence_arrow_texture.visible = not _sequence.is_empty()
	if _sequence.is_empty():
		_letter_texture.texture = null

	if _progress_value <= 0.0:
		_animate_hide()
		failed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_anim_locked or _is_minigame_finished():
		return

	if event.is_action_pressed("ui_accept"):
		_is_anim_locked = true
		if _sequence.is_empty():
			return

		var pip: Pip = _get_current_pip()
		if _sequence[0] == pip.value:
			var letter: TextureRect = _create_letter(_pip_textures[pip.value])
			_completed_sequence_container.add_child(letter)
			_sequence.remove_at(0)
			_sequence_container.remove_child(_sequence_container.get_child(0))
			_animate_lock_arrow()

			if _sequence.is_empty():
				_complete_stage()
		else:
			for child: Node in _sequence_container.get_children():
				child.queue_free()
			for child: Node in _completed_sequence_container.get_children():
				child.queue_free()

			_sequence.clear()
			_sequence.append_array(initial_sequence)
			for i: int in initial_sequence:
				var letter: TextureRect = _create_letter(_pip_textures[i])
				letter.self_modulate = Color.DIM_GRAY
				_sequence_container.add_child(letter)

			_animate_failure()


func reset() -> void:
	_is_anim_locked = false
	_dial_parent.rotation_degrees = 0.0

	_sequence.clear()
	for child: Node in _sequence_container.get_children():
		child.queue_free()
	for child: Node in _completed_sequence_container.get_children():
		child.queue_free()

	_progress_bar.max_value = duration
	_progress_value = duration
	_progress_bar.value = duration
	_progress_speed = _progress_bar.max_value / duration

	_rand()
	_animate_show()


func _complete_stage() -> void:
	_animate_hide()
	succeed.emit()


func _is_minigame_finished() -> bool:
	return _progress_bar.value <= 0.0


func _rand() -> void:
	var positions: Array[int] = _get_random_pip_positions(initial_sequence.size(), 12, 2)

	var sequence_textures: Dictionary[int, DPITexture] = {}
	for i: int in range(initial_sequence.size()):
		var pip_index: int = positions[i]
		sequence_textures[pip_index] = _pip_textures[initial_sequence[i]]

	var uniques: Array[DPITexture] = []
	for i: int in range(_pip_textures.size()):
		if not initial_sequence.has(i):
			uniques.append(_pip_textures[i])

	for i: int in range(_pips.size()):
		var p: Pip = _pips[i]
		var texture: DPITexture
		if sequence_textures.has(i):
			texture = sequence_textures[i]
		else:
			texture = uniques.pick_random()
			uniques.erase(texture)

		p.letter.texture = texture
		p.value = _pip_textures.find(texture)


	for i: int in initial_sequence:
		var letter: TextureRect = _create_letter(_pip_textures[i])
		letter.self_modulate = Color.DIM_GRAY
		_sequence_container.add_child(letter)
	_sequence.append_array(initial_sequence)


func _get_random_pip_positions(count: int, segments: int, gap: int) -> Array[int]:
	var start_offset: int = 2
	var positions: Array[int] = []
	var prev: int = -gap - 1

	for i: int in range(count):
		var minPos: int = prev + gap + 1
		var maxPos: int = segments - 1 - (count - i - 1) * (gap + 1)

		var pos: int = randi_range(minPos, maxPos)
		positions.append((pos + start_offset) % segments)
		prev = pos

	return positions


func _get_current_pip() -> Pip:
	var pip: Pip
	for p: Pip in _pips:
		if _angle_is_inside_arc(0, _dial_parent.rotation_degrees + p.angle, p.arc_size):
			pip = p
	return pip


func _create_letter(texture: DPITexture) -> TextureRect:
	var letter: TextureRect = TextureRect.new()
	letter.texture = texture
	letter.custom_maximum_size = Vector2(32.0, 32.0)
	return letter


func _create_pips() -> void:
	if not _pips.is_empty():
		push_warning("Pips already created")
		return

	var dial_radius: float = 105.0
	var center: Vector2 = size * 0.5
	var pip_size: Vector2 = _dial_pip_texture.get_size()
	_dial_parent.pivot_offset = _root.size * 0.5

	for i: int in range(12):
		var pip: TextureRect = TextureRect.new()
		pip.texture = _dial_pip_texture
		#pip.self_modulate = Color("#0A0A0A")
		pip.size = pip_size
		pip.pivot_offset = pip_size * 0.5
		pip.rotation_degrees = -i * 30
		var angle: float = pip.rotation
		var direction: Vector2 = Vector2.UP.rotated(angle)
		pip.position = center + direction * dial_radius - pip.pivot_offset
		_dial_parent.add_child(pip)

		var pip_letter_texture: DPITexture = _pip_textures[0]
		var pip_letter: TextureRect = TextureRect.new()
		pip_letter.texture = pip_letter_texture
		pip_letter.self_modulate = Color("#A99555")
		pip_letter.custom_maximum_size = Vector2(24.0, 24.0)
		pip_letter.position = Vector2(22.0, 22.0)
		pip_letter.pivot_offset = pip_letter.size * 0.5
		pip.add_child(pip_letter)

		var arc_size: float = rad_to_deg(2.0 * asin((pip_size.x * 0.5) / _radius))
		_pips.append(
			Pip.new(pip_letter, pip.rotation_degrees, arc_size, 0)
		)


#region animations
func _animate_show() -> void:
	var tween: Tween = create_tween()
	visible = true
	_root.modulate = Color(Color.WHITE, 0)
	tween.tween_property(
			_root,
			"modulate",
			Color.WHITE,
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_hide() -> void:
	var tween: Tween = create_tween()
	visible = true
	_root.modulate = Color.WHITE
	tween.tween_property(
			_root,
			"modulate",
			Color(Color.WHITE, 0),
			0.433
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: visible = false)


func _animate_lock_arrow() -> void:
	var tween: Tween = create_tween()
	var init_position: Vector2 = _arrow_texture.position
	tween.tween_property(
			_arrow_texture,
			"position",
			init_position + Vector2(0, 4),
			0.066
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			_arrow_texture,
			"position",
			init_position + Vector2(0, -6),
			0.133
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			_arrow_texture,
			"position",
			init_position,
			0.066
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: _is_anim_locked = false)


func _animate_failure() -> void:
	var letters: Array[TextureRect]
	for child: Node in _completed_sequence_container.get_children():
		var texture: TextureRect = child as TextureRect
		if is_instance_valid(texture):
			letters.append(child)
	for child: Node in _sequence_container.get_children():
		var texture: TextureRect = child as TextureRect
		if is_instance_valid(texture):
			letters.append(child)
	letters.append(_letter_texture)

	var tween: Tween = create_tween()
	tween.set_parallel( )
	for texture: TextureRect in letters:
		texture.modulate = FAILURE_COLOR
		tween.parallel()
		tween.tween_property(
				texture,
				"modulate",
				Color(FAILURE_COLOR, 0.75),
				0.1
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.chain()

	for texture: TextureRect in letters:
		tween.tween_property(
				texture,
				"modulate",
				Color.WHITE,
				0.1
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(
		func() -> void:
			_is_anim_locked = false
	)
#endregion

class Pip:
	var letter: TextureRect
	var angle: float
	var arc_size: float
	var value: int

	func _init(p_letter: TextureRect, p_angle: float, p_arc_size: float, p_value: int) -> void:
		letter = p_letter
		angle = p_angle
		arc_size = p_arc_size
		value = p_value
