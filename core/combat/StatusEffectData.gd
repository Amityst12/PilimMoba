class_name StatusEffectData
extends Resource
## Declarative description of a status effect applied by an ability or passive.

@export var kind: GameConst.Status = GameConst.Status.SLOW
## Meaning depends on kind: slow/haste/attack-speed fraction, shield amount, empower damage.
@export var value: float = 0.3
## Optional per-rank override for value (index = rank - 1). Empty = use `value`.
@export var value_per_rank: PackedFloat32Array = PackedFloat32Array()
@export var duration: float = 1.5


func get_value(rank: int) -> float:
	if value_per_rank.is_empty():
		return value
	return value_per_rank[clampi(rank - 1, 0, value_per_rank.size() - 1)]


static func make(p_kind: GameConst.Status, p_value: float, p_duration: float) -> StatusEffectData:
	var effect := StatusEffectData.new()
	effect.kind = p_kind
	effect.value = p_value
	effect.duration = p_duration
	return effect


func describe(rank: int) -> String:
	var v: float = get_value(rank)
	match kind:
		GameConst.Status.SLOW:
			return "slows by %d%% for %.1fs" % [roundi(v * 100.0), duration]
		GameConst.Status.HASTE:
			return "+%d%% move speed for %.1fs" % [roundi(v * 100.0), duration]
		GameConst.Status.STUN:
			return "stuns for %.2gs" % duration
		GameConst.Status.ROOT:
			return "roots for %.2gs" % duration
		GameConst.Status.SHIELD:
			return "shield of %d for %.1fs" % [roundi(v), duration]
		GameConst.Status.ATTACK_SPEED:
			return "+%d%% attack speed for %.1fs" % [roundi(v * 100.0), duration]
		GameConst.Status.EMPOWER:
			return "next attack deals +%d damage" % roundi(v)
		GameConst.Status.UNTARGETABLE:
			return "untargetable for %.2gs" % duration
	return ""
