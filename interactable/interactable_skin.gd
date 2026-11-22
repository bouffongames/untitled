class_name InteractableSkin
extends Node

@export var mesh: MeshInstance3D

@export_group("Shine")
@export var shine_color: Color = Color(0.059, 0.173, 1.0)
@export var shine_color_offset: Color = Color.WHITE
@export var shine_offset_matrix: Array[bool]
@export var shine_angle: Vector3i
@export var shine_shader: Shader

@export_group("Hover Outline")
@export var hover_outline_color: Color = Color.RED
@export var hover_outline_size: float = 1.00
@export var hover_outline_shader: Shader


func _ready() -> void:
	for i: int in range(mesh.get_surface_override_material_count()):
		var original_material: StandardMaterial3D = mesh.get_active_material(i) as StandardMaterial3D

		var shine_material: ShaderMaterial = ShaderMaterial.new()
		shine_material.shader = shine_shader
		shine_material.next_pass = original_material
		shine_material.set_shader_parameter(
			"shine_color", 
			shine_color_offset 
			if i < shine_offset_matrix.size() and shine_offset_matrix[i] 
			else shine_color
		)
		shine_material.set_shader_parameter("shine_angle_x", shine_angle.x)
		shine_material.set_shader_parameter("shine_angle_y", shine_angle.y)
		shine_material.set_shader_parameter("shine_angle_z", shine_angle.z)

		var hover_material: ShaderMaterial = ShaderMaterial.new()
		hover_material.shader = hover_outline_shader
		hover_material.next_pass = shine_material
		hover_material.set_shader_parameter("color", hover_outline_color)
		hover_material.set_shader_parameter("size", 1.0)

		mesh.set_surface_override_material(i, hover_material)


func hide_shine() -> void:
	for i: int in range(mesh.get_surface_override_material_count()):
		var material: Material = mesh.get_surface_override_material(i)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material != null:
			var next_material: ShaderMaterial = shader_material.next_pass as ShaderMaterial
			if next_material != null:
				var previous_color: Color = next_material.get_shader_parameter("shine_color")
				next_material.set_shader_parameter("shine_color", Color(previous_color, 0.0))


func show_shine() -> void:
	for i: int in range(mesh.get_surface_override_material_count()):
		var material: Material = mesh.get_surface_override_material(i)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material != null:
			var next_material: ShaderMaterial = shader_material.next_pass as ShaderMaterial
			if next_material != null:
				var previous_color: Color = next_material.get_shader_parameter("shine_color")
				next_material.set_shader_parameter("shine_color", Color(previous_color, 1.0))


func hide_hover() -> void:
	for i: int in range(mesh.get_surface_override_material_count()):
		var material: Material = mesh.get_surface_override_material(i)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("size", 1.0)



func show_hover() -> void:
	for i: int in range(mesh.get_surface_override_material_count()):
		var material: Material = mesh.get_surface_override_material(i)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("size", hover_outline_size)
