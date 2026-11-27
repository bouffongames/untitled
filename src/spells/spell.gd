@abstract
class_name Spell
extends Resource

@export var display_name: String = ""
## Minigame the player has to win to cast the spell.
@export var minigame_scene: PackedScene
## Cooldown time in seconds after the player uses a spell
@export_range(0.0, 60.0, 0.5, "or_greater") var cooldown: float = 6.0
