@abstract class_name Minigame
extends Control

@warning_ignore("unused_signal")
signal failed
@warning_ignore("unused_signal")
signal succeed


@abstract func reset() -> void


func _angle_distance(a: float, b: float) -> float:
	var diff: float = fposmod(absf(a - b), 360.0)
	return min(diff, 360.0 - diff)


func _angle_is_inside_arc(target_angle: float, arc_center: float, arc_size: float) -> bool:
	return _angle_distance(target_angle, arc_center) <= arc_size * 0.5
