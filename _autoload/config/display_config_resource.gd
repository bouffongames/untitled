class_name DisplayConfigResource
extends ConfigResource

@export_group("General")
@export var brightness: float
@export var field_of_view: float

@export_group("Display")
@export var window_mode: DisplayServer.WindowMode
@export var resolution: Vector2i
@export var vsync_mode: DisplayServer.VSyncMode


func apply() -> void:
	_apply_window_mode(window_mode)
	_apply_resolution(resolution)
	_apply_vsync_mode(vsync_mode)


func _apply_window_mode(new_window_mode: DisplayServer.WindowMode) -> void:
	if OS.has_feature("web"):
		return
	var window_id: int = get_window().get_window_id()
	if DisplayServer.window_get_mode(window_id) != new_window_mode:
		DisplayServer.window_set_mode(new_window_mode, window_id)


func _apply_resolution(new_resolution: Vector2i) -> void:
	if OS.has_feature("web"):
		return
	if (
		window_mode == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
		or window_mode == DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	):
		return
	if new_resolution.x == 0 or new_resolution.y == 0:
		return
	if get_window().size != new_resolution:
		get_window().size = new_resolution
		get_window().move_to_center()


func _apply_vsync_mode(new_vsync_mode: DisplayServer.VSyncMode) -> void:
	if OS.has_feature("web"):
		return
	var window_id: int = get_window().get_window_id()
	if DisplayServer.window_get_vsync_mode(window_id) != new_vsync_mode:
		DisplayServer.window_set_vsync_mode(new_vsync_mode, window_id)
