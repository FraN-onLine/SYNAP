extends CharacterBody2D

# ---- Stats ----
@export var HP_Max: int = 25
var HP: int = 25
@export var damage: int = 3.5
@export var bullet_scene: PackedScene
@export var damage_popup_scene: PackedScene

# ---- Physics ----
@export var gravity: float = 900.0   # pulls down
var is_dead: bool = false

# ---- Nodes ----
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $Healthbar
@onready var attack_timer: Timer = $AttackTimer

# ---- Target ----
var player: Node = null

func _ready() -> void:
	sprite.play("idle")
	health_bar.init_health(HP_Max)
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# inside _physics_process, after player is set
	if player:
		sprite.flip_h = player.global_position.x > global_position.x
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	#else:
		#velocity.y = 0

	move_and_slide()

	# track player reference
	if not player or not player.is_inside_tree():
		player = get_tree().get_first_node_in_group("player")
		return

# ---- Attack cycle ----
func _on_attack_timer_timeout() -> void:
	if is_dead:
		return

	# play attack animation
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

	# shoot 3 bullets spaced slightly apart
	for i in range(3):
		_shoot_bullet(i * 0.2)

func _shoot_bullet(delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	if not player or not player.is_inside_tree():
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# spawn at shooter's position
	bullet.global_position = global_position

	# aim toward player
	var dir = (player.global_position - global_position).normalized()
	bullet.start(dir, damage)

	# flip bullet sprite
	if dir.x != 0 and bullet.has_node("Sprite2D"):
		bullet.get_node("AnimatedSprite2D").flip_h = dir.x > 0

# ---- Damage system ----
func take_damage(amount: int) -> void:
	HP -= amount
	health_bar.value = HP

	if damage_popup_scene:
		var popup := damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))

	modulate = Color(1, 0, 0, 0.5)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if HP <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	queue_free()
