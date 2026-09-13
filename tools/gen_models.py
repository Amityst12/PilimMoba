#!/usr/bin/env python3
"""Generates 3D procedural model scenes for the 7 champions:
Erez, Stephen, Amit, Nissim, Rogo, Yakir, Edgy.
"""

import os

MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "entities", "champion", "models")
os.makedirs(MODELS_DIR, exist_ok=True)

def write_tscn(name: str, content: str) -> None:
    path = os.path.join(MODELS_DIR, f"{name}.tscn")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip())
    print(f"Wrote {path}")

# 1. ErezModel (Commander / Royal Knight)
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

[node name="ErezModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)
mesh = SubResource("mesh_body")

[node name="Chest" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.05, 0)
mesh = SubResource("mesh_chest")

[node name="Trim" type="MeshInstance3D" parent="Chest"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
mesh = SubResource("mesh_trim")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.55, 0)
mesh = SubResource("mesh_head")

[node name="Sword" type="MeshInstance3D" parent="."]
transform = Transform3D(0.95, -0.31, 0, 0.31, 0.95, 0, 0, 0, 1, 0.5, 0.9, 0.1)
mesh = SubResource("mesh_sword")
"""

# 2. StephenModel (Psionic Mystic / Mage)
stephen_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="robe"]
albedo_color = Color(0.22, 0.1, 0.38, 1)
roughness = 0.85

[sub_resource type="StandardMaterial3D" id="indigo"]
albedo_color = Color(0.12, 0.05, 0.24, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="psionic"]
albedo_color = Color(0.65, 0.3, 1, 1)
roughness = 0.15
emission_enabled = true
emission = Color(0.7, 0.25, 1, 1)
emission_energy_multiplier = 4.5

[sub_resource type="CylinderMesh" id="mesh_robe"]
material = SubResource("robe")
top_radius = 0.18
bottom_radius = 0.5
height = 1.3
radial_segments = 16

[sub_resource type="SphereMesh" id="mesh_cowl"]
material = SubResource("indigo")
radius = 0.26
height = 0.5

[sub_resource type="SphereMesh" id="mesh_orb"]
material = SubResource("psionic")
radius = 0.15
height = 0.3

[node name="StephenModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Robe" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.65, 0)
mesh = SubResource("mesh_robe")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.45, 0)
mesh = SubResource("mesh_cowl")

[node name="Orbit" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.1, 0)

[node name="Orb1" type="MeshInstance3D" parent="Orbit"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.55, 0, 0)
mesh = SubResource("mesh_orb")

[node name="Orb2" type="MeshInstance3D" parent="Orbit"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.55, 0, 0)
mesh = SubResource("mesh_orb")
"""

# 3. AmitModel (Grand Architect / Tech Marksman)
amit_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="tunic"]
albedo_color = Color(0.12, 0.16, 0.22, 1)
roughness = 0.8

[sub_resource type="StandardMaterial3D" id="gold"]
albedo_color = Color(0.95, 0.72, 0.2, 1)
metallic = 0.75
roughness = 0.3

[sub_resource type="StandardMaterial3D" id="bow_mat"]
albedo_color = Color(0.2, 0.75, 1, 1)
metallic = 0.8
roughness = 0.2
emission_enabled = true
emission = Color(0.1, 0.6, 0.9, 1)
emission_energy_multiplier = 2.5

[sub_resource type="CapsuleMesh" id="mesh_body"]
material = SubResource("tunic")
radius = 0.24
height = 1.2

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("gold")
radius = 0.18
height = 0.36

[sub_resource type="TorusMesh" id="mesh_bow"]
material = SubResource("bow_mat")
inner_radius = 0.45
outer_radius = 0.52

[node name="AmitModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.75, 0)
mesh = SubResource("mesh_body")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
mesh = SubResource("mesh_head")

[node name="Bow" type="MeshInstance3D" parent="."]
transform = Transform3D(0.2, 0, 0.98, 0, 1, 0, -0.98, 0, 0.2, 0.4, 0.9, 0.2)
mesh = SubResource("mesh_bow")
"""

# 4. NissimModel (Miracle Worker / Support)
nissim_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="robe"]
albedo_color = Color(0.08, 0.35, 0.3, 1)
roughness = 0.85

[sub_resource type="StandardMaterial3D" id="gold"]
albedo_color = Color(0.95, 0.82, 0.3, 1)
metallic = 0.8
roughness = 0.25

[sub_resource type="StandardMaterial3D" id="radiance"]
albedo_color = Color(0.3, 1, 0.75, 1)
roughness = 0.2
emission_enabled = true
emission = Color(0.25, 0.95, 0.7, 1)
emission_energy_multiplier = 4.5

[sub_resource type="CylinderMesh" id="mesh_robe"]
material = SubResource("robe")
top_radius = 0.18
bottom_radius = 0.48
height = 1.25
radial_segments = 16

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("gold")
radius = 0.18
height = 0.36

[sub_resource type="TorusMesh" id="mesh_halo"]
material = SubResource("radiance")
inner_radius = 0.26
outer_radius = 0.32

[node name="NissimModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Robe" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.65, 0)
mesh = SubResource("mesh_robe")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.45, 0)
mesh = SubResource("mesh_head")

[node name="Halo" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.86, 0.5, 0, -0.5, 0.86, 0, 1.75, -0.1)
mesh = SubResource("mesh_halo")
"""

# 5. RogoModel (Berserker / Juggernaut)
rogo_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="iron"]
albedo_color = Color(0.3, 0.1, 0.1, 1)
roughness = 0.7

[sub_resource type="StandardMaterial3D" id="blood"]
albedo_color = Color(0.85, 0.15, 0.15, 1)
roughness = 0.6

[sub_resource type="StandardMaterial3D" id="axe_edge"]
albedo_color = Color(1, 0.4, 0.1, 1)
metallic = 0.8
roughness = 0.2
emission_enabled = true
emission = Color(1, 0.3, 0, 1)
emission_energy_multiplier = 3.0

[sub_resource type="BoxMesh" id="mesh_chest"]
material = SubResource("iron")
size = Vector3(0.8, 0.75, 0.5)

[sub_resource type="CylinderMesh" id="mesh_legs"]
material = SubResource("iron")
top_radius = 0.3
bottom_radius = 0.45
height = 0.7
radial_segments = 12

[sub_resource type="BoxMesh" id="mesh_pauldron"]
material = SubResource("blood")
size = Vector3(0.35, 0.35, 0.45)

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("blood")
radius = 0.22
height = 0.44

[sub_resource type="BoxMesh" id="mesh_axe"]
material = SubResource("axe_edge")
size = Vector3(0.1, 0.9, 0.4)

[node name="RogoModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Legs" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.35, 0)
mesh = SubResource("mesh_legs")

[node name="Chest" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.95, 0)
mesh = SubResource("mesh_chest")

[node name="PauldronL" type="MeshInstance3D" parent="Chest"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.45, 0.25, 0)
mesh = SubResource("mesh_pauldron")

[node name="PauldronR" type="MeshInstance3D" parent="Chest"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.45, 0.25, 0)
mesh = SubResource("mesh_pauldron")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
mesh = SubResource("mesh_head")

[node name="Axe" type="MeshInstance3D" parent="."]
transform = Transform3D(0.9, 0.4, 0, -0.4, 0.9, 0, 0, 0, 1, 0.65, 0.9, 0.1)
mesh = SubResource("mesh_axe")
"""

# 6. YakirModel (Bulwark / Colossus Tank)
yakir_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="slate"]
albedo_color = Color(0.35, 0.4, 0.48, 1)
metallic = 0.8
roughness = 0.4

[sub_resource type="StandardMaterial3D" id="cyan_glow"]
albedo_color = Color(0.2, 0.75, 1, 1)
roughness = 0.2
emission_enabled = true
emission = Color(0.15, 0.7, 1, 1)
emission_energy_multiplier = 4.0

[sub_resource type="BoxMesh" id="mesh_body"]
material = SubResource("slate")
size = Vector3(0.85, 1.0, 0.6)

[sub_resource type="BoxMesh" id="mesh_head"]
material = SubResource("slate")
size = Vector3(0.35, 0.35, 0.4)

[sub_resource type="BoxMesh" id="mesh_visor"]
material = SubResource("cyan_glow")
size = Vector3(0.36, 0.08, 0.1)

[sub_resource type="BoxMesh" id="mesh_shield"]
material = SubResource("slate")
size = Vector3(0.15, 1.2, 0.8)

[sub_resource type="BoxMesh" id="mesh_shield_core"]
material = SubResource("cyan_glow")
size = Vector3(0.18, 0.3, 0.3)

[node name="YakirModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.65, 0)
mesh = SubResource("mesh_body")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.35, 0.05)
mesh = SubResource("mesh_head")

[node name="Visor" type="MeshInstance3D" parent="Head"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0.18)
mesh = SubResource("mesh_visor")

[node name="Shield" type="MeshInstance3D" parent="."]
transform = Transform3D(0.96, 0, 0.26, 0, 1, 0, -0.26, 0, 0.96, 0.45, 0.75, 0.3)
mesh = SubResource("mesh_shield")

[node name="Core" type="MeshInstance3D" parent="Shield"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.05, 0, 0)
mesh = SubResource("mesh_shield_core")
"""

# 7. EdgyModel (Shadowblade / Assassin)
edgy_tscn = """[gd_scene format=3]

[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]

[sub_resource type="StandardMaterial3D" id="cowl"]
albedo_color = Color(0.08, 0.04, 0.09, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="neon_red"]
albedo_color = Color(1, 0.05, 0.25, 1)
roughness = 0.15
emission_enabled = true
emission = Color(1, 0, 0.3, 1)
emission_energy_multiplier = 5.0

[sub_resource type="CylinderMesh" id="mesh_cloak"]
material = SubResource("cowl")
top_radius = 0.16
bottom_radius = 0.42
height = 1.2
radial_segments = 14

[sub_resource type="SphereMesh" id="mesh_head"]
material = SubResource("cowl")
radius = 0.2
height = 0.4

[sub_resource type="BoxMesh" id="mesh_dagger"]
material = SubResource("neon_red")
size = Vector3(0.05, 0.65, 0.12)

[node name="EdgyModel" type="Node3D"]
script = ExtResource("1_model")

[node name="Cloak" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)
mesh = SubResource("mesh_cloak")

[node name="Head" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)
mesh = SubResource("mesh_head")

[node name="DaggerL" type="MeshInstance3D" parent="."]
transform = Transform3D(0.85, 0.52, 0, -0.52, 0.85, 0, 0, 0, 1, -0.4, 0.6, 0.15)
mesh = SubResource("mesh_dagger")

[node name="DaggerR" type="MeshInstance3D" parent="."]
transform = Transform3D(0.85, -0.52, 0, 0.52, 0.85, 0, 0, 0, 1, 0.4, 0.6, 0.15)
mesh = SubResource("mesh_dagger")
"""

def gen_all():
    write_tscn("ErezModel", erez_tscn)
    write_tscn("StephenModel", stephen_tscn)
    write_tscn("AmitModel", amit_tscn)
    write_tscn("NissimModel", nissim_tscn)
    write_tscn("RogoModel", rogo_tscn)
    write_tscn("YakirModel", yakir_tscn)
    write_tscn("EdgyModel", edgy_tscn)

if __name__ == "__main__":
    gen_all()
