extends CanvasLayer

signal _typing_finished

signal dialogue_ended
signal dialogue_signal(value: String)

@export var speaker_label: Label
@export var text_label: Label
@export var response_container: Control
@export var text_speed_multiplier: float = 1.0

@export var continue_container: HBoxContainer
@export var continue_arrow_label: Label

var _manager: DialogueManager = DialogueManager.new()
var _active: bool
var _interrupt: bool


func _ready() -> void:
	visible = false
	_manager.dialogue_ended.connect(dialogue_ended.emit)
	_manager.dialogue_signal.connect(dialogue_signal.emit)
	_animate_continue_arrow()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialogue_next_line"):
		if _active:
			_interrupt = true
			return
		
		if not _manager.has_responses():
			_next_line()


func play(file_path: String) -> void:
	visible = true
	_manager.load_dialogue(file_path)
	_next_line()


func _next_line() -> void:
	var line: DialogueLine = _manager.next_line()
	if line == null:
		speaker_label.visible = false
		speaker_label.text = ""
		text_label.text = ""
		visible = false
		return

	visible = true
	continue_container.visible = false
	await _set_text(line.text)
	if not line.responses.is_empty():
		_show_responses(line.responses)
	else:
		continue_container.visible = true


func _set_text(new_text: String) -> void:
	var split: PackedStringArray = new_text.split(":")
	if split.size() > 1:
		speaker_label.visible = true
		speaker_label.text = split[0]
		new_text = split[1].strip_edges()
	else:
		speaker_label.visible = false
		speaker_label.text = ""
	await _type_characters(new_text)


func _type_characters(text: String) -> void:
	if _active:
		await _typing_finished
	_active = true
	text_label.text = text
	text_label.visible_characters = 0
	var normal_delay: float = 0.08 / text_speed_multiplier
	var upper_case_delay: float = 0.16 / text_speed_multiplier
	var punctuation_delay: float = 0.15 / text_speed_multiplier
	var pause_delay: float = 1.0 / text_speed_multiplier
	for i: int in range(text.length()):
		if _interrupt:
			break
		text_label.visible_characters = i + 1
		var wait_time: float = normal_delay
		if text[i] in [".", ",", "!", "?", ";", ":", "~", "(", ")", "*"]:
			wait_time = punctuation_delay
		elif text[i] in ["\t"]:
			wait_time = pause_delay
		else:
			var char_code: int = int(text[i])
			if ((char_code >= 65 and char_code <= 90) or (char_code >= 97 and char_code <= 122)) and text[i].to_upper() == text[i]:
				wait_time = upper_case_delay
		if _interrupt:
			break
		await get_tree().create_timer(wait_time).timeout
	text_label.text = text
	text_label.visible_characters = -1
	_interrupt = false
	_active = false
	_typing_finished.emit()


func _show_responses(responses: Array[DialogueLine]) -> void:
	for child: Node in response_container.get_children():
		child.queue_free()
	response_container.visible = true
	for response: DialogueLine in responses:
		var button: Button = Button.new()
		button.text = response.text
		button.pressed.connect(
			func() -> void:
				response_container.visible = false
				for child: Node in response_container.get_children():
					child.queue_free()
				_manager.set_response(response)
				_next_line()
		)
		response_container.add_child(button)


func _animate_continue_arrow() -> void:
	var _init_position: Vector2 = continue_arrow_label.position
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(
			continue_arrow_label,
			"position:y",
			_init_position.y - 6.0,
			0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			continue_arrow_label,
			"position:y",
			_init_position.y,
			0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
