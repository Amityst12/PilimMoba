class_name BotBrain
extends RefCounted
## Server-side AI for bot champions. Uses exactly the same order / cast API as human players,
## so bots follow every gameplay rule (cooldowns, mana, range, validation).
##
## Priorities each think tick: survive (retreat / recall) > shop & level up > fight champions
## when favourable > last-hit & push minions > siege structures with minion cover > hold lane.

const THINK_INTERVAL: float = 0.25
const SIGHT_RANGE: float = 13.0

var champion: Champion
var _think_timer: float = randf() * THINK_INTERVAL
var _retreating: bool = false
var _next_cast_time: float = 0.0
var _lane_offset: float = randf_range(-3.5, 3.5)
var _reaction_delay: float = randf_range(0.15, 0.4)


func _init(owner: Champion) -> void:
	champion = owner


func on_level_up() -> void:
	_spend_skill_points()


func think(delta: float, now: float) -> void:
	_think_timer -= delta
	if _think_timer > 0.0:
		return
	_think_timer = THINK_INTERVAL + randf() * 0.08
	var game := Game.current
	if game == null or champion.dead:
		return
	_spend_skill_points()
	if champion.can_shop():
		_shop()

	var enemy_champions: Array[Champion] = _enemy_champions_near(SIGHT_RANGE)
	var enemy_tower: Tower = _nearest_enemy_tower(Tower.TOWER_RANGE + 6.0)
	var hp: float = champion.health_fraction()
	var tower_on_me: bool = enemy_tower != null and enemy_tower.target_id == champion.net_id

	# --- Survival ------------------------------------------------------------------------
	if hp < 0.28 or (tower_on_me and hp < 0.8):
		_retreating = true
	elif hp > 0.7:
		_retreating = false
	if champion.is_recalling():
		if not enemy_champions.is_empty() and hp > 0.1:
			_retreat(enemy_champions, now)
		return
	if _retreating or tower_on_me:
		_retreat(enemy_champions, now)
		return
	if game.is_in_fountain(champion) and (hp < 0.9 or champion.mana_fraction() < 0.5):
		if champion.order != Champion.Order.IDLE:
			champion.order_stop()
		return
	if champion.gold >= _next_item_cost() + 350 and enemy_champions.is_empty() and hp < 0.6 \
			and not game.is_in_fountain(champion):
		champion.start_recall()
		return

	# --- Champion fights --------------------------------------------------------------------
	var target: Champion = _choose_champion_target(enemy_champions)
	if target:
		var target_under_tower: bool = _is_under_enemy_tower(target.global_position)
		var allied_minions_tanking: bool = _allied_minions_near(target.global_position, 8.0) >= 2
		var safe_to_dive: bool = not target_under_tower or (target.health_fraction() < 0.25 and hp > 0.5) \
				or (allied_minions_tanking and hp > 0.6)
		if safe_to_dive and _should_fight(target, enemy_champions):
			_use_abilities(target, enemy_champions, now)
			if champion.order != Champion.Order.ATTACK or champion.order_target_id != target.net_id:
				champion.order_attack(target)
			return
		# Poke from range without committing.
		_use_poke_abilities(target, now)

	# --- Minions ----------------------------------------------------------------------------
	var minion: Minion = _choose_minion_target(enemy_tower)
	if minion:
		if champion.order != Champion.Order.ATTACK or champion.order_target_id != minion.net_id:
			champion.order_attack(minion)
		_use_waveclear(minion, now)
		return

	# --- Structures ---------------------------------------------------------------------------
	var structure: Entity = _choose_structure_target()
	if structure:
		if champion.order != Champion.Order.ATTACK or champion.order_target_id != structure.net_id:
			champion.order_attack(structure)
		return

	# --- Hold the lane ----------------------------------------------------------------------------
	var hold: Vector3 = _lane_hold_position()
	if champion.planar_distance_to_point(hold) > 2.5:
		if champion.order != Champion.Order.MOVE or champion.order_point.distance_to(hold) > 3.0:
			champion.order_move(hold)
	elif champion.order == Champion.Order.MOVE:
		champion.order_stop()


# --- Decisions ---------------------------------------------------------------------------------------

func _should_fight(target: Champion, enemies: Array[Champion]) -> bool:
	var hp: float = champion.health_fraction()
	var allies: int = _allied_champions_near(champion.global_position, 12.0)
	var odds: float = float(allies + 1) - float(enemies.size())
	var power: float = hp * (1.0 + float(champion.level) * 0.08) - target.health_fraction() * (1.0 + float(target.level) * 0.08)
	return target.health_fraction() < 0.35 or power + odds * 0.25 > -0.05


func _choose_champion_target(enemies: Array[Champion]) -> Champion:
	var best: Champion = null
	var best_score: float = INF
	for enemy: Champion in enemies:
		var score: float = enemy.health + champion.planar_distance_to_point(enemy.global_position) * 40.0
		if score < best_score:
			best_score = score
			best = enemy
	return best


func _choose_minion_target(enemy_tower: Tower) -> Minion:
	var game := Game.current
	var best_last_hit: Minion = null
	var best_push: Minion = null
	var push_distance: float = INF
	var reach: float = champion.attack_range + 5.0
	for minion: Minion in game.minions:
		if not minion.is_targetable_by(champion.team):
			continue
		var d: float = champion.edge_distance_to(minion)
		if d > reach + 3.0:
			continue
		if enemy_tower and _is_under_enemy_tower(minion.global_position) and not _tower_busy_with_minions(enemy_tower):
			continue
		var expected: float = GameConst.mitigate(champion.attack_damage, minion.armor)
		if minion.health <= expected * 1.05 and d <= reach:
			if best_last_hit == null or minion.health < best_last_hit.health:
				best_last_hit = minion
		elif d < push_distance:
			push_distance = d
			best_push = minion
	if best_last_hit:
		return best_last_hit
	# Push only when no enemy champion is threatening, otherwise wait for last hits.
	if best_push and push_distance <= reach and _enemy_champions_near(10.0).is_empty():
		return best_push
	if best_push and push_distance <= champion.attack_range + 0.5:
		return best_push
	return null


func _choose_structure_target() -> Entity:
	var game := Game.current
	for structure: Entity in game.structures:
		if not structure.is_targetable_by(champion.team):
			continue
		if champion.planar_distance_to_point(structure.global_position) > 14.0:
			continue
		if structure is Tower and not _tower_busy_with_minions(structure as Tower) and champion.health_fraction() < 0.9:
			continue
		if _allied_minions_near(structure.global_position, 11.0) == 0 and structure is Tower:
			continue
		return structure
	return null


func _lane_hold_position() -> Vector3:
	var game := Game.current
	var direction: float = 1.0 if champion.team == GameConst.TEAM_BLUE else -1.0
	var front: float = -INF
	for minion: Minion in game.minions:
		if minion.team == champion.team and not minion.dead:
			front = maxf(front, minion.global_position.x * direction)
	var fallback: float = -INF
	for structure: Entity in game.structures:
		if structure is Tower and structure.team == champion.team and not structure.dead:
			fallback = maxf(fallback, structure.global_position.x * direction)
	if fallback == -INF:
		fallback = -Arena.NEXUS_X + 6.0
	var hold_x: float = (front - 3.0) if front > -INF else fallback + 4.0
	# Never stand inside an enemy tower range without minion cover.
	for structure: Entity in game.structures:
		if structure is Tower and structure.team != champion.team and not structure.dead:
			var tower_x: float = structure.global_position.x * direction
			if not _tower_busy_with_minions(structure as Tower):
				hold_x = minf(hold_x, tower_x - Tower.TOWER_RANGE - 2.0)
	return Vector3(hold_x * direction, 0.0, _lane_offset)


# --- Abilities ----------------------------------------------------------------------------------------------

func _use_abilities(target: Champion, enemies: Array[Champion], now: float) -> void:
	if now < _next_cast_time:
		return
	for slot: int in [3, 0, 2, 1]:
		if _try_ability(slot, target, enemies, now, true):
			_next_cast_time = now + _reaction_delay
			return


func _use_poke_abilities(target: Champion, now: float) -> void:
	if now < _next_cast_time or champion.mana_fraction() < 0.35:
		return
	for slot: int in [0, 2]:
		var ability: AbilityData = champion.get_ability(slot)
		if ability and (ability is ProjectileAbility or ability is AreaAbility) and _try_ability(slot, target, [target], now, false):
			_next_cast_time = now + _reaction_delay + 0.6
			return


func _use_waveclear(minion: Minion, now: float) -> void:
	if now < _next_cast_time or champion.mana_fraction() < 0.7:
		return
	var nearby: int = Game.current.find_enemies_in_radius(champion.team, minion.global_position, 3.5).size()
	if nearby < 3:
		return
	for slot: int in [0, 2]:
		var ability: AbilityData = champion.get_ability(slot)
		if ability is AreaAbility or (ability is ProjectileAbility and (ability as ProjectileAbility).pierce):
			if _try_ability(slot, minion, [], now, false):
				_next_cast_time = now + 1.5
				return


func _try_ability(slot: int, target: Entity, enemies: Array, now: float, committed: bool) -> bool:
	var ability: AbilityData = champion.get_ability(slot)
	if ability == null or champion.ability_ranks[slot] <= 0:
		return false
	if champion.cooldown_ends[slot] > now or champion.mana < ability.get_mana_cost(champion.ability_ranks[slot]):
		return false
	var distance: float = champion.planar_distance_to_point(target.global_position)
	var target_hp: float = target.health_fraction()
	if ability.is_ultimate and target_hp > 0.65 and enemies.size() < 2:
		return false
	var cast_point: Vector3 = target.global_position
	if ability is ProjectileAbility:
		var projectile := ability as ProjectileAbility
		if distance > ability.cast_range * 0.92:
			return false
		cast_point = _predict(target, distance / maxf(projectile.projectile_speed, 1.0))
	elif ability is BeamAbility:
		var beam := ability as BeamAbility
		if distance > beam.beam_length * 0.85:
			return false
		cast_point = _predict(target, beam.charge_time * 0.8)
	elif ability is AreaAbility:
		var area := ability as AreaAbility
		if area.center == AreaAbility.Center.SELF:
			if distance > area.radius + target.radius * 0.5:
				return false
		else:
			if distance > ability.cast_range + area.radius * 0.5:
				return false
			cast_point = _predict(target, area.delay)
	elif ability is DashAbility:
		var dash := ability as DashAbility
		match dash.mode:
			DashAbility.Mode.TARGET_DASH:
				if distance > ability.cast_range + target.radius:
					return false
			DashAbility.Mode.LEAP:
				if not committed or distance > ability.cast_range:
					return false
			DashAbility.Mode.BLINK, DashAbility.Mode.DASH:
				# Gap close only when the target is just out of attack range and low.
				if not committed or target_hp > 0.5 or distance < champion.attack_range + 1.0 or distance > champion.attack_range + 6.0:
					return false
	elif ability is SelfBuffAbility:
		if distance > 7.0 or champion.health_fraction() > 0.85:
			return false
	return champion.try_cast(slot, cast_point, target.net_id) == ""


func _predict(target: Entity, lead_time: float) -> Vector3:
	var predicted: Vector3 = target.global_position + target.net_velocity * clampf(lead_time, 0.0, 1.2)
	predicted.y = 0.0
	return predicted


func _retreat(enemies: Array[Champion], now: float) -> void:
	var game := Game.current
	var home: Vector3 = Arena.fountain_position(champion.team)
	var threatened: bool = not enemies.is_empty() or _nearest_enemy_tower(Tower.TOWER_RANGE + 1.0) != null
	if not threatened and not champion.is_recalling() and not game.is_in_fountain(champion) \
			and champion.planar_distance_to_point(home) > 25.0:
		if champion.order != Champion.Order.IDLE:
			champion.order_stop()
		champion.start_recall()
		return
	# Escape with movement abilities when chased.
	if not enemies.is_empty() and now >= _next_cast_time:
		for slot: int in range(4):
			var ability: AbilityData = champion.get_ability(slot)
			if ability is DashAbility and (ability as DashAbility).mode in [DashAbility.Mode.BLINK, DashAbility.Mode.DASH]:
				var toward_home: Vector3 = champion.flat_position() + (home - champion.flat_position()).normalized() * 8.0
				if champion.cooldown_ends[slot] <= now and champion.try_cast(slot, toward_home, -1) == "":
					_next_cast_time = now + 0.5
					break
			elif ability is SelfBuffAbility and champion.cooldown_ends[slot] <= now:
				if champion.try_cast(slot, champion.global_position, -1) == "":
					_next_cast_time = now + 0.5
					break
	if champion.order != Champion.Order.MOVE or champion.order_point.distance_to(home) > 1.0:
		champion.order_move(home)


# --- Economy --------------------------------------------------------------------------------------------------

func _spend_skill_points() -> void:
	var guard: int = 0
	while champion.skill_points > 0 and guard < 8:
		guard += 1
		if champion.can_level_ability(3):
			champion.level_ability(3)
			continue
		var leveled: bool = false
		for slot: int in champion.data.bot_skill_priority:
			if champion.can_level_ability(slot):
				champion.level_ability(slot)
				leveled = true
				break
		if not leveled:
			for slot: int in range(3):
				if champion.can_level_ability(slot):
					champion.level_ability(slot)
					leveled = true
					break
		if not leveled:
			break


func _next_item_id() -> String:
	var owned: Dictionary = {}
	for item_id: String in champion.items:
		owned[item_id] = int(owned.get(item_id, 0)) + 1
	for item_id: String in champion.data.bot_item_build:
		if int(owned.get(item_id, 0)) > 0:
			owned[item_id] = int(owned[item_id]) - 1
			continue
		return item_id
	return ""


func _next_item_cost() -> int:
	var item_id: String = _next_item_id()
	return ItemDB.cost(item_id) if item_id != "" else 999999


func _shop() -> void:
	for i: int in range(3):
		if champion.items.size() >= GameConst.INVENTORY_SIZE:
			return
		var item_id: String = _next_item_id()
		if item_id == "" or champion.gold < ItemDB.cost(item_id):
			return
		champion.buy_item(item_id)


# --- Helpers -------------------------------------------------------------------------------------------------

func _enemy_champions_near(search_range: float) -> Array[Champion]:
	var result: Array[Champion] = []
	for other: Champion in Game.current.champions:
		if other.is_targetable_by(champion.team) and champion.planar_distance_to_point(other.global_position) <= search_range:
			result.append(other)
	return result


func _allied_champions_near(point: Vector3, search_range: float) -> int:
	var count: int = 0
	for other: Champion in Game.current.champions:
		if other != champion and other.team == champion.team and not other.dead \
				and other.planar_distance_to_point(point) <= search_range:
			count += 1
	return count


func _allied_minions_near(point: Vector3, search_range: float) -> int:
	var count: int = 0
	for minion: Minion in Game.current.minions:
		if minion.team == champion.team and not minion.dead and minion.planar_distance_to_point(point) <= search_range:
			count += 1
	return count


func _nearest_enemy_tower(search_range: float) -> Tower:
	for structure: Entity in Game.current.structures:
		if structure is Tower and structure.team != champion.team and not structure.dead \
				and champion.planar_distance_to_point(structure.global_position) <= search_range:
			return structure as Tower
	return null


func _is_under_enemy_tower(point: Vector3) -> bool:
	for structure: Entity in Game.current.structures:
		if structure is Tower and structure.team != champion.team and not structure.dead \
				and structure.planar_distance_to_point(point) <= Tower.TOWER_RANGE + 0.5:
			return true
	return false


func _tower_busy_with_minions(tower: Tower) -> bool:
	var target: Entity = Game.current.get_entity(tower.target_id)
	return target is Minion or _allied_minions_near(tower.global_position, Tower.TOWER_RANGE) >= 2
