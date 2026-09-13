class_name ItemDB
extends RefCounted
## Shop item table. Stats keys:
##   ad (attack damage), ap (ability power), hp (max health), mana, armor, mr (magic resist),
##   as (attack speed fraction), ms (flat move speed), hp_regen, mana_regen, cdr (cooldown reduction fraction)

const ITEMS: Dictionary = {
	"long_sword": {"name": "Long Sword", "cost": 350, "stats": {"ad": 12}},
	"amp_tome": {"name": "Amplifying Tome", "cost": 400, "stats": {"ap": 25}},
	"ruby_crystal": {"name": "Ruby Crystal", "cost": 400, "stats": {"hp": 160}},
	"sapphire_crystal": {"name": "Sapphire Crystal", "cost": 300, "stats": {"mana": 250, "mana_regen": 1.0}},
	"dagger": {"name": "Dagger", "cost": 300, "stats": {"as": 0.15}},
	"cloth_armor": {"name": "Cloth Armor", "cost": 300, "stats": {"armor": 18}},
	"null_mantle": {"name": "Null-Magic Mantle", "cost": 400, "stats": {"mr": 24}},
	"boots": {"name": "Boots of Speed", "cost": 350, "stats": {"ms": 0.7}},
	"blade_of_ruin": {"name": "Blade of Ruin", "cost": 1500, "stats": {"ad": 40, "as": 0.2}},
	"storm_bow": {"name": "Storm Bow", "cost": 1350, "stats": {"ad": 20, "as": 0.35, "ms": 0.3}},
	"archmage_staff": {"name": "Archmage Staff", "cost": 1500, "stats": {"ap": 75, "cdr": 0.1}},
	"crystal_heart": {"name": "Crystal Heart", "cost": 1250, "stats": {"ap": 40, "mana": 400, "cdr": 0.1}},
	"titan_plate": {"name": "Titan Plate", "cost": 1400, "stats": {"hp": 450, "armor": 25}},
	"spirit_cloak": {"name": "Spirit Cloak", "cost": 1200, "stats": {"hp": 300, "mr": 35, "hp_regen": 2.0}},
}

## Display order in the shop.
const SHOP_ORDER: Array[String] = [
	"long_sword", "amp_tome", "ruby_crystal", "sapphire_crystal", "dagger", "cloth_armor", "null_mantle",
	"boots", "blade_of_ruin", "storm_bow", "archmage_staff", "crystal_heart", "titan_plate", "spirit_cloak",
]

const STAT_LABELS: Dictionary = {
	"ad": "Attack Damage", "ap": "Ability Power", "hp": "Health", "mana": "Mana", "armor": "Armor",
	"mr": "Magic Resist", "as": "Attack Speed", "ms": "Move Speed", "hp_regen": "Health Regen",
	"mana_regen": "Mana Regen", "cdr": "Cooldown Reduction",
}

static var _icon_cache: Dictionary = {}


static func exists(item_id: String) -> bool:
	return ITEMS.has(item_id)


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func cost(item_id: String) -> int:
	return int(get_item(item_id).get("cost", 0))


static func display_name(item_id: String) -> String:
	return String(get_item(item_id).get("name", item_id))


static func icon(item_id: String) -> Texture2D:
	if _icon_cache.has(item_id):
		return _icon_cache[item_id]
	var path: String = "res://assets/icons/items/%s.svg" % item_id
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_icon_cache[item_id] = tex
	return tex


static func format_stat(key: String, value: float) -> String:
	var label: String = STAT_LABELS.get(key, key)
	match key:
		"as", "cdr":
			return "+%d%% %s" % [roundi(value * 100.0), label]
		"ms", "hp_regen", "mana_regen":
			return "+%.1f %s" % [value, label]
	return "+%d %s" % [roundi(value), label]


static func stats_bbcode(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]  [color=#ffd060]%dg[/color]" % [item.get("name", item_id), item.get("cost", 0)])
	var stats: Dictionary = item.get("stats", {})
	for key: String in stats:
		lines.append("[color=#b8e0a0]%s[/color]" % format_stat(key, float(stats[key])))
	return "\n".join(lines)


## Sums the stats of a list of item ids.
static func total_stats(item_ids: PackedStringArray) -> Dictionary:
	var total: Dictionary = {}
	for item_id: String in item_ids:
		var stats: Dictionary = get_item(item_id).get("stats", {})
		for key: String in stats:
			total[key] = float(total.get(key, 0.0)) + float(stats[key])
	return total
