extends CanvasLayer

@onready var chmanager = $"../CharacterManager"

@onready var sprite = $Sprite2D/CenterContainer/Sprite2D
@onready var name_label = $NameLabel
@onready var hp_label = $HPLabel
@onready var healthbar = $Healthbar
@onready var slots = [
	$Characters.get_node("Player Slot1"),
	$Characters.get_node("Player Slot2"),
	$Characters.get_node("Player Slot3")
]

func _ready():
	if chmanager.has_signal("active_character_changed"):
		chmanager.connect("active_character_changed", _on_active_character_changed)

func _on_active_character_changed(character, index: int) -> void:
	if character:
		sprite.texture = character.character_profile
		name_label.text = character.unit_name
		hp_label.text = "HP: %d/%d" % [character.HP, character.MaxHP]
		healthbar.max_value = character.MaxHP
		healthbar.value = character.HP
	else:
		sprite.texture = null
		name_label.text = ""
		hp_label.text = ""
		healthbar.set_value(0)

	slots[index].modulate = Color("#ab9cffc6")
	

func _on_deployed_characters_updated(characters):
	for i in range(3):
		if i < len(characters) and characters[i]:
			slots[i].update_slot(characters[i])
		else:
			slots[i].clear_slot()
