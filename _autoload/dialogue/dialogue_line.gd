class_name DialogueLine
extends RefCounted

var id: String

var next: DialogueLine

var text: String

var responses: Array[DialogueLine]

var mutations: Array[Dictionary]


func _to_string() -> String:
	return "{id=%s, text=%s, next=%s, responses=%s}" % [id, text, next, responses]
