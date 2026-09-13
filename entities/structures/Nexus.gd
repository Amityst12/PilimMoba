class_name Nexus
extends Entity
## The team's core. Destroying the enemy Nexus wins the match.
## It can only be damaged once both towers of its team have fallen.


func _ready() -> void:
	mobile = false
	radius = 2.4
	bar_height = 6.2
	max_health = 5000.0
	armor = 20.0
	magic_resist = 20.0
	if multiplayer.is_server():
		health = max_health
	super._ready()
	if visual:
		visual.add_child(StructureModel.build_nexus(team))


func get_kind() -> Kind:
	return Kind.NEXUS


func get_display_name() -> String:
	return "%s Nexus" % GameConst.team_name(team)


func is_vulnerable() -> bool:
	return Game.current == null or Game.current.is_structure_vulnerable(self)


func _modify_incoming_damage(amount: float, _source: Entity, _damage_type: int) -> float:
	var game := Game.current
	if game:
		for minion: Entity in game.minions:
			if minion.team != team and not minion.dead \
					and planar_distance_to_point(minion.global_position) < GameConst.BACKDOOR_MINION_RADIUS + 2.0:
				return amount
	return amount * (1.0 - GameConst.BACKDOOR_REDUCTION)


func _on_dead_changed() -> void:
	var model: Node = visual.get_child(0) if visual and visual.get_child_count() > 0 else null
	if model and model.has_method("set_destroyed"):
		model.set_destroyed(dead)


func _update_presentation(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
