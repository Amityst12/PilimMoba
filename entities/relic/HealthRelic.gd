class_name HealthRelic
extends Node3D
## ARAM Health Relic (Shrine / Pickup).
## Placed along the Howling Abyss bridge. Stepping on an active relic grants instant
## sustain, drops a 2.5s pulsing healing circle, and detonates an AoE heal for all
## champions in the area before going on a 60s cooldown.

const GameConst = preload("res://core/GameConst.gd")

var net_id: int = 0
var is_active: bool = true
var cooldown_end: float = 0.0
var charge_timer: float = 0.0

var _time: float = randf() * 10.0
var _burst_pending: bool = false

@onready var visual: Node3D = $Visual
@onready var crystal: Node3D = $Visual/Crystal
@onready var aoe_ring: Node3D = $Visual/AoERing
@onready var light: OmniLight3D = $Visual/OmniLight3D


func _ready() -> void:
	if multiplayer.is_server():
		is_active = true
		cooldown_end = 0.0
		charge_timer = 0.0



func _process(delta: float) -> void:
	_time += delta
	if crystal:
		crystal.visible = is_active
		if is_active:
			crystal.rotation.y += delta * 2.2
			crystal.position.y = 1.1 + sin(_time * 2.8) * 0.12
	if light:
		light.visible = is_active or charge_timer > 0.0
		if charge_timer > 0.0:
			light.light_energy = 2.0 + sin(_time * 12.0) * 1.0
			light.light_color = Color(0.3, 1.0, 0.6)
		elif is_active:
			light.light_energy = 1.2 + sin(_time * 3.0) * 0.3
			light.light_color = Color(0.2, 0.9, 0.4)

	# Visual AoE charging ring
	if aoe_ring:
		aoe_ring.visible = charge_timer > 0.0
		if charge_timer > 0.0:
			var progress: float = 1.0 - clampf(charge_timer / GameConst.HEALTH_RELIC_BURST_DELAY, 0.0, 1.0)
			aoe_ring.scale = Vector3.ONE * (0.3 + progress * 0.7)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var game := Game.current
	if game == null or game.phase != Game.Phase.PLAYING:
		return

	var now: float = game.game_time

	# 1. Active: Check for champion stepping onto the relic
	if is_active:
		for champ: Champion in game.champions:
			if champ.dead:
				continue
			var dist: float = Vector2(global_position.x - champ.global_position.x, global_position.z - champ.global_position.z).length()
			if dist <= 1.6:
				_on_activated_by(champ)
				break
		return

	# 2. Charging AoE healing burst
	if _burst_pending and charge_timer > 0.0:
		charge_timer -= delta
		if charge_timer <= 0.0:
			charge_timer = 0.0
			_detonate_burst()
		return

	#3. On cooldown: waiting to respawn
	if not is_active and not _burst_pending:
		if now >= cooldown_end:
			is_active = true
			cooldown_end = 0.0
			if game:
				game.play_fx("sparkle", global_position + Vector3(0.0, 1.0, 0.0), {"color": Color(0.3, 1.0, 0.5)})


func _on_activated_by(activator: Champion) -> void:
	is_active = false
	_burst_pending = true
	charge_timer = GameConst.HEALTH_RELIC_BURST_DELAY

	# Instant pickup reward for activator: 8% max HP + 8% max Mana
	activator.heal(activator.max_health * 0.08)
	activator.mana = minf(activator.max_mana, activator.mana + activator.max_mana * 0.08)
	if Game.current:
		Game.current.play_fx("heal", activator.global_position, {"color": Color(0.2, 0.95, 0.4)})
		Sfx.play("powerup", -6.0)



func _detonate_burst() -> void:
	_burst_pending = false
	var game := Game.current
	if game == null:
		return

	cooldown_end = game.game_time + GameConst.HEALTH_RELIC_COOLDOWN

	# AoE Heal: heals ALL champions in range for 16% max HP and 16% max Mana
	var r: float = GameConst.HEALTH_RELIC_RADIUS
	for champ: Champion in game.champions:
		if champ.dead:
			continue
		var dist: float = Vector2(global_position.x - champ.global_position.x, global_position.z - champ.global_position.z).length()
		if dist <= r:
			champ.heal(champ.max_health * 0.16)
			champ.mana = minf(champ.max_mana, champ.mana + champ.max_mana * 0.16)
			game.play_fx("heal", champ.global_position, {"color": Color(0.25, 1.0, 0.5)})

	game.play_fx("impact", global_position + Vector3(0.0, 0.2, 0.0), {"color": Color(0.2, 0.95, 0.45), "radius": r})
	Sfx.play("spell", -4.0, 0.05)
