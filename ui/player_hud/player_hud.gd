class_name PlayerHud
extends CanvasLayer

@export var _range_indicator: MeshInstance3D
@export var _range_fill: MeshInstance3D
@export var _spread_indicator: MeshInstance3D
@export var _spread_fill: MeshInstance3D
@export var _spread_arrow_scene: PackedScene
@export_flags_3d_physics var _obstacle_layer: int = 4

@export_group("Spell Range Indicator")
@export var _idle_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var _in_range_color: Color = Color(0.3, 1.0, 0.3, 0.9)
@export var _blocked_color: Color = Color(1.0, 0.85, 0.2, 0.9)
@export var _ring_thickness: float = 0.08
## Opacity of the inside of the circle, relative to the ring color.
@export_range(0.0, 1.0) var _fill_opacity: float = 0.25

@export_group("Spread Indicator")
## Color of the circle around the target guard when other guards are inside it.
@export var _spread_valid_color: Color = Color(0.3, 1.0, 0.3, 0.9)
## Color of the circle around the target guard when no other guard is inside it.
@export var _spread_invalid_color: Color = Color(1.0, 0.25, 0.25, 0.9)
## Width of the arrows pointing at the guards the spell spreads to, in meters.
@export var _arrow_width: float = 0.4
## Space left between each end of an arrow and the guards it connects, in meters.
@export var _arrow_gap: float = 0.6
## Height of the arrows above the ground, in meters.
@export var _arrow_height: float = 0.1

@export_group("Targeting")
@export var _mouse_ray_length: float = 1_000.0
## Height of the line-of-sight ray, similar to the one the guard uses
@export var _sight_height: float = 1.0

var _player: Player
var _aiming_spell: GuardSpell
var _minigame: Minigame
var _spell_target: Guard
var _spell_spread_targets: Array[Guard] = []
var _casting_spell: Spell
var _spread_arrows: Array[MeshInstance3D] = []

@onready var _control: Control = %Control
@onready var _active_spell_hud: ActiveSpellHUD = %ActiveSpellHUD
@onready var _read_mind_hud: ReadMindHUD = %ReadMindHUD
@onready var _spell_buttons: Array[SpellButton] = [%MindControlButton, %ReadMindButton, %AngerButton, %MergeButton]


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	_range_indicator.visible = false
	_spread_indicator.visible = false
	_player.mind_control_started.connect(_on_mind_control_started)
	_player.mind_control_ended.connect(_active_spell_hud.stop.unbind(1))
	_player.merge_started.connect(_on_merge_started)
	_player.merge_ended.connect(_active_spell_hud.stop)
	_player.thought_read.connect(_read_mind_hud.show_thought)
	for button: SpellButton in _spell_buttons:
		if button.spell != null:
			button.pressed.connect(_on_spell_button_pressed.bind(button.spell))
	Global.game.spell_learned.connect(enable_spells)
	Dialogue.visibility_changed.connect(_on_dialogue_visibility_changed)
	_on_dialogue_visibility_changed()


func _process(_delta: float) -> void:
	if _aiming_spell == null:
		return

	var color: Color = _idle_color
	var guard: Guard = _get_hovered_guard()
	var in_range: bool = guard != null and _is_in_range(_aiming_spell, guard)
	var can_target: bool = in_range and not _is_blocked(_aiming_spell, guard)
	if in_range:
		color = _in_range_color if can_target else _blocked_color
	_set_indicator_color(_range_indicator, _range_fill, color)
	_update_spread_indicator(guard if can_target else null)


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
		if _can_target(_aiming_spell, guard) and _aiming_spell.can_cast_on(guard):
			_start_minigame(_aiming_spell, guard)
	_stop_aiming()


func _on_spell_button_pressed(spell: Spell) -> void:
	if _minigame != null or _player.get_mind_controlled_guard() != null or _player.is_merged():
		return
	_stop_aiming()
	if spell is GuardSpell:
		_start_aiming(spell as GuardSpell)
	elif spell is SelfSpell:
		_start_minigame(spell)


func _on_dialogue_visibility_changed() -> void:
	_control.visible = not Dialogue.visible
	if Dialogue.visible:
		_stop_aiming()


func _on_mind_control_started(guard: Guard, spell: MindControlSpell) -> void:
	_active_spell_hud.start(spell.display_name, spell.control_duration, guard.get_mind_control_time_left)


func _on_merge_started(spell: MergeSpell) -> void:
	_active_spell_hud.start(spell.display_name, spell.duration, _player.get_merge_time_left)


func disable_spells() -> void:
	# guard is blocking the spells
	for button: SpellButton in _spell_buttons:
		var spell_name: String = button.spell.display_name.to_lower()
		button.disabled = true
		if spell_name == "merge":
			button.disabled = false


func enable_spells(except_spell_name: String = "") -> void:
	for button: SpellButton in _spell_buttons:
		var spell_name: String = button.spell.display_name.to_lower()
		if spell_name == except_spell_name:
			button.disabled = true
			continue
		
		if (Global.game.merge_spell_learned and spell_name == "merge") \
			or (Global.game.mind_control_spell_learned and spell_name == "mind control") \
			or (Global.game.anger_spell_learned and spell_name == "anger") \
			or spell_name == "read mind":
			button.disabled = false
		else:
			button.disabled = true


func _start_aiming(spell: GuardSpell) -> void:
	_aiming_spell = spell
	_set_indicator_radius(_range_indicator, _range_fill, spell.cast_range)
	if spell.get_spread_range() > 0.0:
		_set_indicator_radius(_spread_indicator, _spread_fill, spell.get_spread_range())
	_range_indicator.visible = true


func _stop_aiming() -> void:
	_aiming_spell = null
	_range_indicator.visible = false
	_spread_indicator.visible = false


func _set_indicator_radius(ring_node: MeshInstance3D, fill_node: MeshInstance3D, radius: float) -> void:
	var ring: TorusMesh = ring_node.mesh as TorusMesh
	ring.outer_radius = radius
	ring.inner_radius = radius - _ring_thickness
	var fill: CylinderMesh = fill_node.mesh as CylinderMesh
	fill.top_radius = ring.inner_radius
	fill.bottom_radius = ring.inner_radius


func _set_indicator_color(ring_node: MeshInstance3D, fill_node: MeshInstance3D, color: Color) -> void:
	((ring_node.mesh as TorusMesh).material as StandardMaterial3D).albedo_color = color
	((fill_node.mesh as CylinderMesh).material as StandardMaterial3D).albedo_color = Color(color, color.a * _fill_opacity)


func _update_spread_indicator(target: Guard) -> void:
	if target == null or _aiming_spell.get_spread_range() <= 0.0:
		_spread_indicator.visible = false
		return

	var spread_targets: Array[Guard] = _aiming_spell.get_spread_targets(target)
	_spread_indicator.global_position = target.global_position + Vector3.UP * _range_indicator.position.y
	_set_indicator_color(_spread_indicator, _spread_fill, _spread_invalid_color if spread_targets.is_empty() else _spread_valid_color)
	_spread_indicator.visible = true

	while _spread_arrows.size() < spread_targets.size():
		var arrow: MeshInstance3D = _spread_arrow_scene.instantiate() as MeshInstance3D
		_spread_indicator.add_child(arrow)
		_spread_arrows.append(arrow)
	for i: int in _spread_arrows.size():
		_spread_arrows[i].visible = i < spread_targets.size()
		if _spread_arrows[i].visible:
			_place_spread_arrow(_spread_arrows[i], target.global_position, spread_targets[i].global_position)


func _place_spread_arrow(arrow: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var offset := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if offset.length() <= 0.01:
		arrow.visible = false
		return
	var direction: Vector3 = offset.normalized()
	var length: float = maxf(offset.length() - _arrow_gap * 2.0, 0.1)
	var center: Vector3 = from + direction * (_arrow_gap + length * 0.5) + Vector3.UP * _arrow_height
	var arrow_basis: Basis = Basis.looking_at(direction) * Basis.from_scale(Vector3(_arrow_width, _arrow_width, length))
	arrow.global_transform = Transform3D(arrow_basis, center)


func _get_hovered_guard() -> Guard:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * _mouse_ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF & ~_obstacle_layer)
	query.exclude = [_player.get_rid()]
	var result: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.collider as Guard


func _can_target(spell: GuardSpell, guard: Guard) -> bool:
	return guard != null and _is_in_range(spell, guard) and not _is_blocked(spell, guard)


func _is_in_range(spell: GuardSpell, guard: Guard) -> bool:
	var offset: Vector3 = guard.global_position - _player.global_position
	return Vector2(offset.x, offset.z).length() <= spell.cast_range


func _is_blocked(spell: GuardSpell, guard: Guard) -> bool:
	if not spell.requires_line_of_sight:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		_player.global_position + Vector3.UP * _sight_height,
		guard.global_position + Vector3.UP * _sight_height,
		_obstacle_layer
	)
	return not _player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _start_minigame(spell: Spell, guard: Guard = null) -> void:
	get_tree().paused = true
	if spell.minigame_scene == null:
		push_warning("%s has no minigame scene assigned." % spell.resource_path)
		return
	_minigame = spell.minigame_scene.instantiate() as Minigame
	_control.add_child(_minigame)
	_minigame.succeed.connect(_on_minigame_finished.bind(true))
	_minigame.failed.connect(_on_minigame_finished.bind(false))
	_casting_spell = spell
	_player.start_casting()
	if guard == null:
		return
	_spell_target = guard
	_spell_spread_targets = (spell as GuardSpell).get_spread_targets(guard)
	_spell_target.enter_spellbound()
	for spread_target: Guard in _spell_spread_targets:
		spread_target.enter_spellbound()


func _on_minigame_finished(success: bool) -> void:
	get_tree().paused = false
	if _casting_spell == null:
		return
	print("Spell minigame ", "succeeded" if success else "failed")
	_player.finish_casting()
	if _casting_spell is GuardSpell:
		AudioManager.play_sfx("spell success")
		_finish_guard_spell(_casting_spell as GuardSpell, success)
	elif _casting_spell is SelfSpell:
		_finish_self_spell(_casting_spell as SelfSpell, success)
	_spell_target = null
	_spell_spread_targets = []
	_casting_spell = null
	await get_tree().create_timer(1.0).timeout
	_minigame.queue_free()
	_minigame = null


func _finish_guard_spell(spell: GuardSpell, success: bool) -> void:
	if success:
		spell.apply(_player, _spell_target, _spell_spread_targets)
	else:
		spell.fail(_player, _spell_target, _spell_spread_targets)


func _finish_self_spell(spell: SelfSpell, success: bool) -> void:
	if success:
		spell.apply(_player)
	else:
		spell.fail(_player)
