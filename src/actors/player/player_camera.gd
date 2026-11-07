extends Camera3D

const RAY_LENGTH := 1_000.0

const CLICK_POSITION_PARTICLE = preload("uid://7lcjf6g22ofl")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_viewport().get_mouse_position()
			var ray_origin := project_ray_origin(mouse_pos)
			var ray_end := ray_origin + project_ray_normal(mouse_pos) * RAY_LENGTH

			var space_state := get_world_3d().direct_space_state
			var mask_bits := 1 << 0 # Layer 1 "Ground"
			var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, mask_bits)

			var result := space_state.intersect_ray(query)

			if result.is_empty():
				print("Didn't click the ground")
			else:
				print("Clicked the ground at ", result.position)
				var particle_instance := CLICK_POSITION_PARTICLE.instantiate()
				get_parent().add_child(particle_instance)
				particle_instance.global_position = result.position
				particle_instance.restart()
				particle_instance.finished.connect(func() -> void:
					particle_instance.queue_free()
				)

				var player = get_tree().get_first_node_in_group("Player")
				if not player:
					push_error("Player not found by the player camera")
					return

				(player as Player).target_position = result.position
