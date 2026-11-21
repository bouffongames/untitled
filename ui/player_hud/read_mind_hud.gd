class_name ReadMindHUD
extends Control

@onready var _thought_label: Label = %ThoughtLabel
@onready var _hide_timer: Timer = %HideTimer


func _ready() -> void:
	hide()
	_hide_timer.timeout.connect(hide)


func show_thought(text: String, duration: float) -> void:
	_thought_label.text = text
	show()
	_hide_timer.start(duration)
