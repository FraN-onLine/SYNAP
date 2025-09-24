extends Node2D

@export var duration: float = 7.5
@export var tick_interval: float = 0.4
@export var damage: int = 5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var elapsed := 0.0
var tick_timer := 0.0

func _ready() -> void:
	# Play spawn anim, then idle
	sprite.play("spawn")
	sprite.animation_finished.connect(_on_spawn_finished)

func _process(delta: float) -> void:
	elapsed += delta
	tick_timer += delta

	# Apply tick damage every interval
	if tick_timer >= tick_interval:
		_apply_damage()
		tick_timer = 0.0

	# Lifetime check
	if elapsed >= duration:
		queue_free()

func _on_spawn_finished() -> void:
	if sprite.animation == "spawn":
		sprite.play("idle")

func _apply_damage() -> void:
	print("lantern doing lantern things")
	for body in area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
