class_name ProjectileAbility
extends AbilityData
## Skillshot that fires one or more projectiles towards the cursor.
## Supports multi-projectile fans (volleys) and piercing projectiles.

@export_group("Projectile")
@export var projectile_count: int = 1
@export var spread_degrees: float = 0.0
@export var projectile_speed: float = 22.0
@export var projectile_width: float = 1.0
## Piercing projectiles continue after hitting a unit.
@export var pierce: bool = false
## Damage multiplier lost per unit already hit by a piercing projectile (0.15 = -15% per hit).
@export var pierce_falloff: float = 0.0
@export var min_pierce_multiplier: float = 0.4


func _init() -> void:
	targeting = Targeting.DIRECTION


func execute(caster: Champion, rank: int, target_pos: Vector3, _target: Entity) -> void:
	var game := Game.current
	if game == null:
		return
	var dir: Vector3 = aim_direction(caster, target_pos)
	var damage: float = compute_damage(caster, rank)
	# One shared registry: a volley hits each enemy at most once.
	var hit_registry: Dictionary = {}
	var count: int = maxi(1, projectile_count)
	for i: int in range(count):
		var angle: float = 0.0
		if count > 1:
			angle = deg_to_rad(lerpf(-spread_degrees * 0.5, spread_degrees * 0.5, float(i) / float(count - 1)))
		var shot_dir: Vector3 = dir.rotated(Vector3.UP, angle)
		var projectile: Projectile = game.spawn_projectile({
			"style": String(fx_style),
			"pos": caster.flat_position() + shot_dir * 0.6 + Vector3(0.0, 1.1, 0.0),
			"dir": shot_dir,
			"speed": projectile_speed,
			"range": cast_range,
			"radius": projectile_width * 0.5,
			"team": caster.team,
			"color": color,
		})
		if projectile == null:
			continue
		projectile.hit_ids = hit_registry
		var hits: Array[int] = [0]
		projectile.on_hit = func(_p: Projectile, hit: Entity) -> bool:
			var multiplier: float = maxf(min_pierce_multiplier, 1.0 - pierce_falloff * float(hits[0]))
			hits[0] += 1
			hit_target(caster, hit, rank, damage, multiplier)
			if Game.current:
				Game.current.play_fx("hit", hit.global_position + Vector3(0.0, 1.0, 0.0), {"color": color})
			return not pierce
	apply_self_effects(caster, rank)


func _tooltip_lines(_caster: Champion, _rank: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	if projectile_count > 1:
		lines.append("Fires %d projectiles in a %d° cone. Each enemy is hit once." % [projectile_count, roundi(spread_degrees)])
	if pierce:
		lines.append("Pierces through all enemies" + (" (-%d%% per hit)." % roundi(pierce_falloff * 100.0) if pierce_falloff > 0.0 else "."))
	return lines
