extends Area3D
## Hide walls (and some objects) that are eligible to be hidden when the player
## gets close to them.

const MAX_TARGET_STRENGTH: float = 0.8
const GROUP_NAME: String = "hideable"

@export var hidden_alpha: float = 0.2
@export var fade_speed: float = 8.0
@export var height_fade_softness: float = 0.5
@export var cuttoff_shader: Shader

var _target_wall_strengths: Dictionary[MeshInstance3D, float] = {}
var _current_wall_strengths: Dictionary[MeshInstance3D, float] = {}
var _original_materials: Dictionary[MeshInstance3D, Array] = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	for wall: MeshInstance3D in _target_wall_strengths.keys():
		if not is_instance_valid(wall):
			_target_wall_strengths.erase(wall)
			_current_wall_strengths.erase(wall)
			_original_materials.erase(wall)
			continue

		var target_strength: float = _target_wall_strengths[wall]
		var current_strength: float = _current_wall_strengths.get(wall, 0.0)

		# smooth transition when the target is changed
		current_strength = lerp(current_strength, target_strength, fade_speed * delta)
		_current_wall_strengths[wall] = current_strength
		_update_wall_shader(wall, current_strength)

		# once the wall is stored remove it from the list of hidden walls
		if target_strength == 0.0 and current_strength < 0.02:
			_update_wall_shader(wall, 0.0)
			_restore_original_materials(wall)

			_target_wall_strengths.erase(wall)
			_current_wall_strengths.erase(wall)
			_original_materials.erase(wall)


func _on_body_entered(body: Node3D) -> void:
	if _is_valid_body(body):
		var mesh: MeshInstance3D = _find_mesh(body)
		if is_instance_valid(mesh):
			_apply_cutoff_materials(mesh)
			_target_wall_strengths[mesh] = MAX_TARGET_STRENGTH  # to hide wall


func _on_body_exited(body: Node3D) -> void:
	if _is_valid_body(body):
		var mesh: MeshInstance3D = _find_mesh(body)
		if is_instance_valid(mesh):
			_target_wall_strengths[mesh] = 0.0  # to restore wall


func _is_valid_body(body: Node3D) -> bool:
	if body.is_in_group(GROUP_NAME):
		return true
	# the body may be child of a node that is in the group
	var parent: Node3D = body.get_parent_node_3d()
	return is_instance_valid(parent) and parent.is_in_group(GROUP_NAME)


func _restore_original_materials(wall: MeshInstance3D) -> void:
	if not _original_materials.has(wall):
		return

	# HACK we should be able to unset the override material once set, but that does not seem to be
	#  possible so we need to restore them.
	var saved_materials: Array = _original_materials[wall]
	for surface_index: int in range(saved_materials.size()):
		var original_material: Material = saved_materials[surface_index]
		wall.set_surface_override_material(surface_index, original_material)


func _apply_cutoff_materials(wall: MeshInstance3D) -> void:
	if _original_materials.has(wall):
		return

	# HACK we should be able to unset the override material once set, but that does not seem to be
	#  possible so we need to save them.
	var saved_materials: Array = []
	for i: int in range(wall.get_surface_override_material_count()):
		var original_material: Material = wall.get_active_material(i)
		saved_materials.append(original_material)

		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = cuttoff_shader
		_copy_material_values(original_material, shader_material)

		wall.set_surface_override_material(i, shader_material)

	_original_materials[wall] = saved_materials


func _copy_material_values(original_material: Material, shader_material: ShaderMaterial) -> void:
	if not is_instance_valid(original_material):
		return

	var standard_material: StandardMaterial3D = original_material as StandardMaterial3D
	if is_instance_valid(standard_material):
		# transfer the original color and texture to the cuttoff shader
		shader_material.set_shader_parameter("albedo_color", standard_material.albedo_color)
		if is_instance_valid(standard_material.albedo_texture):
			shader_material.set_shader_parameter("albedo_texture", standard_material.albedo_texture)


func _update_wall_shader(wall: MeshInstance3D, effect_strength: float) -> void:
	if not is_instance_valid(wall.mesh):
		return

	var cutoff_local_y: float = _get_cutoff_height_from_aabb(wall)
	for i: int in range(wall.get_surface_override_material_count()):
		var material: Material = wall.get_surface_override_material(i)

		var shader_material: ShaderMaterial = material as ShaderMaterial
		if is_instance_valid(shader_material):
			shader_material.set_shader_parameter("effect_strength", effect_strength)
			shader_material.set_shader_parameter("hidden_alpha", hidden_alpha)
			shader_material.set_shader_parameter("cutoff_local_y", cutoff_local_y)
			shader_material.set_shader_parameter("height_fade_softness", height_fade_softness)


func _get_cutoff_height_from_aabb(wall: MeshInstance3D) -> float:
	var mesh_aabb: AABB = wall.mesh.get_aabb()
	return mesh_aabb.position.y + mesh_aabb.size.y * 0.44  # this *magic number* height seems to fit wall for the gated walls


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node

	if node.get_parent() != null:
		for sibling: Node in node.get_parent().get_children():
			if sibling is MeshInstance3D:
				return sibling

	return null
