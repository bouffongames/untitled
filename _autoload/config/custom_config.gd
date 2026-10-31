class_name CustomConfig
extends RefCounted

var _config_path: String
var _default_config_path: String
var _config_file: ConfigFile

var _resources: Dictionary[String, ConfigResource] = {}


func _init(config_path: String, default_config_path: String) -> void:
	_config_path = config_path
	_default_config_path = default_config_path


func add_section(section: String, resource: ConfigResource) -> void:
	if section.is_empty():
		push_error("Config section name must be set")
		return
	if _resources.has(section):
		push_error("Config section already exists")
		return

	_resources.set(section, resource)
	resource.saved.connect(save_all)


func load_all(window: Window) -> void:
	for section: String in _resources.keys():
		var resource: ConfigResource = _resources[section]
		var default_values: Dictionary[String, Variant] = (
			ConfigResourceSerializer.get_default_values(resource)
		)
		resource.set_default_values(default_values)

	_load_config_file()
	for section: String in _resources.keys():
		var resource: ConfigResource = _resources[section]
		ConfigResourceSerializer.load(section, resource, _config_file)
		resource.set_window(window)
		resource.apply()
	save_all()


func save_all() -> void:
	for section: String in _resources.keys():
		var resource: ConfigResource = _resources[section]
		ConfigResourceSerializer.save(section, resource, _config_file)
	_save_config_file()


func _load_config_file() -> void:
	if _config_file != null:
		return
	_config_file = ConfigFile.new()
	_config_file.load(_config_path)


func _save_config_file() -> void:
	var save_error: Error = _config_file.save(_config_path)
	if save_error > OK:
		push_error("Save config file failed with error %d" % save_error)
