class_name AbilityData
extends Resource
## Base class for an active ability (Q / W / E / R).
##
## An AbilityData is a *stateless definition* shared by every champion using it.
## Per-champion runtime state (rank, cooldown, stacks) lives on the Champion.
## Subclasses implement `execute()` which always runs on the server.

enum Targeting {
	NONE,       ## Cast instantly on self (no aiming).
	DIRECTION,  ## Skillshot towards the cursor.
	POINT,      ## Ground target (clamped to cast range).
	UNIT,       ## Point-and-click on an enemy unit (walks into range).
}

@export var id: StringName = &""
@export var display_name: String = "Ability"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var color: Color = Color(0.4, 0.7, 1.0)

@export_group("Casting")
@export var targeting: Targeting = Targeting.DIRECTION
@export var cast_range: float = 10.0
## Wind-up before the ability fires. The champion stops and faces the target.
@export var cast_time: float = 0.0
@export var max_rank: int = 5
@export var is_ultimate: bool = false
@export var cooldown: PackedFloat32Array = PackedFloat32Array([8.0])
@export var mana_cost: PackedFloat32Array = PackedFloat32Array([50.0])
## Movement abilities cannot be used while rooted.
@export var blocked_by_root: bool = false
## Width of the skillshot indicator (DIRECTION) or radius of the area indicator (POINT / NONE).
@export var indicator_size: float = 1.0

@export_group("Damage")
@export var base_damage: PackedFloat32Array = PackedFloat32Array()
@export var ad_ratio: float = 0.0
@export var ap_ratio: float = 0.0
@export var damage_type: GameConst.DamageType = GameConst.DamageType.MAGIC
## Status effects applied to every enemy hit.
@export var target_effects: Array[StatusEffectData] = []
## Status effects applied to the caster when the ability resolves.
@export var self_effects: Array[StatusEffectData] = []

@export_group("Presentation")
## Visual preset used by spawned projectiles / areas (see FxStyles).
@export var fx_style: StringName = &""
@export var cast_sound: StringName = &"cast"


static func rank_value(values: PackedFloat32Array, rank: int) -> float:
	if values.is_empty():
		return 0.0
	return values[clampi(rank - 1, 0, values.size() - 1)]


func get_cooldown(rank: int) -> float:
	return rank_value(cooldown, rank)


func get_mana_cost(rank: int) -> float:
	return rank_value(mana_cost, rank)


func compute_damage(caster: Champion, rank: int) -> float:
	if base_damage.is_empty() and ad_ratio == 0.0 and ap_ratio == 0.0:
		return 0.0
	return rank_value(base_damage, rank) + caster.attack_damage * ad_ratio + caster.ability_power * ap_ratio


## Deals this ability's damage and target effects to one enemy (server only).
func hit_target(caster: Champion, target: Entity, rank: int, damage: float, multiplier: float = 1.0) -> void:
	if not is_instance_valid(target) or target.dead:
		return
	if damage > 0.0:
		target.take_damage(damage * multiplier, damage_type, caster if is_instance_valid(caster) else null, true)
	if not target.dead and not target.is_structure():
		target.apply_effects(target_effects, rank, caster if is_instance_valid(caster) else null)


func apply_self_effects(caster: Champion, rank: int) -> void:
	if is_instance_valid(caster) and not caster.dead:
		caster.apply_effects(self_effects, rank, caster)


## Direction on the ground plane from the caster towards `target_pos` (falls back to facing).
static func aim_direction(caster: Entity, target_pos: Vector3) -> Vector3:
	var dir := Vector3(target_pos.x - caster.global_position.x, 0.0, target_pos.z - caster.global_position.z)
	if dir.length_squared() < 0.01:
		var yaw: float = caster.visual.rotation.y if caster.visual else 0.0
		dir = Vector3(-sin(yaw), 0.0, -cos(yaw))
	return dir.normalized()


## Clamps a ground point to the ability range around the caster.
func clamp_point(caster: Entity, target_pos: Vector3) -> Vector3:
	var origin: Vector3 = caster.flat_position()
	var offset := Vector3(target_pos.x, 0.0, target_pos.z) - origin
	if offset.length() > cast_range:
		offset = offset.normalized() * cast_range
	return origin + offset


## Server-side effect of the ability. Override in subclasses.
func execute(_caster: Champion, _rank: int, _target_pos: Vector3, _target: Entity) -> void:
	push_warning("Ability %s has no execute() implementation" % id)


## Extra tooltip lines specific to the ability type.
func _tooltip_lines(_caster: Champion, _rank: int) -> PackedStringArray:
	return PackedStringArray()


## BBCode tooltip used by the HUD. `caster` may be null (e.g. in the lobby).
func build_tooltip(caster: Champion, rank: int) -> String:
	var shown_rank: int = maxi(rank, 1)
	var lines: PackedStringArray = []
	var header: String = "[b][color=#%s]%s[/color][/b]" % [color.lightened(0.3).to_html(false), display_name]
	if rank > 0:
		header += "  [color=#9aa4b2](rank %d/%d)[/color]" % [rank, max_rank]
	lines.append(header)
	var cost: float = get_mana_cost(shown_rank)
	var meta: String = "[color=#8fb8ff]%d mana[/color]   [color=#c8c8c8]%.1fs cooldown[/color]" % [roundi(cost), get_cooldown(shown_rank)]
	if targeting != Targeting.NONE:
		meta += "   [color=#c8c8c8]range %.0f[/color]" % cast_range
	lines.append(meta)
	lines.append(description)
	if not base_damage.is_empty():
		var dmg_text: String = "Damage: [b]%d[/b]" % roundi(rank_value(base_damage, shown_rank))
		if caster:
			dmg_text = "Damage: [b]%d[/b]" % roundi(compute_damage(caster, shown_rank))
		var ratios: PackedStringArray = []
		if ad_ratio > 0.0:
			ratios.append("[color=#ffb060]+%d%% AD[/color]" % roundi(ad_ratio * 100.0))
		if ap_ratio > 0.0:
			ratios.append("[color=#a0a8ff]+%d%% AP[/color]" % roundi(ap_ratio * 100.0))
		if not ratios.is_empty():
			dmg_text += " (" + ", ".join(ratios) + ")"
		dmg_text += " %s" % ["physical", "magic", "true"][damage_type]
		lines.append(dmg_text)
	for effect: StatusEffectData in target_effects:
		lines.append("On hit: " + effect.describe(shown_rank))
	for effect: StatusEffectData in self_effects:
		lines.append("Self: " + effect.describe(shown_rank))
	lines.append_array(_tooltip_lines(caster, shown_rank))
	if is_ultimate:
		lines.append("[color=#9aa4b2]Ranks unlock at levels %s[/color]" % ", ".join(GameConst.ULT_RANK_LEVELS.map(func(l: int) -> String: return str(l))))
	return "\n".join(lines)
