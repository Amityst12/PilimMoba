class_name CastCounterPassive
extends PassiveData
## Every N ability casts, applies buffs to the champion (e.g. a burst of movement speed).

@export var casts_required: int = 3
@export var effects: Array[StatusEffectData] = []


func get_max_stacks() -> int:
	return casts_required


func on_ability_cast(caster: Champion, _slot: int) -> void:
	caster.passive_stacks += 1
	if caster.passive_stacks >= casts_required:
		caster.passive_stacks = 0
		caster.apply_effects(effects, 1, caster)
		if Game.current:
			Game.current.play_fx("buff", caster.global_position, {"color": color})
