class_name SpellButton
extends Button

@export var spell: Spell


func _ready() -> void:
	visible = spell != null
	if spell == null:
		return
	text = spell.display_name
	if shortcut != null and not shortcut.get_as_text().is_empty():
		text += " (%s)" % shortcut.get_as_text()
