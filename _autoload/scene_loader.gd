class_name SceneLoader
extends CanvasLayer

signal changed

const LOADABLE: String = "loadable"

var _loading: bool = false
var _scene_path: String

@export var _transition: Transition


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _loading:
		_handle_scene_loading()


func change(path: String) -> bool:
	if _loading:
		push_warning("A scene is already loading")
		return false

	_loading = true
	_transition.enter()
	visible = true
	await _transition.finished
	_scene_path = path
	ResourceLoader.load_threaded_request(path, "PackedScene", true)
	await changed
	return true


func _handle_scene_loading() -> void:
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
		_scene_path, progress
	)

	match status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			_instantiate_scene()
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			push_error("Failed to load scene")


func _instantiate_scene() -> void:
	var scene: PackedScene = ResourceLoader.load_threaded_get(_scene_path)
	_clear_existing_nodes()
	await get_tree().process_frame  # give a chance to the nodes to be cleared
	var scene_instance: Node = scene.instantiate()
	get_tree().root.add_child(scene_instance)
	_transition.exit()
	await _transition.finished
	visible = false
	_loading = false
	changed.emit()


func _clear_existing_nodes() -> void:
	var exist_nodes: Array[Node] = get_tree().get_nodes_in_group(LOADABLE)
	for n: Node in exist_nodes:
		n.queue_free()
