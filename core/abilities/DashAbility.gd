class_name DashAbility
extends AbilityData
## Mobility ability: dash, blink (teleport), leap (arc with landing impact) or dash-to-target.

enum Mode {
	DASH,         ## Fast movement in the aimed direction for a fixed distance.
	BLINK,        ## Instant teleport to the cursor (up to range).
	LEAP,         ## Airborne arc to a ground point, untargetable, impact on landing.
	TARGET_DASH,  ## Dash to an enemy unit and strike it on arrival.
}

@export_group("Movement")
@export var mode: Mode = Mode.DASH
@export var dash_distance: float = 5.0
@export var travel_speed: float = 24.0
@export var leap_duration: float = 0.7
@export var arc_height: float = 3.0
## Radius of the landing impact (LEAP). 0 = no impact.
@export var impact_radius: float = 0.0


func _init() -> void:
	blocked_by_root = true


func execute(caster: Champion, rank: int, target_pos: Vector3, target: Entity) -> void:
	var game := Game.current
	if game == null:
		return
	match mode:
		Mode.BLINK:
			_blink(game, caster, rank, target_pos)
		Mode.DASH:
			_dash(game, caster, rank, target_pos)
		Mode.LEAP:
			_leap(game, caster, rank, target_pos)
		Mode.TARGET_DASH:
			_target_dash(caster, rank, target)


func _blink(game: Game, caster: Champion, rank: int, target_pos: Vector3) -> void:
	var destination: Vector3 = game.clamp_to_navmesh(clamp_point(caster, target_pos))
	game.play_fx("blink", caster.global_position, {"color": color})
	caster.blink_to(destination)
	game.play_fx("blink", destination, {"color": color})
	apply_self_effects(caster, rank)


func _dash(game: Game, caster: Champion, rank: int, target_pos: Vector3) -> void:
	var dir: Vector3 = aim_direction(caster, target_pos)
	var destination: Vector3 = game.clamp_to_navmesh(caster.flat_position() + dir * dash_distance)
	var on_arrive := func() -> void:
		apply_self_effects(caster, rank)
	caster.start_dash({"mode": "dash", "to": destination, "speed": travel_speed, "on_arrive": on_arrive})
	game.play_fx("dash", caster.global_position, {"color": color})


func _leap(game: Game, caster: Champion, rank: int, target_pos: Vector3) -> void:
	var destination: Vector3 = game.clamp_to_navmesh(clamp_point(caster, target_pos))
	var damage: float = compute_damage(caster, rank)
	var team: int = caster.team
	var on_arrive := func() -> void:
		apply_self_effects(caster, rank)
	caster.start_dash({
		"mode": "leap",
		"to": destination,
		"duration": leap_duration,
		"arc": arc_height,
		"untargetable": true,
		"on_arrive": on_arrive,
	})
	if impact_radius <= 0.0:
		return
	# The landing telegraph warns enemies where the champion will land.
	var area: AreaEffect = game.spawn_area_effect({
		"style": String(fx_style),
		"pos": destination,
		"radius": impact_radius,
		"delay": leap_duration,
		"ticks": 1,
		"interval": 0.0,
		"team": team,
		"color": color,
	})
	if area:
		var on_tick := func(effect: AreaEffect, _index: int) -> void:
			for enemy: Entity in Game.current.find_enemies_in_radius(team, effect.global_position, impact_radius):
				hit_target(caster, enemy, rank, damage)
		area.on_tick = on_tick


func _target_dash(caster: Champion, rank: int, target: Entity) -> void:
	if target == null:
		return
	var damage: float = compute_damage(caster, rank)
	var target_id: int = target.net_id
	var on_arrive := func() -> void:
		var victim: Entity = Game.current.get_entity(target_id) if Game.current else null
		if victim and victim.is_targetable_by(caster.team):
			hit_target(caster, victim, rank, damage)
			Game.current.play_fx("impact", victim.global_position, {"color": color, "radius": 1.6})
			if not caster.dead:
				caster.order_attack(victim)
		apply_self_effects(caster, rank)
	caster.start_dash({
		"mode": "target",
		"target_id": target_id,
		"speed": travel_speed,
		"max_time": 1.2,
		"on_arrive": on_arrive,
	})


func _tooltip_lines(_caster: Champion, _rank: int) -> PackedStringArray:
	var lines: PackedStringArray = []
	match mode:
		Mode.BLINK:
			lines.append("Teleports up to %.1f units." % cast_range)
		Mode.DASH:
			lines.append("Dashes %.1f units." % dash_distance)
		Mode.LEAP:
			lines.append("Leaps up to %.1f units, untargetable while airborne." % cast_range)
		Mode.TARGET_DASH:
			lines.append("Dashes to the target enemy.")
	return lines
