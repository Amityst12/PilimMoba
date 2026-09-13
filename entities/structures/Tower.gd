class_name Tower
extends Entity
## Defensive turret. Shoots minions first, but switches to enemy champions that attack
## allied champions within its range. Consecutive shots on the same champion deal more damage.

const TOWER_RANGE: float = 9.0
const CHAMPION_DAMAGE: float = 170.0
const WARMUP_BONUS_PER_SHOT: float = 0.35
const MAX_WARMUP_SHOTS: int = 3

# Replicated
var tier: int = 1
var target_id: int = -1

# Server
var _aggro_champion_id: int = -1
var _aggro_until: float = 0.0
var _last_shot_target: int = -1
var _consecutive_shots: int = 0


func _ready() -> void:
	mobile = false
	radius = 1.25
	bar_height = 5.2
	attack_range = TOWER_RANGE - radius
	attack_projectile_style = &"tower_shot"
	attack_projectile_speed = 17.0
	attack_windup_ratio = 0.12
	base_attack_speed = 0.83
	armor = 45.0
	magic_resist = 45.0
	max_health = 3000.0 if tier == 1 else 3600.0
	if multiplayer.is_server():
		health = max_health
	super._ready()
	if visual:
		visual.add_child(StructureModel.build_tower(team))


func get_kind() -> Kind:
	return Kind.TOWER


func get_display_name() -> String:
	return "%s %s Tower" % [GameConst.team_name(team), "Outer" if tier == 1 else "Inner"]


func is_vulnerable() -> bool:
	return Game.current == null or Game.current.is_structure_vulnerable(self)


## Called when an enemy champion damages an allied champion.
func notify_champion_attacked(attacker: Entity, victim: Entity, now: float) -> void:
	if dead or attacker.team == team:
		return
	if planar_distance_to_point(attacker.global_position) <= TOWER_RANGE + attacker.radius \
			and planar_distance_to_point(victim.global_position) <= TOWER_RANGE + 4.0:
		_aggro_champion_id = attacker.net_id
		_aggro_until = now + 3.0


func _server_tick(_delta: float, now: float) -> void:
	process_attack_windup(now)
	var target: Entity = _pick_target(now)
	target_id = target.net_id if target else -1
	if target and can_start_attack(now):
		begin_attack(target, now)


func _pick_target(now: float) -> Entity:
	var game := Game.current
	if _aggro_champion_id >= 0 and now < _aggro_until:
		var aggro: Entity = game.get_entity(_aggro_champion_id)
		if aggro and aggro.is_targetable_by(team) and in_attack_range(aggro):
			return aggro
	var current: Entity = game.get_entity(target_id)
	if current and current.is_targetable_by(team) and in_attack_range(current):
		return current
	var best: Entity = null
	var best_distance: float = INF
	for minion: Entity in game.minions:
		if minion.is_targetable_by(team) and in_attack_range(minion):
			var d: float = edge_distance_to(minion)
			if d < best_distance:
				best_distance = d
				best = minion
	if best:
		return best
	for champion: Entity in game.champions:
		if champion.is_targetable_by(team) and in_attack_range(champion):
			var d: float = edge_distance_to(champion)
			if d < best_distance:
				best_distance = d
				best = champion
	return best


func deliver_attack(target: Entity) -> void:
	if target is Minion:
		var fraction: float = 0.45 if (target as Minion).minion_type == Minion.MinionType.MELEE else 0.7
		target.take_damage(target.max_health * fraction, GameConst.DamageType.TRUE, self, false)
		_consecutive_shots = 0
		_last_shot_target = target.net_id
		return
	if target.net_id == _last_shot_target:
		_consecutive_shots = mini(_consecutive_shots + 1, MAX_WARMUP_SHOTS)
	else:
		_consecutive_shots = 0
	_last_shot_target = target.net_id
	var damage: float = CHAMPION_DAMAGE * (1.0 + WARMUP_BONUS_PER_SHOT * float(_consecutive_shots))
	target.take_damage(damage, GameConst.DamageType.PHYSICAL, self, false)


func _modify_incoming_damage(amount: float, _source: Entity, _damage_type: int) -> float:
	# Backdoor protection: structures take much less damage without enemy minions nearby.
	var game := Game.current
	if game:
		for minion: Entity in game.minions:
			if minion.team != team and not minion.dead \
					and planar_distance_to_point(minion.global_position) < GameConst.BACKDOOR_MINION_RADIUS:
				return amount
	return amount * (1.0 - GameConst.BACKDOOR_REDUCTION)


func _on_death(_killer: Entity) -> void:
	target_id = -1


func _on_dead_changed() -> void:
	# Towers leave rubble behind instead of disappearing.
	var model: Node = visual.get_child(0) if visual and visual.get_child_count() > 0 else null
	if model and model.has_method("set_destroyed"):
		model.set_destroyed(dead)


func _update_presentation(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
