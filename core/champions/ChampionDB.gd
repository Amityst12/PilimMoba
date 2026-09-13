class_name ChampionDB
extends RefCounted
## Registry of playable champions. Add a new champion by creating
## `res://data/champions/<id>.tres` and adding its id to IDS.

const IDS: Array[StringName] = [&"erez", &"stephen", &"amit", &"nissim", &"rogo", &"yakir", &"lior"]

static var _cache: Dictionary = {}


static func get_champion(champion_id: StringName) -> ChampionData:
	if _cache.has(champion_id):
		return _cache[champion_id]
	var path: String = "res://data/champions/%s.tres" % champion_id
	if not ResourceLoader.exists(path):
		push_error("Unknown champion id: %s" % champion_id)
		return null
	var data: ChampionData = load(path) as ChampionData
	_cache[champion_id] = data
	return data


static func has_champion(champion_id: StringName) -> bool:
	return IDS.has(champion_id) or ResourceLoader.exists("res://data/champions/%s.tres" % champion_id)


static func all() -> Array[ChampionData]:
	var result: Array[ChampionData] = []
	for champion_id: StringName in IDS:
		var data: ChampionData = get_champion(champion_id)
		if data:
			result.append(data)
	return result


static func default_id() -> StringName:
	return IDS[0]

