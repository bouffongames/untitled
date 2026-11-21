class_name ReadMindSpell
extends GuardSpell

## Seconds the thought stays on screen.
@export_range(0.5, 30.0, 0.5, "or_greater") var display_duration: float = 6.0
## Shown instead of a thought when the guard has none.
@export_multiline var no_thoughts_text: String = "This guard is thinking of nothing particular at the moment."


func apply(caster: Player, target: Guard, _spread_targets: Array[Guard]) -> void:
	var thought: Thought = target.read_next_thought()
	caster.read_thought(thought.text if thought != null else no_thoughts_text, display_duration)
	target.exit_spellbound()
