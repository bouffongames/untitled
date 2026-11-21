class_name MindControlHUD
extends Control

var _guard: Guard

@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	stop()


func start(guard: Guard) -> void:
	_guard = guard
	_progress_bar.max_value = guard.get_mind_control_duration()
	_progress_bar.value = guard.get_mind_control_time_left()
	show()
	set_process(true)


func stop() -> void:
	_guard = null
	hide()
	set_process(false)


func _process(_delta: float) -> void:
	_progress_bar.value = _guard.get_mind_control_time_left()
