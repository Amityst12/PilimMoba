class_name ChampionData
extends Resource
## Static definition of a playable champion: base stats, growth, kit and presentation.

@export var id: StringName = &""
@export var display_name: String = "Champion"
@export var title: String = ""
@export var role: String = "Fighter"
@export_multiline var lore: String = ""
@export var color: Color = Color(0.5, 0.7, 1.0)
@export var model_scene: PackedScene
@export var portrait: Texture2D
@export var splash_art: Texture2D
@export var loading_card: Texture2D
## 1 (easy) .. 3 (hard), shown in champion select.
@export_range(1, 3) var difficulty: int = 1

@export_group("Base Stats")
@export var max_health: float = 600.0
@export var health_per_level: float = 90.0
@export var health_regen: float = 1.5
@export var health_regen_per_level: float = 0.12
@export var max_mana: float = 340.0
@export var mana_per_level: float = 38.0
@export var mana_regen: float = 2.2
@export var mana_regen_per_level: float = 0.12
@export var attack_damage: float = 55.0
@export var attack_damage_per_level: float = 3.2
@export var attack_speed: float = 0.65
## Fractional attack speed gained per level (0.025 = +2.5%).
@export var attack_speed_per_level: float = 0.02
@export var attack_range: float = 1.8
@export var armor: float = 25.0
@export var armor_per_level: float = 4.0
@export var magic_resist: float = 30.0
@export var magic_resist_per_level: float = 1.3
@export var move_speed: float = 5.8
@export var radius: float = 0.55

@export_group("Basic Attack")
## Empty = melee attack.
@export var attack_projectile_style: StringName = &""
@export var attack_projectile_speed: float = 20.0
@export var attack_windup: float = 0.3

@export_group("Kit")
@export var passive: PassiveData
## Exactly 4 abilities: Q, W, E, R (R should have is_ultimate = true).
@export var abilities: Array[AbilityData] = []

@export_group("Bot Behaviour")
## Order in which the bot ranks up its basic abilities (slot indices 0..2).
@export var bot_skill_priority: PackedInt32Array = PackedInt32Array([0, 2, 1])
## Item ids the bot buys in order.
@export var bot_item_build: PackedStringArray = PackedStringArray()
## Preferred distance a bot keeps from enemies (ranged champions kite).
@export var bot_preferred_range: float = 5.0


func stat(base: float, per_level: float, level: int) -> float:
	return base + per_level * float(level - 1)


func is_ranged() -> bool:
	return attack_projectile_style != &""


func get_splash_art() -> Texture2D:
	if splash_art:
		return splash_art
	for ext: String in ["png", "webp", "jpg"]:
		var path: String = "res://assets/SplashArts/%s_splash.%s" % [id, ext]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return portrait


func get_loading_card() -> Texture2D:
	if loading_card:
		return loading_card
	for ext: String in ["png", "webp", "jpg"]:
		var path: String = "res://assets/SplashArts/%s_card.%s" % [id, ext]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return get_splash_art()

