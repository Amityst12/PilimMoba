class_name AttackStackPassive
extends PassiveData
## Basic attacks grant stacking attack speed. At max stacks the champion also gains move speed.

@export var attack_speed_per_stack: float = 0.1
@export var stack_duration: float = 3.5
@export var full_stack_haste: float = 0.12
@export var stack_limit: int = 5


func get_max_stacks() -> int:
	return stack_limit


func on_basic_attack(caster: Champion, _target: Entity) -> float:
	caster.passive_stacks = mini(stack_limit, caster.passive_stacks + 1)
	caster.passive_timer = stack_duration
	caster.apply_status(GameConst.Status.ATTACK_SPEED, attack_speed_per_stack * caster.passive_stacks,
			stack_duration, caster, &"passive_attack_speed")
	if caster.passive_stacks >= stack_limit and full_stack_haste > 0.0:
		caster.apply_status(GameConst.Status.HASTE, full_stack_haste, stack_duration, caster, &"passive_haste")
	return 0.0


func on_tick(caster: Champion, delta: float) -> void:
	if caster.passive_timer > 0.0:
		caster.passive_timer -= delta
		if caster.passive_timer <= 0.0:
			caster.passive_stacks = 0
