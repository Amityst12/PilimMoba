class_name PassiveData
extends Resource
## Base class for a champion passive. Hooks are called on the server.
## Runtime state must be stored on the champion (passive_stacks / passive_timer), never here,
## because a PassiveData resource is shared by every champion of that type.

@export var id: StringName = &""
@export var display_name: String = "Passive"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var color: Color = Color(0.9, 0.8, 0.4)
## Shown as a stack counter on the HUD when > 0.
@export var max_stacks: int = 0


func get_max_stacks() -> int:
	return max_stacks


## Called when a basic attack lands. Returns bonus physical damage for this attack.
func on_basic_attack(_caster: Champion, _target: Entity) -> float:
	return 0.0


## Called when the champion casts an ability (slot 0..3).
func on_ability_cast(_caster: Champion, _slot: int) -> void:
	pass


## Called every server tick while alive.
func on_tick(_caster: Champion, _delta: float) -> void:
	pass


func build_tooltip(_caster: Champion) -> String:
	return "[b][color=#%s]%s[/color][/b]  [color=#9aa4b2](passive)[/color]\n%s" % [
		color.lightened(0.3).to_html(false), display_name, description]
