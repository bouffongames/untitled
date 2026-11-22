@abstract
class_name Interactable
extends Node3D

signal interacted

@export var disabled: bool = false
@export var skin: InteractableSkin


func hide_hover() -> void:
	if is_instance_valid(skin):
		skin.hide_hover()


func show_hover() -> void:
	if is_instance_valid(skin):
		skin.show_hover()


func interact() -> void:
	interacted.emit()


func can_interact() -> bool:
	return not disabled and visible
