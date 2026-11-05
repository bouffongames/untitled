class_name DialogueManager
extends RefCounted

signal dialogue_ended
signal dialogue_signal(value: String)

var _start_line: DialogueLine
var _current_line: DialogueLine

var _parser: DialogueParser = DialogueParser.new()


func set_response(line: DialogueLine) -> void:
	_evaluate_mutation(line)
	_current_line = line


func next_line() -> DialogueLine:
	if _has_next_line():
		var line: DialogueLine = _get_next_line()
		_evaluate_mutation(line)
		return line
	else:
		if _start_line != null:
			_start_line = null
			dialogue_ended.emit()
		return null


func has_responses() -> bool:
	return (
		not _current_line.responses.is_empty()
		if _current_line != null
		else _start_line != null and not _start_line.responses.is_empty()
	)

func load_dialogue(file_path: String) -> void:
	_current_line = null
	_start_line = _parser.load_dialogue(file_path)


func _has_next_line() -> bool:
	return (
		_current_line.next != null if _current_line != null else _start_line != null
	)


func _get_next_line() -> DialogueLine:
	if _current_line == null:
		_current_line = _start_line
		return _start_line
	_current_line = _current_line.next
	return _current_line


func _evaluate_mutation(line: DialogueLine) -> void:
	for mutation: Dictionary in line.mutations:
		var type: String = mutation.type
		var value: String = mutation.value

		match type:
			"emit":
				dialogue_signal.emit(value)
			_:
				print("Mutation: unknown type ", type, " value=", value)
