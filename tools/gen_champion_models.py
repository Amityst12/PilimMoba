"""Generates the primitive-mesh champion model scenes (entities/champion/models/*.tscn).

The generated scenes are normal Godot scenes: open them in the editor to tweak, or replace
`model_scene` in data/champions/<id>.tres with your own imported 3D model.
Run from the project root:  python tools/gen_champion_models.py
"""
import math
import os

OUT_DIR = os.path.join("entities", "champion", "models")


def rot_matrix(rx, ry, rz):
    # Godot default Euler order YXZ: M = Ry * Rx * Rz
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    Rx = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    Ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    Rz = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

    return mul(mul(Ry, Rx), Rz)


def transform(pos, rot=(0, 0, 0), scale=(1, 1, 1)):
    m = rot_matrix(*[math.radians(a) for a in rot])
    for i in range(3):
        for j in range(3):
            m[i][j] *= scale[j]
    vals = [m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2], *pos]
    return "Transform3D(%s)" % ", ".join(("%.5g" % v) for v in vals)


def color(c):
    return "Color(%s)" % ", ".join("%.4g" % v for v in (list(c) + [1.0])[:4])


def build_scene(name, materials, parts):
    """materials: id -> dict(albedo, metallic, roughness, emission)
    parts: list of dict(name, mesh=(type, {props}), mat, pos, rot, scale, parent)"""
    lines = ["[gd_scene format=3]", "",
             '[ext_resource type="Script" path="res://entities/champion/ChampionModel.gd" id="1_model"]', ""]
    for mid, m in materials.items():
        lines.append('[sub_resource type="StandardMaterial3D" id="%s"]' % mid)
        lines.append("albedo_color = %s" % color(m["albedo"]))
        if m.get("metallic"):
            lines.append("metallic = %.3g" % m["metallic"])
        lines.append("roughness = %.3g" % m.get("roughness", 0.8))
        if m.get("emission"):
            lines.append("emission_enabled = true")
            lines.append("emission = %s" % color(m.get("emission_color", m["albedo"])))
            lines.append("emission_energy_multiplier = %.3g" % m["emission"])
        lines.append("")
    for i, part in enumerate(parts):
        mesh_type, props = part["mesh"]
        lines.append('[sub_resource type="%s" id="mesh_%d"]' % (mesh_type, i))
        lines.append('material = SubResource("%s")' % part["mat"])
        for key, value in props.items():
            if isinstance(value, tuple):
                lines.append("%s = Vector3(%s)" % (key, ", ".join("%.4g" % v for v in value)))
            elif isinstance(value, int) and not isinstance(value, bool):
                lines.append("%s = %d" % (key, value))
            else:
                lines.append("%s = %.4g" % (key, value))
        lines.append("")
    lines.append('[node name="%s" type="Node3D"]' % name)
    lines.append('script = ExtResource("1_model")')
    lines.append("")
    groups = sorted({p.get("parent", ".") for p in parts if p.get("parent", ".") != "."})
    for g in groups:
        lines.append('[node name="%s" type="Node3D" parent="."]' % g)
        lines.append("")
    for i, part in enumerate(parts):
        lines.append('[node name="%s" type="MeshInstance3D" parent="%s"]' % (part["name"], part.get("parent", ".")))
        lines.append("transform = %s" % transform(part.get("pos", (0, 0, 0)), part.get("rot", (0, 0, 0)), part.get("scale", (1, 1, 1))))
        lines.append('mesh = SubResource("mesh_%d")' % i)
        lines.append("")
    return "\n".join(lines)


SKIN = {"albedo": (0.88, 0.72, 0.6), "roughness": 0.7}


def arcanist():
    mats = {
        "robe": {"albedo": (0.3, 0.2, 0.55), "roughness": 0.85},
        "robe_dark": {"albedo": (0.18, 0.12, 0.34), "roughness": 0.9},
        "gold": {"albedo": (0.95, 0.75, 0.3), "metallic": 0.8, "roughness": 0.3},
        "skin": SKIN,
        "wood": {"albedo": (0.36, 0.24, 0.15), "roughness": 0.8},
        "arcane": {"albedo": (0.45, 0.9, 1.0), "roughness": 0.2, "emission": 5.0},
    }
    parts = [
        dict(name="Robe", mesh=("CylinderMesh", {"top_radius": 0.2, "bottom_radius": 0.52, "height": 1.3, "radial_segments": 16}), mat="robe", pos=(0, 0.65, 0)),
        dict(name="RobeTrim", mesh=("CylinderMesh", {"top_radius": 0.53, "bottom_radius": 0.55, "height": 0.08, "radial_segments": 16}), mat="gold", pos=(0, 0.05, 0)),
        dict(name="Belt", mesh=("CylinderMesh", {"top_radius": 0.34, "bottom_radius": 0.36, "height": 0.08, "radial_segments": 16}), mat="gold", pos=(0, 1.02, 0)),
        dict(name="Shoulders", mesh=("SphereMesh", {"radius": 0.34, "height": 0.6}), mat="robe_dark", pos=(0, 1.36, 0), scale=(1.15, 0.8, 0.9)),
        dict(name="Head", mesh=("SphereMesh", {"radius": 0.21, "height": 0.42}), mat="skin", pos=(0, 1.72, 0)),
        dict(name="HatBrim", mesh=("CylinderMesh", {"top_radius": 0.46, "bottom_radius": 0.46, "height": 0.05, "radial_segments": 20}), mat="robe_dark", pos=(0, 1.87, 0)),
        dict(name="Hat", mesh=("CylinderMesh", {"top_radius": 0.0, "bottom_radius": 0.3, "height": 0.8, "radial_segments": 16}), mat="robe", pos=(0.04, 2.25, 0.05), rot=(-12, 0, -8)),
        dict(name="HatBand", mesh=("CylinderMesh", {"top_radius": 0.29, "bottom_radius": 0.31, "height": 0.07, "radial_segments": 16}), mat="gold", pos=(0.01, 1.93, 0.01), rot=(-12, 0, -8)),
        dict(name="Staff", mesh=("BoxMesh", {"size": (0.07, 2.0, 0.07)}), mat="wood", pos=(0.48, 1.0, -0.12)),
        dict(name="StaffHead", mesh=("TorusMesh", {"inner_radius": 0.12, "outer_radius": 0.17}), mat="gold", pos=(0.48, 2.08, -0.12), rot=(90, 0, 0)),
        dict(name="StaffOrb", mesh=("SphereMesh", {"radius": 0.12, "height": 0.24}), mat="arcane", pos=(0.48, 2.08, -0.12)),
        dict(name="OrbA", mesh=("SphereMesh", {"radius": 0.08, "height": 0.16}), mat="arcane", pos=(0.55, 1.3, 0.0), parent="Orbit"),
        dict(name="OrbB", mesh=("SphereMesh", {"radius": 0.07, "height": 0.14}), mat="arcane", pos=(-0.55, 1.5, 0.0), parent="Orbit"),
    ]
    return build_scene("ArcanistModel", mats, parts)


def warden():
    mats = {
        "steel": {"albedo": (0.6, 0.63, 0.68), "metallic": 0.85, "roughness": 0.35},
        "steel_dark": {"albedo": (0.28, 0.3, 0.34), "metallic": 0.7, "roughness": 0.45},
        "gold": {"albedo": (0.95, 0.72, 0.28), "metallic": 0.8, "roughness": 0.3},
        "crimson": {"albedo": (0.7, 0.12, 0.12), "roughness": 0.7},
        "visor": {"albedo": (1.0, 0.55, 0.15), "roughness": 0.3, "emission": 4.0},
        "leather": {"albedo": (0.3, 0.2, 0.13), "roughness": 0.9},
    }
    parts = [
        dict(name="LegL", mesh=("BoxMesh", {"size": (0.24, 0.8, 0.28)}), mat="steel_dark", pos=(-0.19, 0.4, 0)),
        dict(name="LegR", mesh=("BoxMesh", {"size": (0.24, 0.8, 0.28)}), mat="steel_dark", pos=(0.19, 0.4, 0)),
        dict(name="Tabard", mesh=("BoxMesh", {"size": (0.46, 0.7, 0.05)}), mat="crimson", pos=(0, 0.62, -0.2)),
        dict(name="Torso", mesh=("BoxMesh", {"size": (0.82, 0.78, 0.52)}), mat="steel", pos=(0, 1.18, 0)),
        dict(name="ChestPlate", mesh=("BoxMesh", {"size": (0.62, 0.42, 0.06)}), mat="gold", pos=(0, 1.24, -0.27)),
        dict(name="Belt", mesh=("BoxMesh", {"size": (0.86, 0.1, 0.56)}), mat="leather", pos=(0, 0.84, 0)),
        dict(name="PauldronL", mesh=("SphereMesh", {"radius": 0.28, "height": 0.5}), mat="gold", pos=(-0.52, 1.52, 0)),
        dict(name="PauldronR", mesh=("SphereMesh", {"radius": 0.28, "height": 0.5}), mat="gold", pos=(0.52, 1.52, 0)),
        dict(name="Helmet", mesh=("SphereMesh", {"radius": 0.26, "height": 0.56}), mat="steel", pos=(0, 1.84, 0)),
        dict(name="Visor", mesh=("BoxMesh", {"size": (0.32, 0.05, 0.06)}), mat="visor", pos=(0, 1.86, -0.24)),
        dict(name="Crest", mesh=("BoxMesh", {"size": (0.07, 0.28, 0.56)}), mat="crimson", pos=(0, 2.1, 0.02)),
        dict(name="Shield", mesh=("BoxMesh", {"size": (0.12, 1.0, 0.78)}), mat="steel", pos=(-0.66, 1.1, -0.12)),
        dict(name="ShieldRim", mesh=("BoxMesh", {"size": (0.08, 1.08, 0.86)}), mat="gold", pos=(-0.62, 1.1, -0.12)),
        dict(name="ShieldGem", mesh=("SphereMesh", {"radius": 0.12, "height": 0.24}), mat="visor", pos=(-0.74, 1.15, -0.12)),
        dict(name="MaceHandle", mesh=("BoxMesh", {"size": (0.07, 1.0, 0.07)}), mat="leather", pos=(0.66, 1.0, -0.2)),
        dict(name="MaceHead", mesh=("BoxMesh", {"size": (0.32, 0.28, 0.28)}), mat="steel_dark", pos=(0.66, 1.55, -0.2)),
    ]
    return build_scene("WardenModel", mats, parts)


def ranger():
    mats = {
        "leaf": {"albedo": (0.22, 0.45, 0.25), "roughness": 0.85},
        "leaf_dark": {"albedo": (0.12, 0.28, 0.16), "roughness": 0.9},
        "leather": {"albedo": (0.42, 0.28, 0.17), "roughness": 0.85},
        "skin": SKIN,
        "gold": {"albedo": (0.95, 0.8, 0.4), "metallic": 0.7, "roughness": 0.35},
        "wood": {"albedo": (0.5, 0.33, 0.18), "roughness": 0.7},
        "glow": {"albedo": (1.0, 0.9, 0.5), "roughness": 0.2, "emission": 5.0},
    }
    parts = [
        dict(name="LegL", mesh=("BoxMesh", {"size": (0.18, 0.82, 0.22)}), mat="leather", pos=(-0.14, 0.41, 0)),
        dict(name="LegR", mesh=("BoxMesh", {"size": (0.18, 0.82, 0.22)}), mat="leather", pos=(0.14, 0.41, 0)),
        dict(name="Torso", mesh=("CapsuleMesh", {"radius": 0.26, "height": 0.86}), mat="leaf", pos=(0, 1.16, 0)),
        dict(name="Belt", mesh=("CylinderMesh", {"top_radius": 0.28, "bottom_radius": 0.28, "height": 0.08, "radial_segments": 14}), mat="gold", pos=(0, 0.92, 0)),
        dict(name="Cloak", mesh=("BoxMesh", {"size": (0.62, 1.05, 0.06)}), mat="leaf_dark", pos=(0, 1.08, 0.27), rot=(-8, 0, 0)),
        dict(name="Head", mesh=("SphereMesh", {"radius": 0.19, "height": 0.38}), mat="skin", pos=(0, 1.72, -0.02)),
        dict(name="Hood", mesh=("SphereMesh", {"radius": 0.23, "height": 0.46}), mat="leaf_dark", pos=(0, 1.76, 0.06), scale=(1.0, 1.0, 1.05)),
        dict(name="HoodTip", mesh=("CylinderMesh", {"top_radius": 0.0, "bottom_radius": 0.12, "height": 0.3, "radial_segments": 10}), mat="leaf_dark", pos=(0, 1.9, 0.26), rot=(-60, 0, 0)),
        dict(name="BowUpper", mesh=("BoxMesh", {"size": (0.05, 0.75, 0.06)}), mat="wood", pos=(-0.42, 1.52, -0.3), rot=(-18, 0, 0)),
        dict(name="BowLower", mesh=("BoxMesh", {"size": (0.05, 0.75, 0.06)}), mat="wood", pos=(-0.42, 0.86, -0.3), rot=(18, 0, 0)),
        dict(name="BowGrip", mesh=("BoxMesh", {"size": (0.08, 0.16, 0.09)}), mat="gold", pos=(-0.42, 1.19, -0.36)),
        dict(name="BowString", mesh=("BoxMesh", {"size": (0.015, 1.3, 0.015)}), mat="glow", pos=(-0.42, 1.19, -0.16)),
        dict(name="Quiver", mesh=("CylinderMesh", {"top_radius": 0.1, "bottom_radius": 0.09, "height": 0.62, "radial_segments": 10}), mat="leather", pos=(0.2, 1.36, 0.3), rot=(0, 0, -20)),
        dict(name="ArrowTips", mesh=("SphereMesh", {"radius": 0.07, "height": 0.14}), mat="glow", pos=(0.31, 1.7, 0.3)),
    ]
    return build_scene("RangerModel", mats, parts)


def wraith():
    mats = {
        "shadow": {"albedo": (0.06, 0.06, 0.08), "roughness": 0.9},
        "shadow_dark": {"albedo": (0.02, 0.02, 0.03), "roughness": 0.95},
        "crimson": {"albedo": (0.65, 0.08, 0.12), "roughness": 0.5},
        "steel_dark": {"albedo": (0.15, 0.17, 0.2), "metallic": 0.85, "roughness": 0.3},
        "red_glow": {"albedo": (1.0, 0.15, 0.25), "roughness": 0.2, "emission": 6.0},
    }
    parts = [
        dict(name="LegL", mesh=("BoxMesh", {"size": (0.16, 0.82, 0.18)}), mat="shadow_dark", pos=(-0.14, 0.41, 0)),
        dict(name="LegR", mesh=("BoxMesh", {"size": (0.16, 0.82, 0.18)}), mat="shadow_dark", pos=(0.14, 0.41, 0)),
        dict(name="Torso", mesh=("CapsuleMesh", {"radius": 0.24, "height": 0.82}), mat="shadow", pos=(0, 1.15, 0)),
        dict(name="Sash", mesh=("BoxMesh", {"size": (0.52, 0.1, 0.4)}), mat="crimson", pos=(0, 0.88, 0)),
        dict(name="Cloak", mesh=("BoxMesh", {"size": (0.58, 1.1, 0.05)}), mat="shadow_dark", pos=(0, 1.1, 0.22), rot=(-12, 0, 0)),
        dict(name="Hood", mesh=("SphereMesh", {"radius": 0.22, "height": 0.44}), mat="shadow_dark", pos=(0, 1.74, 0.04)),
        dict(name="EyeL", mesh=("BoxMesh", {"size": (0.07, 0.02, 0.04)}), mat="red_glow", pos=(-0.07, 1.76, -0.16), rot=(0, 0, 15)),
        dict(name="EyeR", mesh=("BoxMesh", {"size": (0.07, 0.02, 0.04)}), mat="red_glow", pos=(0.07, 1.76, -0.16), rot=(0, 0, -15)),
        dict(name="BladeL", mesh=("BoxMesh", {"size": (0.05, 0.65, 0.08)}), mat="steel_dark", pos=(-0.44, 1.1, -0.25), rot=(-35, 0, 0)),
        dict(name="GlowL", mesh=("BoxMesh", {"size": (0.02, 0.55, 0.03)}), mat="red_glow", pos=(-0.44, 1.1, -0.28), rot=(-35, 0, 0)),
        dict(name="BladeR", mesh=("BoxMesh", {"size": (0.05, 0.65, 0.08)}), mat="steel_dark", pos=(0.44, 1.1, -0.25), rot=(-35, 0, 0)),
        dict(name="GlowR", mesh=("BoxMesh", {"size": (0.02, 0.55, 0.03)}), mat="red_glow", pos=(0.44, 1.1, -0.28), rot=(-35, 0, 0)),
    ]
    return build_scene("WraithModel", mats, parts)


def luminary():
    mats = {
        "silk_white": {"albedo": (0.92, 0.94, 0.98), "roughness": 0.85},
        "gold": {"albedo": (0.95, 0.82, 0.35), "metallic": 0.85, "roughness": 0.25},
        "skin": SKIN,
        "solar_glow": {"albedo": (1.0, 0.85, 0.3), "roughness": 0.2, "emission": 5.5},
    }
    parts = [
        dict(name="Robe", mesh=("CylinderMesh", {"top_radius": 0.18, "bottom_radius": 0.48, "height": 1.25, "radial_segments": 16}), mat="silk_white", pos=(0, 0.62, 0)),
        dict(name="RobeTrim", mesh=("CylinderMesh", {"top_radius": 0.49, "bottom_radius": 0.51, "height": 0.08, "radial_segments": 16}), mat="gold", pos=(0, 0.05, 0)),
        dict(name="Torso", mesh=("CapsuleMesh", {"radius": 0.24, "height": 0.8}), mat="silk_white", pos=(0, 1.18, 0)),
        dict(name="Belt", mesh=("CylinderMesh", {"top_radius": 0.28, "bottom_radius": 0.3, "height": 0.08, "radial_segments": 16}), mat="gold", pos=(0, 0.95, 0)),
        dict(name="Head", mesh=("SphereMesh", {"radius": 0.19, "height": 0.38}), mat="skin", pos=(0, 1.7, 0)),
        dict(name="Halo", mesh=("TorusMesh", {"inner_radius": 0.35, "outer_radius": 0.42}), mat="solar_glow", pos=(0, 1.85, 0.18), rot=(90, 0, 0)),
        dict(name="Crown", mesh=("CylinderMesh", {"top_radius": 0.22, "bottom_radius": 0.2, "height": 0.08, "radial_segments": 12}), mat="gold", pos=(0, 1.86, 0)),
        dict(name="Staff", mesh=("BoxMesh", {"size": (0.06, 1.9, 0.06)}), mat="gold", pos=(0.42, 1.0, -0.15)),
        dict(name="StaffHead", mesh=("TorusMesh", {"inner_radius": 0.16, "outer_radius": 0.22}), mat="gold", pos=(0.42, 1.98, -0.15), rot=(90, 0, 0)),
        dict(name="StaffSun", mesh=("SphereMesh", {"radius": 0.14, "height": 0.28}), mat="solar_glow", pos=(0.42, 1.98, -0.15)),
    ]
    return build_scene("LuminaryModel", mats, parts)


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    models = (
        ("ArcanistModel.tscn", arcanist()),
        ("WardenModel.tscn", warden()),
        ("RangerModel.tscn", ranger()),
        ("WraithModel.tscn", wraith()),
        ("LuminaryModel.tscn", luminary()),
    )
    for file_name, text in models:
        with open(os.path.join(OUT_DIR, file_name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print("wrote", file_name)
