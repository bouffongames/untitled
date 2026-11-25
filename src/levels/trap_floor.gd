class_name TrapFloor
extends Node3D

@export_flags_3d_physics var ground_layer: int

@export var door: Door
@export var floor_tiles: Array[StaticBody3D]
@export var spike_tiles: Array[MeshInstance3D]
@export var navigation_region: NavigationRegion3D


func _ready() -> void:
	enable(false)


func enable(bake: bool = true) -> void:
	if is_instance_valid(door):
		door.disabled = true

	for tile: StaticBody3D in floor_tiles:
		if is_instance_valid(tile):
			tile.collision_layer = 0

	for spike: MeshInstance3D in spike_tiles:
		if is_instance_valid(spike):
			spike.visible = true

	if is_instance_valid(navigation_region) and bake:
		navigation_region.bake_navigation_mesh(true)


func disable() -> void:
	if is_instance_valid(door):
		door.disabled = false

	for tile: StaticBody3D in floor_tiles:
		if is_instance_valid(tile):
			tile.collision_layer = ground_layer

	for spike: MeshInstance3D in spike_tiles:
		if is_instance_valid(spike):
			spike.visible = false

	if is_instance_valid(navigation_region):
		navigation_region.bake_navigation_mesh(true)
