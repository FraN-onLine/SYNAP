extends Node

var damage_immune_triggers: int = 0
var active_character
var active_index

signal damage_mitigated

func try_mitigate_damage():
	if damage_immune_triggers > 0:
		damage_immune_triggers -= 1
		emit_signal("damage_mitigated")
		return true
	return false

func set_active_character(char: Character) -> void:
	active_character = char
