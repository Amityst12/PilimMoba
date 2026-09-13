extends Node
## Persistent user preferences (stored in user://settings.cfg) and global UI theme setup.

const SETTINGS_PATH: String = "user://settings.cfg"

const RESOLUTIONS_16_9: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const RESOLUTION_LABELS_16_9: Array[String] = [
	"1280 x 720 (720p HD - 16:9)",
	"1366 x 768 (Laptop - 16:9)",
	"1600 x 900 (900p HD+ - 16:9)",
	"1920 x 1080 (1080p FHD - 16:9)",
	"2560 x 1440 (2K QHD - 16:9)",
]

const WINDOW_MODES: Array[String] = [
	"Windowed (16:9)",
	"Fullscreen (מסך מלא)",
	"Borderless (חלון מלא ללא מסגרת)",
]

var player_name: String = ""
var last_address: String = "127.0.0.1"
var port: int = GameConst.DEFAULT_PORT
var last_champion: String = "erez"
var master_volume: float = 0.8
var sfx_volume: float = 0.9
var resolution_idx: int = 0
var window_mode_idx: int = 0
var fullscreen: bool:
	get: return window_mode_idx == 1
	set(v): window_mode_idx = 1 if v else 0
var vsync: bool = true
var show_fps: bool = false
var camera_locked: bool = true
var screen_shake: bool = true


func _ready() -> void:
	load_settings()
	if player_name.strip_edges().is_empty():
		var system_name: String = OS.get_environment("USERNAME")
		if system_name.is_empty():
			system_name = OS.get_environment("USER")
		player_name = system_name.substr(0, 16) if not system_name.is_empty() else "Player%d" % (randi() % 900 + 100)
	apply()
	get_tree().root.theme = UITheme.build()
	UICursor.set_attack(false)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	player_name = config.get_value("player", "name", player_name)
	last_address = config.get_value("network", "address", last_address)
	port = config.get_value("network", "port", port)
	last_champion = config.get_value("player", "champion", last_champion)
	if not ChampionDB.IDS.has(StringName(last_champion)):
		last_champion = String(ChampionDB.default_id())
	master_volume = config.get_value("audio", "master", master_volume)
	sfx_volume = config.get_value("audio", "sfx", sfx_volume)
	resolution_idx = config.get_value("video", "resolution_idx", resolution_idx)
	window_mode_idx = config.get_value("video", "window_mode_idx", 1 if config.get_value("video", "fullscreen", false) else 0)
	vsync = config.get_value("video", "vsync", vsync)
	show_fps = config.get_value("video", "show_fps", show_fps)
	camera_locked = config.get_value("game", "camera_locked", camera_locked)
	screen_shake = config.get_value("game", "screen_shake", screen_shake)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "name", player_name)
	config.set_value("player", "champion", last_champion)
	config.set_value("network", "address", last_address)
	config.set_value("network", "port", port)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "resolution_idx", resolution_idx)
	config.set_value("video", "window_mode_idx", window_mode_idx)
	config.set_value("video", "fullscreen", window_mode_idx == 1)
	config.set_value("video", "vsync", vsync)
	config.set_value("video", "show_fps", show_fps)
	config.set_value("game", "camera_locked", camera_locked)
	config.set_value("game", "screen_shake", screen_shake)
	config.save(SETTINGS_PATH)


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	if DisplayServer.get_name() == "headless":
		return

	var res: Vector2i = RESOLUTIONS_16_9[clampi(resolution_idx, 0, RESOLUTIONS_16_9.size() - 1)]

	match window_mode_idx:
		0: # Windowed 16:9
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(res)
			var screen_id: int = DisplayServer.window_get_current_screen()
			var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
			var pos: Vector2i = (screen_size - res) / 2
			if pos.x >= 0 and pos.y >= 0:
				DisplayServer.window_set_position(pos)
		1: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: # Borderless Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen_id: int = DisplayServer.window_get_current_screen()
			var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
			DisplayServer.window_set_size(screen_size)
			DisplayServer.window_set_position(Vector2i.ZERO)

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
