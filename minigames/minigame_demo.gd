extends Control

@export var _buttons: Array[Button]

@export var _minigames: Array[Minigame]

# TODO add activate button and unhandled_input
# TODO add toggle for button, disable the one currently selected


func _ready() -> void:
	if _buttons.size() != _minigames.size():
		push_error("Buttons and minigames arrays must have the same size.")
		return
	
	for i: int in range(_buttons.size()):
		var button: Button = _buttons[i]
		button.disabled = true
		var minigame: Minigame = _minigames[i]
		minigame.visible = false
		button.pressed.connect(_refresh.bind(i))
		minigame.succeed.connect(_reset.bind(minigame))
		minigame.failed.connect(_reset.bind(minigame))

	_refresh(0)


func _unhandled_input(event: InputEvent) -> void:
	var event_key: InputEventKey = event as InputEventKey
	if event_key == null or not event_key.pressed or event_key.echo:
		return
	match event_key.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			var index: int = event_key.keycode - KEY_1
			_refresh(index)


func _reset(minigame: Minigame) -> void:
	await get_tree().create_timer(1.0).timeout
	minigame.reset()


func _refresh(index: int) -> void:	
	for button: Button in _buttons:
		button.disabled = false
	for minigame: Minigame in _minigames:
		minigame.visible = false
	var new_button: Button = _buttons[index]
	new_button.disabled = true
	var new_minigame: Minigame = _minigames[index]
	new_minigame.reset()
	new_minigame.visible = true
