class_name StatusController
extends RefCounted
## Server-side runtime container for the status effects active on one entity.
## Aggregated values (move multiplier, stun, shields...) are recomputed whenever effects change.

class ActiveEffect:
	var kind: int
	var value: float
	var time_left: float
	var source_id: int
	var tag: StringName

var move_multiplier: float = 1.0
var attack_speed_bonus: float = 0.0
var stunned: bool = false
var rooted: bool = false
var untargetable: bool = false
var silenced: bool = false
var has_blue_buff: bool = false
var has_red_buff: bool = false
var has_boss_buff: bool = false
var shield: float = 0.0
var empower: float = 0.0
var slow_amount: float = 0.0
var haste_amount: float = 0.0

var _effects: Array[ActiveEffect] = []


## Adds an effect. Effects with the same non-empty `tag` refresh instead of stacking.
func add(kind: int, value: float, duration: float, source_id: int = 0, tag: StringName = &"") -> void:
	if duration <= 0.0:
		return
	if tag != &"":
		for effect: ActiveEffect in _effects:
			if effect.tag == tag and effect.kind == kind:
				effect.value = value
				effect.time_left = maxf(effect.time_left, duration)
				effect.source_id = source_id
				_recompute()
				return
	if kind == GameConst.Status.EMPOWER:
		# Only one empowered attack can be stored; keep the strongest.
		for effect: ActiveEffect in _effects:
			if effect.kind == kind:
				effect.value = maxf(effect.value, value)
				effect.time_left = maxf(effect.time_left, duration)
				_recompute()
				return
	var e := ActiveEffect.new()
	e.kind = kind
	e.value = value
	e.time_left = duration
	e.source_id = source_id
	e.tag = tag
	_effects.append(e)
	_recompute()


func tick(delta: float) -> void:
	if _effects.is_empty():
		return
	var changed: bool = false
	for i: int in range(_effects.size() - 1, -1, -1):
		var effect: ActiveEffect = _effects[i]
		effect.time_left -= delta
		if effect.time_left <= 0.0:
			_effects.remove_at(i)
			changed = true
	if changed:
		_recompute()


## Consumes shields and returns the damage that goes through.
func absorb_damage(amount: float) -> float:
	if shield <= 0.0 or amount <= 0.0:
		return amount
	var remaining: float = amount
	# Consume the shields that expire soonest first.
	var shields: Array[ActiveEffect] = []
	for effect: ActiveEffect in _effects:
		if effect.kind == GameConst.Status.SHIELD:
			shields.append(effect)
	shields.sort_custom(func(a: ActiveEffect, b: ActiveEffect) -> bool: return a.time_left < b.time_left)
	for effect: ActiveEffect in shields:
		var absorbed: float = minf(effect.value, remaining)
		effect.value -= absorbed
		remaining -= absorbed
		if effect.value <= 0.01:
			_effects.erase(effect)
		if remaining <= 0.0:
			break
	_recompute()
	return remaining


## Returns the bonus damage of a stored empowered attack and removes it.
func consume_empower() -> float:
	for i: int in range(_effects.size()):
		if _effects[i].kind == GameConst.Status.EMPOWER:
			var bonus: float = _effects[i].value
			_effects.remove_at(i)
			_recompute()
			return bonus
	return 0.0


func count_tag(tag: StringName) -> int:
	var n: int = 0
	for effect: ActiveEffect in _effects:
		if effect.tag == tag:
			n += 1
	return n


func remove_tag(tag: StringName) -> void:
	var before: int = _effects.size()
	_effects = _effects.filter(func(e: ActiveEffect) -> bool: return e.tag != tag)
	if _effects.size() != before:
		_recompute()


func remove_kind(kind: int) -> void:
	var before: int = _effects.size()
	_effects = _effects.filter(func(e: ActiveEffect) -> bool: return e.kind != kind)
	if _effects.size() != before:
		_recompute()


## Removes crowd control (used on death / respawn).
func clear() -> void:
	_effects.clear()
	_recompute()


func has_kind(kind: int) -> bool:
	for effect: ActiveEffect in _effects:
		if effect.kind == kind:
			return true
	return false


func flags() -> int:
	var f: int = 0
	if stunned:
		f |= GameConst.FLAG_STUNNED
	if rooted:
		f |= GameConst.FLAG_ROOTED
	if slow_amount > 0.0:
		f |= GameConst.FLAG_SLOWED
	if haste_amount > 0.0:
		f |= GameConst.FLAG_HASTED
	if shield > 0.0:
		f |= GameConst.FLAG_SHIELDED
	if empower > 0.0:
		f |= GameConst.FLAG_EMPOWERED
	if untargetable:
		f |= GameConst.FLAG_UNTARGETABLE
	if silenced:
		f |= GameConst.FLAG_SILENCED
	if has_blue_buff:
		f |= GameConst.FLAG_BLUE_BUFF
	if has_red_buff:
		f |= GameConst.FLAG_RED_BUFF
	if has_boss_buff:
		f |= GameConst.FLAG_BOSS_BUFF
	return f


func _recompute() -> void:
	var slow: float = 0.0
	var haste: float = 0.0
	var attack_speed: float = 0.0
	var shield_total: float = 0.0
	var empower_total: float = 0.0
	var is_stunned: bool = false
	var is_rooted: bool = false
	var is_untargetable: bool = false
	var is_silenced: bool = false
	var blue: bool = false
	var red: bool = false
	var boss: bool = false
	for effect: ActiveEffect in _effects:
		match effect.kind:
			GameConst.Status.SLOW:
				slow = maxf(slow, effect.value)
			GameConst.Status.HASTE:
				haste += effect.value
			GameConst.Status.STUN:
				is_stunned = true
			GameConst.Status.ROOT:
				is_rooted = true
			GameConst.Status.SHIELD:
				shield_total += effect.value
			GameConst.Status.ATTACK_SPEED:
				attack_speed += effect.value
			GameConst.Status.EMPOWER:
				empower_total = maxf(empower_total, effect.value)
			GameConst.Status.UNTARGETABLE:
				is_untargetable = true
			GameConst.Status.SILENCE:
				is_silenced = true
			GameConst.Status.BLUE_BUFF:
				blue = true
			GameConst.Status.RED_BUFF:
				red = true
			GameConst.Status.BOSS_BUFF:
				boss = true
	slow_amount = clampf(slow, 0.0, 0.9)
	haste_amount = haste
	move_multiplier = maxf(0.2, (1.0 + haste) * (1.0 - slow_amount))
	attack_speed_bonus = attack_speed
	shield = shield_total
	empower = empower_total
	stunned = is_stunned
	rooted = is_rooted
	untargetable = is_untargetable
	silenced = is_silenced
	has_blue_buff = blue
	has_red_buff = red
	has_boss_buff = boss
