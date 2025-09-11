extends Node2D

@export var spawn_order: Array[PackedScene] = []
@export var spawn_points: Array[Marker2D] = []
@export var max_concurrent: int = 3
@export var spawn_interval: float = 1.5

var spawn_index: int = 0
var alive: int = 0
var defeated: int = 0
var finished: bool = false

signal all_cleared
signal progress_changed(current: int, total: int)   # NEW

func _ready():
	_spawn_loop()
	emit_signal("progress_changed", 0, spawn_order.size()) # initial counter

func _spawn_loop() -> void:
	while spawn_index < spawn_order.size():
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

	# connect to enemy's death (when freed from tree)
	if not mob.is_connected("tree_exited", Callable(self, "_on_enemy_died")):
		mob.connect("tree_exited", Callable(self, "_on_enemy_died"))

	alive += 1
	spawn_index += 1

func _on_enemy_died() -> void:
	alive -= 1
	defeated += 1
	emit_signal("progress_changed", defeated, spawn_order.size())

	if alive <= 0 and spawn_index >= spawn_order.size() and not finished:
		finished = true
		emit_signal("all_cleared")
