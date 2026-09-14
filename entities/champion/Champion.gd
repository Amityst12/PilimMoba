class_name Champion
extends Entity
## A player- or bot-controlled champion.
##
## Server: executes orders (move / attack / attack-move / cast), validates every command,
## handles leveling, items, recall and respawn.
## Clients: render the model and read the replicated state for HUD / overhead bars.

enum Order { IDLE, MOVE, ATTACK, ATTACK_MOVE }

const ATTACK_MOVE_ACQUIRE_BONUS: float = 3.5
const IDLE_ACQUIRE_INTERVAL: float = 0.25

# --- Replicated (spawn) ------------------------------------------------------------
var champion_id: String = "arcanist"
var player_name: String = "Champion"

# --- Replicated (on change) -------------------------------------------------------
var owner_peer_id: int = 0
var is_bot: bool = false
var max_mana: float = 300.0
var level: int = 1
var xp: float = 0.0
var gold: int = GameConst.STARTING_GOLD
var kills: int = 0
var deaths: int = 0
var assists: int = 0
var creep_score: int = 0
var skill_points: int = 0
var ability_ranks: PackedInt32Array = PackedInt32Array([1, 1, 1, 0])
var cooldown_ends: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var items: PackedStringArray = PackedStringArray()
var respawn_at: float = 0.0
var passive_stacks: int = 0
## [AD, AP, armor, MR, attack speed, move speed, range, CDR]
var stat_block: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0])
var cast_slot: int = -1
var cast_end: float = 0.0
var recall_end: float = 0.0
var is_concealed: bool = false
var current_brush_idx: int = -1
var reveal_timer: float = 0.0

# --- Replicated (always) ----------------------------------------------------------
var mana: float = 300.0

# --- Server-only ------------------------------------------------------------------
var data: ChampionData
var brain: BotBrain
var order: Order = Order.IDLE
var order_point: Vector3 = Vector3.ZERO
var order_target_id: int = -1
var passive_timer: float = 0.0
var mana_regen: float = 1.0
var cdr: float = 0.0
var damage_log: Dictionary = {}          # champion net_id -> game time of last damage
var kill_streak: int = 0
var multi_kill_count: int = 0
var last_kill_time: float = -100.0
var last_combat_time: float = -100.0
var last_damaged_time: float = -100.0

var _auto_acquired: bool = false
var _pending_cast: Dictionary = {}
var _queued_cast: Dictionary = {}
var _dash: Dictionary = {}
var _repath_timer: float = 0.0
var _acquire_timer: float = 0.0
var _stat_timer: float = 0.0
var _gold_accumulator: float = 0.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	data = ChampionDB.get_champion(StringName(champion_id))
	if data == null:
		data = ChampionDB.get_champion(ChampionDB.default_id())
	radius = data.radius
	attack_projectile_style = data.attack_projectile_style
	attack_projectile_speed = data.attack_projectile_speed
	attack_windup_ratio = data.attack_windup
	nav_agent.radius = radius
	if visual and data.model_scene:
		var model: Node3D = data.model_scene.instantiate() as Node3D
		model.name = "Model"
		visual.add_child(model)
	super._ready()
	if multiplayer.is_server():
		_initialize_server_state()


func _initialize_server_state() -> void:
	recalc_stats()
	health = max_health
	mana = max_mana
	if is_bot and brain == null:
		brain = BotBrain.new(self)


func get_kind() -> Kind:
	return Kind.CHAMPION


func get_display_name() -> String:
	return player_name


func is_local() -> bool:
	return owner_peer_id != 0 and owner_peer_id == multiplayer.get_unique_id()


func get_ability(slot: int) -> AbilityData:
	if data == null or slot < 0 or slot >= data.abilities.size():
		return null
	return data.abilities[slot]


func get_cooldown_remaining(slot: int) -> float:
	if Game.current == null or slot < 0 or slot >= cooldown_ends.size():
		return 0.0
	return maxf(0.0, cooldown_ends[slot] - Game.current.game_time)


func xp_fraction() -> float:
	if level >= GameConst.MAX_LEVEL:
		return 1.0
	return clampf(xp / GameConst.xp_to_next_level(level), 0.0, 1.0)


func mana_fraction() -> float:
	return mana / max_mana if max_mana > 0.0 else 0.0


func is_recalling() -> bool:
	return recall_end > 0.0


func is_dashing() -> bool:
	return not _dash.is_empty()


func is_casting() -> bool:
	return not _pending_cast.is_empty()


func respawn_time_left() -> float:
	if not dead or Game.current == null:
		return 0.0
	return maxf(0.0, respawn_at - Game.current.game_time)


## Whether an ability rank-up is currently allowed (works on clients too, uses replicated state).
func can_level_ability(slot: int) -> bool:
	var ability: AbilityData = get_ability(slot)
	if ability == null or skill_points <= 0:
		return false
	var rank: int = ability_ranks[slot]
	if rank >= ability.max_rank:
		return false
	if ability.is_ultimate:
		return rank < GameConst.ULT_RANK_LEVELS.size() and level >= GameConst.ULT_RANK_LEVELS[rank]
	return rank < (level + 2) / 2


# --- Orders (server) ------------------------------------------------------------------

func order_move(point: Vector3) -> void:
	if dead:
		return
	_clear_actions()
	order = Order.MOVE
	order_point = Game.current.clamp_to_map(point) if Game.current else point
	nav_agent.target_position = order_point


func order_attack(target: Entity) -> void:
	if dead or target == null or not target.is_targetable_by(team):
		return
	if order == Order.ATTACK and order_target_id == target.net_id and _queued_cast.is_empty():
		return
	_clear_actions()
	order = Order.ATTACK
	order_target_id = target.net_id
	_auto_acquired = false
	_repath_timer = 0.0


func order_attack_move(point: Vector3) -> void:
	if dead:
		return
	_clear_actions()
	order = Order.ATTACK_MOVE
	order_point = Game.current.clamp_to_map(point) if Game.current else point
	order_target_id = -1
	nav_agent.target_position = order_point


func order_stop() -> void:
	_clear_actions()
	order = Order.IDLE
	order_target_id = -1
	velocity = Vector3.ZERO
	nav_agent.target_position = global_position


func _clear_actions() -> void:
	cancel_recall()
	_queued_cast = {}
	if is_winding_up():
		cancel_attack_windup()


# --- Server simulation ---------------------------------------------------------------------

func _server_tick(delta: float, now: float) -> void:
	health = minf(max_health, health + health_regen * delta)
	mana = minf(max_mana, mana + mana_regen * delta)
	_gold_accumulator += GameConst.PASSIVE_GOLD_PER_SEC * delta
	if _gold_accumulator >= 1.0:
		var whole: int = int(_gold_accumulator)
		gold += whole
		_gold_accumulator -= float(whole)
	if data.passive:
		data.passive.on_tick(self, delta)
	_stat_timer -= delta
	if _stat_timer <= 0.0:
		_stat_timer = 0.2
		_update_stat_block()

	if Game.current and Game.current.arena:
		var b_idx: int = Game.current.arena.get_brush_index(global_position)
		current_brush_idx = b_idx
		if reveal_timer > 0.0:
			reveal_timer -= delta
		is_concealed = b_idx != -1 and reveal_timer <= 0.0
	if brain:
		brain.think(delta, now)
	if recall_end > 0.0 and now >= recall_end:
		_complete_recall()

	if not _dash.is_empty():
		_process_dash(delta)
		return
	if statuses.stunned:
		velocity = Vector3.ZERO
		return
	if not _pending_cast.is_empty():
		velocity = Vector3.ZERO
		_process_pending_cast(now)
		return
	process_attack_windup(now)
	if not _queued_cast.is_empty():
		_process_queued_cast(delta)
		return

	match order:
		Order.IDLE:
			velocity = Vector3.ZERO
			_acquire_timer -= delta
			if _acquire_timer <= 0.0 and recall_end <= 0.0:
				_acquire_timer = IDLE_ACQUIRE_INTERVAL
				var target: Entity = _find_attack_target(attack_range + 0.3)
				if target:
					order = Order.ATTACK
					order_target_id = target.net_id
					_auto_acquired = true
		Order.MOVE:
			if _move_along_path(delta):
				order = Order.IDLE
		Order.ATTACK:
			var target: Entity = Game.current.get_entity(order_target_id)
			if target == null or not target.is_targetable_by(team):
				order = Order.IDLE
				velocity = Vector3.ZERO
			elif _auto_acquired and edge_distance_to(target) > attack_range + 2.5:
				order = Order.IDLE
				velocity = Vector3.ZERO
			else:
				_attack_target_step(target, delta, now)
		Order.ATTACK_MOVE:
			var target: Entity = Game.current.get_entity(order_target_id)
			if target == null or not target.is_targetable_by(team):
				order_target_id = -1
				_acquire_timer -= delta
				if _acquire_timer <= 0.0:
					_acquire_timer = 0.15
					target = _find_attack_target(attack_range + ATTACK_MOVE_ACQUIRE_BONUS)
					if target:
						order_target_id = target.net_id
					else:
						nav_agent.target_position = order_point
			if target and target.is_targetable_by(team):
				_attack_target_step(target, delta, now)
			elif _move_along_path(delta):
				order = Order.IDLE


func _attack_target_step(target: Entity, delta: float, now: float) -> void:
	if in_attack_range(target):
		velocity = Vector3.ZERO
		face_point(target.global_position)
		if can_start_attack(now):
			begin_attack(target, now)
			last_combat_time = now
	elif is_winding_up():
		velocity = Vector3.ZERO
	else:
		_chase(target, delta)


func _chase(target: Entity, delta: float) -> void:
	_repath_timer -= delta
	var goal: Vector3 = target.flat_position()
	if _repath_timer <= 0.0 or nav_agent.target_position.distance_squared_to(goal) > 1.0:
		_repath_timer = 0.25
		nav_agent.target_position = goal
	_move_along_path(delta)


## Moves along the navigation path. Returns true once the destination is reached.
func _move_along_path(delta: float) -> bool:
	if statuses.rooted:
		velocity = Vector3.ZERO
		return false
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return true
	var next: Vector3 = nav_agent.get_next_path_position()
	var offset := Vector3(next.x - global_position.x, 0.0, next.z - global_position.z)
	var distance: float = offset.length()
	if distance < 0.001:
		velocity = Vector3.ZERO
		return nav_agent.is_navigation_finished()
	var dir: Vector3 = offset / distance
	var speed: float = get_move_speed()
	velocity = dir * minf(speed, distance / maxf(delta, 0.0001))
	move_and_slide()
	global_position.y = 0.0
	turn_towards_direction(dir, delta, 20.0)
	return false


func _find_attack_target(search_range: float) -> Entity:
	var best: Entity = null
	var best_score: float = INF
	for entity: Entity in Game.current.find_enemies_in_radius(team, global_position, search_range + radius, true):
		var score: float = edge_distance_to(entity)
		if entity.is_structure():
			score += 50.0  # Prefer units over structures.
		if score < best_score:
			best_score = score
			best = entity
	return best


# --- Casting (server) ---------------------------------------------------------------------

## Validates and starts casting an ability. Returns "" on success or an error code.
func try_cast(slot: int, target_pos: Vector3, target_id: int) -> String:
	if dead:
		return "dead"
	if statuses.stunned:
		return "stunned"
	var ability: AbilityData = get_ability(slot)
	if ability == null:
		return "invalid"
	var rank: int = ability_ranks[slot]
	if rank <= 0:
		return "not_learned"
	var now: float = Game.current.game_time
	if cooldown_ends[slot] > now + 0.05:
		return "cooldown"
	if not _pending_cast.is_empty() or not _dash.is_empty():
		return "busy"
	if mana < ability.get_mana_cost(rank):
		return "mana"
	if ability.blocked_by_root and statuses.rooted:
		return "rooted"
	target_pos = Game.current.clamp_to_map(target_pos)
	var target: Entity = null
	if ability.targeting == AbilityData.Targeting.UNIT:
		target = Game.current.get_entity(target_id)
		if target == null or not target.is_targetable_by(team) or target.is_structure():
			return "invalid_target"
		if edge_distance_to(target) > ability.cast_range:
			# Walk into range, then cast automatically.
			cancel_recall()
			_queued_cast = {"slot": slot, "target_id": target_id}
			_repath_timer = 0.0
			return ""
		target_pos = target.flat_position()
	_commit_cast(slot, ability, rank, target_pos, target)
	return ""


func _commit_cast(slot: int, ability: AbilityData, rank: int, target_pos: Vector3, target: Entity) -> void:
	var now: float = Game.current.game_time
	mana -= ability.get_mana_cost(rank)
	var ends: PackedFloat32Array = cooldown_ends
	ends[slot] = now + ability.get_cooldown(rank) * (1.0 - cdr)
	cooldown_ends = ends
	cancel_recall()
	if is_winding_up():
		cancel_attack_windup()
	_queued_cast = {}
	last_combat_time = now
	reveal_timer = 2.5
	is_concealed = false
	if ability.targeting != AbilityData.Targeting.NONE:
		face_point(target_pos)
	if data.passive:
		data.passive.on_ability_cast(self, slot)
	Game.current.on_ability_cast(self, slot)
	if ability.cast_time > 0.0:
		_pending_cast = {
			"slot": slot, "rank": rank, "pos": target_pos,
			"target_id": target.net_id if target else -1, "fire_at": now + ability.cast_time,
		}
		cast_slot = slot
		cast_end = now + ability.cast_time
	else:
		ability.execute(self, rank, target_pos, target)


func _process_pending_cast(now: float) -> void:
	var pos: Vector3 = _pending_cast["pos"]
	face_point(pos)
	if now < float(_pending_cast["fire_at"]):
		return
	var cast: Dictionary = _pending_cast
	_pending_cast = {}
	cast_slot = -1
	var ability: AbilityData = get_ability(int(cast["slot"]))
	var target: Entity = Game.current.get_entity(int(cast["target_id"]))
	if ability.targeting == AbilityData.Targeting.UNIT:
		if target == null or not target.is_targetable_by(team):
			return
		pos = target.flat_position()
	ability.execute(self, int(cast["rank"]), pos, target)


func _process_queued_cast(delta: float) -> void:
	var slot: int = int(_queued_cast["slot"])
	var target: Entity = Game.current.get_entity(int(_queued_cast["target_id"]))
	var ability: AbilityData = get_ability(slot)
	if target == null or ability == null or not target.is_targetable_by(team):
		_queued_cast = {}
		velocity = Vector3.ZERO
		return
	if edge_distance_to(target) <= ability.cast_range:
		var target_id: int = target.net_id
		_queued_cast = {}
		velocity = Vector3.ZERO
		try_cast(slot, target.flat_position(), target_id)
	else:
		_chase(target, delta)


func level_ability(slot: int) -> bool:
	if not can_level_ability(slot):
		return false
	var ranks: PackedInt32Array = ability_ranks
	ranks[slot] += 1
	ability_ranks = ranks
	skill_points -= 1
	return true


# --- Movement abilities (server) ------------------------------------------------------------

## params: mode ("dash" | "leap" | "target"), to, speed, duration, arc, target_id, max_time,
##         untargetable, on_arrive (Callable)
func start_dash(params: Dictionary) -> void:
	_dash = params.duplicate()
	_dash["elapsed"] = 0.0
	_dash["from"] = flat_position()
	_pending_cast = {}
	cast_slot = -1
	_queued_cast = {}
	cancel_recall()
	if is_winding_up():
		cancel_attack_windup()
	velocity = Vector3.ZERO
	order = Order.IDLE
	if bool(_dash.get("untargetable", false)):
		apply_status(GameConst.Status.UNTARGETABLE, 0.0, float(_dash.get("duration", 0.5)) + 0.05, self)
	nav_agent.target_position = global_position


func _process_dash(delta: float) -> void:
	var elapsed: float = float(_dash["elapsed"]) + delta
	_dash["elapsed"] = elapsed
	match String(_dash["mode"]):
		"leap":
			var duration: float = maxf(0.05, float(_dash.get("duration", 0.5)))
			var t: float = clampf(elapsed / duration, 0.0, 1.0)
			var from: Vector3 = _dash["from"]
			var to: Vector3 = _dash["to"]
			var p: Vector3 = from.lerp(to, t)
			p.y = float(_dash.get("arc", 2.0)) * 4.0 * t * (1.0 - t)
			global_position = p
			face_point(to)
			if t >= 1.0:
				_finish_dash()
		"dash":
			var to: Vector3 = _dash["to"]
			var offset := Vector3(to.x - global_position.x, 0.0, to.z - global_position.z)
			var speed: float = float(_dash.get("speed", 20.0))
			var step: float = speed * delta
			face_point(to)
			if offset.length() <= step or elapsed > 1.5:
				velocity = offset / maxf(delta, 0.0001)
				move_and_slide()
				_finish_dash()
			else:
				var before: Vector3 = global_position
				velocity = offset.normalized() * speed
				move_and_slide()
				if global_position.distance_to(before) < step * 0.25:
					_finish_dash()
		"target":
			var target: Entity = Game.current.get_entity(int(_dash.get("target_id", -1)))
			if target == null or not target.is_targetable_by(team) or elapsed > float(_dash.get("max_time", 1.0)):
				_dash = {}
				velocity = Vector3.ZERO
				return
			var step: float = float(_dash.get("speed", 20.0)) * delta
			face_point(target.global_position)
			if edge_distance_to(target) <= step + 0.15:
				_finish_dash()
			else:
				var offset := Vector3(target.global_position.x - global_position.x, 0.0, target.global_position.z - global_position.z)
				global_position += offset.normalized() * step
		_:
			_dash = {}
	global_position.y = maxf(global_position.y, 0.0)


func _finish_dash() -> void:
	global_position.y = 0.0
	velocity = Vector3.ZERO
	var callback: Callable = _dash.get("on_arrive", Callable())
	_dash = {}
	nav_agent.target_position = global_position
	if callback.is_valid():
		callback.call()


func blink_to(point: Vector3) -> void:
	if is_winding_up():
		cancel_attack_windup()
	_queued_cast = {}
	global_position = Vector3(point.x, 0.0, point.z)
	net_position = global_position
	velocity = Vector3.ZERO
	order = Order.IDLE
	nav_agent.target_position = global_position


# --- Recall (server) --------------------------------------------------------------------------

func start_recall() -> void:
	if dead or recall_end > 0.0 or not _dash.is_empty() or not _pending_cast.is_empty() or statuses.stunned:
		return
	order_stop()
	recall_end = Game.current.game_time + GameConst.RECALL_DURATION
	Game.current.play_fx("recall", global_position, {"color": GameConst.team_color(team), "duration": GameConst.RECALL_DURATION})


func cancel_recall() -> void:
	recall_end = 0.0


func _complete_recall() -> void:
	recall_end = 0.0
	blink_to(Game.current.fountain_position(team))
	Game.current.play_fx("blink", global_position, {"color": GameConst.team_color(team)})


# --- Economy & progression (server) -------------------------------------------------------------

func add_gold(amount: int) -> void:
	gold += amount


func add_xp(amount: float) -> void:
	if level >= GameConst.MAX_LEVEL or amount <= 0.0:
		return
	xp += amount * 1.20
	while level < GameConst.MAX_LEVEL and xp >= GameConst.xp_to_next_level(level):
		xp -= GameConst.xp_to_next_level(level)
		_level_up()
	if level >= GameConst.MAX_LEVEL:
		xp = 0.0


func _level_up() -> void:
	level += 1
	skill_points += 1
	recalc_stats()
	if Game.current:
		Game.current.play_fx("levelup", global_position, {"color": GameConst.COLOR_GOLD})
	if brain:
		brain.on_level_up()


func can_shop() -> bool:
	return dead or (Game.current != null and Game.current.is_in_fountain(self))


func buy_item(item_id: String) -> String:
	if not ItemDB.exists(item_id):
		return "invalid"
	if items.size() >= GameConst.INVENTORY_SIZE:
		return "inventory_full"
	if not can_shop():
		return "not_in_base"
	var price: int = ItemDB.cost(item_id)
	if gold < price:
		return "not_enough_gold"
	gold -= price
	var inventory: PackedStringArray = items
	inventory.append(item_id)
	items = inventory
	recalc_stats()
	return ""


func sell_item(index: int) -> String:
	if index < 0 or index >= items.size():
		return "invalid"
	if not can_shop():
		return "not_in_base"
	var inventory: PackedStringArray = items
	var item_id: String = inventory[index]
	inventory.remove_at(index)
	items = inventory
	gold += int(float(ItemDB.cost(item_id)) * GameConst.SELL_RATIO)
	recalc_stats()
	return ""


func recalc_stats() -> void:
	var bonus: Dictionary = ItemDB.total_stats(items)
	var previous_max_health: float = max_health
	var previous_max_mana: float = max_mana
	max_health = data.stat(data.max_health, data.health_per_level, level) + float(bonus.get("hp", 0.0))
	max_mana = data.stat(data.max_mana, data.mana_per_level, level) + float(bonus.get("mana", 0.0))
	attack_damage = data.stat(data.attack_damage, data.attack_damage_per_level, level) + float(bonus.get("ad", 0.0))
	ability_power = float(bonus.get("ap", 0.0))
	base_attack_speed = data.attack_speed * (1.0 + data.attack_speed_per_level * float(level - 1) + float(bonus.get("as", 0.0)))
	armor = data.stat(data.armor, data.armor_per_level, level) + float(bonus.get("armor", 0.0))
	magic_resist = data.stat(data.magic_resist, data.magic_resist_per_level, level) + float(bonus.get("mr", 0.0))
	base_move_speed = data.move_speed + float(bonus.get("ms", 0.0))
	health_regen = data.stat(data.health_regen, data.health_regen_per_level, level) + float(bonus.get("hp_regen", 0.0))
	mana_regen = data.stat(data.mana_regen, data.mana_regen_per_level, level) + float(bonus.get("mana_regen", 0.0))
	cdr = minf(0.4, float(bonus.get("cdr", 0.0)))
	if statuses.has_blue_buff:
		cdr = minf(0.4, cdr + 0.2)
		mana_regen += 10.0
	if statuses.has_boss_buff:
		attack_damage *= 1.15
		ability_power = (ability_power + 25.0) * 1.2
	attack_range = data.attack_range
	if max_health > previous_max_health:
		health += max_health - previous_max_health
	if max_mana > previous_max_mana:
		mana += max_mana - previous_max_mana
	health = minf(health, max_health)
	mana = minf(mana, max_mana)
	_update_stat_block()


func _update_stat_block() -> void:
	var block := PackedFloat32Array([attack_damage, ability_power, armor, magic_resist,
			get_attack_speed(), get_move_speed(), attack_range, cdr])
	if block != stat_block:
		stat_block = block


# --- Combat hooks (server) --------------------------------------------------------------------

func deliver_attack(target: Entity) -> void:
	reveal_timer = 2.5
	is_concealed = false
	if statuses.has_red_buff and target and not target.dead:
		target.take_damage(20.0, GameConst.DamageType.TRUE, self, false)
		target.apply_status(GameConst.Status.SLOW, 0.25, 2.0, self, &"red_burn")
	var bonus: float = 0.0
	if data.passive:
		bonus += data.passive.on_basic_attack(self, target)
	var empower: float = statuses.consume_empower()
	if empower > 0.0 and Game.current:
		Game.current.play_fx("impact", target.global_position, {"color": data.color, "radius": 1.0})
	target.take_damage(attack_damage + bonus + empower, GameConst.DamageType.PHYSICAL, self, false)
	if Game.current:
		last_combat_time = Game.current.game_time


func _play_attack_animation() -> void:
	super._play_attack_animation()
	if visual:
		var model_node := visual.get_node_or_null("Model")
		if model_node and model_node.has_method("trigger_attack"):
			var windup_dur: float = 1.0 / maxf(0.5, get_attack_speed()) * attack_windup_ratio
			model_node.trigger_attack(attack_range > 3.0, windup_dur)


func _on_took_damage(_amount: float, source: Entity, _damage_type: int, _is_ability: bool) -> void:
	if Game.current == null:
		return
	var now: float = Game.current.game_time
	last_damaged_time = now
	if source != null:
		cancel_recall()
	if source is Champion:
		damage_log[source.net_id] = now
		last_combat_time = now


func _on_stunned() -> void:
	_pending_cast = {}
	cast_slot = -1
	_queued_cast = {}
	cancel_recall()


func _extra_status_flags() -> int:
	var flags: int = 0
	if recall_end > 0.0:
		flags |= GameConst.FLAG_RECALLING
	if not _pending_cast.is_empty():
		flags |= GameConst.FLAG_CASTING
	return flags


func _on_death(_killer: Entity) -> void:
	deaths += 1
	kill_streak = 0
	respawn_at = Game.current.game_time + GameConst.respawn_time(level) if Game.current else 0.0
	_pending_cast = {}
	_queued_cast = {}
	_dash = {}
	cast_slot = -1
	recall_end = 0.0
	order = Order.IDLE
	global_position.y = 0.0
	collision_layer = 0


func respawn() -> void:
	if not dead:
		return
	var spawn_point: Vector3 = Game.current.fountain_position(team)
	statuses.clear()
	health = max_health
	mana = max_mana
	damage_log.clear()
	global_position = spawn_point
	net_position = spawn_point
	velocity = Vector3.ZERO
	collision_layer = GameConst.LAYER_UNITS
	nav_agent.target_position = spawn_point
	order = Order.IDLE
	dead = false
	Game.current.play_fx("blink", spawn_point, {"color": GameConst.team_color(team)})


## Hands the champion over to AI control (used when its player disconnects).
func convert_to_bot() -> void:
	owner_peer_id = 0
	is_bot = true
	if multiplayer.is_server() and brain == null:
		brain = BotBrain.new(self)



func is_targetable_by(other_team: int) -> bool:
	if not super.is_targetable_by(other_team):
		return false
	if is_concealed:
		var local_c: Champion = Game.current.local_champion if Game.current else null
		if local_c and local_c.team == other_team:
			var in_same_brush: bool = local_c.current_brush_idx == current_brush_idx and current_brush_idx != -1
			if not in_same_brush:
				return false
	return true


func _process(delta: float) -> void:
	super._process(delta)
	_update_stealth_visuals()


func _update_stealth_visuals() -> void:
	if visual == null or dead:
		return
	var local_team: int = Game.current.local_team() if Game.current else 0
	if is_concealed:
		if team == local_team:
			_set_model_transparency(0.45)
			visual.visible = true
		else:
			var local_c: Champion = Game.current.local_champion if Game.current else null
			var in_same_brush: bool = local_c != null and local_c.current_brush_idx == current_brush_idx and current_brush_idx != -1
			visual.visible = in_same_brush
			_set_model_transparency(0.0)
	else:
		visual.visible = true
		_set_model_transparency(0.0)


func _set_model_transparency(t: float) -> void:
	if visual:
		for child: Node in visual.find_children("*", "GeometryInstance3D", true, false):
			(child as GeometryInstance3D).transparency = t
