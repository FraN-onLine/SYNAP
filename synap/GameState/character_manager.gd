extends Node2D
class_name CharacterManager

@export var character_scenes: Array[PackedScene] = []   # drag your character scenes
@export_range(0, 2) var starting_index: int = 0         # who starts first

var _slots: Array = []          # holds info for each character
var _active_index: int = -1
var _active: Node = null

@onready var _spawn: Marker2D = $SpawnPoint

signal active_character_changed(character: Node, index: int)

func _ready() -> void:
	assert(_spawn, "Need a Marker2D named SpawnPoint under CharacterManager!")
	_init_all_slots()
	_activate(starting_index, _spawn.global_position)

func _physics_process(delta: float) -> void:
	if _active and _active.is_inside_tree():
		$Camera2D.global_position = _active.global_position

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
	_slots.clear()
	for ps in character_scenes:
		if ps == null:
			_slots.append(null)
			continue

		var inst = ps.instantiate()
		add_child(inst)
		_set_node_active(inst, false)
		inst.visible = false
		inst.global_position = _spawn.global_position
		inst.remove_from_group("player")

		_slots.append({
			"scene": ps,
			"instance": inst,
			"hp": inst.HP,
			"max_hp": inst.MaxHP,
			"alive": true,
		})

# ---------------------------------------------------
# SWITCHING
# ---------------------------------------------------

func switch_to(index: int) -> void:
	if index == _active_index: return
	if index < 0 or index >= _slots.size(): return
	if _slots[index] == null: return
	if not _slots[index]["alive"]: return

	var target_pos = _spawn.global_position
	if _active and _active.is_inside_tree():
		target_pos = _active.global_position

	_park_current_and_save()
	_activate(index, target_pos)

func _park_current_and_save() -> void:
	if _active == null: return
	var idx = _active_index
	_slots[idx]["hp"] = _active.HP
	_set_node_active(_active, false)
	_active.visible = false
	_active.remove_from_group("player")
	_active = null
	_active_index = -1

func _activate(index: int, world_position: Vector2) -> void:
	var slot = _slots[index]
	var inst = slot["instance"]

	# If character died and freed, reinstantiate
	if inst == null and slot["alive"]:
		inst = slot["scene"].instantiate()
		add_child(inst)
		slot["instance"] = inst

	inst.MaxHP = slot["max_hp"]
	inst.HP = slot["hp"]
	inst.global_position = world_position
	if inst is CharacterBody2D:
		inst.velocity = Vector2.ZERO

	_set_node_active(inst, true)
	inst.visible = true
	inst.add_to_group("player")

	_active = inst
	_active_index = index
	emit_signal("active_character_changed", inst, index)

# ---------------------------------------------------
# HELPERS
# ---------------------------------------------------

func _set_node_active(n: Node, active: bool) -> void:
	n.set_process(active)
	if "set_physics_process" in n:
		n.set_physics_process(active)
