extends Node
## Immediately hide all walls (and some objects) that are eligible to be hidden.

const MAX_TARGET_STRENGTH: float = 0.8
const GROUP_NAME: String = "hideable"

@export var hidden_alpha: float = 0.2
@export var fade_speed: float = 8.0
@export var height_fade_softness: float = 0.5
@export var cuttoff_shader: Shader

var _original_materials: Dictionary[MeshInstance3D, Array] = {}


func _ready() -> void:
	for node: Node in get_tree().get_nodes_in_group(GROUP_NAME):
		var node_3d: Node3D = node as Node3D
		if _is_valid_body(node_3d):
			var mesh: MeshInstance3D = _find_mesh(node)
			if is_instance_valid(mesh):
				_apply_cutoff_materials(mesh)


func _is_valid_body(body: Node3D) -> bool:
	if not is_instance_valid(body):
		return false
	return body.is_in_group(GROUP_NAME)


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
		shader_material.render_priority = -1
		_copy_material_values(original_material, shader_material)

		wall.set_surface_override_material(i, shader_material)

	_update_wall_shader(wall, MAX_TARGET_STRENGTH)

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

	for sibling: Node in node .get_children():
		if sibling is MeshInstance3D:
			return sibling

	return null
