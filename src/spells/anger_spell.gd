class_name AngerSpell
extends Spell


func apply(_caster: Player, target: Guard) -> void:
	# TODO: implement the Anger effect.
	target.exit_spellbound()
