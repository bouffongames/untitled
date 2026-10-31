@tool
class_name Options
extends Control

@warning_ignore("unused_signal")
signal state_changed

enum MenuState { NONE, GAMEPLAY, DISPLAY, AUDIO, CONTROLS }

@export var state: MenuState:
	set(value):
		if value != state:
			state = value
			if not Engine.is_editor_hint():
				state_changed.emit()
		_refresh()
	get():
		return state

@export_group("Root menu")
@export var gameplay_menu_button: Button
@export var display_menu_button: Button
@export var audio_menu_button: Button
@export var controls_menu_button: Button
@export var back_button: Button

@export_group("Submenu")
@export var gameplay_menu: Control
@export var display_menu: Control
@export var audio_menu: Control
@export var controls_menu: Control


func _ready() -> void:
	if not Engine.is_editor_hint():
		gameplay_menu_button.pressed.connect(func() -> void: state = MenuState.GAMEPLAY)
		display_menu_button.pressed.connect(func() -> void: state = MenuState.DISPLAY)
		audio_menu_button.pressed.connect(func() -> void: state = MenuState.AUDIO)
		controls_menu_button.pressed.connect(func() -> void: state = MenuState.CONTROLS)
		back_button.pressed.connect(func() -> void: state = MenuState.NONE)
	state = state


func _refresh() -> void:
	var is_root_menu: bool = state == MenuState.NONE
	if is_instance_valid(gameplay_menu_button):
		gameplay_menu_button.visible = is_root_menu
	if is_instance_valid(display_menu_button):
		display_menu_button.visible = is_root_menu
	if is_instance_valid(audio_menu_button):
		audio_menu_button.visible = is_root_menu
	if is_instance_valid(controls_menu_button):
		controls_menu_button.visible = is_root_menu
	if is_instance_valid(back_button):
		back_button.visible = not is_root_menu
	if is_instance_valid(gameplay_menu):
		gameplay_menu.visible = state == MenuState.GAMEPLAY
	if is_instance_valid(display_menu):
		display_menu.visible = state == MenuState.DISPLAY
	if is_instance_valid(audio_menu):
		audio_menu.visible = state == MenuState.AUDIO
	if is_instance_valid(controls_menu):
		controls_menu.visible = state == MenuState.CONTROLS
