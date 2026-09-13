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

	_build_erez()
	_build_stephen()
	_build_amit()
	_build_nissim()
	_build_rogo()
	_build_yakir()
	_build_edgy()

	# Also retain original 5
	_build_arcanist()
	_build_warden()
	_build_ranger()
	_build_wraith()
	_build_luminary()

	print("All champion data resources generated successfully!")

# =========================================================================
# 1. EREZ - The Tactician (Bruiser / Fighter)
# =========================================================================
func _build_erez() -> void:
	var champ := ChampionData.new()
	champ.id = &"erez"
	champ.display_name = "Erez"
	champ.title = "The Tactician"
	champ.role = "Bruiser"
	champ.lore = "A master strategist whose calculated strikes and resolute presence inspire allies on the front lines."
	champ.color = Color(0.25, 0.45, 0.95)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/ErezModel.tscn")
	champ.portrait = load("res://assets/icons/champions/erez.svg")

	champ.max_health = 610.0
	champ.health_per_level = 88.0
	champ.health_regen = 1.8
	champ.max_mana = 350.0
	champ.mana_per_level = 38.0
	champ.mana_regen = 1.8
	champ.attack_damage = 60.0
	champ.attack_damage_per_level = 3.6
	champ.attack_speed = 0.65
	champ.attack_range = 1.9
	champ.armor = 32.0
	champ.magic_resist = 32.0
	champ.move_speed = 5.8
	champ.attack_windup = 0.22

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"battle_command"
	passive.display_name = "Battle Command"
	passive.description = "Every 3rd ability cast grants +35% movement speed and 15% bonus armor for 2.5s."
	passive.color = Color(0.25, 0.45, 0.95)
	passive.icon = load("res://assets/icons/abilities/erez_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.5)]
	champ.passive = passive

	# Q
	var q := DashAbility.new()
	q.id = &"tactical_strike"
	q.display_name = "Tactical Strike"
	q.description = "Charges forward in the targeted direction, striking enemies for physical damage."
	q.color = Color(0.3, 0.5, 0.95)
	q.icon = load("res://assets/icons/abilities/erez_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 6.0
	q.dash_distance = 6.0
	q.travel_speed = 22.0
	q.indicator_size = 1.3
	q.cooldown = PackedFloat32Array([7.0, 6.5, 6.0, 5.5, 5.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([75.0, 110.0, 145.0, 180.0, 215.0])
	q.ad_ratio = 0.8
	q.damage_type = GameConst.DamageType.PHYSICAL

	# W
	var w := SelfBuffAbility.new()
	w.id = &"commanders_aegis"
	w.display_name = "Commander's Aegis"
	w.description = "Braces for battle, gaining a durable shield and 25% damage reduction for 3s."
	w.color = Color(0.2, 0.6, 0.9)
	w.icon = load("res://assets/icons/abilities/erez_w.svg")
	w.cooldown = PackedFloat32Array([13.0, 12.0, 11.0, 10.0, 9.0])
	w.mana_cost = PackedFloat32Array([55.0, 55.0, 55.0, 55.0, 55.0])
	w.base_damage = PackedFloat32Array()
	w.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 140.0, 3.0)]

	# E
	var e := AreaAbility.new()
	e.id = &"rallying_quake"
	e.display_name = "Rallying Quake"
	e.description = "Stomps the ground, sending a shockwave that deals physical damage and slows nearby enemies by 40%."
	e.color = Color(0.35, 0.65, 0.95)
	e.icon = load("res://assets/icons/abilities/erez_e.svg")
	e.center = AreaAbility.Center.SELF
	e.targeting = AbilityData.Targeting.NONE
	e.radius = 4.2
	e.indicator_size = 4.2
	e.cooldown = PackedFloat32Array([10.0, 9.0, 8.0, 7.0, 6.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([65.0, 100.0, 135.0, 170.0, 205.0])
	e.ad_ratio = 0.6
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.4, 2.0)]

	# R
	var r := DashAbility.new()
	r.id = &"vanguard_onslaught"
	r.display_name = "Vanguard Onslaught"
	r.description = "Unleashes an unstoppable charge across the battlefield, slamming the first enemy champion for massive damage and stunning them for 1.2s."
	r.color = Color(0.95, 0.75, 0.25)
	r.icon = load("res://assets/icons/abilities/erez_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.mode = DashAbility.Mode.DASH
	r.targeting = AbilityData.Targeting.DIRECTION
	r.cast_range = 10.0
	r.dash_distance = 10.0
	r.travel_speed = 28.0
	r.indicator_size = 2.0
	r.cooldown = PackedFloat32Array([80.0, 70.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([240.0, 360.0, 480.0])
	r.ad_ratio = 1.0
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.2, 1.2)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 2, 1])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "blade_of_ruin", "titan_plate", "crystal_heart"])
	champ.bot_preferred_range = 2.0

	ResourceSaver.save(champ, "res://data/champions/erez.tres")

# =========================================================================
# 2. STEPHEN - The Mindbender (Mage)
# =========================================================================
func _build_stephen() -> void:
	var champ := ChampionData.new()
	champ.id = &"stephen"
	champ.display_name = "Stephen"
	champ.title = "The Mindbender"
	champ.role = "Mage"
	champ.lore = "A psychic savant capable of tearing through the minds of enemies with waves of astral force."
	champ.color = Color(0.65, 0.25, 0.95)
	champ.difficulty = 2
	champ.model_scene = load("res://entities/champion/models/StephenModel.tscn")
	champ.portrait = load("res://assets/icons/champions/stephen.svg")

	champ.max_health = 550.0
	champ.health_per_level = 80.0
	champ.health_regen = 1.4
	champ.max_mana = 420.0
	champ.mana_per_level = 46.0
	champ.mana_regen = 2.5
	champ.attack_damage = 48.0
	champ.attack_damage_per_level = 2.8
	champ.attack_speed = 0.62
	champ.attack_range = 5.6
	champ.armor = 21.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.6
	champ.attack_projectile_style = &"arcane"
	champ.attack_projectile_speed = 22.0
	champ.attack_windup = 0.24

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"mental_surge"
	passive.display_name = "Mental Surge"
	passive.description = "Every 3rd ability cast grants +35% movement speed for 2.5s."
	passive.color = Color(0.65, 0.25, 0.95)
	passive.icon = load("res://assets/icons/abilities/stephen_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.5)]
	champ.passive = passive

	# Q
	var q := ProjectileAbility.new()
	q.id = &"psionic_blast"
	q.display_name = "Psionic Blast"
	q.description = "Fires a concentrated bolt of telepathic energy piercing the target."
	q.color = Color(0.7, 0.35, 1.0)
	q.icon = load("res://assets/icons/abilities/stephen_q.svg")
	q.fx_style = &"void"
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
	w.id = &"phase_dimension"
	w.display_name = "Phase Dimension"
	w.description = "Instantly blinks through the astral plane, briefly dodging all incoming harm."
	w.color = Color(0.5, 0.2, 0.8)
	w.icon = load("res://assets/icons/abilities/stephen_w.svg")
	w.mode = DashAbility.Mode.BLINK
	w.targeting = AbilityData.Targeting.POINT
	w.cast_range = 6.0
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.UNTARGETABLE, 0.0, 0.25)]

	# E
	var e := AreaAbility.new()
	e.id = &"mind_warp"
	e.display_name = "Mind Warp"
	e.description = "Creates a rift of distorted time that detonates after 0.6s, dealing magic damage and slowing enemies."
	e.color = Color(0.6, 0.15, 0.85)
	e.icon = load("res://assets/icons/abilities/stephen_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.5
	e.radius = 3.2
	e.indicator_size = 3.2
	e.delay = 0.6
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([65.0, 70.0, 75.0, 80.0, 85.0])
	e.base_damage = PackedFloat32Array([80.0, 120.0, 160.0, 200.0, 240.0])
	e.ap_ratio = 0.7
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	# R
	var r := BeamAbility.new()
	r.id = &"psychic_cataclysm"
	r.display_name = "Psychic Cataclysm"
	r.description = "Channels astral fury for 0.6s then fires a devastating mental laser across the arena."
	r.color = Color(0.8, 0.2, 1.0)
	r.icon = load("res://assets/icons/abilities/stephen_r.svg")
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

	ResourceSaver.save(champ, "res://data/champions/stephen.tres")

# =========================================================================
# 3. AMIT - The Grand Architect (Marksman)
# =========================================================================
func _build_amit() -> void:
	var champ := ChampionData.new()
	champ.id = &"amit"
	champ.display_name = "Amit"
	champ.title = "The Grand Architect"
	champ.role = "Marksman"
	champ.lore = "An ingenious engineer and pinpoint sniper who shapes the battlefield with deadly precision."
	champ.color = Color(0.95, 0.7, 0.2)
	champ.difficulty = 2
	champ.model_scene = load("res://entities/champion/models/AmitModel.tscn")
	champ.portrait = load("res://assets/icons/champions/amit.svg")

	champ.max_health = 530.0
	champ.health_per_level = 76.0
	champ.health_regen = 1.3
	champ.max_mana = 340.0
	champ.mana_per_level = 38.0
	champ.mana_regen = 1.6
	champ.attack_damage = 54.0
	champ.attack_damage_per_level = 3.2
	champ.attack_speed = 0.68
	champ.attack_range = 6.0
	champ.armor = 24.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.7
	champ.attack_projectile_style = &"arrow"
	champ.attack_projectile_speed = 26.0
	champ.attack_windup = 0.16

	# Passive
	var passive := AttackStackPassive.new()
	passive.id = &"calculated_shot"
	passive.display_name = "Calculated Shot"
	passive.description = "Every 4th basic attack deals +45% bonus physical damage."
	passive.color = Color(0.95, 0.7, 0.2)
	passive.icon = load("res://assets/icons/abilities/amit_p.svg")
	passive.max_stacks = 4
	champ.passive = passive

	# Q
	var q := ProjectileAbility.new()
	q.id = &"piercing_rail"
	q.display_name = "Piercing Rail"
	q.description = "Fires a high-velocity kinetic rail shot that damages all enemies in its path."
	q.color = Color(0.95, 0.7, 0.2)
	q.icon = load("res://assets/icons/abilities/amit_q.svg")
	q.cast_range = 11.0
	q.indicator_size = 1.0
	q.projectile_speed = 28.0
	q.projectile_width = 1.0
	q.cooldown = PackedFloat32Array([6.0, 5.5, 5.0, 4.5, 4.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([80.0, 120.0, 160.0, 200.0, 240.0])
	q.ad_ratio = 0.85
	q.damage_type = GameConst.DamageType.PHYSICAL

	# W
	var w := DashAbility.new()
	w.id = &"tactical_slide"
	w.display_name = "Tactical Slide"
	w.description = "Slides nimbly in target direction, resetting basic attack windup and gaining haste."
	w.color = Color(0.3, 0.8, 0.5)
	w.icon = load("res://assets/icons/abilities/amit_w.svg")
	w.mode = DashAbility.Mode.DASH
	w.targeting = AbilityData.Targeting.DIRECTION
	w.cast_range = 4.8
	w.dash_distance = 4.8
	w.travel_speed = 18.0
	w.cooldown = PackedFloat32Array([10.0, 9.0, 8.0, 7.0, 6.0])
	w.mana_cost = PackedFloat32Array([40.0, 40.0, 40.0, 40.0, 40.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.25, 2.0)]

	# E
	var e := AreaAbility.new()
	e.id = &"stasis_caltrop"
	e.display_name = "Stasis Caltrop"
	e.description = "Deploys an electrified stasis field that damages and slows enemies by 50% for 2.5s."
	e.color = Color(0.9, 0.3, 0.3)
	e.icon = load("res://assets/icons/abilities/amit_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.0
	e.radius = 2.8
	e.indicator_size = 2.8
	e.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	e.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	e.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	e.ad_ratio = 0.5
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.5, 2.5)]

	# R
	var r := AreaAbility.new()
	r.id = &"orbital_barrage"
	r.display_name = "Orbital Barrage"
	r.description = "Calls down a devastating artillery barrage from afar that saturates the target zone."
	r.color = Color(0.95, 0.6, 0.1)
	r.icon = load("res://assets/icons/abilities/amit_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.targeting = AbilityData.Targeting.POINT
	r.cast_range = 16.0
	r.radius = 5.0
	r.indicator_size = 5.0
	r.delay = 0.5
	r.cooldown = PackedFloat32Array([70.0, 60.0, 50.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([250.0, 380.0, 510.0])
	r.ad_ratio = 0.95
	r.damage_type = GameConst.DamageType.PHYSICAL

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "dagger", "storm_bow", "blade_of_ruin"])
	champ.bot_preferred_range = 5.8

	ResourceSaver.save(champ, "res://data/champions/amit.tres")

# =========================================================================
# 4. NISSIM - The Miracle Worker (Support)
# =========================================================================
func _build_nissim() -> void:
	var champ := ChampionData.new()
	champ.id = &"nissim"
	champ.display_name = "Nissim"
	champ.title = "The Miracle Worker"
	champ.role = "Support"
	champ.lore = "A compassionate beacon of light who weaves protective barriers and revitalizing miracles."
	champ.color = Color(0.1, 0.8, 0.55)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/NissimModel.tscn")
	champ.portrait = load("res://assets/icons/champions/nissim.svg")

	champ.max_health = 570.0
	champ.health_per_level = 82.0
	champ.health_regen = 1.8
	champ.max_mana = 400.0
	champ.mana_per_level = 45.0
	champ.mana_regen = 2.6
	champ.attack_damage = 48.0
	champ.attack_damage_per_level = 2.6
	champ.attack_speed = 0.64
	champ.attack_range = 5.2
	champ.armor = 25.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.6
	champ.attack_projectile_style = &"solar"
	champ.attack_projectile_speed = 20.0
	champ.attack_windup = 0.2

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"living_grace"
	passive.display_name = "Living Grace"
	passive.description = "Every 3rd ability cast restores health to Nissim and grants +30% movement speed."
	passive.color = Color(0.1, 0.8, 0.55)
	passive.icon = load("res://assets/icons/abilities/nissim_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.5)]
	champ.passive = passive

	# Q
	var q := ProjectileAbility.new()
	q.id = &"radiant_spark"
	q.display_name = "Radiant Spark"
	q.description = "Fires a spark of divine radiance that damages the first enemy hit."
	q.color = Color(0.2, 0.9, 0.6)
	q.icon = load("res://assets/icons/abilities/nissim_q.svg")
	q.cast_range = 9.0
	q.indicator_size = 1.1
	q.projectile_speed = 20.0
	q.projectile_width = 1.1
	q.cooldown = PackedFloat32Array([6.0, 5.5, 5.0, 4.5, 4.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([70.0, 105.0, 140.0, 175.0, 210.0])
	q.ap_ratio = 0.6
	q.damage_type = GameConst.DamageType.MAGIC

	# W
	var w := SelfBuffAbility.new()
	w.id = &"sanctuary_ward"
	w.display_name = "Sanctuary Ward"
	w.description = "Conjures a sanctuary shield absorbing damage and granting speed."
	w.color = Color(0.1, 0.85, 0.5)
	w.icon = load("res://assets/icons/abilities/nissim_w.svg")
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [
		StatusEffectData.make(GameConst.Status.SHIELD, 130.0, 3.5),
		StatusEffectData.make(GameConst.Status.HASTE, 0.25, 2.5),
	]

	# E
	var e := AreaAbility.new()
	e.id = &"binding_constellation"
	e.display_name = "Binding Constellation"
	e.description = "Calls down a constellation that detonates after 0.5s, rooting enemies for 1.4s."
	e.color = Color(0.3, 0.7, 0.9)
	e.icon = load("res://assets/icons/abilities/nissim_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.5
	e.radius = 3.0
	e.indicator_size = 3.0
	e.delay = 0.5
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([60.0, 65.0, 70.0, 75.0, 80.0])
	e.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	e.ap_ratio = 0.55
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.ROOT, 1.4, 1.4)]

	# R
	var r := AreaAbility.new()
	r.id = &"divine_intervention"
	r.display_name = "Divine Intervention"
	r.description = "Unleashes a tidal wave of holy starlight across the arena, shielding allies and scorching foes."
	r.color = Color(0.95, 0.85, 0.3)
	r.icon = load("res://assets/icons/abilities/nissim_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.center = AreaAbility.Center.SELF
	r.targeting = AbilityData.Targeting.NONE
	r.radius = 7.5
	r.indicator_size = 7.5
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([200.0, 300.0, 400.0])
	r.ap_ratio = 0.7
	r.damage_type = GameConst.DamageType.MAGIC
	r.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 280.0, 4.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["sapphire_crystal", "boots", "archmage_staff", "crystal_heart"])
	champ.bot_preferred_range = 5.2

	ResourceSaver.save(champ, "res://data/champions/nissim.tres")

# =========================================================================
# 5. ROGO - The Juggernaut (Berserker)
# =========================================================================
func _build_rogo() -> void:
	var champ := ChampionData.new()
	champ.id = &"rogo"
	champ.display_name = "Rogo"
	champ.title = "The Juggernaut"
	champ.role = "Berserker"
	champ.lore = "An unstoppable warrior fueled by raw fury who cuts down anyone reckless enough to enter his domain."
	champ.color = Color(0.9, 0.25, 0.15)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/RogoModel.tscn")
	champ.portrait = load("res://assets/icons/champions/rogo.svg")

	champ.max_health = 640.0
	champ.health_per_level = 94.0
	champ.health_regen = 2.2
	champ.max_mana = 300.0
	champ.mana_per_level = 32.0
	champ.mana_regen = 1.4
	champ.attack_damage = 64.0
	champ.attack_damage_per_level = 3.8
	champ.attack_speed = 0.68
	champ.attack_range = 1.8
	champ.armor = 34.0
	champ.magic_resist = 32.0
	champ.move_speed = 5.9
	champ.attack_windup = 0.2

	# Passive
	var passive := AttackCounterPassive.new()
	passive.id = &"blood_rage"
	passive.display_name = "Blood Rage"
	passive.description = "Every 3rd basic attack strikes with primal fury, dealing +40% bonus physical damage."
	passive.color = Color(0.9, 0.25, 0.15)
	passive.icon = load("res://assets/icons/abilities/rogo_p.svg")
	passive.attacks_required = 3
	passive.bonus_max_health_ratio = 0.04
	champ.passive = passive

	# Q
	var q := DashAbility.new()
	q.id = &"cleaving_strike"
	q.display_name = "Cleaving Strike"
	q.description = "Lunges forward 5m swinging heavy twin axes, cleaving all enemies in path."
	q.color = Color(0.95, 0.35, 0.1)
	q.icon = load("res://assets/icons/abilities/rogo_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 5.2
	q.dash_distance = 5.2
	q.travel_speed = 20.0
	q.indicator_size = 1.4
	q.cooldown = PackedFloat32Array([6.5, 6.0, 5.5, 5.0, 4.5])
	q.mana_cost = PackedFloat32Array([35.0, 40.0, 45.0, 50.0, 55.0])
	q.base_damage = PackedFloat32Array([80.0, 115.0, 150.0, 185.0, 220.0])
	q.ad_ratio = 0.85
	q.damage_type = GameConst.DamageType.PHYSICAL

	# W
	var w := SelfBuffAbility.new()
	w.id = &"unyielding_roar"
	w.display_name = "Unyielding Roar"
	w.description = "Bellows a ferocious war roar, gaining a temporary shield and +30% movement speed."
	w.color = Color(0.85, 0.15, 0.15)
	w.icon = load("res://assets/icons/abilities/rogo_w.svg")
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([50.0, 50.0, 50.0, 50.0, 50.0])
	w.self_effects = [
		StatusEffectData.make(GameConst.Status.SHIELD, 150.0, 3.0),
		StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.5),
	]

	# E
	var e := AreaAbility.new()
	e.id = &"earth_shaker"
	e.display_name = "Earth Shaker"
	e.description = "Slams the ground with monstrous force, damaging and slowing enemies by 45%."
	e.color = Color(0.8, 0.25, 0.1)
	e.icon = load("res://assets/icons/abilities/rogo_e.svg")
	e.center = AreaAbility.Center.SELF
	e.targeting = AbilityData.Targeting.NONE
	e.radius = 4.0
	e.indicator_size = 4.0
	e.cooldown = PackedFloat32Array([9.0, 8.0, 7.0, 6.0, 5.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([70.0, 105.0, 140.0, 175.0, 210.0])
	e.ad_ratio = 0.7
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	# R
	var r := AreaAbility.new()
	r.id = &"rampage_apex"
	r.display_name = "Rampage Apex"
	r.description = "Leaps into the air and crashes down upon target zone, shattering the ground and stunning enemies for 1.0s."
	r.color = Color(1.0, 0.2, 0.1)
	r.icon = load("res://assets/icons/abilities/rogo_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.targeting = AbilityData.Targeting.POINT
	r.cast_range = 9.0
	r.radius = 4.5
	r.indicator_size = 4.5
	r.delay = 0.4
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([260.0, 390.0, 520.0])
	r.ad_ratio = 1.05
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.0, 1.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 2, 1])
	champ.bot_item_build = PackedStringArray(["long_sword", "ruby_crystal", "boots", "blade_of_ruin", "titan_plate"])
	champ.bot_preferred_range = 1.9

	ResourceSaver.save(champ, "res://data/champions/rogo.tres")

# =========================================================================
# 6. YAKIR - The Bulwark (Tank)
# =========================================================================
func _build_yakir() -> void:
	var champ := ChampionData.new()
	champ.id = &"yakir"
	champ.display_name = "Yakir"
	champ.title = "The Bulwark"
	champ.role = "Tank"
	champ.lore = "A stalwart guardian who plants his tower shield into the earth to weather the fiercest storms."
	champ.color = Color(0.25, 0.65, 0.85)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/YakirModel.tscn")
	champ.portrait = load("res://assets/icons/champions/yakir.svg")

	champ.max_health = 660.0
	champ.health_per_level = 96.0
	champ.health_regen = 2.4
	champ.max_mana = 320.0
	champ.mana_per_level = 35.0
	champ.mana_regen = 1.5
	champ.attack_damage = 56.0
	champ.attack_damage_per_level = 3.0
	champ.attack_speed = 0.62
	champ.attack_range = 1.8
	champ.armor = 38.0
	champ.magic_resist = 34.0
	champ.move_speed = 5.6
	champ.attack_windup = 0.22

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"granite_fortress"
	passive.display_name = "Granite Fortress"
	passive.description = "Casting abilities grants a protective stone barrier that absorbs 120 damage for 3s."
	passive.color = Color(0.25, 0.65, 0.85)
	passive.icon = load("res://assets/icons/abilities/yakir_p.svg")
	passive.casts_required = 2
	passive.effects = [StatusEffectData.make(GameConst.Status.SHIELD, 120.0, 3.0)]
	champ.passive = passive

	# Q
	var q := DashAbility.new()
	q.id = &"shield_vault"
	q.display_name = "Shield Vault"
	q.description = "Dashes forward 5m behind an enormous tower shield, stunning the first enemy hit for 1.0s."
	q.color = Color(0.3, 0.7, 0.9)
	q.icon = load("res://assets/icons/abilities/yakir_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 5.5
	q.dash_distance = 5.5
	q.travel_speed = 18.0
	q.indicator_size = 1.5
	q.cooldown = PackedFloat32Array([9.0, 8.0, 7.5, 7.0, 6.5])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([65.0, 95.0, 125.0, 155.0, 185.0])
	q.ad_ratio = 0.5
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.0, 1.0)]

	# W
	var w := SelfBuffAbility.new()
	w.id = &"barricade_stance"
	w.display_name = "Barricade Stance"
	w.description = "Roots down in defensive stance, gaining a massive 180 HP shield and armor."
	w.color = Color(0.2, 0.6, 0.8)
	w.icon = load("res://assets/icons/abilities/yakir_w.svg")
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 180.0, 3.5)]

	# E
	var e := AreaAbility.new()
	e.id = &"colossal_stomp"
	e.display_name = "Colossal Stomp"
	e.description = "Strikes the ground causing heavy fractures that slow enemies by 50% for 2.0s."
	e.color = Color(0.3, 0.75, 0.95)
	e.icon = load("res://assets/icons/abilities/yakir_e.svg")
	e.center = AreaAbility.Center.SELF
	e.targeting = AbilityData.Targeting.NONE
	e.radius = 4.2
	e.indicator_size = 4.2
	e.cooldown = PackedFloat32Array([10.0, 9.0, 8.0, 7.0, 6.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([60.0, 90.0, 120.0, 150.0, 180.0])
	e.ad_ratio = 0.5
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.5, 2.0)]

	# R
	var r := AreaAbility.new()
	r.id = &"titans_fortress"
	r.display_name = "Titan's Fortress"
	r.description = "Plants a colossal barrier into the arena, providing massive shields to self and stunning nearby foes."
	r.color = Color(0.4, 0.85, 1.0)
	r.icon = load("res://assets/icons/abilities/yakir_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.center = AreaAbility.Center.SELF
	r.targeting = AbilityData.Targeting.NONE
	r.radius = 6.0
	r.indicator_size = 6.0
	r.cooldown = PackedFloat32Array([85.0, 75.0, 65.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([180.0, 270.0, 360.0])
	r.ad_ratio = 0.6
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 350.0, 5.0)]
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.2, 1.2)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["cloth_armor", "ruby_crystal", "boots", "titan_plate", "crystal_heart"])
	champ.bot_preferred_range = 1.8

	ResourceSaver.save(champ, "res://data/champions/yakir.tres")

# =========================================================================
# 7. EDGY - The Shadowblade (Assassin)
# =========================================================================
func _build_edgy() -> void:
	var champ := ChampionData.new()
	champ.id = &"edgy"
	champ.display_name = "Edgy"
	champ.title = "The Shadowblade"
	champ.role = "Assassin"
	champ.lore = "A deadly operative stalking the shadows, striking with lethal haste and vanishing without a trace."
	champ.color = Color(0.95, 0.1, 0.3)
	champ.difficulty = 3
	champ.model_scene = load("res://entities/champion/models/EdgyModel.tscn")
	champ.portrait = load("res://assets/icons/champions/edgy.svg")

	champ.max_health = 540.0
	champ.health_per_level = 85.0
	champ.health_regen = 1.6
	champ.max_mana = 360.0
	champ.mana_per_level = 40.0
	champ.mana_regen = 2.0
	champ.attack_damage = 59.0
	champ.attack_damage_per_level = 3.5
	champ.attack_speed = 0.69
	champ.attack_range = 1.8
	champ.armor = 26.0
	champ.magic_resist = 32.0
	champ.move_speed = 6.0
	champ.attack_windup = 0.18

	# Passive
	var passive := CastCounterPassive.new()
	passive.id = &"nightstalker"
	passive.display_name = "Nightstalker"
	passive.description = "Every 3rd ability cast grants +40% movement speed for 2.5s."
	passive.color = Color(0.95, 0.1, 0.3)
	passive.icon = load("res://assets/icons/abilities/edgy_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.4, 2.5)]
	champ.passive = passive

	# Q
	var q := DashAbility.new()
	q.id = &"shadow_step"
	q.display_name = "Shadow Step"
	q.description = "Dashes swiftly through shadows in the targeted direction, striking enemies."
	q.color = Color(0.95, 0.1, 0.3)
	q.icon = load("res://assets/icons/abilities/edgy_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 6.5
	q.dash_distance = 6.5
	q.travel_speed = 26.0
	q.indicator_size = 1.2
	q.cooldown = PackedFloat32Array([8.0, 7.0, 6.0, 5.0, 4.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([75.0, 110.0, 145.0, 180.0, 215.0])
	q.ad_ratio = 0.85
	q.damage_type = GameConst.DamageType.PHYSICAL

	# W
	var w := AreaAbility.new()
	w.id = &"smoke_mirage"
	w.display_name = "Smoke Mirage"
	w.description = "Deploys an obscuring smoke cloud around self, gaining haste and brief untargetability."
	w.color = Color(0.7, 0.05, 0.2)
	w.icon = load("res://assets/icons/abilities/edgy_w.svg")
	w.center = AreaAbility.Center.SELF
	w.targeting = AbilityData.Targeting.NONE
	w.radius = 3.6
	w.indicator_size = 3.6
	w.cooldown = PackedFloat32Array([16.0, 15.0, 14.0, 13.0, 12.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [
		StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.0),
		StatusEffectData.make(GameConst.Status.UNTARGETABLE, 0.0, 0.75),
	]

	# E
	var e := ProjectileAbility.new()
	e.id = &"venom_dagger"
	e.display_name = "Venom Dagger"
	e.description = "Flings a poisoned dagger that damages and slows the first target hit by 45% for 2s."
	e.color = Color(0.2, 0.8, 0.3)
	e.icon = load("res://assets/icons/abilities/edgy_e.svg")
	e.cast_range = 8.5
	e.indicator_size = 0.9
	e.projectile_speed = 24.0
	e.projectile_width = 0.9
	e.cooldown = PackedFloat32Array([8.0, 7.5, 7.0, 6.5, 6.0])
	e.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	e.base_damage = PackedFloat32Array([65.0, 100.0, 135.0, 170.0, 205.0])
	e.ad_ratio = 0.75
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	# R
	var r := DashAbility.new()
	r.id = &"reapers_execution"
	r.display_name = "Reaper's Execution"
	r.description = "Targets an enemy champion, blinking behind them to deliver a lethal blow that silences for 1.2s."
	r.color = Color(1.0, 0.0, 0.2)
	r.icon = load("res://assets/icons/abilities/edgy_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.mode = DashAbility.Mode.BLINK
	r.targeting = AbilityData.Targeting.UNIT
	r.cast_range = 8.0
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([260.0, 390.0, 520.0])
	r.ad_ratio = 1.05
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.SILENCE, 1.2, 1.2)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 2, 1])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "dagger", "blade_of_ruin", "storm_bow"])
	champ.bot_preferred_range = 1.9

	ResourceSaver.save(champ, "res://data/champions/edgy.tres")


# =========================================================================
# ORIGINAL 5 (PRESERVED)
# =========================================================================
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

	var passive := CastCounterPassive.new()
	passive.id = &"arcane_flow"
	passive.display_name = "Arcane Surge"
	passive.description = "Every 3rd ability cast grants +35% movement speed for 2.5s."
	passive.color = Color(0.3, 0.7, 1.0)
	passive.icon = load("res://assets/icons/abilities/arcanist_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.5)]
	champ.passive = passive

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
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.blocked_by_root = true
	w.base_damage = PackedFloat32Array()
	w.self_effects = [StatusEffectData.make(GameConst.Status.UNTARGETABLE, 0.0, 0.25)]

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
	e.indicator_size = 3.2
	e.delay = 0.6
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([65.0, 70.0, 75.0, 80.0, 85.0])
	e.base_damage = PackedFloat32Array([80.0, 120.0, 160.0, 200.0, 240.0])
	e.ap_ratio = 0.7
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

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
	champ.lore = "A stalwart defender sworn to protect the ancient monoliths."
	champ.color = Color(0.9, 0.7, 0.2)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/WardenModel.tscn")
	champ.portrait = load("res://assets/icons/champions/warden.svg")

	champ.max_health = 680.0
	champ.health_per_level = 95.0
	champ.health_regen = 2.2
	champ.max_mana = 320.0
	champ.mana_per_level = 35.0
	champ.mana_regen = 1.6
	champ.attack_damage = 58.0
	champ.attack_damage_per_level = 3.2
	champ.attack_speed = 0.60
	champ.attack_range = 1.8
	champ.armor = 38.0
	champ.magic_resist = 34.0
	champ.move_speed = 5.6
	champ.attack_windup = 0.22

	var passive := CastCounterPassive.new()
	passive.id = &"ironhide"
	passive.display_name = "Ironhide"
	passive.description = "Casting abilities grants a temporary shield absorbing up to 120 damage for 3s."
	passive.color = Color(0.9, 0.7, 0.2)
	passive.icon = load("res://assets/icons/abilities/warden_p.svg")
	passive.casts_required = 2
	passive.effects = [StatusEffectData.make(GameConst.Status.SHIELD, 120.0, 3.0)]
	champ.passive = passive

	var q := DashAbility.new()
	q.id = &"shield_charge"
	q.display_name = "Shield Charge"
	q.description = "Charges forward, slamming into the first enemy hit and stunning them."
	q.color = Color(0.9, 0.65, 0.2)
	q.icon = load("res://assets/icons/abilities/warden_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 5.5
	q.dash_distance = 5.5
	q.travel_speed = 18.0
	q.indicator_size = 1.5
	q.cooldown = PackedFloat32Array([9.0, 8.5, 8.0, 7.5, 7.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	q.ad_ratio = 0.5
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.0, 1.0)]

	var w := SelfBuffAbility.new()
	w.id = &"fortress"
	w.display_name = "Fortress"
	w.description = "Fortifies his defenses, gaining a large shield and bonus armor for 3.5s."
	w.color = Color(0.95, 0.8, 0.3)
	w.icon = load("res://assets/icons/abilities/warden_w.svg")
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 160.0, 3.5)]

	var e := AreaAbility.new()
	e.id = &"ground_slam"
	e.display_name = "Ground Slam"
	e.description = "Slams the ground, dealing damage and slowing all nearby enemies."
	e.color = Color(0.85, 0.55, 0.15)
	e.icon = load("res://assets/icons/abilities/warden_e.svg")
	e.center = AreaAbility.Center.SELF
	e.targeting = AbilityData.Targeting.NONE
	e.radius = 4.0
	e.indicator_size = 4.0
	e.cooldown = PackedFloat32Array([9.0, 8.5, 8.0, 7.5, 7.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([65.0, 100.0, 135.0, 170.0, 205.0])
	e.ad_ratio = 0.5
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	var r := AreaAbility.new()
	r.id = &"colossus_roar"
	r.display_name = "Colossus Roar"
	r.description = "Roars with titan power, gaining a massive shield and stunning nearby enemies."
	r.color = Color(1.0, 0.85, 0.2)
	r.icon = load("res://assets/icons/abilities/warden_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.center = AreaAbility.Center.SELF
	r.targeting = AbilityData.Targeting.NONE
	r.radius = 5.5
	r.indicator_size = 5.5
	r.cooldown = PackedFloat32Array([80.0, 70.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([150.0, 250.0, 350.0])
	r.ad_ratio = 0.6
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 300.0, 4.0)]
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.25, 1.25)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["cloth_armor", "ruby_crystal", "boots", "titan_plate", "crystal_heart"])
	champ.bot_preferred_range = 1.8

	ResourceSaver.save(champ, "res://data/champions/warden.tres")

func _build_ranger() -> void:
	var champ := ChampionData.new()
	champ.id = &"ranger"
	champ.display_name = "Ranger"
	champ.title = "The Swift Arrow"
	champ.role = "Marksman"
	champ.lore = "A forest marksman whose arrows never miss their mark."
	champ.color = Color(0.4, 0.9, 0.3)
	champ.difficulty = 2
	champ.model_scene = load("res://entities/champion/models/RangerModel.tscn")
	champ.portrait = load("res://assets/icons/champions/ranger.svg")

	champ.max_health = 520.0
	champ.health_per_level = 75.0
	champ.health_regen = 1.2
	champ.max_mana = 350.0
	champ.mana_per_level = 40.0
	champ.mana_regen = 1.8
	champ.attack_damage = 52.0
	champ.attack_damage_per_level = 3.0
	champ.attack_speed = 0.66
	champ.attack_range = 6.2
	champ.armor = 24.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.7
	champ.attack_projectile_style = &"arrow"
	champ.attack_projectile_speed = 26.0
	champ.attack_windup = 0.15

	var passive := AttackStackPassive.new()
	passive.id = &"sharpshooter"
	passive.display_name = "Sharpshooter"
	passive.description = "Every 4th basic attack critically strikes for +50% bonus physical damage."
	passive.color = Color(0.4, 0.9, 0.3)
	passive.icon = load("res://assets/icons/abilities/ranger_p.svg")
	passive.max_stacks = 4
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"piercing_arrow"
	q.display_name = "Piercing Arrow"
	q.description = "Fires a swift arrow that pierces through all enemies in a line."
	q.color = Color(0.4, 0.9, 0.3)
	q.icon = load("res://assets/icons/abilities/ranger_q.svg")
	q.cast_range = 10.5
	q.indicator_size = 1.0
	q.projectile_speed = 26.0
	q.projectile_width = 1.0
	q.cooldown = PackedFloat32Array([6.0, 5.5, 5.0, 4.5, 4.0])
	q.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	q.base_damage = PackedFloat32Array([85.0, 125.0, 165.0, 205.0, 245.0])
	q.ad_ratio = 0.8
	q.damage_type = GameConst.DamageType.PHYSICAL

	var w := DashAbility.new()
	w.id = &"quick_tumble"
	w.display_name = "Quick Tumble"
	w.description = "Tumbles a short distance in the target direction, resetting basic attack windup."
	w.color = Color(0.6, 1.0, 0.4)
	w.icon = load("res://assets/icons/abilities/ranger_w.svg")
	w.mode = DashAbility.Mode.DASH
	w.targeting = AbilityData.Targeting.DIRECTION
	w.cast_range = 4.5
	w.dash_distance = 4.5
	w.travel_speed = 16.0
	w.cooldown = PackedFloat32Array([8.0, 7.0, 6.0, 5.0, 4.0])
	w.mana_cost = PackedFloat32Array([35.0, 35.0, 35.0, 35.0, 35.0])

	var e := AreaAbility.new()
	e.id = &"caltrop_trap"
	e.display_name = "Caltrop Trap"
	e.description = "Throws a field of caltrops that slows enemies walking through it."
	e.color = Color(0.35, 0.75, 0.25)
	e.icon = load("res://assets/icons/abilities/ranger_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.0
	e.radius = 3.0
	e.indicator_size = 3.0
	e.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	e.mana_cost = PackedFloat32Array([55.0, 55.0, 55.0, 55.0, 55.0])
	e.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	e.ad_ratio = 0.4
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.5)]

	var r := AreaAbility.new()
	r.id = &"volley_barrage"
	r.display_name = "Volley Barrage"
	r.description = "Unleashes a massive barrage of arrows over a wide cone area."
	r.color = Color(0.7, 1.0, 0.3)
	r.icon = load("res://assets/icons/abilities/ranger_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.targeting = AbilityData.Targeting.POINT
	r.cast_range = 14.0
	r.radius = 5.0
	r.indicator_size = 5.0
	r.delay = 0.4
	r.cooldown = PackedFloat32Array([70.0, 60.0, 50.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([240.0, 360.0, 480.0])
	r.ad_ratio = 0.9
	r.damage_type = GameConst.DamageType.PHYSICAL

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
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
	champ.attack_windup = 0.18

	var passive := CastCounterPassive.new()
	passive.id = &"shadow_stalker"
	passive.display_name = "Shadow Stalker"
	passive.description = "Every 3rd ability cast grants +40% movement speed for 2.5s."
	passive.color = Color(0.7, 0.25, 0.95)
	passive.icon = load("res://assets/icons/abilities/wraith_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.4, 2.5)]
	champ.passive = passive

	var q := DashAbility.new()
	q.id = &"shadow_dash"
	q.display_name = "Shadow Dash"
	q.description = "Dashes swiftly through shadows in the targeted direction, striking enemies."
	q.color = Color(0.65, 0.2, 0.85)
	q.icon = load("res://assets/icons/abilities/wraith_q.svg")
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

	var w := AreaAbility.new()
	w.id = &"smoke_shroud"
	w.display_name = "Smoke Shroud"
	w.description = "Deploys an obscuring smoke cloud around self, gaining haste and brief untargetability."
	w.color = Color(0.4, 0.15, 0.6)
	w.icon = load("res://assets/icons/abilities/wraith_w.svg")
	w.center = AreaAbility.Center.SELF
	w.targeting = AbilityData.Targeting.NONE
	w.radius = 3.6
	w.indicator_size = 3.6
	w.cooldown = PackedFloat32Array([16.0, 15.0, 14.0, 13.0, 12.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [
		StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.0),
		StatusEffectData.make(GameConst.Status.UNTARGETABLE, 0.0, 0.75),
	]

	var e := ProjectileAbility.new()
	e.id = &"crippling_dagger"
	e.display_name = "Crippling Dagger"
	e.description = "Throws a poisoned dagger slowing the first target by 45% for 2s."
	e.color = Color(0.55, 0.18, 0.75)
	e.icon = load("res://assets/icons/abilities/wraith_e.svg")
	e.cast_range = 8.0
	e.indicator_size = 0.9
	e.projectile_speed = 24.0
	e.projectile_width = 0.9
	e.cooldown = PackedFloat32Array([8.0, 7.5, 7.0, 6.5, 6.0])
	e.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	e.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	e.ad_ratio = 0.75
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	var r := DashAbility.new()
	r.id = &"death_mark"
	r.display_name = "Death Mark"
	r.description = "Targeted leap striking behind an enemy for massive burst damage and 1.2s silence."
	r.color = Color(0.85, 0.1, 0.4)
	r.icon = load("res://assets/icons/abilities/wraith_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.mode = DashAbility.Mode.BLINK
	r.targeting = AbilityData.Targeting.UNIT
	r.cast_range = 8.0
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([250.0, 380.0, 500.0])
	r.ad_ratio = 1.0
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.SILENCE, 1.2, 1.2)]

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
	champ.lore = "A celestial priestess channeling the radiant sun to protect allies and blind oppressors."
	champ.color = Color(1.0, 0.78, 0.28)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/LuminaryModel.tscn")
	champ.portrait = load("res://assets/icons/champions/luminary.svg")

	champ.max_health = 550.0
	champ.health_per_level = 80.0
	champ.health_regen = 1.6
	champ.max_mana = 420.0
	champ.mana_per_level = 48.0
	champ.mana_regen = 2.8
	champ.attack_damage = 44.0
	champ.attack_damage_per_level = 2.4
	champ.attack_speed = 0.62
	champ.attack_range = 5.4
	champ.armor = 24.0
	champ.magic_resist = 30.0
	champ.move_speed = 5.6
	champ.attack_projectile_style = &"solar"
	champ.attack_projectile_speed = 20.0
	champ.attack_windup = 0.22

	var passive := CastCounterPassive.new()
	passive.id = &"solar_grace"
	passive.display_name = "Solar Grace"
	passive.description = "Every 3rd ability cast grants Luminary and nearby allies a burst of +30% movement speed."
	passive.color = Color(1.0, 0.85, 0.3)
	passive.icon = load("res://assets/icons/abilities/luminary_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.5)]
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"sunburst"
	q.display_name = "Sunburst"
	q.description = "Launches an orb of condensed solar energy that damages the first enemy struck."
	q.color = Color(1.0, 0.75, 0.2)
	q.icon = load("res://assets/icons/abilities/luminary_q.svg")
	q.cast_range = 9.0
	q.indicator_size = 1.1
	q.projectile_speed = 20.0
	q.projectile_width = 1.1
	q.cooldown = PackedFloat32Array([6.5, 6.0, 5.5, 5.0, 4.5])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([70.0, 105.0, 140.0, 175.0, 210.0])
	q.ap_ratio = 0.6
	q.damage_type = GameConst.DamageType.MAGIC

	var w := SelfBuffAbility.new()
	w.id = &"solar_aegis"
	w.display_name = "Solar Aegis"
	w.description = "Surrounds herself in a protective solar shield absorbing damage for 3.5s."
	w.color = Color(1.0, 0.85, 0.35)
	w.icon = load("res://assets/icons/abilities/luminary_w.svg")
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [
		StatusEffectData.make(GameConst.Status.SHIELD, 140.0, 3.5),
		StatusEffectData.make(GameConst.Status.HASTE, 0.2, 2.0),
	]

	var e := AreaAbility.new()
	e.id = &"starlight_snare"
	e.display_name = "Starlight Snare"
	e.description = "Conjures a starlight pool that detonates after 0.5s, rooting enemies for 1.25s."
	e.color = Color(0.9, 0.65, 0.2)
	e.icon = load("res://assets/icons/abilities/luminary_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.cast_range = 8.5
	e.radius = 3.0
	e.indicator_size = 3.0
	e.delay = 0.5
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([60.0, 65.0, 70.0, 75.0, 80.0])
	e.base_damage = PackedFloat32Array([60.0, 95.0, 130.0, 165.0, 200.0])
	e.ap_ratio = 0.55
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.ROOT, 1.25, 1.25)]

	var r := AreaAbility.new()
	r.id = &"dawns_radiance"
	r.display_name = "Dawn's Radiance"
	r.description = "Channels a holy solar flare that damages all enemies around Luminary and blinds them."
	r.color = Color(1.0, 0.9, 0.4)
	r.icon = load("res://assets/icons/abilities/luminary_r.svg")
	r.is_ultimate = true
	r.max_rank = 3
	r.center = AreaAbility.Center.SELF
	r.targeting = AbilityData.Targeting.NONE
	r.radius = 7.0
	r.indicator_size = 7.0
	r.cooldown = PackedFloat32Array([80.0, 70.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([220.0, 330.0, 440.0])
	r.ap_ratio = 0.75
	r.damage_type = GameConst.DamageType.MAGIC
	r.self_effects = [StatusEffectData.make(GameConst.Status.SHIELD, 250.0, 4.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["sapphire_crystal", "boots", "archmage_staff", "amp_tome", "crystal_heart"])
	champ.bot_preferred_range = 5.4

	ResourceSaver.save(champ, "res://data/champions/luminary.tres")