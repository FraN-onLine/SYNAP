extends Node

var can_switch = true
var is_in_immunity_state = false
var damage_immune_triggers: int = 0
var active_character
var active_index
var current_shield 
var party_cooldowns = [0,0,0]

signal damage_mitigated

func _process(delta: float) -> void:
	for i in range(party_cooldowns.size()):
		if party_cooldowns[i] > 0:
			party_cooldowns[i] = max(party_cooldowns[i] - delta, 0)
	

func try_mitigate_damage():
	if damage_immune_triggers > 0:
		damage_immune_triggers -= 1
		emit_signal("damage_mitigated")
		return true
	return false

func set_active_character(char: Character) -> void:
	active_character = char
	if current_shield:
		reparent_shield(char)
	
	
func reparent_shield(new_parent: Node2D) -> void:
	current_shield.get_parent().remove_child(current_shield)
	new_parent.add_child(current_shield)
	current_shield.position = Vector2.ZERO
