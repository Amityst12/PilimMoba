# ⚔️ Pilim MOBA

A lightweight, top-down multiplayer MOBA built in **Godot 4.7** using typed GDScript, authoritative server-client multiplayer networking, responsive 16:9 UI, neutral jungle camps, and 5 distinct champions.

![Pilim MOBA](https://raw.githubusercontent.com/Amityst12/PilimMoba/main/icon.svg)

---

## 🚀 How to Run & Play

### Option 1: Quick Launch
1. Ensure you have **[Godot Engine 4](https://godotengine.org/download)** (v4.3+ / v4.7).
2. Either place your `Godot_v4.x.exe` in the root project folder, or open Godot and click **Import** -> select `project.godot`.
3. Press **F5** or click the **Play** button in Godot / VS Code.
4. You can also run `Play_Game.bat` directly!

### Option 2: Playing Multiplayer With a Friend 🌐

Pilim MOBA supports seamless online and local multiplayer:

#### 1. On Local Network (Same Wi-Fi / LAN):
1. **Host**: Open the game -> Click **HOST GAME** (default port: `7777`).
2. The lobby will display your local IP address (e.g. `192.168.1.X`).
3. **Friend**: Open the game -> Enter the Host's IP address -> Click **JOIN**.
4. Both choose your champions and teams, add bots if desired, and click **START MATCH**!

#### 2. Over the Internet (Remote Friends):
- Use a virtual LAN tool like **[Radmin VPN](https://www.radmin-vpn.com/)** or **Hamachi** (recommended, zero-configuration):
  - Join the same virtual room.
  - Host starts the game.
  - Friend enters the Host's virtual IP (e.g., from Radmin) and clicks **JOIN**.
- Or forward port **`7777 UDP`** on the host's router and connect via public IP.

---

## 🎮 Controls & Hotkeys

| Action | Input | Description |
| :--- | :--- | :--- |
| **Move / Attack** | `Right Click` | Smart click-to-move pathfinding or basic attack target |
| **Attack-Move** | `A + Left Click` | Attack-move towards destination |
| **Stop Movement** | `S` | Immediately halt movement and combat |
| **Recall** | `B` | 8-second channel to return to base fountain |
| **Abilities (Q, W, E, R)** | `Q`, `W`, `E`, `R` | Hold to aim indicator, release to cast. `Right Click` while aiming cancels |
| **Rank Up Ability** | `Ctrl + Q/W/E/R` | Level up abilities when skill points are available (or click `+` on HUD) |
| **Item Shop** | `P` | Open/close base item shop |
| **Scoreboard** | `Tab` | View player stats, KDA, items, and CS |
| **Smart Pings** | `G` / `V` / `Alt + Click` | Alert, Danger, On My Way, and Assist pings with 3D beacons and minimap radar |
| **Camera Lock** | `Y` | Toggle camera lock to your champion |
| **Center Camera** | `Space` | Snap camera back to your champion |
| **Settings / Menu** | `Escape` | In-game pause & settings (audio, 16:9 resolutions, display modes) |

---

## 🛡️ The 5 Champions

1. **Arcanist (Mage)**
   - *Role*: Burst Magic Damage & Crowd Control
   - *Passive*: **Arcane Flow** (Every 3rd ability grants +40% speed boost).
   - *Q*: **Mystic Bolt** (Long-range skillshot projectile).
   - *W*: **Phase Dash** (Instant blink/teleport).
   - *E*: **Gravity Well** (Delayed vortex pulling and slowing enemies).
   - *R*: **Obliteration Beam** (Massive piercing laser beam).

2. **Warden (Tank)**
   - *Role*: Frontline Initiator & CC
   - *Passive*: **Ironclad** (Periodically gains armor boost and bonus regen).
   - *Q*: **Shield Charge** (Dash forward colliding with and knocking back enemies).
   - *W*: **Bulwark** (Durable shield absorbing incoming damage).
   - *E*: **Ground Slam** (AoE earthquake stunning nearby foes).
   - *R*: **Colossus Roar** (Massive team-wide damage reduction and taunt).

3. **Ranger (Marksman)**
   - *Role*: High-Sustained Physical Ranged DPS
   - *Passive*: **Swift Hunter** (Bonus attack speed on consecutive hits).
   - *Q*: **Piercing Arrow** (High-velocity sniper shot).
   - *W*: **Quick Tumble** (Combat roll reposition).
   - *E*: **Caltrop Trap** (Ground trap dealing damage and slowing).
   - *R*: **Volley Barrage** (Cone barrage of deadly arrows).

4. **Wraith (Assassin)**
   - *Role*: High-Mobility Burst & Flanking
   - *Passive*: **Shadow Stalker** (Burst of speed after ability cast).
   - *Q*: **Shadow Dash** (Slash through enemies dealing physical damage).
   - *W*: **Smoke Shroud** (Deploys smoke cloud granting brief untargetability).
   - *E*: **Crippling Dagger** (Throws poison blade heavily slowing target).
   - *R*: **Death Mark** (Leap behind an enemy with heavy burst & silence).

5. **Luminary (Support / Mage)**
   - *Role*: Radiant Healing, Buffs & Disruption
   - *Passive*: **Solar Grace** (Grants nearby allies movement haste).
   - *Q*: **Sunburst** (Piercing radiant light beam).
   - *W*: **Solar Aegis** (Heals and grants protective radiant shield).
   - *E*: **Starlight Snare** (Constellation trap rooting enemies in place).
   - *R*: **Dawn's Radiance** (Massive solar explosion dealing magic damage and silencing enemies).

---

## 🌲 Map & Arena Features

- **Neutral Jungle Camps**:
  - **Blue Buff Golem**: Slaying grants *Crest of Insight* (+MP5 & 20% Cooldown Reduction).
  - **Red Buff Bramble**: Slaying grants *Crest of Cinders* (Basic attacks apply true damage burn & slow).
  - **Rift Behemoth (Epic River Boss)**: 4,200 HP epic monster granting team-wide +15% AD, +20% AP, and 300 gold.
- **Tall Grass / Bushes**: Conceals champions from enemy vision. Stepping into the same brush or attacking reveals stealth.
- **Structures**: Defensive Turrets with attack prioritization and Nexus structures.
- **Minion Waves**: Continuous waves of melee and caster minions clashing in lanes.
- **Adaptive 16:9 Display**: Strict 16:9 aspect ratio preservation across all screen sizes with static resolution presets (720p, 768p, 900p, 1080p, 2K).

---

## 🌐 Networking Architecture

1. **Host as Authoritative Server (`peer_id == 1`)**:
   - The host maintains the simulation state (player positions, collision, health/mana, cooldown validation, spell entity spawning).
2. **Client Inputs via RPC**:
   - Right-click movement requests are sent via `@rpc("any_peer", "call_local", "reliable") func request_move(target_pos)`.
   - Ability cast requests are sent via `@rpc("any_peer", "call_local", "reliable") func request_cast_ability(slot, target_pos)`.
3. **Replication via Godot 4 Nodes**:
   - **`MultiplayerSpawner`**: Automatically synchronizes instantiation of player champions (`Player.tscn`) and spell projectiles/effects (`ProjectileQ.tscn`, `GroundAoEE.tscn`, `UltimateBeamR.tscn`).
   - **`MultiplayerSynchronizer`**: Continuously replicates `position`, `rotation`, `current_health`, and `current_mana`.

---

## ⚡ How to Add a New Ability

1. Create a script extending `Ability.gd` (e.g. `scripts/abilities/AbilityHeal.gd`):
   ```gdscript
   class_name AbilityHeal
   extends Ability

   func _init() -> void:
       id = "W"
       ability_name = "Restoration"
       cooldown = 8.0
       mana_cost = 45.0
       icon_color = Color(0.2, 0.9, 0.3)

   func execute(caster: CharacterBody3D, target_pos: Vector3) -> void:
       if caster.has_method("heal"):
           caster.heal(120.0)
   ```
2. In `AbilityHolder.gd` (or in the Inspector on `Player.tscn`), assign your custom ability resource to any slot (`ability_q`, `ability_w`, `ability_e`, `ability_r`).
3. The HUD and networking will automatically detect and bind the new ability name, cooldown, mana cost, and color!

---

## 🚀 How to Run & Test Multiplayer

### In the Godot 4 Editor:
1. Open Godot 4 and import/open the project in `PilimMoba`.
2. Under **Debug** in the top menu, click **Run Multiple Instances** -> Select **2 Instances**.
3. Press **F5** (Run Project).
4. On **Window 1**: Click **Host Game (Port 7777)**. A Blue champion will spawn at the Blue base (`-14, 0, 0`).
5. On **Window 2**: Keep `127.0.0.1` and click **Join Game**. A Red champion will spawn at the Red base (`14, 0, 0`).
6. Right-click to move around the arena. Press **Q**, **W**, **E**, and **R** to fire abilities at each other and test damage, slow, dash, and cooldown timers!
