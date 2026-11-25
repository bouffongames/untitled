extends Control


func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	Global.scene.change(Const.SCENE_MAIN)
