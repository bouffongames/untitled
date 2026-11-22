class_name Player
extends Character

signal mind_control_started(guard: Guard, spell: MindControlSpell)
signal mind_control_ended(guard: Guard)
signal thought_read(text: String, duration: float)
signal merge_started(spell: MergeSpell)
signal merge_ended

var _mind_controlled_guard: Guard
var _is_casting: bool
var _merge_spell: MergeSpell

@export var hud: PlayerHud
@onready var _merge_timer: Timer = %MergeTimer


func _ready() -> void:
	super()
	_merge_timer.timeout.connect(end_merge)


func start_casting() -> void:
	_is_casting = true
	stop_movement()


func finish_casting() -> void:
	_is_casting = false


func is_casting() -> bool:
	return _is_casting


func read_thought(text: String, duration: float) -> void:
	thought_read.emit(text, duration)


func start_mind_control(guard: Guard, spell: MindControlSpell) -> void:
	if _mind_controlled_guard != null:
		end_mind_control()
	_mind_controlled_guard = guard
	guard.mind_control_ended.connect(_on_mind_control_ended, CONNECT_ONE_SHOT)
	guard.start_mind_control(spell)
	mind_control_started.emit(guard, spell)


func end_mind_control() -> void:
	if _mind_controlled_guard != null:
		_mind_controlled_guard.end_mind_control()


func get_mind_controlled_guard() -> Guard:
	return _mind_controlled_guard


func _on_mind_control_ended() -> void:
	var guard: Guard = _mind_controlled_guard
	_mind_controlled_guard = null
	mind_control_ended.emit(guard)


func start_merge(spell: MergeSpell) -> void:
	_merge_spell = spell
	stop_movement()
	_character_skin.merge()
	if spell.duration > 0.0:
		_merge_timer.start(spell.duration)
	merge_started.emit(spell)


func end_merge() -> void:
	if _merge_spell == null:
		return
	_merge_spell = null
	_merge_timer.stop()
	_character_skin.unmerge()
	merge_ended.emit()


func is_merged() -> bool:
	return _merge_spell != null


func get_merge_time_left() -> float:
	return _merge_timer.time_left
