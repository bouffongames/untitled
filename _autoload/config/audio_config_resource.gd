class_name AudioConfigResource
extends ConfigResource

@export var master_volume: float
@export var sfx_volume: float
@export var music_volume: float
@export var ui_volume: float
@export var ambient_volume: float


func apply() -> void:
	for prop: Dictionary in ConfigResourceSerializer.get_user_property_list(self):
		if not str(prop.name).ends_with("_volume"):
			continue
		var bus_name: String = str(prop.name).split("_")[0]
		var bus_index: int = _get_bus_index(bus_name)
		if bus_index == -1:
			continue
		@warning_ignore("unsafe_call_argument")
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(get(prop.name)))


func _get_bus_index(what: String) -> int:
	for bus_index: int in AudioServer.bus_count:
		var bus_name: String = AudioServer.get_bus_name(bus_index).to_lower()
		if bus_name == what:
			return bus_index
	return -1
