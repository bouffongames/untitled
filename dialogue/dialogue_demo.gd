extends Control


func _ready() -> void:
	Dialogue.play("dialogue/test.txt")
	Dialogue.dialogue_ended.connect(
		func() -> void: 
			print("dialogue ended")
			print("loop dialogue")
			Dialogue.play.call_deferred("dialogue/test.txt")
	)
	Dialogue.dialogue_signal.connect(
		func(value: String) -> void: 
			print("dialogue event: ", value)
	)
