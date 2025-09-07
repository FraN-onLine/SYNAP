extends Node2D

class_name CharacterManager

@onready var player_UI = $"../UI"

@export var character_scenes: Array[PackedScene] = [] # drag your character scenes
var active_character: Node = null
@export_range(0, 2) var starting_index: int = 0 # who starts first

var slots: Array = [] # holds info for each character
var active_index: int = -1

@onready var spawn: Marker2D = $SpawnPoint

signal active_character_changed(character: Node, index: int)

func _ready() -> void:
	_init_all_slots() 
	_activate(starting_index, spawn.global_position)

func _physics_process(delta: float) -> void:
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
			slots.append(null)
			continue

		var inst = charac.instantiate()
		add_child(inst)
		_set_node_active(inst, false)
		inst.visible = false
		inst.global_position = spawn.global_position
		inst.remove_from_group("player")

		slots.append({
			"scene": charac,
			"instance": inst,
			"hp": inst.HP,
			"max_hp": inst.MaxHP,
			"alive": true,
		})

	player_UI.set_deployed_characters()

# ---------------------------------------------------
# SWITCHING
# ---------------------------------------------------

func switch_to(index: int) -> void:
	if index == active_index: return
	if index < 0 or index >= slots.size(): return
	if slots[index] == null: return
	if not slots[index]["alive"]: return

	var previous_position = spawn.global_position
	if active_character and active_character.is_inside_tree():
		previous_position = active_character.global_position

	_park_current_and_save()
	_activate(index, previous_position)

func _park_current_and_save() -> void:
	if active_character == null or active_index < 0 or active_index >= slots.size():
		return

	# Save HP to slot
	slots[active_index]["hp"] = active_character.HP

	# Remove from player group
	active_character.remove_from_group("player")

	# Hide character and disable processing
	active_character.visible = false
	_set_node_active(active_character, false)

	# If CharacterBody2D, stop movement
	if active_character is CharacterBody2D:
		active_character.velocity = Vector2.ZERO

	# Remove from tree
	if active_character.get_parent():
		active_character.get_parent().remove_child(active_character)

func _activate(index: int, world_position: Vector2) -> void:
	var slot = slots[index]
	var inst = slot["instance"]

	# If character died and freed, reinstantiate
	if inst == null and slot["alive"]:
		inst = slot["scene"].instantiate()
		slot["instance"] = inst

	# Add to tree if not already
	if not inst.is_inside_tree():
		add_child(inst)

	inst.MaxHP = slot["max_hp"]
	inst.HP = slot["hp"]
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
# HELPERS
# ---------------------------------------------------

func _set_node_active(n: Node, active: bool) -> void:
	n.set_process(active)
	if "set_physics_process" in n:
		n.set_physics_process(active)
