class_name MindControlSpell
extends Spell

## Seconds the player can control the guard.
@export_range(0.0, 60.0, 0.1, "or_greater") var control_duration: float = 8.0
## Seconds the guard stays stunned once released. The guard isn't alerted afterwards.
@export_range(0.0, 10.0, 0.1, "or_greater") var release_stun_duration: float = 3.0
## Fraction of the guard's max movement speed it moves at while controlled. 0.8 means 80% of its usual speed.
@export_range(0.0, 1.0, 0.05) var speed_multiplier: float = 0.7


func apply(caster: Player, target: Guard) -> void:
	caster.start_mind_control(target, self)
