@tool
extends Control

enum MenuState { NONE, PLAY, OPTIONS, CREDITS, EXIT }

@export var state: MenuState:
	set(value):
		state = value
		if Engine.is_editor_hint() or _is_ready:
			_refresh()
	get():
		return state

@export var version_label: Label

@export_group("Root menu")
@export var play_menu_button: Button
@export var options_menu_button: Button
@export var credits_menu_button: Button
@export var exit_menu_button: Button
@export var back_button: Button

@export_group("Submenu")
@export var options_menu: Options
@export var credits: Credits

var _is_ready: bool = false


func _ready() -> void:
	_is_ready = true

	if not OS.has_feature("debug"):
		state = MenuState.NONE
		options_menu.state = Options.MenuState.NONE

	if not Engine.is_editor_hint():
		version_label.text = "v." + ProjectSettings.get_setting("application/config/version")

		credits.back_button_pressed.connect(func() -> void: state = MenuState.NONE)
		options_menu.state_changed.connect(_on_options_menu_state_changed)

		play_menu_button.pressed.connect(func() -> void: state = MenuState.PLAY)
		options_menu_button.pressed.connect(func() -> void: state = MenuState.OPTIONS)
		credits_menu_button.pressed.connect(func() -> void: state = MenuState.CREDITS)
		exit_menu_button.pressed.connect(func() -> void: state = MenuState.EXIT)
		back_button.pressed.connect(func() -> void: state = MenuState.NONE)

	state = state


func _on_options_menu_state_changed() -> void:
	_refresh()


func _refresh() -> void:
	var is_root_menu: bool = (
		state == MenuState.NONE or state == MenuState.PLAY or state == MenuState.CREDITS
	)
	if is_instance_valid(play_menu_button):
		play_menu_button.visible = is_root_menu
	if is_instance_valid(options_menu_button):
		options_menu_button.visible = is_root_menu
	if is_instance_valid(credits_menu_button):
		credits_menu_button.visible = is_root_menu
	if is_instance_valid(exit_menu_button):
		exit_menu_button.visible = is_root_menu and not OS.has_feature("web")
	if is_instance_valid(back_button):
		back_button.visible = not is_root_menu and options_menu.state == MenuState.NONE

	if is_instance_valid(options_menu):
		options_menu.visible = state == MenuState.OPTIONS

	if Engine.is_editor_hint():
		return

	if state == MenuState.PLAY:
		_start_game()
	elif state == MenuState.CREDITS:
		_show_credits()
	elif state == MenuState.EXIT:
		_exit()


func _start_game() -> void:
	if await Global.scene.change(Const.SCENE_LEVEL):
		Global.game.set_state(Game.GameState.PLAYING)


func _show_credits() -> void:
	credits_menu_button.release_focus()
	credits.enter()


func _exit() -> void:
	get_tree().quit.call_deferred()
