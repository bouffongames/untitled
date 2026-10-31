@tool
class_name Menu
extends CanvasLayer
## In-game menu.

enum MenuState { NONE, RESUME_GAME, OPTIONS, RETURN_TO_MAIN_MENU }

static var _has_user_controlled: bool = false

@export var state: MenuState:
	set(value):
		state = value
		if Engine.is_editor_hint() or _is_ready:
			_refresh()
	get():
		return state

@export_group("Root menu")
@export var resume_game_menu_button: Button
@export var options_menu_button: Button
@export var return_to_main_menu_button: Button
@export var back_button: Button

@export_group("Submenu")
@export var options_menu: Options

var _game: Game
var _scene: SceneLoader

var _is_ready: bool = false
var _last_mouse_mode: Input.MouseMode
var _is_mouse_captured: bool = false


func _ready() -> void:
	_is_ready = true

	if not Engine.is_editor_hint():
		visible = false

	if not OS.has_feature("debug"):
		state = MenuState.NONE
		options_menu.state = Options.MenuState.NONE

	if not Engine.is_editor_hint():
		options_menu.state_changed.connect(_on_options_menu_state_changed)

		resume_game_menu_button.pressed.connect(func() -> void: state = MenuState.RESUME_GAME)
		options_menu_button.pressed.connect(func() -> void: state = MenuState.OPTIONS)
		return_to_main_menu_button.pressed.connect(
			func() -> void: state = MenuState.RETURN_TO_MAIN_MENU
		)
		back_button.pressed.connect(func() -> void: state = MenuState.NONE)

	state = state


func _exit_tree() -> void:
	if (
		is_instance_valid(_scene)
		and _scene.changed.is_connected(_on_scene_transition_finished)
	):
		_scene.changed.disconnect(_on_scene_transition_finished)


func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		or event is InputEventKey
		or event is InputEventJoypadButton
		or event is InputEventScreenTouch
	):
		_has_user_controlled = true

	if _game.get_state() == Game.GameState.NONE:
		return
	if event is not InputEventKey:
		return
	var event_key: InputEventKey = event as InputEventKey
	if event_key.is_pressed() and event_key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if visible and not OS.has_feature("web"):
			_resume_game()
		else:
			_pause_game()


func _process(_delta: float) -> void:
	if not OS.has_feature("web"):
		return

	if _game.get_state() == Game.GameState.NONE:
		return

	var is_captured: bool = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _is_mouse_captured and not is_captured and _game.get_state() == Game.GameState.PLAYING:
		if not is_captured:
			_pause_game()
	_is_mouse_captured = is_captured


func _on_options_menu_state_changed() -> void:
	_refresh()


func _on_scene_transition_finished() -> void:
	if not _has_user_controlled:
		_is_mouse_captured = true


func init(game: Game, scene: SceneLoader) -> void:
	_game = game
	_scene = scene

	_scene.changed.connect(_on_scene_transition_finished)


func _refresh() -> void:
	var is_root_menu: bool = (
		state == MenuState.NONE
		or state == MenuState.RESUME_GAME
		or state == MenuState.RETURN_TO_MAIN_MENU
	)
	if is_instance_valid(resume_game_menu_button):
		resume_game_menu_button.visible = is_root_menu
	if is_instance_valid(options_menu_button):
		options_menu_button.visible = is_root_menu
	if is_instance_valid(return_to_main_menu_button):
		return_to_main_menu_button.visible = is_root_menu
	if is_instance_valid(back_button):
		back_button.visible = not is_root_menu and options_menu.state == MenuState.NONE

	if is_instance_valid(options_menu):
		options_menu.visible = state == MenuState.OPTIONS

	if Engine.is_editor_hint():
		return

	if state == MenuState.RESUME_GAME:
		_resume_game()
	elif state == MenuState.RETURN_TO_MAIN_MENU:
		_return_to_main_menu()


func _resume_game() -> void:
	get_tree().paused = false
	visible = false
	if _last_mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = _last_mouse_mode
	_game.set_state(Game.GameState.PLAYING)


func _pause_game() -> void:
	state = MenuState.NONE
	options_menu.state = Options.MenuState.NONE
	get_tree().paused = true
	visible = true
	_last_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_game.set_state(Game.GameState.PAUSED)


func _return_to_main_menu() -> void:
	get_tree().paused = false
	visible = false
	_game.set_state(Game.GameState.NONE)
	_scene.change(Const.SCENE_MAIN)
