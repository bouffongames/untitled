extends CanvasLayer

signal _typing_finished

signal dialogue_ended
signal dialogue_signal(value: String)

enum Voice { NARRATOR, GUARD, WITCH }

@onready var guard_blip: AudioStreamPlayer2D = $GuardBlip
@onready var witch_blip: AudioStreamPlayer2D = $WitchBlip
@onready var narrator_blip: AudioStreamPlayer2D = $NarratorBlip

var narrator_blip_interval: int = 1
var guard_blip_interval: int = 3
var witch_blip_interval: int = 1

var _current_blip: AudioStreamPlayer2D
var _current_blip_interval: int = 5

@export var text_speed_multiplier: float = 1.0

@export var _speaker_label: Label
@export var _text_label: Label

@export var _response_container: Control

@export var _continue_container: HBoxContainer
@export var _continue_arrow: Control

var _manager: DialogueManager = DialogueManager.new()
var _active: bool
var _interrupt: bool


func _ready() -> void:
	visible = false
	_manager.dialogue_ended.connect(dialogue_ended.emit)
	_manager.dialogue_signal.connect(dialogue_signal.emit)
	_animate_continue_arrow()


func _input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()  # disable all input when dialogue is visible
	
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


func play_from_string(value: String) -> void:
	visible = true
	_manager.load_dialogue_from_string(value)
	_next_line()


func forcibly_end_dialogue() -> void:
	_manager.forcibly_end_dialogue()
	_next_line()  # automatically cleans up dialogue when the next line is 'null'


func _next_line() -> void:
	var line: DialogueLine = _manager.next_line()
	if line == null:
		_speaker_label.visible = false
		_speaker_label.text = ""
		_text_label.text = ""
		visible = false
		return

	visible = true
	_continue_container.visible = false
	_response_container.visible = false
	for child: Node in _response_container.get_children():
		child.queue_free()
	await _set_text(line.text)
	if not line.responses.is_empty():
		_show_responses(line.responses)
	else:
		_continue_container.visible = true


func _set_text(new_text: String) -> void:
	var split: PackedStringArray = new_text.split(":")
	if split.size() > 1:
		_speaker_label.visible = true
		_speaker_label.text = split[0]
		new_text = split[1].strip_edges()
	else:
		_speaker_label.visible = false
		_speaker_label.text = ""
	_current_blip = _get_blip_player(_speaker_label.text)
	await _type_characters(new_text)
	

func _get_blip_player(speaker: String) -> AudioStreamPlayer2D:
	var s := speaker.strip_edges().to_lower()

	if s == "":
		return narrator_blip
		_current_blip_interval = narrator_blip_interval
	if s.begins_with("guard"):
		return guard_blip
		_current_blip_interval = guard_blip_interval
	if s.begins_with("witch"):  # ajuste para o nome que a bruxa usa nos diálogos
		return witch_blip
		_current_blip_interval = witch_blip_interval

	return narrator_blip

func _type_characters(text: String) -> void:
	if _active:
		await _typing_finished
	_active = true
	_text_label.text = text
	_text_label.visible_characters = 0
	var normal_delay: float = 0.08 / text_speed_multiplier
	var upper_case_delay: float = 0.16 / text_speed_multiplier
	var punctuation_delay: float = 0.15 / text_speed_multiplier
	var pause_delay: float = 1.0 / text_speed_multiplier
	for i: int in range(text.length()):
		if _interrupt:
			break
		_text_label.visible_characters = i + 1
		if _current_blip and i % _current_blip_interval == 0 and not _current_blip.playing:
			_current_blip.play()
		
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
	_text_label.text = text
	_text_label.visible_characters = -1
	_interrupt = false
	_active = false
	_typing_finished.emit()


func _show_responses(responses: Array[DialogueLine]) -> void:
	_response_container.visible = true
	for response: DialogueLine in responses:
		var button: Button = Button.new()
		button.text = response.text
		button.pressed.connect(
			func() -> void:
				_manager.set_response(response)
				_next_line()
		)
		_response_container.add_child(button)


func _animate_continue_arrow() -> void:
	var _init_position: Vector2 = _continue_arrow.position
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(
			_continue_arrow,
			"position:y",
			_init_position.y - 6.0,
			0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
			_continue_arrow,
			"position:y",
			_init_position.y,
			0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
