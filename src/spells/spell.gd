@abstract
class_name Spell
extends Resource

@export var display_name: String = ""
## Maximum ground distance from the player to the guard, in meters.
@export_range(0.0, 50.0, 0.1, "or_greater") var cast_range: float = 5.0
## If on, the spell can't be cast when an obstacle blocks the line between the player and the guard.
## If off, it can be cast through walls as long as the guard is in range.
@export var requires_line_of_sight: bool = true
## Minigame the player has to win to cast the spell.
@export var minigame_scene: PackedScene
## Seconds the guard stays stunned when the player loses the minigame. The guard is alerted afterwards.
@export_range(0.0, 10.0, 0.1, "or_greater") var fail_stun_duration: float = 3.0


@abstract func apply(caster: Player, target: Guard) -> void


func fail(_caster: Player, target: Guard) -> void:
	target.stun(fail_stun_duration, true)
