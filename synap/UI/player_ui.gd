extends CanvasLayer

@onready var chmanager = $"../CharacterManager"
@onready var spawner = $"../MobSpawner"
@onready var defeated_label = $"Defeated Label"
@onready var level_label = $LevelLabel

@onready var sprite = $Sprite2D/CenterContainer/Sprite2D
@onready var name_label = $NameLabel
@onready var hp_label = $HPLabel
@onready var healthbar = $Healthbar

@onready var slots = [
	$Characters.get_node("Player Slot1"),
	$Characters.get_node("Player Slot2"),
	$Characters.get_node("Player Slot3")
]

func _ready() -> void:
	level_label.text = "Room 1"
	if chmanager.has_signal("active_character_changed"):
		chmanager.connect("active_character_changed", _on_active_character_changed)
	set_deployed_characters()

	if spawner and spawner.has_signal("progress_changed"):
		spawner.connect("progress_changed", _on_progress_changed)

func _process(_delta: float) -> void:
	
	
	# Update each slot’s health directly from the resource
	for i in range(slots.size()):
		var slot = slots[i]
		var charac_info = chmanager.slots[i] if i < chmanager.slots.size() else null
		if charac_info and charac_info.has("data"):
			var data = charac_info["data"]
			slot.get_node("Healthbar").value = data.HP
			slot.visible = true
		else:
			slot.visible = false

# ---------------------------------------------------
# ACTIVE CHARACTER CHANGED
# ---------------------------------------------------
func _on_active_character_changed(character: Node, index: int) -> void:
	if character:
		var data = character.character_data
		_update_main_display(data)
	else:
		_clear_main_display()
		
	if character and character.has_signal("skill_used"):
		if character.is_connected("skill_used", Callable(self, "skill_cd")):
			character.disconnect("skill_used", Callable(self, "skill_cd"))
			character.connect("skill_used", skill_cd)
		else:
			character.connect("skill_used", skill_cd)

	# Highlight active slot
	for i in range(slots.size()):
		slots[i].modulate = Color("#ab9cffc6") if (i == index) else Color("#ffffffc6")

# ---------------------------------------------------
# SLOT INITIALIZATION
# ---------------------------------------------------
func set_deployed_characters() -> void:
	for i in range(slots.size()):
		var slot = slots[i]
		var charac_info = chmanager.slots[i] if i < chmanager.slots.size() else null
		if charac_info and charac_info.has("data"):
			var data = charac_info["data"]
			slot.get_node("Icon").texture = data.character_profile
			slot.get_node("Name").text = data.unit_name
			slot.get_node("Healthbar").max_value = data.MaxHP
			slot.get_node("Healthbar").value = data.HP
			slot.visible = true
		else:
			slot.visible = false

# ---------------------------------------------------
# PROGRESS COUNTER
# ---------------------------------------------------
func _on_progress_changed(current: int, total: int) -> void:
	defeated_label.text = "Enemies Defeated: %d / %d" % [current, total]

# ---------------------------------------------------
# HELPERS
# ---------------------------------------------------
func _update_main_display(data) -> void:
	sprite.texture = data.character_profile
	name_label.text = data.unit_name
	hp_label.text = "HP: %d/%d" % [data.HP, data.MaxHP]
	healthbar.max_value = data.MaxHP
	healthbar.value = data.HP

func _clear_main_display() -> void:
	sprite.texture = null
	name_label.text = ""
	hp_label.text = ""
	healthbar.value = 0

func _initialize_character(character_profile, unit_name, HP, MaxHP ) -> void:
		sprite.texture = character_profile
		name_label.text = unit_name 
		hp_label.text = "HP: %d/%d" % [HP,MaxHP] 
		healthbar.max_value = MaxHP 
		healthbar.value = HP

func skill_cd(skill_cooldown):
	print("skilly")
	$SkillIcon.start_cooldown(skill_cooldown)
