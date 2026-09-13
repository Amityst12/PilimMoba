extends Node
## Connection lifecycle, lobby state and scene flow (menu -> lobby -> match -> lobby).
##
## The host is authoritative over the lobby: clients send requests (team, champion, chat)
## and the host broadcasts the resulting lobby state. Practice mode runs the same code
## with an OfflineMultiplayerPeer, so single player and multiplayer share every code path.

signal lobby_changed
signal status_changed(text: String, is_error: bool)
signal chat_received(sender: String, team: int, text: String)
signal peer_left(peer_id: int, player_name: String)

enum Mode { NONE, HOST, CLIENT, OFFLINE }

const MENU_SCENE: String = "res://ui/menu/MainMenu.tscn"
const LOBBY_SCENE: String = "res://ui/menu/Lobby.tscn"
const GAME_SCENE: String = "res://game/Game.tscn"
const CONNECT_TIMEOUT: float = 8.0
const BOT_NAMES: Array[String] = ["Aria", "Bram", "Cora", "Dax", "Elin", "Finn", "Gwen", "Hugo", "Iris", "Juno"]

var mode: Mode = Mode.NONE
## peer id (bots use negative ids) -> {id, name, team, champion, bot}
var players: Dictionary = {}
var in_match: bool = false
var dedicated: bool = false
var host_port: int = GameConst.DEFAULT_PORT
## Message the main menu shows after returning (e.g. why the connection closed).
var pending_message: String = ""
var launch_options: Dictionary = {}
var launch_consumed: bool = false

var _pending_name: String = ""
var _connect_elapsed: float = -1.0
var _next_bot_id: int = -1
var _quit_after: float = -1.0
var _screenshot_times: Array[float] = []
var _screenshot_dir: String = ""
var _run_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_parse_launch_options()


# --- Public API -------------------------------------------------------------------------------------

func host(port: int, player_name: String, as_dedicated: bool = false) -> Error:
	close_connection()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, GameConst.MAX_PLAYERS)
	if error != OK:
		status_changed.emit("Could not host on port %d (%s). Is a server already running on this port?" % [port, error_string(error)], true)
		return error
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	dedicated = as_dedicated
	host_port = port
	players.clear()
	in_match = false
	if not dedicated:
		players[1] = _make_player(1, sanitize_name(player_name, 1), GameConst.TEAM_BLUE, Settings.last_champion, false)
	lobby_changed.emit()
	_change_scene(LOBBY_SCENE)
	return OK


func join(address: String, port: int, player_name: String) -> Error:
	close_connection()
	address = address.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		status_changed.emit("Could not connect to %s:%d (%s)." % [address, port, error_string(error)], true)
		return error
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	_pending_name = player_name
	_connect_elapsed = 0.0
	status_changed.emit("Connecting to %s:%d..." % [address, port], false)
	return OK


func start_practice(player_name: String) -> void:
	close_connection()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.OFFLINE
	players.clear()
	in_match = false
	players[1] = _make_player(1, sanitize_name(player_name, 1), GameConst.TEAM_BLUE, Settings.last_champion, false)
	_add_bot(GameConst.TEAM_BLUE)
	_add_bot(GameConst.TEAM_RED)
	_add_bot(GameConst.TEAM_RED)
	lobby_changed.emit()
	_change_scene(LOBBY_SCENE)


## Leaves the current session and returns to the main menu with an optional message.
func leave(message: String = "") -> void:
	close_connection()
	pending_message = message
	_change_scene(MENU_SCENE)


func close_connection() -> void:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	mode = Mode.NONE
	if peer != null and not (peer is OfflineMultiplayerPeer):
		peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	in_match = false
	dedicated = false
	_connect_elapsed = -1.0


func is_host() -> bool:
	return mode == Mode.HOST or mode == Mode.OFFLINE


func is_online_host() -> bool:
	return mode == Mode.HOST


func is_offline() -> bool:
	return mode == Mode.OFFLINE


func local_id() -> int:
	return multiplayer.get_unique_id()


func local_player() -> Dictionary:
	return players.get(local_id(), {})


func local_team() -> int:
	return int(local_player().get("team", GameConst.TEAM_BLUE))


func team_count(team: int) -> int:
	var count: int = 0
	for info: Dictionary in players.values():
		if int(info["team"]) == team:
			count += 1
	return count


static func local_ipv4_addresses() -> PackedStringArray:
	var result: PackedStringArray = []
	for address: String in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254"):
			result.append(address)
	return result


static func sanitize_text(text: String, max_length: int) -> String:
	var clean: String = text.strip_edges().replace("\n", " ").replace("\t", " ")
	clean = clean.replace("[", "(").replace("]", ")")
	return clean.substr(0, max_length)


func sanitize_name(player_name: String, id: int) -> String:
	var clean: String = sanitize_text(player_name, 16)
	if clean.is_empty():
		clean = "Player%d" % (absi(id) % 1000)
	var base: String = clean
	var suffix: int = 2
	while _name_taken(clean, id):
		clean = "%s%d" % [base.substr(0, 14), suffix]
		suffix += 1
	return clean


# --- Lobby requests (any peer -> host) ------------------------------------------------------------------

func request_team(team: int) -> void:
	_rpc_request_team.rpc_id(1, team)


func request_champion(champion_id: String) -> void:
	Settings.last_champion = champion_id
	Settings.save_settings()
	_rpc_request_champion.rpc_id(1, champion_id)


func request_add_bot(team: int) -> void:
	_rpc_request_add_bot.rpc_id(1, team)


func request_remove(player_id: int) -> void:
	_rpc_request_remove.rpc_id(1, player_id)


func request_bot_champion(bot_id: int, champion_id: String) -> void:
	_rpc_request_bot_champion.rpc_id(1, bot_id, champion_id)


func request_start() -> void:
	_rpc_request_start.rpc_id(1)


func send_chat(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	_rpc_chat_request.rpc_id(1, text)


func start_match() -> void:
	if not is_host() or in_match or players.is_empty():
		return
	in_match = true
	_broadcast_lobby()
	_rpc_load_game.rpc()


func return_to_lobby() -> void:
	if not is_host() or not in_match:
		return
	if Game.current:
		Game.current.cleanup_networked_entities()
	await get_tree().create_timer(0.4).timeout
	in_match = false
	_broadcast_lobby()
	_rpc_return_to_lobby.rpc()


# --- Connection events ------------------------------------------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server() or not players.has(id):
		return
	var player_name: String = players[id]["name"]
	players.erase(id)
	if in_match:
		peer_left.emit(id, player_name)
	_broadcast_lobby()
	_system_chat("%s left the game." % player_name)


func _on_connected_to_server() -> void:
	_connect_elapsed = -1.0
	status_changed.emit("Connected! Joining lobby...", false)
	_rpc_register.rpc_id(1, _pending_name, GameConst.GAME_VERSION)


func _on_connection_failed() -> void:
	if mode == Mode.CLIENT:
		leave("Could not connect to the server. Check the address, port and firewall.")


func _on_server_disconnected() -> void:
	if mode == Mode.CLIENT:
		leave("Disconnected: the host closed the game.")


func _process(delta: float) -> void:
	_run_time += delta
	if _connect_elapsed >= 0.0:
		_connect_elapsed += delta
		if _connect_elapsed > CONNECT_TIMEOUT and mode == Mode.CLIENT:
			leave("Connection timed out. Make sure the host is running and the port is open.")
	_process_dev_options()


# --- RPC handlers ---------------------------------------------------------------------------------------------

func _sender() -> int:
	var sender: int = multiplayer.get_remote_sender_id()
	return sender if sender != 0 else multiplayer.get_unique_id()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_register(player_name: String, version: String) -> void:
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	if version != GameConst.GAME_VERSION:
		_reject(id, "Version mismatch: host runs %s, you run %s." % [GameConst.GAME_VERSION, version])
		return
	if in_match:
		_reject(id, "A match is in progress. Try again when it ends.")
		return
	var team: int = GameConst.TEAM_BLUE if team_count(GameConst.TEAM_BLUE) <= team_count(GameConst.TEAM_RED) else GameConst.TEAM_RED
	if team_count(team) >= GameConst.MAX_TEAM_SIZE:
		# Replace a bot if the lobby is full of bots.
		var bot_id: int = _find_bot(team)
		if bot_id == 0:
			bot_id = _find_bot(GameConst.enemy_team(team))
			team = GameConst.enemy_team(team)
		if bot_id == 0:
			_reject(id, "The lobby is full.")
			return
		players.erase(bot_id)
	players[id] = _make_player(id, sanitize_name(player_name, id), team, String(ChampionDB.default_id()), false)
	_broadcast_lobby()
	_system_chat("%s joined the lobby." % players[id]["name"])


func _reject(id: int, reason: String) -> void:
	_rpc_rejected.rpc_id(id, reason)
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if multiplayer.multiplayer_peer != null and mode == Mode.HOST:
			multiplayer.multiplayer_peer.disconnect_peer(id))


@rpc("authority", "call_remote", "reliable")
func _rpc_rejected(reason: String) -> void:
	leave(reason)


@rpc("authority", "call_remote", "reliable")
func _rpc_lobby_state(state: Dictionary, match_running: bool) -> void:
	var was_empty: bool = players.is_empty()
	players = state
	in_match = match_running
	if was_empty and not in_match:
		_change_scene(LOBBY_SCENE)
	lobby_changed.emit()


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_team(team: int) -> void:
	var id: int = _sender()
	if not multiplayer.is_server() or in_match or not players.has(id):
		return
	if team != GameConst.TEAM_BLUE and team != GameConst.TEAM_RED or int(players[id]["team"]) == team:
		return
	if team_count(team) >= GameConst.MAX_TEAM_SIZE:
		return
	players[id]["team"] = team
	_broadcast_lobby()


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_champion(champion_id: String) -> void:
	var id: int = _sender()
	if not multiplayer.is_server() or in_match or not players.has(id) or not ChampionDB.has_champion(StringName(champion_id)):
		return
	players[id]["champion"] = champion_id
	_broadcast_lobby()


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_add_bot(team: int) -> void:
	if not multiplayer.is_server() or _sender() != 1 or in_match:
		return
	_add_bot(team)
	_broadcast_lobby()


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_remove(player_id: int) -> void:
	if not multiplayer.is_server() or _sender() != 1 or in_match or player_id == 1 or not players.has(player_id):
		return
	var info: Dictionary = players[player_id]
	players.erase(player_id)
	if not bool(info["bot"]):
		_reject(player_id, "You were removed from the lobby by the host.")
		_system_chat("%s was removed by the host." % info["name"])
	_broadcast_lobby()


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_bot_champion(bot_id: int, champion_id: String) -> void:
	if not multiplayer.is_server() or _sender() != 1 or in_match or not players.has(bot_id):
		return
	if bool(players[bot_id]["bot"]) and ChampionDB.has_champion(StringName(champion_id)):
		players[bot_id]["champion"] = champion_id
		_broadcast_lobby()


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_start() -> void:
	if multiplayer.is_server() and _sender() == 1:
		start_match()


@rpc("any_peer", "call_local", "reliable")
func _rpc_chat_request(text: String) -> void:
	if not multiplayer.is_server():
		return
	var id: int = _sender()
	var clean: String = sanitize_text(text, 140)
	if clean.is_empty():
		return
	var info: Dictionary = players.get(id, {})
	var sender_name: String = String(info.get("name", "Spectator"))
	_rpc_chat.rpc(sender_name, int(info.get("team", 0)), clean)


@rpc("authority", "call_local", "reliable")
func _rpc_chat(sender_name: String, team: int, text: String) -> void:
	chat_received.emit(sender_name, team, text)


@rpc("authority", "call_local", "reliable")
func _rpc_load_game() -> void:
	in_match = true
	_change_scene(GAME_SCENE)


@rpc("authority", "call_local", "reliable")
func _rpc_return_to_lobby() -> void:
	in_match = false
	_change_scene(LOBBY_SCENE)


# --- Internals -----------------------------------------------------------------------------------------------

func _broadcast_lobby() -> void:
	lobby_changed.emit()
	if mode == Mode.HOST:
		_rpc_lobby_state.rpc(players, in_match)


func _system_chat(text: String) -> void:
	if multiplayer.is_server():
		_rpc_chat.rpc("", 0, text)


func _make_player(id: int, player_name: String, team: int, champion_id: String, is_bot: bool) -> Dictionary:
	if not ChampionDB.has_champion(StringName(champion_id)):
		champion_id = String(ChampionDB.default_id())
	return {"id": id, "name": player_name, "team": team, "champion": champion_id, "bot": is_bot}


func _add_bot(team: int) -> void:
	if team_count(team) >= GameConst.MAX_TEAM_SIZE or players.size() >= GameConst.MAX_PLAYERS:
		return
	var id: int = _next_bot_id
	_next_bot_id -= 1
	var used: Dictionary = {}
	for info: Dictionary in players.values():
		used[info["name"]] = true
	var bot_name: String = "Bot"
	for candidate: String in BOT_NAMES:
		if not used.has("Bot " + candidate):
			bot_name = "Bot " + candidate
			break
	var champion_ids: Array[StringName] = ChampionDB.IDS
	var champion_id: String = String(champion_ids[absi(id) % champion_ids.size()])
	players[id] = _make_player(id, bot_name, team, champion_id, true)


func _find_bot(team: int) -> int:
	for id: int in players:
		if bool(players[id]["bot"]) and int(players[id]["team"]) == team:
			return id
	return 0


func _name_taken(player_name: String, id: int) -> bool:
	for other_id: int in players:
		if other_id != id and String(players[other_id]["name"]).to_lower() == player_name.to_lower():
			return true
	return false


func _change_scene(path: String) -> void:
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == path and path != LOBBY_SCENE:
		return
	get_tree().call_deferred("change_scene_to_file", path)


# --- Command line options (testing & tooling) --------------------------------------------------------------------

func _parse_launch_options() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var pair: PackedStringArray = arg.substr(2).split("=", true, 1)
		launch_options[pair[0]] = pair[1] if pair.size() > 1 else "true"
	if launch_options.has("timescale"):
		Engine.time_scale = clampf(float(launch_options["timescale"]), 0.1, 20.0)
	if launch_options.has("quit-after"):
		_quit_after = float(launch_options["quit-after"])
	if launch_options.has("screenshot-dir"):
		_screenshot_dir = String(launch_options["screenshot-dir"])
		for t: String in String(launch_options.get("shots", "5")).split(","):
			_screenshot_times.append(float(t))
	if launch_options.has("autotest"):
		var script: GDScript = load("res://tests/AutoTest.gd") as GDScript
		if script:
			var agent: Node = script.new()
			agent.name = "AutoTest"
			add_child.call_deferred(agent)


func _process_dev_options() -> void:
	if _quit_after > 0.0 and _run_time >= _quit_after:
		_quit_after = -1.0
		get_tree().quit()
	if not _screenshot_times.is_empty() and _run_time >= _screenshot_times[0]:
		var t: float = _screenshot_times.pop_front()
		var image: Image = get_viewport().get_texture().get_image()
		if image:
			DirAccess.make_dir_recursive_absolute(_screenshot_dir)
			var scene_name: String = get_tree().current_scene.name if get_tree().current_scene else "none"
			image.save_png("%s/shot_%05.1f_%s.png" % [_screenshot_dir, t, scene_name])
