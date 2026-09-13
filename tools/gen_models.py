#!/usr/bin/env python3
"""Generates 3D procedural model scenes for the 7 champions:
Erez (Beastmaster Melee), Stephen (Petite Filipino Support), Amit (3-Stance Musician),
Nissim (Dad Strategist Mage), Rogo (Heavy Smasher Tank), Yakir (Snack & Energy Support),
Lior (Graceful Effeminate Tank), plus Edgy (fallback).
"""

import os

MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "entities", "champion", "models")
os.makedirs(MODELS_DIR, exist_ok=True)

def write_tscn(name: str, content: str) -> None:
    path = os.path.join(MODELS_DIR, f"{name}.tscn")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")
    print(f"Wrote {path}")

# =========================================================================
# 1. EREZ - The Beast Vanguard (Melee Fighter with Animal Companions)
# =========================================================================
erez_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="steel"]
albedo_color = Color(0.65, 0.68, 0.75, 1)
metallic = 0.8
roughness = 0.3

[sub_resource type="StandardMaterial3D" id="royal_blue"]
albedo_color = Color(0.12, 0.28, 0.7, 1)
roughness = 0.7

[sub_resource type="StandardMaterial3D" id="gold"]
albedo_color = Color(0.95, 0.75, 0.25, 1)
metallic = 0.85
roughness = 0.25

[sub_resource type="StandardMaterial3D" id="blade"]
albedo_color = Color(0.85, 0.9, 1, 1)
metallic = 0.9
roughness = 0.2
emission_enabled = true
emission = Color(0.3, 0.5, 0.9, 1)
emission_energy_multiplier = 2.0

[sub_resource type="StandardMaterial3D" id="fur"]
albedo_color = Color(0.6, 0.4, 0.25, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="pet_eye"]
albedo_color = Color(0.95, 0.85, 0.2, 1)
emission_enabled = true
emission = Color(0.95, 0.85, 0.2, 1)

[sub_resource type="CylinderMesh" id="mesh_body"]
material = SubResource("royal_blue")
top_radius = 0.22
bottom_radius = 0.45
height = 1.15
radial_segments = 16

[sub_resource type="BoxMesh" id="mesh_chest"]
material = SubResource("steel")
size = Vector3(0.6, 0.65, 0.4)

[sub_resource type="BoxMesh" id="mesh_trim"]
material = SubResource("gold")
size = Vector3(0.62, 0.1, 0.42)

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("steel")
radius = 0.2
height = 0.4

[sub_resource type="BoxMesh" id="mesh_sword"]
material = SubResource("blade")
size = Vector3(0.08, 1.3, 0.2)

[sub_resource type="SphereMesh" id="mesh_pet_body"]
material = SubResource("fur")
radius = 0.18
height = 0.32

[sub_resource type="SphereMesh" id="mesh_pet_head"]
material = SubResource("fur")
radius = 0.12
height = 0.22

[sub_resource type="BoxMesh" id="mesh_pet_ear"]
material = SubResource("fur")
size = Vector3(0.04, 0.1, 0.04)

[node name="ErezModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.58, 0)
mesh = SubResource("mesh_body")

[node name="ArmorChest" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
mesh = SubResource("mesh_chest")

[node name="Belt" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)
mesh = SubResource("mesh_trim")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.35, 0)
mesh = SubResource("mesh_head")

[node name="Broadsword" type="MeshInstance3D" parent="."]
transform = Transform3D(0.866, -0.5, 0, 0.5, 0.866, 0, 0, 0, 1, 0.55, 0.9, 0.1)
mesh = SubResource("mesh_sword")

[node name="PetCompanionLeft" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.65, 0.2, 0.2)

[node name="PetBody" type="MeshInstance3D" parent="PetCompanionLeft"]
mesh = SubResource("mesh_pet_body")

[node name="PetHead" type="MeshInstance3D" parent="PetCompanionLeft"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0.12)
mesh = SubResource("mesh_pet_head")

[node name="EarL" type="MeshInstance3D" parent="PetCompanionLeft/PetHead"]
transform = Transform3D(0.866, 0.5, 0, -0.5, 0.866, 0, 0, 0, 1, -0.07, 0.12, 0)
mesh = SubResource("mesh_pet_ear")

[node name="EarR" type="MeshInstance3D" parent="PetCompanionLeft/PetHead"]
transform = Transform3D(0.866, -0.5, 0, 0.5, 0.866, 0, 0, 0, 1, 0.07, 0.12, 0)
mesh = SubResource("mesh_pet_ear")

[node name="PetCompanionRight" type="Node3D" parent="."]
transform = Transform3D(0.8, 0, 0, 0, 0.8, 0, 0, 0, 0.8, 0.6, 0.18, -0.3)

[node name="PetBody" type="MeshInstance3D" parent="PetCompanionRight"]
mesh = SubResource("mesh_pet_body")

[node name="PetHead" type="MeshInstance3D" parent="PetCompanionRight"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0.12)
mesh = SubResource("mesh_pet_head")
"""

# =========================================================================
# 2. STEPHEN - The Radiant Spirit (Petite Filipino Support)
# =========================================================================
stephen_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="sun_gold"]
albedo_color = Color(0.95, 0.78, 0.15, 1)
metallic = 0.3
roughness = 0.4
emission_enabled = true
emission = Color(0.95, 0.78, 0.15, 1)
emission_energy_multiplier = 1.2

[sub_resource type="StandardMaterial3D" id="ocean_blue"]
albedo_color = Color(0.08, 0.35, 0.75, 1)
roughness = 0.6

[sub_resource type="StandardMaterial3D" id="barong_white"]
albedo_color = Color(0.92, 0.94, 0.96, 1)
roughness = 0.5

[sub_resource type="StandardMaterial3D" id="staff_wood"]
albedo_color = Color(0.45, 0.3, 0.18, 1)
roughness = 0.7

[sub_resource type="CylinderMesh" id="mesh_body"]
material = SubResource("barong_white")
top_radius = 0.18
bottom_radius = 0.32
height = 0.85
radial_segments = 16

[sub_resource type="BoxMesh" id="mesh_sash"]
material = SubResource("ocean_blue")
size = Vector3(0.38, 0.12, 0.28)

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("barong_white")
radius = 0.17
height = 0.34

[sub_resource type="CylinderMesh" id="mesh_staff"]
material = SubResource("staff_wood")
top_radius = 0.03
bottom_radius = 0.03
height = 1.2

[sub_resource type="SphereMesh" id="mesh_sun_crystal"]
material = SubResource("sun_gold")
radius = 0.15
height = 0.3

[node name="StephenModel" type="Node3D"]
transform = Transform3D(0.78, 0, 0, 0, 0.78, 0, 0, 0, 0.78, 0, 0, 0)
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.45, 0)
mesh = SubResource("mesh_body")

[node name="Sash" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
mesh = SubResource("mesh_sash")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.05, 0)
mesh = SubResource("mesh_head")

[node name="Staff" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.38, 0.6, 0.1)
mesh = SubResource("mesh_staff")

[node name="SunCrystal" type="MeshInstance3D" parent="Staff"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.68, 0)
mesh = SubResource("mesh_sun_crystal")
"""

# =========================================================================
# 3. AMIT - The Maestro of Stances (Rock / White Girl / Mizrahit Fighter)
# =========================================================================
amit_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="leather_black"]
albedo_color = Color(0.12, 0.12, 0.16, 1)
roughness = 0.4

[sub_resource type="StandardMaterial3D" id="electric_red"]
albedo_color = Color(0.9, 0.15, 0.25, 1)
metallic = 0.5
roughness = 0.3
emission_enabled = true
emission = Color(0.9, 0.15, 0.25, 1)
emission_energy_multiplier = 1.0

[sub_resource type="StandardMaterial3D" id="gold_fret"]
albedo_color = Color(0.95, 0.8, 0.2, 1)
metallic = 0.9

[sub_resource type="StandardMaterial3D" id="pop_pink"]
albedo_color = Color(0.95, 0.3, 0.6, 1)
roughness = 0.5

[sub_resource type="CylinderMesh" id="mesh_body"]
material = SubResource("leather_black")
top_radius = 0.2
bottom_radius = 0.4
height = 1.1
radial_segments = 16

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("leather_black")
radius = 0.19
height = 0.38

[sub_resource type="BoxMesh" id="mesh_jacket_trim"]
material = SubResource("pop_pink")
size = Vector3(0.5, 0.6, 0.36)

[sub_resource type="BoxMesh" id="mesh_guitar_body"]
material = SubResource("electric_red")
size = Vector3(0.42, 0.55, 0.1)

[sub_resource type="BoxMesh" id="mesh_guitar_neck"]
material = SubResource("gold_fret")
size = Vector3(0.08, 0.7, 0.05)

[node name="AmitModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)
mesh = SubResource("mesh_body")

[node name="Jacket" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.82, 0)
mesh = SubResource("mesh_jacket_trim")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.3, 0)
mesh = SubResource("mesh_head")

[node name="GuitarOnBack" type="Node3D" parent="."]
transform = Transform3D(0.94, -0.34, 0, 0.34, 0.94, 0, 0, 0, 1, -0.05, 0.8, -0.26)

[node name="GuitarBody" type="MeshInstance3D" parent="GuitarOnBack"]
mesh = SubResource("mesh_guitar_body")

[node name="GuitarNeck" type="MeshInstance3D" parent="GuitarOnBack"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)
mesh = SubResource("mesh_guitar_neck")
"""

# =========================================================================
# 4. NISSIM - "אבא של כולם" (The Grandfather Strategist)
# =========================================================================
nissim_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="sweater_green"]
albedo_color = Color(0.12, 0.42, 0.28, 1)
roughness = 0.85

[sub_resource type="StandardMaterial3D" id="slacks_khaki"]
albedo_color = Color(0.68, 0.62, 0.5, 1)
roughness = 0.8

[sub_resource type="StandardMaterial3D" id="glasses_gold"]
albedo_color = Color(0.95, 0.8, 0.2, 1)
metallic = 0.9
roughness = 0.2

[sub_resource type="StandardMaterial3D" id="coffee_mug"]
albedo_color = Color(0.95, 0.95, 0.95, 1)
roughness = 0.3

[sub_resource type="StandardMaterial3D" id="coffee_dark"]
albedo_color = Color(0.2, 0.12, 0.06, 1)
roughness = 0.3

[sub_resource type="CylinderMesh" id="mesh_legs"]
material = SubResource("slacks_khaki")
top_radius = 0.25
bottom_radius = 0.36
height = 0.7
radial_segments = 16

[sub_resource type="BoxMesh" id="mesh_sweater"]
material = SubResource("sweater_green")
size = Vector3(0.55, 0.65, 0.38)

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("slacks_khaki")
radius = 0.19
height = 0.38

[sub_resource type="BoxMesh" id="mesh_glasses"]
material = SubResource("glasses_gold")
size = Vector3(0.3, 0.05, 0.05)

[sub_resource type="CylinderMesh" id="mesh_mug"]
material = SubResource("coffee_mug")
top_radius = 0.08
bottom_radius = 0.08
height = 0.16
radial_segments = 12

[sub_resource type="CylinderMesh" id="mesh_coffee"]
material = SubResource("coffee_dark")
top_radius = 0.075
bottom_radius = 0.075
height = 0.02
radial_segments = 12

[node name="NissimModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Legs" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.35, 0)
mesh = SubResource("mesh_legs")

[node name="Sweater" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
mesh = SubResource("mesh_sweater")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.32, 0)
mesh = SubResource("mesh_head")

[node name="Glasses" type="MeshInstance3D" parent="Head"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0.18)
mesh = SubResource("mesh_glasses")

[node name="CoffeeMug" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.42, 0.85, 0.2)
mesh = SubResource("mesh_mug")

[node name="CoffeeLiquid" type="MeshInstance3D" parent="CoffeeMug"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.07, 0)
mesh = SubResource("mesh_coffee")
"""

# =========================================================================
# 5. ROGO - The Heavy Smasher (Colossal Heavyweight Tank)
# =========================================================================
rogo_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="iron_red"]
albedo_color = Color(0.65, 0.12, 0.12, 1)
roughness = 0.5
metallic = 0.4

[sub_resource type="StandardMaterial3D" id="dark_metal"]
albedo_color = Color(0.2, 0.2, 0.22, 1)
metallic = 0.8
roughness = 0.3

[sub_resource type="StandardMaterial3D" id="spikes"]
albedo_color = Color(0.85, 0.75, 0.25, 1)
metallic = 0.9

[sub_resource type="CylinderMesh" id="mesh_heavy_body"]
material = SubResource("iron_red")
top_radius = 0.42
bottom_radius = 0.65
height = 1.2
radial_segments = 16

[sub_resource type="BoxMesh" id="mesh_massive_chest"]
material = SubResource("dark_metal")
size = Vector3(0.95, 0.75, 0.6)

[sub_resource type="SphereMesh" id="mesh_pauldron"]
material = SubResource("iron_red")
radius = 0.3
height = 0.45

[sub_resource type="SphereMesh" id="mesh_heavy_head"]
material = SubResource("dark_metal")
radius = 0.24
height = 0.42

[sub_resource type="BoxMesh" id="mesh_fist_slammer"]
material = SubResource("dark_metal")
size = Vector3(0.3, 0.35, 0.3)

[node name="RogoModel" type="Node3D"]
script = ExtResource("1_model")

[node name="HeavyBody" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)
mesh = SubResource("mesh_heavy_body")

[node name="MassiveChest" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
mesh = SubResource("mesh_massive_chest")

[node name="PauldronL" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.62, 1.05, 0)
mesh = SubResource("mesh_pauldron")

[node name="PauldronR" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.62, 1.05, 0)
mesh = SubResource("mesh_pauldron")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
mesh = SubResource("mesh_heavy_head")

[node name="FistL" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.58, 0.5, 0.25)
mesh = SubResource("mesh_fist_slammer")

[node name="FistR" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.58, 0.5, 0.25)
mesh = SubResource("mesh_fist_slammer")
"""

# =========================================================================
# 6. YAKIR - The Refreshment Specialist (Energy Drinks & Food Support)
# =========================================================================
yakir_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="apron_green"]
albedo_color = Color(0.1, 0.5, 0.35, 1)
roughness = 0.6

[sub_resource type="StandardMaterial3D" id="energy_can_mat"]
albedo_color = Color(0.08, 0.08, 0.1, 1)
metallic = 0.8
roughness = 0.2
emission_enabled = true
emission = Color(0.15, 0.85, 0.35, 1)
emission_energy_multiplier = 2.0

[sub_resource type="StandardMaterial3D" id="cooler_box_mat"]
albedo_color = Color(0.15, 0.35, 0.7, 1)
roughness = 0.4

[sub_resource type="StandardMaterial3D" id="snack_gold"]
albedo_color = Color(0.95, 0.68, 0.2, 1)
roughness = 0.7

[sub_resource type="CylinderMesh" id="mesh_body"]
material = SubResource("apron_green")
top_radius = 0.24
bottom_radius = 0.42
height = 1.15
radial_segments = 16

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("apron_green")
radius = 0.2
height = 0.4

[sub_resource type="BoxMesh" id="mesh_cooler_box"]
material = SubResource("cooler_box_mat")
size = Vector3(0.55, 0.45, 0.3)

[sub_resource type="CylinderMesh" id="mesh_energy_can"]
material = SubResource("energy_can_mat")
top_radius = 0.07
bottom_radius = 0.07
height = 0.24
radial_segments = 12

[node name="YakirModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.58, 0)
mesh = SubResource("mesh_body")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.35, 0)
mesh = SubResource("mesh_head")

[node name="CoolerBackpack" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, -0.28)
mesh = SubResource("mesh_cooler_box")

[node name="EnergyCanInHand" type="MeshInstance3D" parent="."]
transform = Transform3D(0.9, 0, 0.436, 0, 1, 0, -0.436, 0, 0.9, 0.45, 0.75, 0.2)
mesh = SubResource("mesh_energy_can")
"""

# =========================================================================
# 7. LIOR - The Graceful Vanguard (Feminine / Effeminate Male Tank)
# =========================================================================
lior_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="rose_gold"]
albedo_color = Color(0.92, 0.65, 0.68, 1)
metallic = 0.8
roughness = 0.25

[sub_resource type="StandardMaterial3D" id="pastel_silk"]
albedo_color = Color(0.98, 0.9, 0.94, 1)
roughness = 0.4

[sub_resource type="StandardMaterial3D" id="crystal_mirror"]
albedo_color = Color(0.9, 0.96, 1, 1)
metallic = 0.95
roughness = 0.1
emission_enabled = true
emission = Color(0.95, 0.8, 0.9, 1)
emission_energy_multiplier = 1.5

[sub_resource type="CylinderMesh" id="mesh_slender_body"]
material = SubResource("pastel_silk")
top_radius = 0.2
bottom_radius = 0.38
height = 1.2
radial_segments = 16

[sub_resource type="BoxMesh" id="mesh_corset_trim"]
material = SubResource("rose_gold")
size = Vector3(0.48, 0.55, 0.34)

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("pastel_silk")
radius = 0.18
height = 0.36

[sub_resource type="BoxMesh" id="mesh_mirror_shield"]
material = SubResource("crystal_mirror")
size = Vector3(0.08, 1.2, 0.65)

[sub_resource type="BoxMesh" id="mesh_shield_border"]
material = SubResource("rose_gold")
size = Vector3(0.1, 1.25, 0.7)

[node name="LiorModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)
mesh = SubResource("mesh_slender_body")

[node name="CorsetPlate" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
mesh = SubResource("mesh_corset_trim")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.36, 0)
mesh = SubResource("mesh_head")

[node name="MirrorShieldBorder" type="MeshInstance3D" parent="."]
transform = Transform3D(0.966, 0, 0.259, 0, 1, 0, -0.259, 0, 0.966, 0.45, 0.75, 0.15)
mesh = SubResource("mesh_shield_border")

[node name="MirrorShieldFace" type="MeshInstance3D" parent="MirrorShieldBorder"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.02, 0, 0)
mesh = SubResource("mesh_mirror_shield")
"""

# =========================================================================
# 7. EDGY (formerly referenced as Lior) - The Graceful Vanguard (Feminine / Effeminate Male Tank)
# =========================================================================
edgy_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="rose_gold"]
albedo_color = Color(0.92, 0.65, 0.68, 1)
metallic = 0.8
roughness = 0.25

[sub_resource type="StandardMaterial3D" id="pastel_silk"]
albedo_color = Color(0.98, 0.9, 0.94, 1)
roughness = 0.4

[sub_resource type="StandardMaterial3D" id="crystal_mirror"]
albedo_color = Color(0.9, 0.96, 1, 1)
metallic = 0.95
roughness = 0.1
emission_enabled = true
emission = Color(0.95, 0.8, 0.9, 1)
emission_energy_multiplier = 1.5

[sub_resource type="CylinderMesh" id="mesh_slender_body"]
material = SubResource("pastel_silk")
top_radius = 0.2
bottom_radius = 0.38
height = 1.2
radial_segments = 16

[sub_resource type="BoxMesh" id="mesh_corset_trim"]
material = SubResource("rose_gold")
size = Vector3(0.48, 0.55, 0.34)

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("pastel_silk")
radius = 0.18
height = 0.36

[sub_resource type="BoxMesh" id="mesh_mirror_shield"]
material = SubResource("crystal_mirror")
size = Vector3(0.08, 1.2, 0.65)

[sub_resource type="BoxMesh" id="mesh_shield_border"]
material = SubResource("rose_gold")
size = Vector3(0.1, 1.25, 0.7)

[node name="EdgyModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)
mesh = SubResource("mesh_slender_body")

[node name="CorsetPlate" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
mesh = SubResource("mesh_corset_trim")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.36, 0)
mesh = SubResource("mesh_head")

[node name="MirrorShieldBorder" type="MeshInstance3D" parent="."]
transform = Transform3D(0.966, 0, 0.259, 0, 1, 0, -0.259, 0, 0.966, 0.45, 0.75, 0.15)
mesh = SubResource("mesh_shield_border")

[node name="MirrorShieldFace" type="MeshInstance3D" parent="MirrorShieldBorder"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.02, 0, 0)
mesh = SubResource("mesh_mirror_shield")
"""

def gen_all():
    write_tscn("ErezModel", erez_tscn)
    write_tscn("StephenModel", stephen_tscn)
    write_tscn("AmitModel", amit_tscn)
    write_tscn("NissimModel", nissim_tscn)
    write_tscn("RogoModel", rogo_tscn)
    write_tscn("YakirModel", yakir_tscn)
    write_tscn("LiorModel", lior_tscn)
    write_tscn("EdgyModel", edgy_tscn)
    print("All 3D procedural models generated successfully!")

if __name__ == "__main__":
    gen_all()
