#class_name Global
extends Node

@export var gameplay_resource: GameplayConfigResource
@export var display_resource: DisplayConfigResource
@export var audio_resource: AudioConfigResource
@export var controls_resource: ControlsConfigResource

@export var scene: SceneLoader
@export var game: Game
@export var menu: Menu
@export var fps_counter: FPSCounter

var _player_config: CustomConfig


func _ready() -> void:
	_init_config()

	if not is_instance_valid(fps_counter):
		push_warning("Fps counter is not set")
	else:
		fps_counter.init(gameplay_resource)

	if not is_instance_valid(game):
		push_warning("Game is not set")
	if not is_instance_valid(menu):
		push_warning("Menu is not set")
	else:
		menu.init(game, scene)


func _init_config() -> void:
	if not is_instance_valid(gameplay_resource):
		push_warning("Video config resource is not set")
	if not is_instance_valid(display_resource):
		push_warning("Video config resource is not set")
	if not is_instance_valid(audio_resource):
		push_warning("Audio config resource is not set")
	if not is_instance_valid(controls_resource):
		push_warning("Input config resource is not set")

	_player_config = CustomConfig.new("user://player_config.cfg", "res://default_player_config.cfg")

	_player_config.add_section("gameplay", gameplay_resource)
	_player_config.add_section("display", display_resource)
	_player_config.add_section("audio", audio_resource)
	_player_config.add_section("controls", controls_resource)

	_player_config.load_all(get_tree().root)
