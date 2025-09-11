extends Node2D

# --- EXPORTS ---
@export var spawn_order: Array[PackedScene] = []   # list of mobs in order
@export var spawn_points: Array[Marker2D] = []     # where they can spawn
@export var max_concurrent: int = 3                # how many mobs allowed on field at once
@export var spawn_interval: float = 1.5            # delay between spawns

# --- INTERNAL STATE ---
var spawn_index: int = 0      # which mob in the order we are spawning
var alive: int = 0
var finished: bool = false

signal all_cleared

# --- LOGIC ---
func _ready():
	_spawn_loop()

func _spawn_loop() -> void:
	while spawn_index < spawn_order.size():
		# Wait until less than max concurrent
		if alive < max_concurrent:
			_spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout

func _spawn_enemy() -> void:
	if spawn_index >= spawn_order.size(): return

	var mob_scene = spawn_order[spawn_index]
	if mob_scene == null: 
		spawn_index += 1
		return

	var mob = mob_scene.instantiate()
	var sp = spawn_points.pick_random()
	mob.global_position = sp.global_position
	add_child(mob)

	# connect death
	if not mob.is_connected("tree_exited", Callable(self, "_on_enemy_died")):
		mob.connect("tree_exited", Callable(self, "_on_enemy_died"))

	alive += 1
	spawn_index += 1

func _on_enemy_died() -> void:
	alive -= 1
	if alive <= 0 and spawn_index >= spawn_order.size() and not finished:
		finished = true
		emit_signal("all_cleared")
