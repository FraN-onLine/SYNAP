# Bullet.gd
extends Area2D

@export var speed: float = 200.0
var dir: Vector2 = Vector2.ZERO
var damage: int = 5

func _ready():
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func start(direction: Vector2, dmg: int) -> void:
	dir = direction.normalized()
	damage = dmg

func _physics_process(delta: float) -> void:
	position += dir * speed * delta

func _on_body_entered(body: Node) -> void:
	print("lols")
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
