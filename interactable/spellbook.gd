extends Interactable

@export var book: MeshInstance3D
@export var hover_shader: Shader


func _ready() -> void:
	for i: int in range(book.get_surface_override_material_count()):
		var original_material: StandardMaterial3D = book.get_active_material(i) as StandardMaterial3D

		var door_material: ShaderMaterial = ShaderMaterial.new()
		door_material.shader = hover_shader

		if original_material:
			door_material.set_shader_parameter("albedo_color", original_material.albedo_color)
	
			if original_material.albedo_texture:
				door_material.set_shader_parameter("albedo_texture", original_material.albedo_texture)

		book.set_surface_override_material(i, door_material)


func hide_hover() -> void:
	for i: int in range(book.get_surface_override_material_count()):
		var material: Material = book.get_surface_override_material(i)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("show_amount", 1.0)
			


func show_hover() -> void:
	for i: int in range(book.get_surface_override_material_count()):
		var material: Material = book.get_surface_override_material(i)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("show_amount", 0.8)


func interact() -> void:
	print("TODO")


func can_interact() -> bool:
	return true
