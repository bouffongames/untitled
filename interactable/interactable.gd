class_name Interactable
extends Node3D

signal disabled_changed
signal interacted

@export var disabled: bool = false:
	set(value):
		if disabled != value:
			disabled = value
			disabled_changed.emit()
@export var skin: InteractableSkin


func _ready() -> void:
	_on_disabled_changed()
	disabled_changed.connect(_on_disabled_changed)


func _on_disabled_changed() -> void:
	if is_instance_valid(skin):
		if disabled:
			skin.hide_shine()
			skin.hide_hover()
		else:
			skin.show_shine()


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
