class_name ConfigResourceSerializer
extends RefCounted


static func save(section: String, resource: ConfigResource, config: ConfigFile) -> void:
	section = section.to_snake_case()
	for prop: Dictionary in get_user_property_list(resource):
		if prop.usage & PROPERTY_USAGE_STORAGE != 0:
			@warning_ignore("unsafe_call_argument", "unsafe_method_access")
			config.set_value(section, prop.name, _serialize_value(resource.get(prop.name)))


static func load(section: String, resource: ConfigResource, config: ConfigFile) -> void:
	section = section.to_snake_case()
	for prop: Dictionary in get_user_property_list(resource):
		@warning_ignore("unsafe_method_access")
		var prop_name: String = prop.name.to_snake_case()
		@warning_ignore("unsafe_call_argument")
		if prop.usage & PROPERTY_USAGE_STORAGE != 0 and config.has_section_key(section, prop_name):
			var value: Variant = config.get_value(section, prop_name)
			var current_value: Variant = resource.get(prop_name)
			@warning_ignore("unsafe_call_argument")
			resource.set(prop_name, _deserialize_value(value, current_value))


static func get_default_values(resource: ConfigResource) -> Dictionary[String, Variant]:
	var default_values: Dictionary[String, Variant]
	for prop: Dictionary in get_user_property_list(resource):
		@warning_ignore("unsafe_method_access")
		var prop_name: String = prop.name.to_snake_case()
		@warning_ignore("unsafe_call_argument")
		if prop.usage & PROPERTY_USAGE_STORAGE != 0:
			var value: Variant = resource.get(prop_name)
			value = _duplicate_if_needed(value)
			@warning_ignore("unsafe_call_argument")
			default_values.set(prop_name, value)
	return default_values


static func get_user_property_list(resource: ConfigResource) -> Array[Dictionary]:
	var new_list: Array[Dictionary] = []
	for prop: Dictionary in resource.get_property_list():
		if _is_exported_user_property(prop):
			new_list.append(prop)
	return new_list


static func _is_exported_user_property(prop: Dictionary) -> bool:
	@warning_ignore("unsafe_method_access")
	return (
		prop.usage & PROPERTY_USAGE_STORAGE != 0
		and not prop.name.begins_with("_")
		and not prop.name.begins_with("metadata/")
		and not prop.name in ["resource_local_to_scene", "resource_name", "script"]
	)


static func _duplicate_if_needed(value: Variant) -> Variant:
	match typeof(value):
		TYPE_ARRAY, TYPE_DICTIONARY:
			@warning_ignore("unsafe_method_access")
			return value.duplicate(true)
		TYPE_OBJECT:
			if value is Resource:
				@warning_ignore("unsafe_method_access")
				return value.duplicate(true)
			return value
		_:
			return value


static func _serialize_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var serialized_dict: Dictionary = {}
			for key: Variant in value:
				serialized_dict[key] = _serialize_value(value[key])
			return serialized_dict
		TYPE_ARRAY:
			var serialized_array: Array = []
			for item: Variant in value:
				serialized_array.append(_serialize_value(item))
			return serialized_array
		TYPE_OBJECT:
			if value is Resource:
				@warning_ignore("unsafe_call_argument")
				return _serialize_resource(value)
			return value
		_:
			return value


static func _serialize_resource(resource: Resource) -> Dictionary:
	var script: Script = resource.get_script()
	if script == null:
		return {}

	var script_uid: String = ResourceUID.path_to_uid(script.resource_path)
	var serialized: Dictionary = {"__resource__": script_uid}

	for prop: Dictionary in resource.get_property_list():
		if _is_exported_user_property(prop):
			@warning_ignore("unsafe_method_access")
			var prop_name: String = prop.name.to_snake_case()
			@warning_ignore("unsafe_call_argument")
			serialized[prop_name] = _serialize_value(resource.get(prop_name))

	return serialized


static func _deserialize_value(value: Variant, current_value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			@warning_ignore("unsafe_method_access")
			if value.get("__resource__", false):
				@warning_ignore("unsafe_call_argument")
				return _deserialize_resource(value)

			var deserialized_dict: Dictionary
			if typeof(current_value) == TYPE_DICTIONARY:
				deserialized_dict = current_value
				deserialized_dict.clear()
			else:
				deserialized_dict = {}

			for key: Variant in value:
				var current_item: Variant = null
				@warning_ignore("unsafe_method_access")
				if typeof(current_value) == TYPE_DICTIONARY and current_value.has(key):
					current_item = current_value[key]
				deserialized_dict[key] = _deserialize_value(value[key], current_item)

			return deserialized_dict
		TYPE_ARRAY:
			var deserialized_array: Array = []
			for item: Variant in value:
				deserialized_array.append(_deserialize_value(item, current_value))
			return deserialized_array
		_:
			return value


static func _deserialize_resource(value: Dictionary) -> Resource:
	var script_path: String = value.get("__resource__", "")
	if script_path.is_empty():
		return null

	var script: Script = load(script_path) as Script
	if script == null:
		push_warning("Could not load resource: %s" % script_path)
		return null

	@warning_ignore("unsafe_cast", "unsafe_method_access")
	var resource: Resource = script.new() as Resource
	if resource == null:
		push_warning("Could not create a resource: %s" % script_path)
		return null

	for prop_name: Variant in value:
		if prop_name == "__resource__":
			continue

		@warning_ignore("unsafe_call_argument")
		resource.set(prop_name, _deserialize_value(value[prop_name], resource.get(prop_name)))

	return resource
