extends Node

@export var target: Control


func _ready() -> void:
	if OS.has_feature("web"):
		target.visible = false
