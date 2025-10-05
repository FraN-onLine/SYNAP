extends Node2D
class_name CharacterManager

@onready var player_UI = $"../UI"
@onready var spawn: Marker2D = $SpawnPoint

var active_character: Node = null
var active_index: int = -1
var slots: Array = []  # [{ scene, instance, data }]

signal active_character_changed(character: Node, index: int)

func _ready() -> void:
	# Connect to Partystate updates
	Partystate.connect("party_updated", Callable(self, "_on_party_updated"))

	# Initialize from current party (in case it's already set before this loads)
	_on_party_updated(Partystate.party)

	# Activate starting character if any
	if slots.size() > 0:
		await get_tree().process_frame
		_activate(0, spawn.global_position)

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
# PARTY HANDLING (now driven by Partystate)
# ---------------------------------------------------

func _on_party_updated(new_party: Array) -> void:
	slots.clear()

	for charac in new_party:
		if charac == null:
			continue

		var inst = charac.instantiate()
		var data = inst.character_data

		if data and data.is_dead:
			continue

		add_child(inst)
		_set_node_active(inst, false)
		inst.visible = false
		inst.global_position = spawn.global_position
		inst.remove_from_group("player")

		if data:
			if not data.is_connected("died", Callable(self, "_on_character_died")):
				data.connect("died", Callable(self, "_on_character_died").bind(inst))

		slots.append({
			"scene": charac,
			"instance": inst,
			"data": data,
		})

	player_UI.set_deployed_characters()

	# Re-select active character if needed
	if active_index < 0 and slots.size() > 0:
		switch_to(0)


# ---------------------------------------------------
# SWITCHING
# ---------------------------------------------------

func switch_to(index: int) -> void:
	if Partystate.can_switch == false: return
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

	# Reinstantiate if freed but not dead
	if inst == null and not data.is_dead:
		inst = slot["scene"].instantiate()
		slot["instance"] = inst

	# 🟡 Add to tree BEFORE calling initialize_data (fixes index 0 init bug)
	if not inst.is_inside_tree():
		add_child(inst)

	inst.initialize_data()

	inst.MaxHP = data.MaxHP
	inst.HP = data.HP
	inst.global_position = world_position
	if inst is CharacterBody2D:
		inst.velocity = Vector2.ZERO

	_set_node_active(inst, true)
	inst.visible = true
	inst.add_to_group("player")

	active_character = inst
	Partystate.set_active_character(active_character)
	active_index = index
	emit_signal("active_character_changed", inst, index)

# ---------------------------------------------------
# DEATH HANDLING
# ---------------------------------------------------

func _on_character_died(inst: Node) -> void:
	# 🛑 Disable collision & groups so enemies ignore the dead character
	if inst is CollisionObject2D:
		inst.set_collision_layer(0)
		inst.set_collision_mask(0)

	for child in inst.get_children():
		if child is CollisionObject2D:
			child.set_collision_layer(0)
			child.set_collision_mask(0)

	inst.remove_from_group("player")
	inst.visible = false
	_set_node_active(inst, false)

	# 🧠 Remove the dead character from slots
	for i in range(slots.size()):
		if slots[i] and slots[i]["instance"] == inst:
			slots.remove_at(i)
			print("removed")
			break

	# ☠️ If all are dead, handle game over
	if slots.is_empty():
		print("All characters dead! Game Over.")
		active_character = null
		active_index = -1
		player_UI.set_deployed_characters()
		return

	# 🔄 Auto-switch to the new first slot after a short delay
	active_index = -1
	await get_tree().create_timer(0.05).timeout
	switch_to(0)

	# 🖼️ Update UI to reflect current roster
	player_UI.set_deployed_characters()

# ---------------------------------------------------
# HELPERS
# ---------------------------------------------------

func _set_node_active(n: Node, active: bool) -> void:
	n.set_process(active)
	if "set_physics_process" in n:
		n.set_physics_process(active)
