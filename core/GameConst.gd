class_name GameConst
extends RefCounted
## Global constants, enums and tuning values shared by every system.
## Balance the game from here: most numbers that affect pacing live in this file.

const GAME_VERSION: String = "1.0.0"
const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 10
const MAX_TEAM_SIZE: int = 5

# --- Teams -------------------------------------------------------------------
const TEAM_NONE: int = 0
const TEAM_BLUE: int = 1
const TEAM_RED: int = 2

const COLOR_BLUE: Color = Color(0.25, 0.62, 1.0)
const COLOR_RED: Color = Color(1.0, 0.3, 0.34)
const COLOR_SELF: Color = Color(0.55, 0.9, 0.25)
const COLOR_GOLD: Color = Color(1.0, 0.8, 0.3)
const COLOR_MANA: Color = Color(0.3, 0.6, 1.0)
const COLOR_XP: Color = Color(0.72, 0.45, 1.0)

# --- Physics layers (bit values) ---------------------------------------------
const LAYER_WORLD: int = 1
const LAYER_UNITS: int = 2

# --- Damage ------------------------------------------------------------------
enum DamageType { PHYSICAL, MAGIC, TRUE }

# --- Status effects ----------------------------------------------------------
enum Status {
	SLOW,          ## value = fraction of move speed removed (0.3 = 30% slow)
	HASTE,         ## value = fraction of move speed added
	STUN,          ## cannot move, attack or cast
	ROOT,          ## cannot move (can still attack / cast non-movement abilities)
	SHIELD,        ## value = damage absorbed
	ATTACK_SPEED,  ## value = fraction of attack speed added
	EMPOWER,       ## value = bonus physical damage on the next basic attack
	UNTARGETABLE,  ## cannot be targeted or hit (leaps, blinks)
	SILENCE,       ## cannot cast abilities
	BLUE_BUFF,     ## +mana regen and +20% CDR
	RED_BUFF,      ## basic attacks burn & slow
	BOSS_BUFF,     ## +15% AD and +20% AP
}

# Replicated bitmask so clients can render status visuals.
const FLAG_STUNNED: int = 1
const FLAG_ROOTED: int = 2
const FLAG_SLOWED: int = 4
const FLAG_HASTED: int = 8
const FLAG_SHIELDED: int = 16
const FLAG_EMPOWERED: int = 32
const FLAG_UNTARGETABLE: int = 64
const FLAG_RECALLING: int = 128
const FLAG_CASTING: int = 256
const FLAG_SILENCED: int = 512
const FLAG_BLUE_BUFF: int = 1024
const FLAG_RED_BUFF: int = 2048
const FLAG_BOSS_BUFF: int = 4096

# --- Smart Pings -------------------------------------------------------------
enum PingType { ALERT, DANGER, ON_MY_WAY, ASSIST }

static func ping_color(type: int) -> Color:
	match type:
		PingType.ALERT: return Color(1.0, 0.85, 0.2)
		PingType.DANGER: return Color(1.0, 0.25, 0.2)
		PingType.ON_MY_WAY: return Color(0.2, 0.85, 1.0)
		PingType.ASSIST: return Color(0.3, 1.0, 0.4)
	return Color.WHITE

static func ping_label(type: int) -> String:
	match type:
		PingType.ALERT: return "Alert"
		PingType.DANGER: return "Danger!"
		PingType.ON_MY_WAY: return "On My Way"
		PingType.ASSIST: return "Assist Me"
	return "Ping"

# --- Economy & progression ---------------------------------------------------
const ARAM_MODE: bool = true
const STARTING_GOLD: int = 1400
const STARTING_LEVEL: int = 3
const STARTING_SKILL_POINTS: int = 3
const PASSIVE_GOLD_PER_SEC: float = 5.5
const PASSIVE_XP_PER_SEC: float = 8.0
const MAX_LEVEL: int = 18
const XP_SHARE_RADIUS: float = 16.0
const KILL_GOLD: int = 300
const FIRST_BLOOD_BONUS: int = 100
const ASSIST_GOLD_POOL: int = 150
const ASSIST_WINDOW: float = 10.0
const CHAMPION_KILL_XP_BASE: float = 140.0
const CHAMPION_KILL_XP_PER_LEVEL: float = 35.0
const TOWER_TEAM_GOLD: int = 150
const INVENTORY_SIZE: int = 6
const SELL_RATIO: float = 0.6

# --- Match pacing ------------------------------------------------------------
const FIRST_WAVE_TIME: float = 12.0
const WAVE_INTERVAL: float = 30.0
const WAVE_MELEE_COUNT: int = 3
const WAVE_CASTER_COUNT: int = 3
const WAVE_SPAWN_SPACING: float = 0.9
const RESPAWN_BASE: float = 5.0
const RESPAWN_PER_LEVEL: float = 1.6
const RECALL_ENABLED: bool = false
const RECALL_DURATION: float = 4.0
const FOUNTAIN_RADIUS: float = 8.0
const FOUNTAIN_HEAL_FRACTION: float = 0.0  # In ARAM, fountain does not heal!
const FOUNTAIN_ENEMY_DPS: float = 700.0
const END_SCREEN_AUTO_RETURN: float = 25.0
const HEALTH_RELIC_COOLDOWN: float = 60.0
const HEALTH_RELIC_BURST_DELAY: float = 2.5
const HEALTH_RELIC_RADIUS: float = 3.5

# --- Structures --------------------------------------------------------------
const BACKDOOR_REDUCTION: float = 0.66
const BACKDOOR_MINION_RADIUS: float = 12.0

# --- Skill ranks -------------------------------------------------------------
## Champion level required for each rank of the ultimate (R).
const ULT_RANK_LEVELS: Array[int] = [6, 11, 16]


static func enemy_team(team: int) -> int:
	if team == TEAM_BLUE:
		return TEAM_RED
	if team == TEAM_RED:
		return TEAM_BLUE
	return TEAM_NONE


static func team_color(team: int) -> Color:
	match team:
		TEAM_BLUE:
			return COLOR_BLUE
		TEAM_RED:
			return COLOR_RED
	return Color(0.7, 0.7, 0.7)


static func team_name(team: int) -> String:
	match team:
		TEAM_BLUE:
			return "Blue"
		TEAM_RED:
			return "Red"
	return "Neutral"


## Total XP needed to go from `level` to `level + 1`.
static func xp_to_next_level(level: int) -> float:
	return 180.0 + 90.0 * float(level - 1)


static func respawn_time(level: int) -> float:
	return RESPAWN_BASE + RESPAWN_PER_LEVEL * float(level)


static func damage_type_color(damage_type: int) -> Color:
	match damage_type:
		DamageType.PHYSICAL:
			return Color(1.0, 0.62, 0.25)
		DamageType.MAGIC:
			return Color(0.55, 0.65, 1.0)
	return Color(1.0, 1.0, 1.0)


## Armor / magic resist mitigation: 100 resist = 50% damage taken.
static func mitigate(amount: float, resist: float) -> float:
	if resist >= 0.0:
		return amount * 100.0 / (100.0 + resist)
	return amount * (2.0 - 100.0 / (100.0 - resist))


static func format_time(seconds: float) -> String:
	var s: int = maxi(0, int(seconds))
	return "%d:%02d" % [s / 60, s % 60]
