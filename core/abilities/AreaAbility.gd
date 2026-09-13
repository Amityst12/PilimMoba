class_name AreaAbility
extends AbilityData
## Circular area of effect at the cursor or around the caster, with optional delay and ticks.

enum Center { POINT, SELF }

@export_group("Area")
@export var center: Center = Center.POINT
@export var radius: float = 3.0
## Telegraph time before the first hit.
@export var delay: float = 0.6
@export var ticks: int = 1
@export var tick_interval: float = 0.5


func _init() -> void:
	targeting = Targeting.POINT


func execute(caster: Champion, rank: int, target_pos: Vector3, _target: Entity) -> void:
	var game := Game.current
	if game == null:
		return
	var position: Vector3 = caster.flat_position() if center == Center.SELF else clamp_point(caster, target_pos)
	var damage: float = compute_damage(caster, rank)
	var team: int = caster.team
	var area: AreaEffect = game.spawn_area_effect({
		"style": String(fx_style),
		"pos": position,
		"radius": radius,
		"delay": delay,
		"ticks": maxi(1, ticks),
		"interval": tick_interval,
		"team": team,
		"color": color,
	})
	if area:
		area.on_tick = func(effect: AreaEffect, _index: int) -> void:
			for enemy: Entity in Game.current.find_enemies_in_radius(team, effect.global_position, radius):
				hit_target(caster, enemy, rank, damage)
	apply_self_effects(caster, rank)


func _tooltip_lines(_caster: Champion, _rank: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	if ticks > 1:
		lines.append("Hits %d times over %.1fs (damage per hit)." % [ticks, tick_interval * float(ticks - 1)])
	if delay > 0.05:
		lines.append("Detonates after %.2gs." % delay)
	return lines
