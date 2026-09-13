extends RefCounted

const GameConst = preload("res://core/GameConst.gd")
const StatusEffectData = preload("res://core/combat/StatusEffectData.gd")
const AbilityData = preload("res://core/abilities/AbilityData.gd")
const ProjectileAbility = preload("res://core/abilities/ProjectileAbility.gd")
const DashAbility = preload("res://core/abilities/DashAbility.gd")
const AreaAbility = preload("res://core/abilities/AreaAbility.gd")
const BeamAbility = preload("res://core/abilities/BeamAbility.gd")
const SelfBuffAbility = preload("res://core/abilities/SelfBuffAbility.gd")
const PassiveData = preload("res://core/abilities/PassiveData.gd")
const CastCounterPassive = preload("res://core/abilities/CastCounterPassive.gd")
const AttackStackPassive = preload("res://core/abilities/AttackStackPassive.gd")
const AttackCounterPassive = preload("res://core/abilities/AttackCounterPassive.gd")
const ChampionData = preload("res://core/champions/ChampionData.gd")

func _init() -> void:

	print("Generating champion and ability data resources...")
	DirAccess.make_dir_recursive_absolute("res://data/champions")
	DirAccess.make_dir_recursive_absolute("res://data/abilities")

	_build_arcanist()
	_build_warden()
	_build_ranger()
	_build_wraith()
	_build_luminary()

	print("All champion data resources generated successfully!")

func _build_arcanist() -> void:
	var champ := ChampionData.new()
	champ.id = &"arcanist"
	champ.display_name = "Arcanist"
	champ.title = "The Rift Sorcerer"
	champ.role = "Mage"
	champ.lore = "A master of spatial manipulation who bends arcane energy across dimensions."
	champ.color = Color(0.3, 0.6, 1.0)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/ArcanistModel.tscn")
	champ.portrait = load("res://assets/icons/champions/arcanist.svg")

	champ.max_health = 560.0
	champ.health_per_level = 82.0
	champ.health_regen = 1.4
	champ.max_mana = 400.0
	champ.mana_per_level = 45.0
	champ.mana_regen = 2.4
	champ.attack_damage = 46.0
	champ.attack_damage_per_level = 2.8
	champ.attack_speed = 0.62
	champ.attack_range = 5.6
	champ.armor = 22.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.6

	champ.attack_projectile_style = &"arcane"
	champ.attack_projectile_speed = 22.0
	champ.attack_windup = 0.25

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"arcane_flow"
	passive.display_name = "Arcane Surge"
	passive.description = "Every 3rd ability cast grants +35% movement speed for 2.5s."
	passive.color = Color(0.3, 0.7, 1.0)
	passive.icon = load("res://assets/icons/abilities/arcanist_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.5)]
	champ.passive = passive

	# Q
	var q := ProjectileAbility.new()
	q.id = &"mystic_bolt"
	q.display_name = "Mystic Bolt"
	q.description = "Fires a swift bolt of pure arcane energy in the target direction."
	q.color = Color(0.25, 0.65, 1.0)
	q.icon = load("res://assets/icons/abilities/arcanist_q.svg")
	q.fx_style = &"arcane"
	q.cast_range = 9.5
	q.indicator_size = 1.2
	q.projectile_speed = 22.0
	q.projectile_width = 1.2
	q.cooldown = PackedFloat32Array([5.0, 4.5, 4.0, 3.5, 3.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([75.0, 110.0, 145.0, 180.0, 215.0])
	q.ap_ratio = 0.65
	q.damage_type = GameConst.DamageType.MAGIC

	# W
	var w := DashAbility.new()
	w.id = &"phase_shift"
	w.display_name = "Phase Shift"
	w.description = "Instantly blinks a short distance, becoming briefly untargetable."
	w.color = Color(0.4, 0.8, 0.9)
	w.icon = load("res://assets/icons/abilities/arcanist_w.svg")
	w.fx_style = &"arcane"
	w.mode = DashAbility.Mode.BLINK
	w.targeting = AbilityData.Targeting.POINT
	w.cast_range = 6.0
	w.indicator_size = 1.0
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.UNTARGETABLE, 0.0, 0.25)]

	# E
	var e := AreaAbility.new()
	e.id = &"gravity_well"
	e.display_name = "Gravity Well"
	e.description = "Creates a field of heavy gravity that detonates after 0.6s, dealing damage and slowing enemies."
	e.color = Color(0.6, 0.3, 0.9)
	e.icon = load("res://assets/icons/abilities/arcanist_e.svg")
	e.fx_style = &"void"
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.5
	e.radius = 3.2
	e.delay = 0.6
	e.indicator_size = 3.2
	e.cooldown = PackedFloat32Array([10.0, 9.5, 9.0, 8.5, 8.0])
	e.mana_cost = PackedFloat32Array([65.0, 70.0, 75.0, 80.0, 85.0])
	e.base_damage = PackedFloat32Array([80.0, 120.0, 160.0, 200.0, 240.0])
	e.ap_ratio = 0.7
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	# R
	var r := BeamAbility.new()
	r.id = &"obliteration_beam"
	r.display_name = "Obliteration Beam"
	r.description = "Channels for 0.6s then unleashes a colossal beam across the arena that pierces all enemies."
	r.color = Color(1.0, 0.25, 0.4)
	r.icon = load("res://assets/icons/abilities/arcanist_r.svg")
	r.fx_style = &"solar"
	r.is_ultimate = true
	r.max_rank = 3
	r.targeting = AbilityData.Targeting.DIRECTION
	r.cast_range = 24.0
	r.beam_length = 24.0
	r.beam_width = 3.0
	r.indicator_size = 3.0
	r.charge_time = 0.6
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([260.0, 390.0, 520.0])
	r.ap_ratio = 0.9
	r.damage_type = GameConst.DamageType.MAGIC

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 2, 1])
	champ.bot_item_build = PackedStringArray(["amp_tome", "boots", "crystal_heart", "archmage_staff"])
	champ.bot_preferred_range = 5.5

	ResourceSaver.save(champ, "res://data/champions/arcanist.tres")

func _build_warden() -> void:
	var champ := ChampionData.new()
	champ.id = &"warden"
	champ.display_name = "Warden"
	champ.title = "The Bulwark"
	champ.role = "Tank"
	champ.lore = "An armored sentinel clad in runic iron who holds the front line against any onslaught."
	champ.color = Color(0.9, 0.65, 0.25)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/WardenModel.tscn")
	champ.portrait = load("res://assets/icons/champions/warden.svg")

	champ.max_health = 680.0
	champ.health_per_level = 98.0
	champ.health_regen = 2.0
	champ.max_mana = 320.0
	champ.mana_per_level = 32.0
	champ.mana_regen = 1.8
	champ.attack_damage = 60.0
	champ.attack_damage_per_level = 3.6
	champ.attack_speed = 0.65
	champ.attack_range = 1.8
	champ.armor = 38.0
	champ.magic_resist = 32.0
	champ.move_speed = 5.8

	champ.attack_projectile_style = &""
	champ.attack_windup = 0.3

	# Passive
	var passive := AttackStackPassive.new()
	passive.id = &"ironhide"
	passive.display_name = "Ironhide"
	passive.description = "Attacking grants stacking attack speed and move speed."
	passive.color = Color(0.9, 0.7, 0.3)
	passive.icon = load("res://assets/icons/abilities/warden_p.svg")
	passive.attack_speed_per_stack = 0.08
	passive.stack_duration = 4.0
	passive.full_stack_haste = 0.15
	passive.stack_limit = 5
	champ.passive = passive

	# Q
	var q := DashAbility.new()
	q.id = &"shield_charge"
	q.display_name = "Shield Charge"
	q.description = "Charges forward, slamming into enemies and stunning them."
	q.color = Color(0.9, 0.6, 0.2)
	q.icon = load("res://assets/icons/abilities/warden_q.svg")
	q.fx_style = &"impact"
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 6.5
	q.dash_distance = 6.5
	q.travel_speed = 22.0
	q.indicator_size = 1.4
	q.cooldown = PackedFloat32Array([9.0, 8.5, 8.0, 7.5, 7.0])
	q.mana_cost = PackedFloat32Array([50.0, 50.0, 50.0, 50.0, 50.0])
	q.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	q.ad_ratio = 0.6
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 0.0, 1.0)]

	# W
	var w := SelfBuffAbility.new()
	w.id = &"fortress"
	w.display_name = "Fortress"
	w.description = "Hardens armor with an impenetrable kinetic barrier, absorbing incoming damage."
	w.color = Color(1.0, 0.75, 0.3)
	w.icon = load("res://assets/icons/abilities/warden_w.svg")
	w.fx_style = &"buff"
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([55.0, 55.0, 55.0, 55.0, 55.0])
	w.shield_amount = PackedFloat32Array([90.0, 135.0, 180.0, 225.0, 270.0])
	w.shield_max_health_ratio = 0.08
	w.shield_duration = 3.5

	# E
	var e := AreaAbility.new()
	e.id = &"ground_slam"
	e.display_name = "Ground Slam"
	e.description = "Slams the ground with massive force, dealing damage and heavily slowing nearby enemies."
	e.color = Color(0.8, 0.5, 0.2)
	e.icon = load("res://assets/icons/abilities/warden_e.svg")
	e.fx_style = &"earth"
	e.targeting = AbilityData.Targeting.NONE
	e.center = AreaAbility.Center.SELF
	e.radius = 4.2
	e.indicator_size = 4.2
	e.delay = 0.15
	e.cooldown = PackedFloat32Array([8.0, 7.5, 7.0, 6.5, 6.0])
	e.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	e.base_damage = PackedFloat32Array([70.0, 105.0, 140.0, 175.0, 210.0])
	e.ad_ratio = 0.65
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.5, 2.0)]

	# R
	var r := AreaAbility.new()
	r.id = &"colossus_roar"
	r.display_name = "Colossus Roar"
	r.description = "Unleashes an earth-shattering roar, dealing massive damage and stunning all surrounding enemies."
	r.color = Color(1.0, 0.4, 0.1)
	r.icon = load("res://assets/icons/abilities/warden_r.svg")
	r.fx_style = &"explosion"
	r.is_ultimate = true
	r.max_rank = 3
	r.targeting = AbilityData.Targeting.NONE
	r.center = AreaAbility.Center.SELF
	r.radius = 5.5
	r.indicator_size = 5.5
	r.delay = 0.2
	r.cooldown = PackedFloat32Array([80.0, 70.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([200.0, 320.0, 440.0])
	r.ad_ratio = 0.8
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 0.0, 1.4)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["ruby_crystal", "boots", "cloth_armor", "titan_plate", "spirit_cloak"])
	champ.bot_preferred_range = 1.8

	ResourceSaver.save(champ, "res://data/champions/warden.tres")

func _build_ranger() -> void:
	var champ := ChampionData.new()
	champ.id = &"ranger"
	champ.display_name = "Ranger"
	champ.title = "The Swift Arrow"
	champ.role = "Marksman"
	champ.lore = "A deadly sharpshooter from the borderlands whose arrows pierce armor and stone."
	champ.color = Color(0.3, 0.85, 0.4)
	champ.difficulty = 2
	champ.model_scene = load("res://entities/champion/models/RangerModel.tscn")
	champ.portrait = load("res://assets/icons/champions/ranger.svg")

	champ.max_health = 540.0
	champ.health_per_level = 80.0
	champ.health_regen = 1.3
	champ.max_mana = 310.0
	champ.mana_per_level = 35.0
	champ.mana_regen = 1.7
	champ.attack_damage = 56.0
	champ.attack_damage_per_level = 3.4
	champ.attack_speed = 0.68
	champ.attack_range = 6.2
	champ.armor = 24.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.7

	champ.attack_projectile_style = &"arrow"
	champ.attack_projectile_speed = 26.0
	champ.attack_windup = 0.2

	# Passive
	var passive := AttackCounterPassive.new()
	passive.id = &"sharpshooter"
	passive.display_name = "Sharpshooter"
	passive.description = "Every 3rd basic attack deals bonus damage and heals the champion."
	passive.color = Color(0.4, 0.9, 0.5)
	passive.icon = load("res://assets/icons/abilities/ranger_p.svg")
	passive.attacks_required = 3
	passive.bonus_damage = 25.0
	passive.bonus_damage_per_level = 6.0
	champ.passive = passive

	# Q
	var q := ProjectileAbility.new()
	q.id = &"piercing_arrow"
	q.display_name = "Piercing Arrow"
	q.description = "Charges a powerful arrow that pierces through all enemies in a line."
	q.color = Color(0.3, 0.8, 0.4)
	q.icon = load("res://assets/icons/abilities/ranger_q.svg")
	q.fx_style = &"arrow"
	q.cast_range = 11.5
	q.projectile_speed = 28.0
	q.projectile_width = 1.0
	q.indicator_size = 1.0
	q.pierce = true
	q.pierce_falloff = 0.1
	q.cooldown = PackedFloat32Array([7.0, 6.5, 6.0, 5.5, 5.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([70.0, 105.0, 140.0, 175.0, 210.0])
	q.ad_ratio = 0.9
	q.damage_type = GameConst.DamageType.PHYSICAL

	# W
	var w := DashAbility.new()
	w.id = &"quick_tumble"
	w.display_name = "Quick Tumble"
	w.description = "Rolls quickly in the aimed direction, gaining a burst of movement speed."
	w.color = Color(0.4, 0.9, 0.6)
	w.icon = load("res://assets/icons/abilities/ranger_w.svg")
	w.fx_style = &"wind"
	w.mode = DashAbility.Mode.DASH
	w.targeting = AbilityData.Targeting.DIRECTION
	w.cast_range = 5.0
	w.dash_distance = 5.0
	w.travel_speed = 20.0
	w.indicator_size = 1.0
	w.cooldown = PackedFloat32Array([6.0, 5.5, 5.0, 4.5, 4.0])
	w.mana_cost = PackedFloat32Array([35.0, 35.0, 35.0, 35.0, 35.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 1.8)]

	# E
	var e := AreaAbility.new()
	e.id = &"caltrop_trap"
	e.display_name = "Caltrop Trap"
	e.description = "Scatters sharp caltrops that detonate when enemies step on them, heavily slowing them."
	e.color = Color(0.6, 0.8, 0.2)
	e.icon = load("res://assets/icons/abilities/ranger_e.svg")
	e.fx_style = &"trap"
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 7.5
	e.radius = 2.8
	e.indicator_size = 2.8
	e.delay = 0.3
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([60.0, 90.0, 120.0, 150.0, 180.0])
	e.ad_ratio = 0.5
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.6, 2.5)]

	# R
	var r := ProjectileAbility.new()
	r.id = &"volley_barrage"
	r.display_name = "Volley Barrage"
	r.description = "Fires a wide volley of 7 piercing arrows in a cone, decimating the enemy team."
	r.color = Color(0.2, 1.0, 0.5)
	r.icon = load("res://assets/icons/abilities/ranger_r.svg")
	r.fx_style = &"barrage"
	r.is_ultimate = true
	r.max_rank = 3
	r.cast_range = 13.0
	r.projectile_count = 7
	r.spread_degrees = 32.0
	r.projectile_speed = 26.0
	r.projectile_width = 1.2
	r.indicator_size = 1.2
	r.cooldown = PackedFloat32Array([70.0, 60.0, 50.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([180.0, 270.0, 360.0])
	r.ad_ratio = 0.85
	r.damage_type = GameConst.DamageType.PHYSICAL

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 2, 1])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "dagger", "storm_bow", "blade_of_ruin"])
	champ.bot_preferred_range = 6.0

	ResourceSaver.save(champ, "res://data/champions/ranger.tres")


func _build_wraith() -> void:
	var champ := ChampionData.new()
	champ.id = &"wraith"
	champ.display_name = "Wraith"
	champ.title = "The Shadow Blade"
	champ.role = "Assassin"
	champ.lore = "A lethal shadow-dancer from the void who strikes from concealment with blinding speed."
	champ.color = Color(0.68, 0.22, 0.9)
	champ.difficulty = 3
	champ.model_scene = load("res://entities/champion/models/WraithModel.tscn")
	champ.portrait = load("res://assets/icons/champions/wraith.svg")

	champ.max_health = 540.0
	champ.health_per_level = 85.0
	champ.health_regen = 1.6
	champ.max_mana = 360.0
	champ.mana_per_level = 40.0
	champ.mana_regen = 2.0
	champ.attack_damage = 58.0
	champ.attack_damage_per_level = 3.4
	champ.attack_speed = 0.68
	champ.attack_range = 1.8
	champ.armor = 26.0
	champ.magic_resist = 32.0
	champ.move_speed = 6.0

	champ.attack_projectile_style = &""
	champ.attack_windup = 0.18

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"shadow_stalker"
	passive.display_name = "Shadow Stalker"
	passive.description = "Every 3rd ability cast grants +40% movement speed for 2.5s."
	passive.color = Color(0.7, 0.25, 0.95)
	passive.icon = load("res://assets/icons/abilities/wraith_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.4, 2.5)]
	champ.passive = passive

	# Q
	var q := DashAbility.new()
	q.id = &"shadow_dash"
	q.display_name = "Shadow Dash"
	q.description = "Dashes swiftly through shadows in the targeted direction, striking enemies."
	q.color = Color(0.65, 0.2, 0.85)
	q.icon = load("res://assets/icons/abilities/wraith_q.svg")
	q.fx_style = &"shadow"
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 6.5
	q.dash_distance = 6.5
	q.travel_speed = 26.0
	q.indicator_size = 1.2
	q.cooldown = PackedFloat32Array([8.0, 7.0, 6.0, 5.0, 4.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([70.0, 105.0, 140.0, 175.0, 210.0])
	q.ad_ratio = 0.8
	q.damage_type = GameConst.DamageType.PHYSICAL

	# W
	var w := AreaAbility.new()
	w.id = &"smoke_shroud"
	w.display_name = "Smoke Shroud"
	w.description = "Deploys an obscuring smoke cloud around self, gaining haste and brief untargetability."
	w.color = Color(0.4, 0.15, 0.6)
	w.icon = load("res://assets/icons/abilities/wraith_w.svg")
	w.fx_style = &"smoke"
	w.center = AreaAbility.Center.SELF
	w.targeting = AbilityData.Targeting.NONE
	w.radius = 4.5
	w.delay = 0.05
	w.ticks = 1
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([50.0, 50.0, 50.0, 50.0, 50.0])
	w.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.4, 2.0)]
	w.self_effects = [
		StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.0),
		StatusEffectData.make(GameConst.Status.UNTARGETABLE, 0.0, 0.75),
	]

	# E
	var e := ProjectileAbility.new()
	e.id = &"crippling_dagger"
	e.display_name = "Crippling Dagger"
	e.description = "Hurls a poisoned dagger that damages and severely slows the first enemy struck."
	e.color = Color(0.8, 0.3, 0.9)
	e.icon = load("res://assets/icons/abilities/wraith_e.svg")
	e.fx_style = &"dagger"
	e.cast_range = 8.5
	e.projectile_speed = 24.0
	e.projectile_width = 1.0
	e.indicator_size = 1.0
	e.cooldown = PackedFloat32Array([7.0, 6.5, 6.0, 5.5, 5.0])
	e.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	e.base_damage = PackedFloat32Array([65.0, 95.0, 125.0, 155.0, 185.0])
	e.ad_ratio = 0.75
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	# R
	var r := DashAbility.new()
	r.id = &"death_mark"
	r.display_name = "Death Mark"
	r.description = "Leaps behind the target enemy with terrifying force, silencing and heavily damaging them."
	r.color = Color(0.9, 0.1, 0.3)
	r.icon = load("res://assets/icons/abilities/wraith_r.svg")
	r.fx_style = &"assassinate"
	r.is_ultimate = true
	r.max_rank = 3
	r.mode = DashAbility.Mode.TARGET_DASH
	r.targeting = AbilityData.Targeting.UNIT
	r.cast_range = 8.0
	r.travel_speed = 32.0
	r.cooldown = PackedFloat32Array([70.0, 60.0, 50.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([220.0, 340.0, 460.0])
	r.ad_ratio = 1.1
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [
		StatusEffectData.make(GameConst.Status.SLOW, 0.6, 2.5),
		StatusEffectData.make(GameConst.Status.SILENCE, 0.0, 1.2),
	]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 2, 1])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "dagger", "blade_of_ruin", "storm_bow"])
	champ.bot_preferred_range = 1.8

	ResourceSaver.save(champ, "res://data/champions/wraith.tres")


func _build_luminary() -> void:
	var champ := ChampionData.new()
	champ.id = &"luminary"
	champ.display_name = "Luminary"
	champ.title = "The Radiant Dawnbringer"
	champ.role = "Support"
	champ.lore = "A solar priestess who channels the burning dawn to shield allies and incinerate foes."
	champ.color = Color(1.0, 0.85, 0.25)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/LuminaryModel.tscn")
	champ.portrait = load("res://assets/icons/champions/luminary.svg")

	champ.max_health = 520.0
	champ.health_per_level = 78.0
	champ.health_regen = 1.8
	champ.max_mana = 440.0
	champ.mana_per_level = 50.0
	champ.mana_regen = 2.8
	champ.attack_damage = 44.0
	champ.attack_damage_per_level = 2.4
	champ.attack_speed = 0.62
	champ.attack_range = 5.4
	champ.armor = 22.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.5

	champ.attack_projectile_style = &"arcane"
	champ.attack_projectile_speed = 20.0
	champ.attack_windup = 0.22

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"solar_grace"
	passive.display_name = "Solar Grace"
	passive.description = "Every 3rd ability cast grants +25% haste to caster for 3.0s."
	passive.color = Color(1.0, 0.9, 0.3)
	passive.icon = load("res://assets/icons/abilities/luminary_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.25, 3.0)]
	champ.passive = passive

	# Q
	var q := BeamAbility.new()
	q.id = &"sunburst"
	q.display_name = "Sunburst"
	q.description = "Channels a beam of concentrated dawn light that pierces through all enemies."
	q.color = Color(1.0, 0.85, 0.2)
	q.icon = load("res://assets/icons/abilities/luminary_q.svg")
	q.fx_style = &"solar_beam"
	q.beam_length = 14.0
	q.beam_width = 2.8
	q.charge_time = 0.4
	q.root_caster = false
	q.cooldown = PackedFloat32Array([6.5, 6.0, 5.5, 5.0, 4.5])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([80.0, 120.0, 160.0, 200.0, 240.0])
	q.ap_ratio = 0.7
	q.damage_type = GameConst.DamageType.MAGIC

	# W
	var w := SelfBuffAbility.new()
	w.id = &"solar_aegis"
	w.display_name = "Solar Aegis"
	w.description = "Surrounds the caster in radiant light, gaining a shield, a heal, and bonus speed."
	w.color = Color(1.0, 0.92, 0.4)
	w.icon = load("res://assets/icons/abilities/luminary_w.svg")
	w.fx_style = &"sun_shield"
	w.shield_amount = PackedFloat32Array([80.0, 130.0, 180.0, 230.0, 280.0])
	w.shield_duration = 3.5
	w.shield_max_health_ratio = 0.05
	w.heal_amount = PackedFloat32Array([50.0, 75.0, 100.0, 125.0, 150.0])
	w.heal_ap_ratio = 0.4
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([60.0, 65.0, 70.0, 75.0, 80.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.25, 2.5)]

	# E
	var e := AreaAbility.new()
	e.id = &"starlight_snare"
	e.display_name = "Starlight Snare"
	e.description = "Calls down a constellation trap that damages, roots, and slows enemies in the area."
	e.color = Color(0.9, 0.75, 1.0)
	e.icon = load("res://assets/icons/abilities/luminary_e.svg")
	e.fx_style = &"star_trap"
	e.center = AreaAbility.Center.POINT
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.5
	e.radius = 3.0
	e.delay = 0.4
	e.ticks = 1
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([55.0, 60.0, 65.0, 70.0, 75.0])
	e.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	e.ap_ratio = 0.5
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [
		StatusEffectData.make(GameConst.Status.ROOT, 0.0, 1.5),
		StatusEffectData.make(GameConst.Status.SLOW, 0.4, 2.5),
	]

	# R
	var r := AreaAbility.new()
	r.id = &"dawns_radiance"
	r.display_name = "Dawn's Radiance"
	r.description = "Unleashes the full fury of the dawn, dealing massive damage, silencing enemies, and shielding self."
	r.color = Color(1.0, 0.95, 0.5)
	r.icon = load("res://assets/icons/abilities/luminary_r.svg")
	r.fx_style = &"dawn_radiance"
	r.is_ultimate = true
	r.max_rank = 3
	r.center = AreaAbility.Center.SELF
	r.targeting = AbilityData.Targeting.NONE
	r.radius = 7.5
	r.delay = 0.45
	r.ticks = 1
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([200.0, 320.0, 440.0])
	r.ap_ratio = 0.85
	r.damage_type = GameConst.DamageType.MAGIC
	r.target_effects = [
		StatusEffectData.make(GameConst.Status.SLOW, 0.6, 3.0),
		StatusEffectData.make(GameConst.Status.SILENCE, 0.0, 1.5),
	]
	r.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 150.0, 4.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["sapphire_crystal", "boots", "archmage_staff", "amp_tome", "crystal_heart"])
	champ.bot_preferred_range = 5.4

	ResourceSaver.save(champ, "res://data/champions/luminary.tres")
