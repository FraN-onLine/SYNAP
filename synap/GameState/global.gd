extends Node

signal active_character_changed(character)
signal deployed_characters_updated(characters)

var active_character = null
var deployed_characters: Array = []

func set_active_character(character):
	active_character = character
	emit_signal("active_character_changed", character)

func set_deployed_characters(characters: Array):
	deployed_characters = characters
	emit_signal("deployed_characters_updated", characters)
