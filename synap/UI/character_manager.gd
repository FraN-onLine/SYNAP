extends Node2D

class_name CharacterManager

@onready var player_UI = $"../UI"

@export var character_scenes: Array[PackedScene] = [] # drag your character scenes
@export_range(0, 2) var starting_index: int = 0 # who starts first

var active_character: Node = null
var active_index: int = -1
var slots: Array = []  # [{ scene, instance, data }]

@onready var spawn: Marker2D = $SpawnPoint

signal active_character_changed(character: Node, index: int)

# ---------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------

func _ready() -> void:
	_init_all_slots()
	_activate(starting_index, spawn.global_position)

func _physics_process(_delta: float) -> void:
	if active_character and active_character.is_inside_tree():
		$Camera2D.global_position = active_character.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_1"):
		switch_to(0)
	elif event.is_action_pressed("character_2"):
		switch_to(1)
	elif event.is_action_pressed("character_3"):
		switch_to(2)

# ---------------------------------------------------
# SETUP
# ---------------------------------------------------

func _init_all_slots() -> void:
	slots.clear()
	for charac in character_scenes:
		if charac == null:
			continue

		var inst = charac.instantiate()
		add_child(inst)
		_set_node_active(inst, false)
		inst.visible = false
		inst.global_position = spawn.global_position
		inst.remove_from_group("player")

		var data = inst.character_data  # <-- resource reference

		# Watch for death
		data.connect("died", Callable(self, "_on_character_died").bind(inst))

		slots.append({
			"scene": charac,
			"instance": inst,
			"data": data,
		})

	player_UI.set_deployed_characters()

# ---------------------------------------------------
# SWITCHING
# ---------------------------------------------------

func switch_to(index: int) -> void:
	if index == active_index: return
	if index < 0 or index >= slots.size(): return

	var slot = slots[index]
	if slot == null: return
	if slot["data"].is_dead: return

	var previous_position = spawn.global_position
	if active_character and active_character.is_inside_tree():
		previous_position = active_character.global_position

	_park_current()
	_activate(index, previous_position)

func _park_current() -> void:
	if active_character == null or active_index < 0 or active_index >= slots.size():
		return

	active_character.remove_from_group("player")
	active_character.visible = false
	_set_node_active(active_character, false)

	if active_character is CharacterBody2D:
		active_character.velocity = Vector2.ZERO

	if active_character.get_parent():
		active_character.get_parent().remove_child(active_character)

func _activate(index: int, world_position: Vector2) -> void:
	if index < 0 or index >= slots.size(): return
	var slot = slots[index]
	if slot == null: return
	if slot["data"].is_dead: return

	var inst = slot["instance"]
	var data = slot["data"]

	# Reinstantiate if freed but still alive
	if inst == null and not data.is_dead:
		inst = slot["scene"].instantiate()
		slot["instance"] = inst

	if not inst.is_inside_tree():
		add_child(inst)

	inst.MaxHP = data.MaxHP
	inst.HP = data.HP
	inst.global_position = world_position
	if inst is CharacterBody2D:
		inst.velocity = Vector2.ZERO

	_set_node_active(inst, true)
	inst.visible = true
	inst.add_to_group("player")

	active_character = inst
	active_index = index
	emit_signal("active_character_changed", inst, index)

# ---------------------------------------------------
# DEATH HANDLING
# ---------------------------------------------------

func _on_character_died(inst: Node) -> void:
	# Find and remove slot
	for i in range(slots.size()):
		if slots[i] and slots[i]["instance"] == inst:
			slots.remove_at(i)
			break

	# Shift active index if needed
	if active_index >= slots.size():
		active_index = slots.size() - 1

	# If no characters left → game over
	if slots.is_empty():
		print("All characters dead! Game Over.")
		active_character = null
		return

	# If current active is dead, auto-switch to first alive
	if not active_character or active_character == inst:
		switch_to(0)

	# Update UI
	player_UI.set_deployed_characters()

# ---------------------------------------------------
# HELPERS
# ---------------------------------------------------

func _set_node_active(n: Node, active: bool) -> void:
	n.set_process(active)
	if "set_physics_process" in n:
		n.set_physics_process(active)
