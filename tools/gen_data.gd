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
	print("Generating champion and ability data resources with balanced survivability...")
	DirAccess.make_dir_recursive_absolute("res://data/champions")
	DirAccess.make_dir_recursive_absolute("res://data/abilities")

	_build_erez()
	_build_stephen()
	_build_amit()
	_build_nissim()
	_build_rogo()
	_build_yakir()
	_build_lior()
	_build_edgy()

	# Also retain original 5
	_build_arcanist()
	_build_warden()
	_build_ranger()
	_build_wraith()
	_build_luminary()

	print("All champion data resources generated successfully!")

# =========================================================================
# 1. EREZ - The Beast Vanguard (Fighter / Bruiser)
# =========================================================================
func _build_erez() -> void:
	var champ := ChampionData.new()
	champ.id = &"erez"
	champ.display_name = "Erez"
	champ.title = "The Beast Vanguard"
	champ.role = "Fighter"
	champ.lore = "A seasoned front-line warrior fighting in perfect synchrony with his faithful animal companions."
	champ.color = Color(0.25, 0.45, 0.95)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/ErezModel.tscn")
	champ.portrait = load("res://assets/icons/champions/erez.svg")

	champ.max_health = 800.0
	champ.health_per_level = 105.0
	champ.health_regen = 3.2
	champ.max_mana = 350.0
	champ.mana_per_level = 38.0
	champ.mana_regen = 1.8
	champ.attack_damage = 55.0
	champ.attack_damage_per_level = 3.4
	champ.attack_speed = 0.65
	champ.attack_range = 1.9
	champ.armor = 36.0
	champ.armor_per_level = 3.8
	champ.magic_resist = 34.0
	champ.magic_resist_per_level = 1.5
	champ.move_speed = 5.0

	var passive := CastCounterPassive.new()
	passive.id = &"feral_instinct"
	passive.display_name = "Feral Instinct"
	passive.description = "Every 3rd ability cast empowers Erez and his pack, granting +35% move speed."
	passive.color = Color(0.25, 0.45, 0.95)
	passive.icon = load("res://assets/icons/abilities/erez_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.5)]
	champ.passive = passive

	var q := DashAbility.new()
	q.id = &"pack_strike"
	q.display_name = "Pack Strike"
	q.description = "Charges forward in targeted direction, commanding his pack to strike enemies for physical damage."
	q.color = Color(0.3, 0.55, 1.0)
	q.icon = load("res://assets/icons/abilities/erez_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 4.5
	q.dash_distance = 4.5
	q.travel_speed = 22.0
	q.cooldown = PackedFloat32Array([8.0, 7.5, 7.0, 6.5, 6.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([55.0, 90.0, 125.0, 160.0, 195.0])
	q.ad_ratio = 0.65
	q.damage_type = GameConst.DamageType.PHYSICAL

	var w := SelfBuffAbility.new()
	w.id = &"beast_ward"
	w.display_name = "Beast Ward"
	w.description = "Lets out a rallying war cry, gaining a durable shield and speed for 3s."
	w.color = Color(0.2, 0.7, 0.9)
	w.icon = load("res://assets/icons/abilities/erez_w.svg")
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([13.0, 12.0, 11.0, 10.0, 9.0])
	w.mana_cost = PackedFloat32Array([55.0, 55.0, 55.0, 55.0, 55.0])
	w.shield_amount = PackedFloat32Array([100.0, 150.0, 200.0, 250.0, 300.0])
	w.shield_duration = 3.5
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.2, 3.5)]

	var e := AreaAbility.new()
	e.id = &"rallying_quake"
	e.display_name = "Rallying Quake"
	e.description = "Stomps the ground, sending a shockwave that deals damage and slows nearby enemies."
	e.color = Color(0.95, 0.65, 0.15)
	e.icon = load("res://assets/icons/abilities/erez_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 4.0
	e.radius = 2.8
	e.delay = 0.25
	e.cooldown = PackedFloat32Array([10.0, 9.5, 9.0, 8.5, 8.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	e.ad_ratio = 0.45
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.35, 2.0)]

	var r := DashAbility.new()
	r.id = &"apex_predator_charge"
	r.display_name = "Apex Predator Charge"
	r.description = "Unleashes an unstoppable charge across the battlefield with his pack, slamming the first enemy champion."
	r.color = Color(0.95, 0.25, 0.35)
	r.icon = load("res://assets/icons/abilities/erez_r.svg")
	r.mode = DashAbility.Mode.DASH
	r.targeting = AbilityData.Targeting.DIRECTION
	r.cast_range = 9.0
	r.dash_distance = 9.0
	r.travel_speed = 26.0
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([90.0, 75.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([175.0, 275.0, 375.0])
	r.ad_ratio = 0.85
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.2, 1.2)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "ruby_crystal", "phage", "trinity_force"])
	champ.bot_preferred_range = 1.9
	ResourceSaver.save(champ, "res://data/champions/erez.tres")

# =========================================================================
# 2. STEPHEN - The Radiant Spirit (Petite Filipino Support)
# =========================================================================
func _build_stephen() -> void:
	var champ := ChampionData.new()
	champ.id = &"stephen"
	champ.display_name = "Stephen"
	champ.title = "The Radiant Spirit"
	champ.role = "Support"
	champ.lore = "A warm-hearted, compact Filipino enchanter channeling island sunlight to heal and protect friends."
	champ.color = Color(0.95, 0.78, 0.2)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/StephenModel.tscn")
	champ.portrait = load("res://assets/icons/champions/stephen.svg")

	champ.max_health = 700.0
	champ.health_per_level = 90.0
	champ.health_regen = 2.8
	champ.max_mana = 450.0
	champ.mana_per_level = 45.0
	champ.mana_regen = 2.4
	champ.attack_damage = 42.0
	champ.attack_damage_per_level = 2.4
	champ.attack_speed = 0.63
	champ.attack_range = 5.2
	champ.armor = 28.0
	champ.armor_per_level = 3.2
	champ.magic_resist = 32.0
	champ.magic_resist_per_level = 1.3
	champ.move_speed = 4.8

	var passive := CastCounterPassive.new()
	passive.id = &"island_warmth"
	passive.display_name = "Island Warmth"
	passive.description = "Every 3rd ability cast grants +25% move speed to empower movement."
	passive.color = Color(0.95, 0.8, 0.2)
	passive.icon = load("res://assets/icons/abilities/stephen_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.25, 2.5)]
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"solar_orb"
	q.display_name = "Solar Orb"
	q.description = "Fires a concentrated ball of tropical sunlight that bursts upon impact."
	q.color = Color(0.95, 0.85, 0.3)
	q.icon = load("res://assets/icons/abilities/stephen_q.svg")
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 7.5
	q.projectile_speed = 15.0
	q.projectile_width = 0.8
	q.cooldown = PackedFloat32Array([7.0, 6.5, 6.0, 5.5, 5.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	q.ap_ratio = 0.5
	q.damage_type = GameConst.DamageType.MAGIC
	q.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.25, 1.5)]

	var w := DashAbility.new()
	w.id = &"bayanihan_shield"
	w.display_name = "Bayanihan Shield"
	w.description = "Blinks swiftly to reposition and gains a burst of movement speed."
	w.color = Color(0.3, 0.75, 0.95)
	w.icon = load("res://assets/icons/abilities/stephen_w.svg")
	w.mode = DashAbility.Mode.BLINK
	w.targeting = AbilityData.Targeting.POINT
	w.cast_range = 4.5
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.0)]

	var e := AreaAbility.new()
	e.id = &"spirit_ward"
	e.display_name = "Spirit Ward"
	e.description = "Conjures a sanctuary of soothing island warmth, damaging and slowing enemies."
	e.color = Color(0.2, 0.85, 0.55)
	e.icon = load("res://assets/icons/abilities/stephen_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 6.0
	e.radius = 3.0
	e.delay = 0.4
	e.cooldown = PackedFloat32Array([11.0, 10.5, 10.0, 9.5, 9.0])
	e.mana_cost = PackedFloat32Array([60.0, 65.0, 70.0, 75.0, 80.0])
	e.base_damage = PackedFloat32Array([45.0, 70.0, 95.0, 120.0, 145.0])
	e.ap_ratio = 0.45
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.3, 2.0)]

	var r := BeamAbility.new()
	r.id = &"radiant_blessing"
	r.display_name = "Radiant Blessing"
	r.description = "Channels a massive beam of pure tropical sunlight across the arena."
	r.color = Color(1.0, 0.85, 0.2)
	r.icon = load("res://assets/icons/abilities/stephen_r.svg")
	r.targeting = AbilityData.Targeting.DIRECTION
	r.beam_length = 14.0
	r.beam_width = 2.0
	r.charge_time = 0.6
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([90.0, 75.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([180.0, 280.0, 380.0])
	r.ap_ratio = 0.7
	r.damage_type = GameConst.DamageType.MAGIC

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["amplifying_tome", "boots", "fiendish_codex", "ludens_echo"])
	champ.bot_preferred_range = 5.2
	ResourceSaver.save(champ, "res://data/champions/stephen.tres")

# =========================================================================
# 3. AMIT - The Maestro of Stances (Rock / White Girl Pop / Mizrahit Fighter)
# =========================================================================
func _build_amit() -> void:
	var champ := ChampionData.new()
	champ.id = &"amit"
	champ.display_name = "Amit"
	champ.title = "The Maestro of Stances"
	champ.role = "Fighter"
	champ.lore = "A dynamic fighter switching rhythms between Rock, White Girl Pop, and Mizrahit to control the tempo of battle."
	champ.color = Color(0.92, 0.28, 0.6)
	champ.difficulty = 2
	champ.model_scene = load("res://entities/champion/models/AmitModel.tscn")
	champ.portrait = load("res://assets/icons/champions/amit.svg")

	champ.max_health = 770.0
	champ.health_per_level = 100.0
	champ.health_regen = 3.0
	champ.max_mana = 360.0
	champ.mana_per_level = 38.0
	champ.mana_regen = 1.6
	champ.attack_damage = 53.0
	champ.attack_damage_per_level = 3.2
	champ.attack_speed = 0.66
	champ.attack_range = 3.2
	champ.armor = 32.0
	champ.armor_per_level = 3.6
	champ.magic_resist = 32.0
	champ.magic_resist_per_level = 1.4
	champ.move_speed = 4.9

	var passive := AttackStackPassive.new()
	passive.id = &"rhythmic_flow"
	passive.display_name = "Rhythmic Flow"
	passive.description = "Attacking in rhythm builds musical tempo stacks, granting attack speed and burst haste."
	passive.color = Color(0.92, 0.28, 0.6)
	passive.icon = load("res://assets/icons/abilities/amit_p.svg")
	passive.attack_speed_per_stack = 0.08
	passive.full_stack_haste = 0.15
	passive.stack_limit = 5
	passive.stack_duration = 4.0
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"rock_powerchord"
	q.display_name = "Rock Powerchord"
	q.description = "Strikes a roaring electric guitar riff, firing a sonic lightning wave forward."
	q.color = Color(0.95, 0.2, 0.2)
	q.icon = load("res://assets/icons/abilities/amit_q.svg")
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 6.5
	q.projectile_speed = 18.0
	q.projectile_width = 0.8
	q.cooldown = PackedFloat32Array([6.5, 6.0, 5.5, 5.0, 4.5])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([55.0, 90.0, 125.0, 160.0, 195.0])
	q.ad_ratio = 0.6
	q.damage_type = GameConst.DamageType.PHYSICAL

	var w := DashAbility.new()
	w.id = &"pop_slide"
	w.display_name = "Pop Slide"
	w.description = "Slides nimbly with pop rhythm, gaining haste and resetting basic attack windup."
	w.color = Color(0.95, 0.4, 0.75)
	w.icon = load("res://assets/icons/abilities/amit_w.svg")
	w.mode = DashAbility.Mode.DASH
	w.targeting = AbilityData.Targeting.DIRECTION
	w.cast_range = 4.8
	w.dash_distance = 4.8
	w.travel_speed = 19.0
	w.cooldown = PackedFloat32Array([9.0, 8.5, 8.0, 7.5, 7.0])
	w.mana_cost = PackedFloat32Array([40.0, 40.0, 40.0, 40.0, 40.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.0)]

	var e := AreaAbility.new()
	e.id = &"mizrahit_groove"
	e.display_name = "Mizrahit Groove"
	e.description = "Drops a pulsating middle-eastern rhythm beat, slowing enemies caught in the groove."
	e.color = Color(0.95, 0.7, 0.15)
	e.icon = load("res://assets/icons/abilities/amit_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 5.5
	e.radius = 2.8
	e.delay = 0.35
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([48.0, 78.0, 108.0, 138.0, 168.0])
	e.ad_ratio = 0.45
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.4, 2.0)]

	var r := AreaAbility.new()
	r.id = &"grand_concert"
	r.display_name = "Grand Concert"
	r.description = "Unleashes a showstopping musical finale that deafens foes and electrifies the arena."
	r.color = Color(0.8, 0.2, 0.95)
	r.icon = load("res://assets/icons/abilities/amit_r.svg")
	r.targeting = AbilityData.Targeting.POINT
	r.center = AreaAbility.Center.POINT
	r.cast_range = 7.0
	r.radius = 4.0
	r.delay = 0.5
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([85.0, 70.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([190.0, 300.0, 410.0])
	r.ad_ratio = 0.75
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.0, 1.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "dagger", "storm_bow", "blade_of_ruin"])
	champ.bot_preferred_range = 3.2
	ResourceSaver.save(champ, "res://data/champions/amit.tres")

# =========================================================================
# 4. NISSIM - "אבא של כולם" (The Grandfather Strategist Mage)
# =========================================================================
func _build_nissim() -> void:
	var champ := ChampionData.new()
	champ.id = &"nissim"
	champ.display_name = "Nissim"
	champ.title = "Everyone's Dad"
	champ.role = "Mage"
	champ.lore = "The wise strategist and father figure of the team, dispensing orders, tactical wisdom, and hot coffee."
	champ.color = Color(0.1, 0.75, 0.45)
	champ.difficulty = 2
	champ.model_scene = load("res://entities/champion/models/NissimModel.tscn")
	champ.portrait = load("res://assets/icons/champions/nissim.svg")

	champ.max_health = 710.0
	champ.health_per_level = 92.0
	champ.health_regen = 2.8
	champ.max_mana = 460.0
	champ.mana_per_level = 45.0
	champ.mana_regen = 2.5
	champ.attack_damage = 44.0
	champ.attack_damage_per_level = 2.6
	champ.attack_speed = 0.63
	champ.attack_range = 5.2
	champ.armor = 28.0
	champ.armor_per_level = 3.2
	champ.magic_resist = 32.0
	champ.magic_resist_per_level = 1.3
	champ.move_speed = 4.8

	var passive := CastCounterPassive.new()
	passive.id = &"fatherly_wisdom"
	passive.display_name = "Fatherly Wisdom"
	passive.description = "Every 3rd ability cast empowers Nissim with +25% movement speed."
	passive.color = Color(0.1, 0.75, 0.45)
	passive.icon = load("res://assets/icons/abilities/nissim_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.25, 3.0)]
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"tactical_decree"
	q.display_name = "Tactical Decree"
	q.description = "Dispatches a calculated tactical blast that pierces through foes."
	q.color = Color(0.2, 0.85, 0.5)
	q.icon = load("res://assets/icons/abilities/nissim_q.svg")
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 8.0
	q.projectile_speed = 16.0
	q.projectile_width = 0.9
	q.cooldown = PackedFloat32Array([6.5, 6.0, 5.5, 5.0, 4.5])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([55.0, 90.0, 125.0, 160.0, 195.0])
	q.ap_ratio = 0.55
	q.damage_type = GameConst.DamageType.MAGIC

	var w := SelfBuffAbility.new()
	w.id = &"time_out"
	w.display_name = "Time-Out"
	w.description = "Calls a tactical time-out, gaining a shield and speed boost."
	w.color = Color(0.1, 0.6, 0.9)
	w.icon = load("res://assets/icons/abilities/nissim_w.svg")
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([55.0, 55.0, 55.0, 55.0, 55.0])
	w.shield_amount = PackedFloat32Array([100.0, 150.0, 200.0, 250.0, 300.0])
	w.shield_duration = 3.5
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.2, 3.0)]

	var e := AreaAbility.new()
	e.id = &"coffee_break"
	e.display_name = "Coffee Break"
	e.description = "Splashes a field of steaming hot coffee, scalding and slowing enemies in the area."
	e.color = Color(0.85, 0.55, 0.15)
	e.icon = load("res://assets/icons/abilities/nissim_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 6.0
	e.radius = 3.0
	e.delay = 0.35
	e.cooldown = PackedFloat32Array([10.5, 9.5, 8.5, 7.5, 6.5])
	e.mana_cost = PackedFloat32Array([60.0, 65.0, 70.0, 75.0, 80.0])
	e.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	e.ap_ratio = 0.45
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.35, 2.0)]

	var r := BeamAbility.new()
	r.id = &"master_plan"
	r.display_name = "Master Plan"
	r.description = "Executes the grand tactical plan, blasting across the arena with a colossal energy beam."
	r.color = Color(0.1, 0.9, 0.6)
	r.icon = load("res://assets/icons/abilities/nissim_r.svg")
	r.targeting = AbilityData.Targeting.DIRECTION
	r.beam_length = 14.0
	r.beam_width = 1.9
	r.charge_time = 0.6
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([90.0, 75.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([200.0, 310.0, 420.0])
	r.ap_ratio = 0.75
	r.damage_type = GameConst.DamageType.MAGIC

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["amplifying_tome", "boots", "fiendish_codex", "rabadon_deathcrown"])
	champ.bot_preferred_range = 5.2
	ResourceSaver.save(champ, "res://data/champions/nissim.tres")

# =========================================================================
# 5. ROGO - The Heavy Smasher (Colossal Heavyweight Tank)
# =========================================================================
func _build_rogo() -> void:
	var champ := ChampionData.new()
	champ.id = &"rogo"
	champ.display_name = "Rogo"
	champ.title = "The Heavy Smasher"
	champ.role = "Tank"
	champ.lore = "A colossal heavyweight whose immense mass and crushing body slams reshape the terrain."
	champ.color = Color(0.85, 0.15, 0.15)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/RogoModel.tscn")
	champ.portrait = load("res://assets/icons/champions/rogo.svg")

	champ.max_health = 920.0
	champ.health_per_level = 125.0
	champ.health_regen = 4.0
	champ.max_mana = 300.0
	champ.mana_per_level = 32.0
	champ.mana_regen = 1.4
	champ.attack_damage = 56.0
	champ.attack_damage_per_level = 3.6
	champ.attack_speed = 0.62
	champ.attack_range = 1.8
	champ.armor = 44.0
	champ.armor_per_level = 4.4
	champ.magic_resist = 38.0
	champ.magic_resist_per_level = 2.0
	champ.move_speed = 4.7

	var passive := AttackCounterPassive.new()
	passive.id = &"colossal_mass"
	passive.display_name = "Colossal Mass"
	passive.description = "Every 3rd basic attack crushes the target with his immense weight, dealing bonus damage."
	passive.color = Color(0.85, 0.15, 0.15)
	passive.icon = load("res://assets/icons/abilities/rogo_p.svg")
	passive.attacks_required = 3
	passive.bonus_damage = 25.0
	passive.bonus_damage_per_level = 6.0
	passive.bonus_max_health_ratio = 0.04
	passive.heal_max_health_ratio = 0.03
	champ.passive = passive

	var q := AreaAbility.new()
	q.id = &"heavy_slam"
	q.display_name = "Heavy Slam"
	q.description = "Slams the ground with colossal fists, fracturing the earth and slowing enemies."
	q.color = Color(0.9, 0.2, 0.2)
	q.icon = load("res://assets/icons/abilities/rogo_q.svg")
	q.targeting = AbilityData.Targeting.POINT
	q.center = AreaAbility.Center.POINT
	q.cast_range = 3.8
	q.radius = 2.8
	q.delay = 0.25
	q.cooldown = PackedFloat32Array([7.5, 7.0, 6.5, 6.0, 5.5])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([55.0, 90.0, 125.0, 160.0, 195.0])
	q.ad_ratio = 0.45
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.4, 2.0)]

	var w := SelfBuffAbility.new()
	w.id = &"iron_belly"
	w.display_name = "Iron Belly"
	w.description = "Hardens his massive midsection, gaining a huge absorption shield."
	w.color = Color(0.95, 0.35, 0.35)
	w.icon = load("res://assets/icons/abilities/rogo_w.svg")
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([50.0, 50.0, 50.0, 50.0, 50.0])
	w.shield_amount = PackedFloat32Array([120.0, 180.0, 240.0, 300.0, 360.0])
	w.shield_duration = 3.5

	var e := DashAbility.new()
	e.id = &"belly_flop"
	e.display_name = "Belly Flop"
	e.description = "Launches himself forward in a devastating belly flop, stunning the first enemy."
	e.color = Color(0.8, 0.1, 0.4)
	e.icon = load("res://assets/icons/abilities/rogo_e.svg")
	e.mode = DashAbility.Mode.DASH
	e.targeting = AbilityData.Targeting.DIRECTION
	e.cast_range = 4.8
	e.dash_distance = 4.8
	e.travel_speed = 18.0
	e.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	e.mana_cost = PackedFloat32Array([55.0, 60.0, 65.0, 70.0, 75.0])
	e.base_damage = PackedFloat32Array([50.0, 85.0, 120.0, 155.0, 190.0])
	e.ad_ratio = 0.4
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 0.75, 0.75)]

	var r := AreaAbility.new()
	r.id = &"cataclysmic_crush"
	r.display_name = "Cataclysmic Crush"
	r.description = "Leaps high into the air and crashes down with earthquake force, crushing and stunning all foes."
	r.color = Color(1.0, 0.2, 0.1)
	r.icon = load("res://assets/icons/abilities/rogo_r.svg")
	r.targeting = AbilityData.Targeting.POINT
	r.center = AreaAbility.Center.POINT
	r.cast_range = 6.0
	r.radius = 4.2
	r.delay = 0.6
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([95.0, 80.0, 65.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([190.0, 290.0, 390.0])
	r.ad_ratio = 0.6
	r.damage_type = GameConst.DamageType.PHYSICAL
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.4, 1.4)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["cloth_armor", "ruby_crystal", "boots", "sunfire_aegis", "thornmail", "warmog_armor"])
	champ.bot_preferred_range = 1.8
	ResourceSaver.save(champ, "res://data/champions/rogo.tres")

# =========================================================================
# 6. YAKIR - The Refreshment Specialist (Energy Drinks & Food Support)
# =========================================================================
func _build_yakir() -> void:
	var champ := ChampionData.new()
	champ.id = &"yakir"
	champ.display_name = "Yakir"
	champ.title = "The Refreshment Specialist"
	champ.role = "Support"
	champ.lore = "A supportive friend who keeps his team in peak condition by tossing snacks, shawarma, and icy energy drinks."
	champ.color = Color(0.12, 0.75, 0.55)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/YakirModel.tscn")
	champ.portrait = load("res://assets/icons/champions/yakir.svg")

	champ.max_health = 740.0
	champ.health_per_level = 96.0
	champ.health_regen = 3.0
	champ.max_mana = 420.0
	champ.mana_per_level = 42.0
	champ.mana_regen = 2.2
	champ.attack_damage = 45.0
	champ.attack_damage_per_level = 2.8
	champ.attack_speed = 0.64
	champ.attack_range = 4.8
	champ.armor = 32.0
	champ.armor_per_level = 3.6
	champ.magic_resist = 34.0
	champ.magic_resist_per_level = 1.5
	champ.move_speed = 4.8

	var passive := CastCounterPassive.new()
	passive.id = &"energy_rush"
	passive.display_name = "Energy Rush"
	passive.description = "Every 3rd ability cast distributes a surge of caffeine and sugar, granting +30% movement speed."
	passive.color = Color(0.15, 0.85, 0.45)
	passive.icon = load("res://assets/icons/abilities/yakir_p.svg")
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 2.5)]
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"energy_drink_toss"
	q.display_name = "Energy Drink Toss"
	q.description = "Hurls a pressurized can of XL energy drink, exploding on impact and slowing enemies."
	q.color = Color(0.2, 0.9, 0.4)
	q.icon = load("res://assets/icons/abilities/yakir_q.svg")
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 7.5
	q.projectile_speed = 16.0
	q.projectile_width = 0.8
	q.cooldown = PackedFloat32Array([7.0, 6.5, 6.0, 5.5, 5.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	q.ap_ratio = 0.5
	q.damage_type = GameConst.DamageType.MAGIC
	q.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.3, 1.8)]

	var w := SelfBuffAbility.new()
	w.id = &"hot_snack_drop"
	w.display_name = "Hot Snack Drop"
	w.description = "Prepares a hot snack platter, gaining a protective shield and move speed."
	w.color = Color(0.95, 0.65, 0.2)
	w.icon = load("res://assets/icons/abilities/yakir_w.svg")
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([55.0, 55.0, 55.0, 55.0, 55.0])
	w.shield_amount = PackedFloat32Array([100.0, 150.0, 200.0, 250.0, 300.0])
	w.shield_duration = 3.5
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.2, 3.0)]

	var e := AreaAbility.new()
	e.id = &"sugar_surge"
	e.display_name = "Sugar Surge"
	e.description = "Splashes a bubbly puddle of energy soda, damaging and slowing enemies caught in the fizz."
	e.color = Color(0.4, 0.5, 0.95)
	e.icon = load("res://assets/icons/abilities/yakir_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 6.0
	e.radius = 2.9
	e.delay = 0.3
	e.cooldown = PackedFloat32Array([10.0, 9.5, 9.0, 8.5, 8.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([48.0, 78.0, 108.0, 138.0, 168.0])
	e.ap_ratio = 0.45
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.35, 2.0)]

	var r := AreaAbility.new()
	r.id = &"the_grand_feast"
	r.display_name = "The Grand Feast"
	r.description = "Deploys a banquet table on the battlefield, unleashing a wave of refreshment that damages and stuns foes."
	r.color = Color(0.15, 0.85, 0.4)
	r.icon = load("res://assets/icons/abilities/yakir_r.svg")
	r.targeting = AbilityData.Targeting.POINT
	r.center = AreaAbility.Center.POINT
	r.cast_range = 7.0
	r.radius = 4.0
	r.delay = 0.5
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([90.0, 75.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([170.0, 260.0, 350.0])
	r.ap_ratio = 0.65
	r.damage_type = GameConst.DamageType.MAGIC
	r.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.25, 1.25)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["amplifying_tome", "boots", "fiendish_codex", "ludens_echo"])
	champ.bot_preferred_range = 4.8
	ResourceSaver.save(champ, "res://data/champions/yakir.tres")

# =========================================================================
# 7. LIOR - The Graceful Vanguard (Feminine / Effeminate Male Tank)
# =========================================================================
func _build_lior() -> void:
	var champ := ChampionData.new()
	champ.id = &"lior"
	champ.display_name = "Lior"
	champ.title = "The Graceful Vanguard"
	champ.role = "Tank"
	champ.lore = "An exceptionally elegant, effeminate warrior whose poise is rivaled only by his impenetrable mirror barrier."
	champ.color = Color(0.95, 0.45, 0.65)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/LiorModel.tscn")
	champ.portrait = load("res://assets/icons/champions/lior.svg")

	champ.max_health = 880.0
	champ.health_per_level = 120.0
	champ.health_regen = 3.8
	champ.max_mana = 320.0
	champ.mana_per_level = 36.0
	champ.mana_regen = 1.6
	champ.attack_damage = 50.0
	champ.attack_damage_per_level = 3.0
	champ.attack_speed = 0.64
	champ.attack_range = 1.9
	champ.armor = 44.0
	champ.armor_per_level = 4.4
	champ.magic_resist = 38.0
	champ.magic_resist_per_level = 2.0
	champ.move_speed = 4.8

	var passive := AttackCounterPassive.new()
	passive.id = &"prismatic_glamour"
	passive.display_name = "Prismatic Glamour"
	passive.description = "Every 3rd attack releases a dazzling flash, dealing bonus damage and restoring health."
	passive.color = Color(0.95, 0.5, 0.7)
	passive.icon = load("res://assets/icons/abilities/lior_p.svg")
	passive.attacks_required = 3
	passive.bonus_damage = 22.0
	passive.bonus_damage_per_level = 6.0
	passive.bonus_max_health_ratio = 0.035
	passive.heal_max_health_ratio = 0.03
	champ.passive = passive

	var q := DashAbility.new()
	q.id = &"graceful_lunge"
	q.display_name = "Graceful Lunge"
	q.description = "Lunges forward with mirror shield, striking the first enemy and slowing them."
	q.color = Color(0.95, 0.4, 0.6)
	q.icon = load("res://assets/icons/abilities/lior_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 5.2
	q.dash_distance = 5.2
	q.travel_speed = 20.0
	q.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	q.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	q.base_damage = PackedFloat32Array([55.0, 85.0, 115.0, 145.0, 175.0])
	q.ad_ratio = 0.4
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.35, 1.8)]

	var w := SelfBuffAbility.new()
	w.id = &"mirror_sheen"
	w.display_name = "Mirror Sheen"
	w.description = "Polishes mirror shield, granting a durable absorption shield and speed."
	w.color = Color(0.98, 0.6, 0.8)
	w.icon = load("res://assets/icons/abilities/lior_w.svg")
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.shield_amount = PackedFloat32Array([115.0, 175.0, 235.0, 295.0, 355.0])
	w.shield_duration = 3.5
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.2, 3.5)]

	var e := AreaAbility.new()
	e.id = &"charming_step"
	e.display_name = "Charming Step"
	e.description = "Performs a graceful twirl, dispersing crystal fragments that stun enemies around him."
	e.color = Color(0.85, 0.35, 0.8)
	e.icon = load("res://assets/icons/abilities/lior_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 4.5
	e.radius = 3.2
	e.delay = 0.3
	e.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	e.mana_cost = PackedFloat32Array([55.0, 60.0, 65.0, 70.0, 75.0])
	e.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	e.ad_ratio = 0.35
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.0, 1.0)]

	var r := SelfBuffAbility.new()
	r.id = &"dazzling_pavilion"
	r.display_name = "Dazzling Pavilion"
	r.description = "Erects a prismatic mirror pavilion, gaining enormous shielding and speed."
	r.color = Color(1.0, 0.7, 0.85)
	r.icon = load("res://assets/icons/abilities/lior_r.svg")
	r.targeting = AbilityData.Targeting.NONE
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([90.0, 80.0, 70.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.shield_amount = PackedFloat32Array([350.0, 550.0, 750.0])
	r.shield_duration = 6.0
	r.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 6.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["cloth_armor", "ruby_crystal", "boots", "sunfire_aegis", "thornmail", "warmog_armor"])
	champ.bot_preferred_range = 1.8
	ResourceSaver.save(champ, "res://data/champions/lior.tres")

# =========================================================================
# 7. EDGY (formerly referred to as Lior) - The Graceful Vanguard (Feminine / Effeminate Male Tank)
# =========================================================================
func _build_edgy() -> void:
	var champ := ChampionData.new()
	champ.id = &"edgy"
	champ.display_name = "Edgy"
	champ.title = "The Graceful Vanguard"
	champ.role = "Tank"
	champ.lore = "An exceptionally elegant, effeminate warrior whose poise is rivaled only by his impenetrable mirror barrier."
	champ.color = Color(0.95, 0.45, 0.65)
	champ.difficulty = 1
	champ.model_scene = load("res://entities/champion/models/EdgyModel.tscn")
	champ.portrait = load("res://assets/icons/champions/edgy.svg")

	champ.max_health = 880.0
	champ.health_per_level = 120.0
	champ.health_regen = 3.8
	champ.max_mana = 320.0
	champ.mana_per_level = 36.0
	champ.mana_regen = 1.6
	champ.attack_damage = 50.0
	champ.attack_damage_per_level = 3.0
	champ.attack_speed = 0.64
	champ.attack_range = 1.9
	champ.armor = 44.0
	champ.armor_per_level = 4.4
	champ.magic_resist = 38.0
	champ.magic_resist_per_level = 2.0
	champ.move_speed = 4.8

	var passive := AttackCounterPassive.new()
	passive.id = &"prismatic_glamour"
	passive.display_name = "Prismatic Glamour"
	passive.description = "Every 3rd attack releases a dazzling flash, dealing bonus damage and restoring health."
	passive.color = Color(0.95, 0.5, 0.7)
	passive.icon = load("res://assets/icons/abilities/edgy_p.svg")
	passive.attacks_required = 3
	passive.bonus_damage = 22.0
	passive.bonus_damage_per_level = 6.0
	passive.bonus_max_health_ratio = 0.035
	passive.heal_max_health_ratio = 0.03
	champ.passive = passive

	var q := DashAbility.new()
	q.id = &"graceful_lunge"
	q.display_name = "Graceful Lunge"
	q.description = "Lunges forward with mirror shield, striking the first enemy and slowing them."
	q.color = Color(0.95, 0.4, 0.6)
	q.icon = load("res://assets/icons/abilities/edgy_q.svg")
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 5.2
	q.dash_distance = 5.2
	q.travel_speed = 20.0
	q.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	q.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	q.base_damage = PackedFloat32Array([55.0, 85.0, 115.0, 145.0, 175.0])
	q.ad_ratio = 0.4
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.35, 1.8)]

	var w := SelfBuffAbility.new()
	w.id = &"mirror_sheen"
	w.display_name = "Mirror Sheen"
	w.description = "Polishes mirror shield, granting a durable absorption shield and speed."
	w.color = Color(0.98, 0.6, 0.8)
	w.icon = load("res://assets/icons/abilities/edgy_w.svg")
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.shield_amount = PackedFloat32Array([115.0, 175.0, 235.0, 295.0, 355.0])
	w.shield_duration = 3.5
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.2, 3.5)]

	var e := AreaAbility.new()
	e.id = &"charming_step"
	e.display_name = "Charming Step"
	e.description = "Performs a graceful twirl, dispersing crystal fragments that stun enemies around him."
	e.color = Color(0.85, 0.35, 0.8)
	e.icon = load("res://assets/icons/abilities/edgy_e.svg")
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 4.5
	e.radius = 3.2
	e.delay = 0.3
	e.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	e.mana_cost = PackedFloat32Array([55.0, 60.0, 65.0, 70.0, 75.0])
	e.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	e.ad_ratio = 0.35
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 1.0, 1.0)]

	var r := SelfBuffAbility.new()
	r.id = &"dazzling_pavilion"
	r.display_name = "Dazzling Pavilion"
	r.description = "Erects a prismatic mirror pavilion, gaining enormous shielding and speed."
	r.color = Color(1.0, 0.7, 0.85)
	r.icon = load("res://assets/icons/abilities/edgy_r.svg")
	r.targeting = AbilityData.Targeting.NONE
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([90.0, 80.0, 70.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.shield_amount = PackedFloat32Array([350.0, 550.0, 750.0])
	r.shield_duration = 6.0
	r.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.3, 6.0)]

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["cloth_armor", "ruby_crystal", "boots", "sunfire_aegis", "thornmail", "warmog_armor"])
	champ.bot_preferred_range = 1.8
	ResourceSaver.save(champ, "res://data/champions/edgy.tres")


# =========================================================================
# Legacy Champions
# =========================================================================
func _build_arcanist() -> void:
	var champ := ChampionData.new()
	champ.id = &"arcanist"
	champ.display_name = "Arcanist"
	champ.title = "The Rift Sorcerer"
	champ.role = "Mage"
	champ.lore = "A master of spatial manipulation who bends arcane energy across dimensions."
	champ.color = Color(0.4, 0.7, 1.0)
	champ.model_scene = load("res://entities/champion/models/StephenModel.tscn")
	champ.portrait = load("res://assets/icons/champions/stephen.svg")
	champ.max_health = 720.0
	champ.health_per_level = 90.0
	champ.health_regen = 2.8
	champ.max_mana = 450.0
	champ.mana_per_level = 45.0
	champ.mana_regen = 2.4
	champ.attack_damage = 44.0
	champ.attack_damage_per_level = 2.5
	champ.attack_speed = 0.65
	champ.attack_range = 5.5
	champ.armor = 28.0
	champ.armor_per_level = 3.2
	champ.magic_resist = 32.0
	champ.magic_resist_per_level = 1.3
	champ.move_speed = 4.8

	var passive := CastCounterPassive.new()
	passive.id = &"arcane_surge"
	passive.display_name = "Arcane Surge"
	passive.description = "Every 3rd ability cast grants +35% movement speed for 2.5s."
	passive.color = Color(0.4, 0.7, 1.0)
	passive.casts_required = 3
	passive.effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.35, 2.5)]
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"mystic_bolt"
	q.display_name = "Mystic Bolt"
	q.description = "Fires a swift bolt of pure arcane energy in the target direction."
	q.color = Color(0.4, 0.7, 1.0)
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 7.5
	q.projectile_speed = 16.0
	q.projectile_width = 0.8
	q.cooldown = PackedFloat32Array([6.0, 5.5, 5.0, 4.5, 4.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([55.0, 85.0, 115.0, 145.0, 175.0])
	q.ap_ratio = 0.55
	q.damage_type = GameConst.DamageType.MAGIC

	var w := DashAbility.new()
	w.id = &"phase_shift"
	w.display_name = "Phase Shift"
	w.description = "Instantly blinks a short distance, becoming briefly untargetable."
	w.color = Color(0.6, 0.4, 1.0)
	w.mode = DashAbility.Mode.BLINK
	w.targeting = AbilityData.Targeting.POINT
	w.cast_range = 5.0
	w.cooldown = PackedFloat32Array([14.0, 13.0, 12.0, 11.0, 10.0])
	w.mana_cost = PackedFloat32Array([60.0, 60.0, 60.0, 60.0, 60.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.UNTARGETABLE, 1.0, 0.5)]

	var e := AreaAbility.new()
	e.id = &"gravity_well"
	e.display_name = "Gravity Well"
	e.description = "Creates a field of heavy gravity that detonates after 0.6s, dealing damage and slowing enemies."
	e.color = Color(0.3, 0.5, 0.9)
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 6.0
	e.radius = 3.0
	e.delay = 0.6
	e.cooldown = PackedFloat32Array([10.0, 9.5, 9.0, 8.5, 8.0])
	e.mana_cost = PackedFloat32Array([55.0, 60.0, 65.0, 70.0, 75.0])
	e.base_damage = PackedFloat32Array([50.0, 75.0, 100.0, 125.0, 150.0])
	e.ap_ratio = 0.45
	e.damage_type = GameConst.DamageType.MAGIC
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.35, 2.0)]

	var r := BeamAbility.new()
	r.id = &"obliteration_beam"
	r.display_name = "Obliteration Beam"
	r.description = "Channels for 0.6s then unleashes a colossal beam across the arena that pierces all enemies."
	r.color = Color(0.5, 0.8, 1.0)
	r.targeting = AbilityData.Targeting.DIRECTION
	r.beam_length = 14.0
	r.beam_width = 2.0
	r.charge_time = 0.6
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([80.0, 65.0, 50.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([200.0, 310.0, 420.0])
	r.ap_ratio = 0.75
	r.damage_type = GameConst.DamageType.MAGIC

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["amplifying_tome", "boots", "fiendish_codex", "ludens_echo", "rabadon_deathcrown", "void_staff"])
	champ.bot_preferred_range = 5.5
	ResourceSaver.save(champ, "res://data/champions/arcanist.tres")

func _build_warden() -> void:
	var champ := ChampionData.new()
	champ.id = &"warden"
	champ.display_name = "Warden"
	champ.title = "The Bulwark"
	champ.role = "Tank"
	champ.lore = "An immovable bastion whose armor absorbs punishment and protects allies."
	champ.color = Color(0.2, 0.8, 0.4)
	champ.model_scene = load("res://entities/champion/models/RogoModel.tscn")
	champ.portrait = load("res://assets/icons/champions/rogo.svg")
	champ.max_health = 920.0
	champ.health_per_level = 120.0
	champ.health_regen = 4.0
	champ.max_mana = 300.0
	champ.mana_per_level = 30.0
	champ.mana_regen = 1.5
	champ.attack_damage = 52.0
	champ.attack_damage_per_level = 3.2
	champ.attack_speed = 0.62
	champ.attack_range = 1.8
	champ.armor = 44.0
	champ.armor_per_level = 4.4
	champ.magic_resist = 38.0
	champ.magic_resist_per_level = 2.0
	champ.move_speed = 4.7

	var passive := AttackCounterPassive.new()
	passive.id = &"iron_resolve"
	passive.display_name = "Iron Resolve"
	passive.description = "Every 3rd basic attack deals bonus damage and heals for 2% max HP."
	passive.color = Color(0.2, 0.8, 0.4)
	passive.attacks_required = 3
	passive.bonus_damage = 20.0
	passive.bonus_damage_per_level = 6.0
	passive.bonus_max_health_ratio = 0.03
	passive.heal_max_health_ratio = 0.02
	champ.passive = passive

	var q := DashAbility.new()
	q.id = &"shield_charge"
	q.display_name = "Shield Charge"
	q.description = "Charges forward, slamming into enemies and stunning them."
	q.color = Color(0.2, 0.8, 0.4)
	q.mode = DashAbility.Mode.DASH
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 5.0
	q.dash_distance = 5.0
	q.travel_speed = 20.0
	q.cooldown = PackedFloat32Array([10.0, 9.5, 9.0, 8.5, 8.0])
	q.mana_cost = PackedFloat32Array([45.0, 50.0, 55.0, 60.0, 65.0])
	q.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	q.ad_ratio = 0.4
	q.damage_type = GameConst.DamageType.PHYSICAL
	q.target_effects = [StatusEffectData.make(GameConst.Status.STUN, 0.8, 0.8)]

	var w := SelfBuffAbility.new()
	w.id = &"bulwark"
	w.display_name = "Bulwark"
	w.description = "Raises a formidable shield, absorbing incoming damage."
	w.color = Color(0.3, 0.9, 0.5)
	w.targeting = AbilityData.Targeting.NONE
	w.cooldown = PackedFloat32Array([12.0, 11.0, 10.0, 9.0, 8.0])
	w.mana_cost = PackedFloat32Array([50.0, 50.0, 50.0, 50.0, 50.0])
	w.shield_amount = PackedFloat32Array([120.0, 180.0, 240.0, 300.0, 360.0])
	w.shield_duration = 3.5

	var e := AreaAbility.new()
	e.id = &"ground_slam"
	e.display_name = "Ground Slam"
	e.description = "Slams the ground with massive force, dealing damage and heavily slowing nearby enemies."
	e.color = Color(0.1, 0.7, 0.3)
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.SELF
	e.cast_range = 3.5
	e.radius = 3.0
	e.delay = 0.3
	e.cooldown = PackedFloat32Array([9.0, 8.5, 8.0, 7.5, 7.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([50.0, 80.0, 110.0, 140.0, 170.0])
	e.ad_ratio = 0.4
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.45, 2.0)]

	var r := SelfBuffAbility.new()
	r.id = &"colossus_roar"
	r.display_name = "Colossus Roar"
	r.description = "Unleashes a titan roar, granting a giant shield for 5s."
	r.color = Color(0.4, 1.0, 0.6)
	r.targeting = AbilityData.Targeting.NONE
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([80.0, 70.0, 60.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.shield_amount = PackedFloat32Array([350.0, 520.0, 700.0])
	r.shield_duration = 5.0

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["cloth_armor", "ruby_crystal", "boots", "sunfire_aegis", "thornmail", "warmog_armor"])
	champ.bot_preferred_range = 1.8
	ResourceSaver.save(champ, "res://data/champions/warden.tres")

func _build_ranger() -> void:
	var champ := ChampionData.new()
	champ.id = &"ranger"
	champ.display_name = "Ranger"
	champ.title = "The Swift Hunter"
	champ.role = "Marksman"
	champ.lore = "A deadly marksman with unmatched accuracy and agility."
	champ.color = Color(0.9, 0.6, 0.2)
	champ.model_scene = load("res://entities/champion/models/AmitModel.tscn")
	champ.portrait = load("res://assets/icons/champions/amit.svg")
	champ.max_health = 700.0
	champ.health_per_level = 88.0
	champ.health_regen = 2.6
	champ.max_mana = 350.0
	champ.mana_per_level = 35.0
	champ.mana_regen = 1.5
	champ.attack_damage = 50.0
	champ.attack_damage_per_level = 3.0
	champ.attack_speed = 0.68
	champ.attack_range = 5.8
	champ.armor = 28.0
	champ.armor_per_level = 3.2
	champ.magic_resist = 32.0
	champ.magic_resist_per_level = 1.2
	champ.move_speed = 4.9

	var passive := AttackStackPassive.new()
	passive.id = &"focus"
	passive.display_name = "Focus"
	passive.description = "Consecutive basic attacks grant stacking attack speed."
	passive.color = Color(0.9, 0.6, 0.2)
	passive.attack_speed_per_stack = 0.08
	passive.full_stack_haste = 0.12
	passive.stack_limit = 5
	passive.stack_duration = 3.5
	champ.passive = passive

	var q := ProjectileAbility.new()
	q.id = &"piercing_arrow"
	q.display_name = "Piercing Arrow"
	q.description = "Charges a powerful arrow that pierces through all enemies in a line."
	q.color = Color(0.3, 0.8, 0.4)
	q.targeting = AbilityData.Targeting.DIRECTION
	q.cast_range = 11.5
	q.projectile_speed = 28.0
	q.projectile_width = 0.7
	q.cooldown = PackedFloat32Array([6.0, 5.5, 5.0, 4.5, 4.0])
	q.mana_cost = PackedFloat32Array([40.0, 45.0, 50.0, 55.0, 60.0])
	q.base_damage = PackedFloat32Array([55.0, 85.0, 115.0, 145.0, 175.0])
	q.ad_ratio = 0.65
	q.damage_type = GameConst.DamageType.PHYSICAL

	var w := DashAbility.new()
	w.id = &"quick_tumble"
	w.display_name = "Quick Tumble"
	w.description = "Rolls quickly in the aimed direction, gaining a burst of movement speed."
	w.color = Color(0.4, 0.9, 0.6)
	w.mode = DashAbility.Mode.DASH
	w.targeting = AbilityData.Targeting.DIRECTION
	w.cast_range = 4.5
	w.dash_distance = 4.5
	w.travel_speed = 18.0
	w.cooldown = PackedFloat32Array([8.0, 7.5, 7.0, 6.5, 6.0])
	w.mana_cost = PackedFloat32Array([35.0, 35.0, 35.0, 35.0, 35.0])
	w.self_effects = [StatusEffectData.make(GameConst.Status.HASTE, 0.25, 2.0)]

	var e := AreaAbility.new()
	e.id = &"caltrop_trap"
	e.display_name = "Caltrop Trap"
	e.description = "Scatters sharp caltrops that detonate when enemies step on them, heavily slowing them."
	e.color = Color(0.6, 0.8, 0.2)
	e.targeting = AbilityData.Targeting.POINT
	e.center = AreaAbility.Center.POINT
	e.cast_range = 7.5
	e.radius = 2.5
	e.delay = 0.3
	e.cooldown = PackedFloat32Array([11.0, 10.0, 9.0, 8.0, 7.0])
	e.mana_cost = PackedFloat32Array([50.0, 55.0, 60.0, 65.0, 70.0])
	e.base_damage = PackedFloat32Array([45.0, 70.0, 95.0, 120.0, 145.0])
	e.ad_ratio = 0.4
	e.damage_type = GameConst.DamageType.PHYSICAL
	e.target_effects = [StatusEffectData.make(GameConst.Status.SLOW, 0.4, 2.5)]

	var r := AreaAbility.new()
	r.id = &"volley_barrage"
	r.display_name = "Volley Barrage"
	r.description = "Fires a wide volley of arrows, decimating the enemy team."
	r.color = Color(0.2, 1.0, 0.5)
	r.targeting = AbilityData.Targeting.POINT
	r.center = AreaAbility.Center.POINT
	r.cast_range = 8.0
	r.radius = 3.5
	r.delay = 0.4
	r.is_ultimate = true
	r.max_rank = 3
	r.cooldown = PackedFloat32Array([75.0, 65.0, 55.0])
	r.mana_cost = PackedFloat32Array([100.0, 100.0, 100.0])
	r.base_damage = PackedFloat32Array([180.0, 280.0, 380.0])
	r.ad_ratio = 0.75
	r.damage_type = GameConst.DamageType.PHYSICAL

	champ.abilities = [q, w, e, r]
	champ.bot_skill_priority = PackedInt32Array([0, 1, 2])
	champ.bot_item_build = PackedStringArray(["long_sword", "boots", "dagger", "storm_bow", "infinity_edge", "phantom_dancer"])
	champ.bot_preferred_range = 5.8
	ResourceSaver.save(champ, "res://data/champions/ranger.tres")

func _build_wraith() -> void:
	_build_edgy()

func _build_luminary() -> void:
	_build_stephen()
