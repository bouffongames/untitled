class_name ActiveSpellHUD
extends Control

var _get_time_left: Callable

@onready var _title_label: Label = %TitleLabel
@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	stop()


func start(title: String, duration: float, get_time_left: Callable) -> void:
	_title_label.text = title
	_get_time_left = get_time_left
	_progress_bar.visible = duration > 0.0
	_progress_bar.max_value = duration
	if duration > 0.0:
		_progress_bar.value = get_time_left.call()
	show()
	set_process(duration > 0.0)


func stop() -> void:
	_get_time_left = Callable()
	hide()
	set_process(false)


func _process(_delta: float) -> void:
	_progress_bar.value = _get_time_left.call()
