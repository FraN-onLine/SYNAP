extends CanvasLayer

@onready var game_state = Global

@onready var sprite = $Sprite2D
@onready var name_label = $NameLabel
@onready var hp_label = $HPLabel
@onready var healthbar = $Healthbar
@onready var slots = [
	$Characters.get_node("Player Slot1"),
	$Characters.get_node("Player Slot2"),
	$Characters.get_node("Player Slot3")
]

func _ready():
	if game_state.has_signal("active_character_changed"):
		game_state.connect("active_character_changed", _on_active_character_changed)
	if game_state.has_signal("deployed_characters_updated"):
		game_state.connect("deployed_characters_updated", _on_deployed_characters_updated)
	# Initial UI update
	_on_active_character_changed(game_state.active_character)
	_on_deployed_characters_updated(game_state.deployed_characters)

func _on_active_character_changed(character):
	if character:
		sprite.texture = character.character_profile
		name_label.text = character.unit_name
		hp_label.text = "HP: %d/%d" % [character.HP, character.MAXHP]
		healthbar.set_value(character.HP, character.MAXHP)
	else:
		sprite.texture = null
		name_label.text = ""
		hp_label.text = ""
		healthbar.set_value(0)

func _on_deployed_characters_updated(characters):
	for i in range(3):
		if i < len(characters) and characters[i]:
			slots[i].update_slot(characters[i])
		else:
			slots[i].clear_slot()
