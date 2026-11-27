class_name AngerSpell
extends GuardSpell

## Radius around the target guard in which other guards join the fight, in meters.
@export_range(0.0, 50.0, 0.1, "or_greater") var spread_range: float = 4.0
## Seconds the guards fight before going back to patrolling.
@export_range(0.5, 60.0, 0.1, "or_greater") var fight_duration: float = 6.0
## How much shorter the guards' vision reaches while fighting. 0.9 means 90% shorter.
@export_range(0.0, 1.0, 0.05) var vision_reduction: float = 0.9


func apply(_caster: Player, target: Guard, spread_targets: Array[Guard]) -> void:
	var fighters: Array[Guard] = [target]
	fighters.append_array(spread_targets)
	var focus_point := Vector3.ZERO
	for guard: Guard in fighters:
		focus_point += guard.global_position
	focus_point /= fighters.size()
	for guard: Guard in fighters:
		guard.start_fight(self, focus_point)


func get_spread_range() -> float:
	return spread_range


func get_spread_targets(target: Guard) -> Array[Guard]:
	var guards: Array[Guard] = []
	for node: Node in target.get_tree().get_nodes_in_group("Guard"):
		var guard: Guard = node as Guard
		if guard == null or guard == target:
			continue
		var offset: Vector3 = guard.global_position - target.global_position
		if Vector2(offset.x, offset.z).length() <= spread_range:
			guards.append(guard)
	return guards


func can_cast_on(target: Guard) -> bool:
	return super(target) and not get_spread_targets(target).is_empty()
