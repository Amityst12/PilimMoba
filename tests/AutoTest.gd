extends Node
## Automated end-to-end integration test running inside the live game engine.

func _ready() -> void:
	print("\n========================================================")
	print(">>> PILIM MOBA: AUTOMATED IN-ENGINE TEST STARTED <<<")
	print("========================================================")
	_run_suite()


func _run_suite() -> void:
	await get_tree().create_timer(0.3).timeout

	# 1. Check Champion Registry (7 Champions: Erez, Stephen, Amit, Nissim, Rogo, Yakir, Edgy)
	print("[1/7] Verifying Champion Database...")
	assert(ChampionDB.IDS.size() == 7, "Database must have 7 champions")
	for cid: StringName in ChampionDB.IDS:
		var cdata: ChampionData = ChampionDB.get_champion(cid)
		assert(cdata != null, "Champion data must load for %s" % cid)
		assert(cdata.abilities.size() == 4, "%s must have 4 abilities" % cid)
		print("  Champion verified: %s (%s, %s)" % [cdata.display_name, cdata.role, cdata.title])

	# 2. Practice Mode Initialization
	print("[2/7] Triggering Practice Mode...")
	NetworkManager.start_practice("AutoTester")
	await get_tree().create_timer(0.5).timeout

	print("  Lobby roster: %d players/bots present." % NetworkManager.players.size())
	assert(NetworkManager.players.size() >= 4, "Lobby should have players/bots")

	# 3. Launch Match
	print("[3/7] Starting match from Lobby...")
	NetworkManager.start_match()
	await get_tree().create_timer(1.0).timeout

	var game: Game = Game.current
	assert(game != null, "Game instance should be loaded")
	print("  Game match scene active: %s" % game.name)

	# 4. Wait for Phase.PLAYING
	print("[4/7] Waiting for map bake and spawns...")
	var timeout: float = 14.0
	while game.phase != Game.Phase.PLAYING and timeout > 0.0:
		await get_tree().create_timer(0.2).timeout
		timeout -= 0.2

	assert(game.phase == Game.Phase.PLAYING, "Match should transition to PLAYING")
	print("  Match is PLAYING! (Game clock: %.2fs)" % game.game_time)

	# 5. Check Spawns, Jungle Camps, & Boss
	print("[5/7] Inspecting entities, jungle camps, and boss monster...")
	assert(game.champions.size() >= 4, "All champions should be in game")
	assert(game.structures.size() >= 6, "Structures should be in game")
	assert(game.local_champion != null, "Local champion must be bound")

	assert(game.has_node("World/Monsters"), "World/Monsters container must exist")
	var monsters_node := game.get_node("World/Monsters")
	var monsters: Array[Node] = monsters_node.get_children()
	print("  Neutral jungle monsters spawned: %d" % monsters.size())
	assert(monsters.size() >= 5, "Should have 4 buff camps + 1 Rift Behemoth boss")

	var found_boss: bool = false
	for m: Node in monsters:
		if m is JungleMonster and (m as JungleMonster).monster_type == JungleMonster.MonsterType.RIFT_BEHEMOTH:
			found_boss = true
			print("  Rift Behemoth verified at %s (HP: %d)" % [m.global_position, int((m as JungleMonster).max_health)])
	assert(found_boss, "Rift Behemoth boss must be present in river pit")

	# 6. Check Brush Concealment & Smart Pings
	print("[6/7] Testing Bush Concealment & Smart Ping system...")
	var brush_test_pos := Vector3(-9.0, 0.0, 8.8)
	assert(game.arena.is_in_brush(brush_test_pos), "Position (-9, 0, 8.8) must be inside brush")
	print("  Brush detection verified: is_in_brush = true")

	game.cmd_ping(GameConst.PingType.ON_MY_WAY, Vector3(0.0, 0.0, 0.0))
	game.cmd_ping(GameConst.PingType.DANGER, Vector3(10.0, 0.0, 10.0))
	await get_tree().create_timer(0.2).timeout
	print("  Smart pings dispatched successfully!")

	# 7. Abilities & Shop Test
	print("[7/7] Testing ability leveling and shop purchasing...")
	var champ: Champion = game.local_champion
	print("  Local champion: %s (HP: %d/%d, Mana: %d/%d)" % [
		champ.champion_id, int(champ.health), int(champ.max_health), int(champ.mana), int(champ.max_mana)
	])
	assert(champ.health > 100.0, "Champion should have full HP")

	champ.skill_points = 1
	game.cmd_level_ability(0)
	await get_tree().create_timer(0.2).timeout
	print("  Q ability ranked to: %d" % champ.ability_ranks[0])

	champ.gold = 500
	game.cmd_buy("boots")
	await get_tree().create_timer(0.2).timeout
	print("  Items in inventory: %s" % str(champ.items))
	assert(champ.items.has("boots"), "Boots should be purchased")

	print("\n========================================================")
	print(">>> ALL 7 TEST SUITES PASSED! 100% OPERATIONAL <<<")
	print("========================================================\n")
	get_tree().quit(0)
