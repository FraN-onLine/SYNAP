extends Control

func update_slot(character):
	if character:
		$Icon.texture = character.character_profile
		$Name.text = character.name
		$Healthbar.set_value(character.HP, character.MAXHP)
	else:
		clear_slot()

func clear_slot():
	$Icon.texture = null
	$Name.text = ""
	$Healthbar.set_value(0)
