class_name Player
extends Character

signal mind_control_started(guard: Guard)
signal mind_control_ended(guard: Guard)
signal thought_read(text: String, duration: float)

var _mind_controlled_guard: Guard
var _is_casting: bool


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
	mind_control_started.emit(guard)


func end_mind_control() -> void:
	if _mind_controlled_guard != null:
		_mind_controlled_guard.end_mind_control()


func get_mind_controlled_guard() -> Guard:
	return _mind_controlled_guard


func _on_mind_control_ended() -> void:
	var guard: Guard = _mind_controlled_guard
	_mind_controlled_guard = null
	mind_control_ended.emit(guard)
