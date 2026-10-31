class_name SceneLoader
extends CanvasLayer

signal changed

const LOADABLE: String = "loadable"

var _loading: bool = false
var _scene_path: String

@export var _animation_player: AnimationPlayer
@export var _progress_bar: ProgressBar


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _loading:
		_handle_scene_loading()


func change(path: String) -> bool:
	if _loading:
		push_warning("A scene is already loading")
		return false

	_progress_bar.value = 0
	_animation_player.play("fade")
	visible = true
	await _animation_player.animation_finished
	_scene_path = path
	_loading = true
	ResourceLoader.load_threaded_request(path, "PackedScene", true)
	await changed
	return true


func _handle_scene_loading() -> void:
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
		_scene_path, progress
	)
	_progress_bar.value = max(_progress_bar.value, progress[0] * 100)

	match status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			_instantiate_scene()
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load scene: Invalid resource or has not been loaded")
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			push_error("Failed to load scene")


func _instantiate_scene() -> void:
	var scene: PackedScene = ResourceLoader.load_threaded_get(_scene_path)
	var scene_instance: Node = scene.instantiate()
	_clear_existing_nodes()
	get_tree().root.add_child(scene_instance)
	_loading = false
	changed.emit()
	_animation_player.play_backwards("fade")
	await _animation_player.animation_finished
	visible = false


func _clear_existing_nodes() -> void:
	var exist_nodes: Array[Node] = get_tree().get_nodes_in_group(LOADABLE)
	for n: Node in exist_nodes:
		n.queue_free()
