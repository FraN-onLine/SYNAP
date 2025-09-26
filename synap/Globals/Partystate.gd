extends Node

var damage_immune_triggers: int = 0

signal damage_mitigated

func try_mitigate_damage() -> bool:
	if damage_immune_triggers > 0:
		damage_immune_triggers -= 1
		emit_signal("damage_mitigated")
		return true
	return false
