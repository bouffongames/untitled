class_name CatWitchSkin
extends CharacterSkin

## Cross-fade time between animations, in seconds.
@export var blend_time := 0.15
## Scale of the model while merged into the floor.
@export var merged_scale := Vector3(1.3, 0.04, 1.3)
## Color laid over the model while merged into the floor. Alpha controls how dark it gets.
@export var merged_color := Color(0.02, 0.02, 0.05, 0.85)

const ANIM_IDLE := &"Idle"
const ANIM_WALK := &"Walk"
const ANIM_CAST := &"SpellCast"

## Looping animation to return to after a one-shot (e.g. the spell cast) finishes.
var _base_animation: StringName = ANIM_IDLE
var _meshes: Array[MeshInstance3D] = []
var _default_overlays: Array[Material] = []
var _merge_overlay := StandardMaterial3D.new()
var _merge_tween: Tween

@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# The cat witch is split into several meshes (body, arms, legs, hat, head...),
	# so the merge overlay is applied to all of them instead of a single model.
	for node in find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node as MeshInstance3D)
		_default_overlays.append((node as MeshInstance3D).material_overlay)

	_merge_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_merge_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_merge_overlay.albedo_color = Color(merged_color, 0.0)

	_animation_player.animation_finished.connect(_on_animation_finished)


## Sets the model to a neutral, action-free state.
func idle() -> void:
	_play_base(ANIM_IDLE)


## Plays the careful walk cycle.
func move() -> void:
	_play_base(ANIM_WALK)


## Plays the spell cast once, then returns to idle or walk.
func cast_spell() -> void:
	_animation_player.play(ANIM_CAST, blend_time)


func merge() -> void:
	_set_overlay(_merge_overlay)
	_restart_merge_tween()
	_merge_tween.tween_property(self, "scale", Vector3(0.85, 1.15, 0.85), 0.08).set_ease(Tween.EASE_OUT)
	_merge_tween.tween_property(self, "scale", merged_scale, 0.15).set_ease(Tween.EASE_IN)
	_merge_tween.parallel().tween_property(_merge_overlay, "albedo_color:a", merged_color.a, 0.15)


func unmerge() -> void:
	_restart_merge_tween()
	_merge_tween.tween_property(self, "scale", Vector3(0.85, 1.15, 0.85), 0.12).set_ease(Tween.EASE_OUT)
	_merge_tween.parallel().tween_property(_merge_overlay, "albedo_color:a", 0.0, 0.12)
	_merge_tween.tween_property(self, "scale", Vector3.ONE, 0.15).set_ease(Tween.EASE_OUT)
	_merge_tween.tween_callback(_restore_overlays)


func _play_base(animation: StringName) -> void:
	_base_animation = animation
	# Don't interrupt a spell cast; it hands back to the base animation when it ends.
	if _animation_player.current_animation == ANIM_CAST:
		return
	if _animation_player.current_animation == animation and _animation_player.is_playing():
		return
	_animation_player.play(animation, blend_time)


func _on_animation_finished(animation: StringName) -> void:
	if animation == ANIM_CAST:
		_animation_player.play(_base_animation, blend_time)


func _set_overlay(material: Material) -> void:
	for mesh in _meshes:
		mesh.material_overlay = material


func _restore_overlays() -> void:
	for i in _meshes.size():
		_meshes[i].material_overlay = _default_overlays[i]


func _restart_merge_tween() -> void:
	if _merge_tween != null:
		_merge_tween.kill()
	_merge_tween = create_tween().set_trans(Tween.TRANS_SINE)
