class_name ReadMindSpell
extends Spell


func apply(_caster: Player, target: Guard) -> void:
	# TODO: implement the Read Mind effect.
	target.exit_spellbound()
