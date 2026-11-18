extends CanvasLayer

@export var _range_indicator: MeshInstance3D
@export var _range_fill: MeshInstance3D
@export_flags_3d_physics var _obstacle_layer: int = 4

@export_group("Spell Range Indicator")
@export var _idle_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var _in_range_color: Color = Color(0.3, 1.0, 0.3, 0.9)
@export var _blocked_color: Color = Color(1.0, 0.85, 0.2, 0.9)
@export var _ring_thickness: float = 0.08
## Opacity of the inside of the circle, relative to the ring color.
@export_range(0.0, 1.0) var _fill_opacity: float = 0.25

@export_group("Targeting")
@export var _mouse_ray_length: float = 1_000.0
## Height of the line-of-sight ray, similar to the one the guard uses
@export var _sight_height: float = 1.0

var _player: Player
var _aiming_spell: SpellButton
var _minigame: Minigame
var _spell_target: Guard

@onready var _control: Control = $Control
@onready var _spell_buttons: Array[SpellButton] = [%MindControlButton, %ReadMindButton, %AngerButton]


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	_range_indicator.visible = false
	for button: SpellButton in _spell_buttons:
		button.pressed.connect(_start_aiming.bind(button))


func _process(_delta: float) -> void:
	if _aiming_spell == null:
		return

	var color: Color = _idle_color
	var guard: Guard = _get_hovered_guard()
	if guard != null and _is_in_range(guard):
		color = _blocked_color if _is_blocked(guard) else _in_range_color
	((_range_indicator.mesh as TorusMesh).material as StandardMaterial3D).albedo_color = color
	((_range_fill.mesh as CylinderMesh).material as StandardMaterial3D).albedo_color = Color(color, color.a * _fill_opacity)


func _unhandled_input(event: InputEvent) -> void:
	if _aiming_spell == null:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_stop_aiming()
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return

	get_viewport().set_input_as_handled()
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		var guard: Guard = _get_hovered_guard()
		if guard != null and _is_in_range(guard) and not _is_blocked(guard):
			_start_minigame(_aiming_spell, guard)
	_stop_aiming()


func _start_aiming(spell: SpellButton) -> void:
	if _minigame != null:
		return
	_aiming_spell = spell
	var ring: TorusMesh = _range_indicator.mesh as TorusMesh
	ring.outer_radius = spell.spell_range
	ring.inner_radius = spell.spell_range - _ring_thickness
	var fill: CylinderMesh = _range_fill.mesh as CylinderMesh
	fill.top_radius = ring.inner_radius
	fill.bottom_radius = ring.inner_radius
	_range_indicator.visible = true


func _stop_aiming() -> void:
	_aiming_spell = null
	_range_indicator.visible = false


func _get_hovered_guard() -> Guard:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * _mouse_ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player.get_rid()]
	var result: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.collider as Guard


func _is_in_range(guard: Guard) -> bool:
	var offset: Vector3 = guard.global_position - _player.global_position
	return Vector2(offset.x, offset.z).length() <= _aiming_spell.spell_range


func _is_blocked(guard: Guard) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		_player.global_position + Vector3.UP * _sight_height,
		guard.global_position + Vector3.UP * _sight_height,
		_obstacle_layer
	)
	return not _player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _start_minigame(spell: SpellButton, guard: Guard) -> void:
	if spell.minigame_scene == null:
		push_warning("%s has no minigame scene assigned." % spell.name)
		return
	_minigame = spell.minigame_scene.instantiate() as Minigame
	_control.add_child(_minigame)
	_minigame.succeed.connect(_on_minigame_finished.bind(true))
	_minigame.failed.connect(_on_minigame_finished.bind(false))
	_spell_target = guard
	_spell_target.enter_spellbound()


func _on_minigame_finished(success: bool) -> void:
	# TODO: apply the spell effect on success.
	print("Spell minigame ", "succeeded" if success else "failed")
	if success:
		_spell_target.exit_spellbound()
	else:
		_spell_target.stun()
	_spell_target = null
	await get_tree().create_timer(1.0).timeout
	_minigame.queue_free()
	_minigame = null
