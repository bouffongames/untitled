extends Node

# Adjust pool size depending on how many simultaneous sound effects you expect
@export var ui_pool_size: int = 4
@export var sfx_pool_size: int = 12
@export var pitch_variation_percent: float = 0

#List of all audio files, edit in inspector
@export_category("SFX Files")
@export var sfx_library: Dictionary[String, AudioStream] = {}
@export_category("Ambient Files")
@export var ambient_library: Dictionary[String, AudioStream] = {}
@export_category("Music Files")
@export var music_library: Dictionary[String, AudioStream] = {}
@export_category("UI Files")
@export var ui_library: Dictionary[String, AudioStream] = {}

# AudioStreamPlayer nodes created automatically at runtime
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ui_players: Array[AudioStreamPlayer] = []

var _music_tween: Tween

func _ready() -> void:
	# Process even when the scene tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Setup SFX player pool
	for i in sfx_pool_size:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
		
	# UI pool setup
	for i in ui_pool_size:
		var player = AudioStreamPlayer.new()
		player.bus = "UI"
		add_child(player)
		ui_players.append(player)

func play_ui(key: String, volume_db: float = 0.0) -> void:
	if not ui_library.has(key) or ui_library[key] == null:
		push_warning("UI key not found in ui_library: " + key)
		return

	for player in ui_players:
		if not player.playing:
			player.stream = ui_library[key]
			player.volume_db = volume_db
			player.play()
			return

## Plays background music (stops if new music is provided)
func play_music(key: String, volume_db: float = 0.0) -> void:
	if not music_library.has(key) or music_library[key] == null:
		push_warning("Music key not found in music_library: " + key)
		return
		
	var stream = music_library[key]
	if music_player.stream == stream and music_player.playing:
		return
		
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

## Stops the current music

func stop_music(fade_time: float = 0.5) -> void:
	if not music_player.playing:
		return

	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()

	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", -80.0, fade_time)
	_music_tween.tween_callback(music_player.stop)

## Plays a 2D/Global sound effect from the pool
func play_sfx(key: String, min_pitch: float = 1.0 - pitch_variation_percent/100, max_pitch: float = 1.0 + pitch_variation_percent/100, volume_db: float = 0.0) -> void:
	if not sfx_library.has(key) or sfx_library[key] == null:
		push_warning("SFX key not found in sfx_library: " + key)
		return
		
	var stream = sfx_library[key]
	var pitch = randf_range(min_pitch, max_pitch)
	
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return
			
func play_ambient_loop(key: String, min_pitch: float = 1.0 - pitch_variation_percent/100, max_pitch: float = 1.0 + pitch_variation_percent/100, volume_db: float = 0.0) -> void:
	if not ambient_library.has(key) or ambient_library[key] == null:
		push_warning("SFX key not found in ambient_library: " + key)
		return
		
	var stream = ambient_library[key]
	var pitch = randf_range(min_pitch, max_pitch)
	
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return

func play_random_step() -> void:
	var steps = ["step1", "step2", "step3"]
	play_sfx(steps.pick_random())

func update_bus_volume(index: int, value: float) -> void:
	AudioServer.set_bus_volume_db(index, linear_to_db(value))
	print(AudioServer.get_bus_volume_db(index))
	
