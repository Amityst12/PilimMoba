extends Node
## UI layout audit: walks through every screen and panel, reports visible controls that extend
## outside the screen, and saves a screenshot of each state.
## Run: Godot --path . -- --ui-audit=<output_dir> [--resolution=N --window-mode=0]

var _out_dir: String = ""
var _issues: int = 0


func _ready() -> void:
	_out_dir = String(NetworkManager.launch_options.get("ui-audit", "user://ui_audit"))
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	print("[UI AUDIT] window=%s viewport=%s" % [DisplayServer.window_get_size(), get_viewport().get_visible_rect().size])
	await _wait(1.0)
	await _capture("01_main_menu")
	var menu: Node = get_tree().current_scene
	if menu.has_method("_on_settings"):
		menu.call("_on_settings")
		await _capture("02_menu_settings")

	NetworkManager.start_practice("AuditTester")
	for team: int in [GameConst.TEAM_BLUE, GameConst.TEAM_RED, GameConst.TEAM_RED]:
		NetworkManager.request_add_bot(team)
	await _wait(1.2)
	await _capture("03_lobby_full")

	NetworkManager.start_match()
	var timeout: float = 20.0
	while (Game.current == null or Game.current.phase != Game.Phase.PLAYING or Game.current.local_champion == null) and timeout > 0.0:
		await _wait(0.25)
		timeout -= 0.25
	var game: Game = Game.current
	if game == null or game.local_champion == null:
		push_error("[UI AUDIT] match did not start")
		get_tree().quit(1)
		return
	await _wait(1.5)
	var hud: HUD = game.get_node("HUD") as HUD
	await _capture("04_hud_default")

	var champion: Champion = game.local_champion
	champion.start_recall()
	await _wait(0.3)
	await _capture("04b_hud_recalling")
	champion.cancel_recall()
	champion.skill_points = 3
	champion.level = 6
	champion.gold = 99999
	for item_id: String in ["boots", "long_sword", "amp_tome", "ruby_crystal", "dagger", "cloth_armor"]:
		champion.buy_item(item_id)
	game.announcement.emit("Rift Behemoth has been slain by the Blue team!", GameConst.COLOR_GOLD, true)
	for i: int in range(6):
		game.kill_feed.emit({"killer": "VeryLongPlayerName%d" % i, "killer_team": 1, "victim": "AnotherLongName%d" % i,
				"victim_team": 2, "killer_champion": "", "victim_champion": "", "assists": 4})
	await _wait(0.6)
	await _capture("05_hud_busy")

	hud.call("_toggle_shop")
	await _wait(0.3)
	await _capture("06_shop")
	hud.call("_toggle_shop")

	hud._scoreboard_modal.visible = true
	hud.call("_refresh_scoreboard")
	await _wait(0.3)
	await _capture("07_scoreboard")
	hud._scoreboard_modal.visible = false

	hud.call("_open_settings")
	await _wait(0.3)
	await _capture("08_ingame_settings")
	hud.call("_open_settings")

	hud.call("_on_phase_changed", Game.Phase.ENDED)
	await _wait(0.3)
	await _capture("09_game_over")

	print("[UI AUDIT] finished with %d overflow issue(s)" % _issues)
	get_tree().quit(0 if _issues == 0 else 2)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_audit(label)
	var image: Image = get_viewport().get_texture().get_image()
	if image:
		image.save_png("%s/%s.png" % [_out_dir, label])


func _audit(label: String) -> void:
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1.0)
	var reported: int = 0
	for control: Control in _visible_controls(get_tree().root):
		if control.size.x < 1.0 or control.size.y < 1.0 or _is_clipped_by_ancestor(control):
			continue
		var rect: Rect2 = control.get_global_rect()
		if not screen.encloses(rect):
			reported += 1
			if reported <= 12:
				print("[UI AUDIT] %s: OFFSCREEN %s rect=%s" % [label, _short_path(control), rect])
	_issues += reported
	print("[UI AUDIT] %s: %d offscreen control(s)" % [label, reported])


func _visible_controls(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child: Node in node.get_children():
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		if child is Control:
			result.append(child)
		result.append_array(_visible_controls(child))
	return result


func _is_clipped_by_ancestor(control: Control) -> bool:
	var parent: Node = control.get_parent()
	while parent is Control:
		if (parent as Control).clip_contents or parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false


func _short_path(node: Node) -> String:
	var parts: PackedStringArray = []
	var current: Node = node
	while current and parts.size() < 5:
		parts.insert(0, "%s(%s)" % [current.name, current.get_class()])
		current = current.get_parent()
	return "/".join(parts)
