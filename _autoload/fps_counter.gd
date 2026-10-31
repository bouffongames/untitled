class_name FPSCounter
extends CanvasLayer

@export var label: Label

var _update_time: float = 0.0
var _frame_count: int = 0

var _gameplay_resource: GameplayConfigResource


func _process(delta: float) -> void:
	visible = (
		_gameplay_resource.is_fps_counter_visible
		if is_instance_valid(_gameplay_resource)
		else false
	)
	if not visible:
		return

	_update_time += delta
	_frame_count += 1

	if _update_time > 0.25:
		var fps: float = _frame_count / _update_time
		label.text = "FPS %d (%.2f ms)" % [fps, delta * 1000.0]

		_update_time = 0.0
		_frame_count = 0


func init(gameplay_resource: GameplayConfigResource) -> void:
	_gameplay_resource = gameplay_resource
