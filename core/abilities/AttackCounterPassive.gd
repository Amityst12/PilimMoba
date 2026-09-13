class_name AttackCounterPassive
extends PassiveData
## Every N-th basic attack deals bonus damage and heals the champion.

@export var attacks_required: int = 3
@export var bonus_damage: float = 20.0
@export var bonus_damage_per_level: float = 6.0
@export var bonus_max_health_ratio: float = 0.03
@export var heal_max_health_ratio: float = 0.02


func get_max_stacks() -> int:
	return attacks_required


func on_basic_attack(caster: Champion, target: Entity) -> float:
	caster.passive_stacks += 1
	if caster.passive_stacks < attacks_required:
		return 0.0
	caster.passive_stacks = 0
	caster.heal(caster.max_health * heal_max_health_ratio)
	if Game.current:
		Game.current.play_fx("impact", target.global_position, {"color": color, "radius": 1.2})
	return bonus_damage + bonus_damage_per_level * float(caster.level - 1) + caster.max_health * bonus_max_health_ratio


func build_tooltip(caster: Champion) -> String:
	var text: String = super.build_tooltip(caster)
	if caster:
		var bonus: float = bonus_damage + bonus_damage_per_level * float(caster.level - 1) + caster.max_health * bonus_max_health_ratio
		text += "\nCurrent bonus damage: [b]%d[/b], heal: [b]%d[/b]" % [roundi(bonus), roundi(caster.max_health * heal_max_health_ratio)]
	return text
