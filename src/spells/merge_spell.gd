class_name MergeSpell
extends SelfSpell

## Seconds the player stays merged into the floor. 0 means it lasts until the player exits.
@export_range(0.0, 60.0, 0.5, "or_greater") var duration: float = 0.0


func apply(caster: Player) -> void:
	caster.start_merge(self)
