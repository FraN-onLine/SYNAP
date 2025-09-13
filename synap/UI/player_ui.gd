extends CanvasLayer

@onready var chmanager = $"../CharacterManager"
@onready var spawner = $"../MobSpawner"
@onready var defeated_label = $"Defeated Label"
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
	set_deployed_characters()
	if spawner.has_signal("progress_changed"):
		spawner.connect("progress_changed", _on_progress_changed)

func _process(_delta: float) -> void:
	for i in range(3):
		var slot = slots[i]
		var charac_info = chmanager.slots[i] if i < chmanager.slots.size() else null
		if charac_info and charac_info["instance"]:
			var charac = charac_info["instance"]
			slot.get_node("Healthbar").value = charac.HP
			slot.visible = true
		else:
			slot.visible = false

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

	for i in range(3):
		if i == index:
			slots[index].modulate = Color("#ab9cffc6")
		else:
			slots[i].modulate = Color("#ffffffc6")
	

func set_deployed_characters() -> void:
	for i in range(3):
		var slot = slots[i]
		var charac_info = chmanager.slots[i] if i < chmanager.slots.size() else null
		if charac_info and charac_info["instance"]:
			var charac = charac_info["instance"]
			slot.get_node("Icon").texture = charac.character_profile
			slot.get_node("Name").text = charac.unit_name
			slot.get_node("Healthbar").max_value = charac.MaxHP
			slot.get_node("Healthbar").value = charac.HP
			slot.visible = true
		else:
			slot.visible = false

func _on_progress_changed(current: int, total: int) -> void:
	defeated_label.text = "Enemies Defeated: %d / %d" % [current, total]

func _initialize_character(character_profile, unit_name, HP, MaxHP ) -> void:
	print("accessed")
	sprite.texture = character_profile
	name_label.text = unit_name
	hp_label.text = "HP: %d/%d" % [HP,MaxHP]
	healthbar.max_value = MaxHP
	healthbar.value = HP
