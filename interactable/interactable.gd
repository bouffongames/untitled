@abstract
class_name Interactable
extends Node3D

signal interacted


@abstract
func hide_hover() -> void


@abstract
func show_hover() -> void


func interact() -> void:
	interacted.emit()


@abstract
func can_interact() -> bool
