class_name DialogueParser
extends RefCounted


func load_dialogue(file_path: String) -> DialogueLine:
	var file_string: String = FileAccess.get_file_as_string(file_path)
	if file_string != null and not file_string.is_empty():
		# remove whitespaces
		file_string = file_string.strip_edges(true, true)
		return _parse_file(file_string)
	return null


func _parse_file(file_string: String) -> DialogueLine:
	var split_lines: PackedStringArray = file_string.split("\n")
	var raw_lines: Array[String] = Array(Array(split_lines), TYPE_STRING, "", null)
	# remove empty lines
	raw_lines = raw_lines.filter(func(item: String) -> bool: return item != "")

	var prev_queue: Array[Dictionary] = []
	var unresolved_tails: Array[DialogueLine] = []

	var first_line: DialogueLine = null
	var prev_line: DialogueLine = null
	var prev_depth: int

	for raw_line: String in raw_lines:
		var depth: int = _get_line_depth(raw_line)

		var line: DialogueLine = DialogueLine.new()
		line.id = _generate_unique_id()
		if first_line == null:
			first_line = line

		# responses start with a dash
		var text: String = raw_line.strip_edges()
		var is_response: bool = text.begins_with("-")
		if is_response:
			text = text.trim_prefix("- ").trim_prefix("-")

		var mutation_result: Dictionary = _scan_mutations(text)
		line.text = mutation_result.text

		for mutation: Dictionary in mutation_result.mutations:
			line.mutations.append(mutation)

		for i: int in range(prev_queue.size() - depth):
			# keep track of lines that don't have next lines
			if prev_line != null and prev_line.next == null:
				unresolved_tails.append(prev_line)
			var data: Dictionary = prev_queue.pop_back()
			prev_line = data.prev_line
			prev_depth = data.prev_depth

		if not is_response and depth == 0:
			# set next line for all unresolved tails with the current line
			for tail: DialogueLine in unresolved_tails:
				if tail.next == null:
					tail.next = line
			unresolved_tails.clear()

		if is_response:
			prev_line.responses.append(line)

		if is_response or depth < prev_depth:
			prev_queue.push_back({"prev_line": prev_line, "prev_depth": prev_depth})

		# build the linked list
		if not is_response and prev_line != null and prev_line.next == null:
			prev_line.next = line
		prev_line = line
		prev_depth = depth

	return first_line


func _get_line_depth(raw_line: String) -> int:
	# count the number of tab characters to determine depth
	var depth: int = 0
	for c: String in raw_line:
		if c == "\t":
			depth += 1
		else:
			break
	return depth


func _generate_unique_id() -> String:
	var time: float = Time.get_unix_time_from_system()
	var hash_value: Variant = hash(time)
	return "%s" % hash_value


func _scan_mutations(text: String) -> Dictionary:
	var new_text: String = ""
	var mutations: Array[Dictionary] = []

	var is_block: bool = false
	var block_text: String = ""

	for character: String in text:
		if character == "[":
			is_block = true
			block_text = ""
			continue

		if character == "]" and is_block:
			is_block = false
			var mutation: Dictionary = _parse_mutation_block(block_text)
			if not mutation.is_empty():
				mutations.append(mutation)
			continue

		if is_block:
			block_text += character
		else:
			new_text += character

	return {
		"text": new_text,
		"mutations": mutations,
	}

func _parse_mutation_block(block_text: String) -> Dictionary:
	var clean_block_text: String = block_text.strip_edges()

	if clean_block_text.is_empty():
		return {}

	var split_block: PackedStringArray = clean_block_text.split(" ", false, 1)
	var mutation_type: String = split_block[0].strip_edges()
	var mutation_value: String = ""

	if split_block.size() > 1:
		mutation_value = split_block[1].strip_edges()

	return {
		"type": mutation_type,
		"value": mutation_value,
	}
