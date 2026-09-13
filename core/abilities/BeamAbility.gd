class_name BeamAbility
extends AbilityData
## Charges then fires a long rectangular beam in the aimed direction, hitting every enemy in it.

@export_group("Beam")
@export var beam_length: float = 18.0
@export var beam_width: float = 3.0
@export var charge_time: float = 0.6
## Root the caster while charging (commits to the cast).
@export var root_caster: bool = true


func _init() -> void:
	targeting = Targeting.DIRECTION


func execute(caster: Champion, rank: int, target_pos: Vector3, _target: Entity) -> void:
	var game := Game.current
	if game == null:
		return
	var dir: Vector3 = aim_direction(caster, target_pos)
	var origin: Vector3 = caster.flat_position()
	var damage: float = compute_damage(caster, rank)
	var team: int = caster.team
	var beam: BeamEffect = game.spawn_beam({
		"style": String(fx_style),
		"pos": origin,
		"dir": dir,
		"length": beam_length,
		"width": beam_width,
		"charge": charge_time,
		"team": team,
		"color": color,
	})
	if root_caster:
		caster.apply_status(GameConst.Status.ROOT, 0.0, charge_time + 0.15, caster)
	if beam:
		beam.on_fire = func(_b: BeamEffect) -> void:
			for enemy: Entity in Game.current.find_enemies_on_segment(team, origin, origin + dir * beam_length, beam_width * 0.5):
				hit_target(caster, enemy, rank, damage)
	apply_self_effects(caster, rank)


func _tooltip_lines(_caster: Champion, _rank: int) -> PackedStringArray:
	return PackedStringArray(["Charges for %.2gs, then fires a %d-unit beam." % [charge_time, roundi(beam_length)]])
