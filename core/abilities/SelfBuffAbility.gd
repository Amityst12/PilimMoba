class_name SelfBuffAbility
extends AbilityData
## Instant self-cast: shield, heal and/or buffs.

@export_group("Buff")
@export var shield_amount: PackedFloat32Array = PackedFloat32Array()
@export var shield_max_health_ratio: float = 0.0
@export var shield_duration: float = 3.0
@export var heal_amount: PackedFloat32Array = PackedFloat32Array()
@export var heal_ap_ratio: float = 0.0


func _init() -> void:
	targeting = Targeting.NONE


func get_shield_value(caster: Champion, rank: int) -> float:
	var value: float = rank_value(shield_amount, rank)
	if caster:
		value += caster.max_health * shield_max_health_ratio
	return value


func execute(caster: Champion, rank: int, _target_pos: Vector3, _target: Entity) -> void:
	var shield_value: float = get_shield_value(caster, rank)
	if shield_value > 0.0:
		caster.apply_status(GameConst.Status.SHIELD, shield_value, shield_duration, caster)
	var heal_value: float = rank_value(heal_amount, rank) + caster.ability_power * heal_ap_ratio
	if heal_value > 0.0:
		caster.heal(heal_value)
	apply_self_effects(caster, rank)
	if Game.current:
		Game.current.play_fx("buff", caster.global_position, {"color": color})


func _tooltip_lines(caster: Champion, rank: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	if not shield_amount.is_empty() or shield_max_health_ratio > 0.0:
		var text: String = "Shield: [b]%d[/b]" % roundi(get_shield_value(caster, rank))
		if shield_max_health_ratio > 0.0:
			text += " ([color=#80e080]+%d%% max health[/color])" % roundi(shield_max_health_ratio * 100.0)
		lines.append(text + " for %.1fs" % shield_duration)
	if not heal_amount.is_empty():
		lines.append("Heals [b]%d[/b]" % roundi(rank_value(heal_amount, rank)))
	return lines
