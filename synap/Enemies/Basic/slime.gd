extends CharacterBody2D

@export var speed: float = 50.0
@export var gravity: float = 900.0
@export var damage: int = 5
@export var attack_range: float = 16.0
@export var chase_delay: float = 0.2
@export var attack_cooldown = 0.5
@export var attack_cooldown_timer: float = 0.0

@export var HP_Max = 30
var HP = 30
@onready var health_bar: TextureProgressBar = $Healthbar
@export var damage_popup_scene: PackedScene


var player: Node = null
var can_chase: bool = true
var is_dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	sprite.play("idle")
	health_bar.init_health(HP_Max)


func _physics_process(delta: float) -> void:

	attack_cooldown_timer += delta

	if is_dead:
		return

	# Apply gravity always
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Find player if not set
	if not player or not player.is_inside_tree() or not player.is_in_group("player"):
		player = get_tree().get_first_node_in_group("player")
		return

	if can_chase:
		var dir_x = player.global_position.x - global_position.x
		var dist_x = abs(dir_x)

		if dist_x <= attack_range and is_on_floor() and attack_cooldown_timer >= attack_cooldown:
			attack_cooldown_timer = 0.0
			_attack_player()
		else:
			# Move horizontally only
			velocity.x = sign(dir_x) * speed

			# Flip slime to face direction
			sprite.flip_h = velocity.x > 0

			if sprite.animation != "walk":
				sprite.play("walk")
	else:
		velocity.x = 0
		move_and_slide()

	move_and_slide()


func _attack_player():
	can_chase = false
	velocity.x = 0
	move_and_slide()

	if player and player.has_method("take_damage"):
		player.take_damage(damage)

	if sprite.animation != "idle":
		sprite.play("idle")

	await get_tree().create_timer(chase_delay).timeout
	can_chase = true


func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

func take_damage(amount: int) -> void:
	HP -= amount
	health_bar.value = HP
	
	var popup := damage_popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	var jitter_x := randf_range(-6, 6)
	popup.show_damage(amount, global_position + Vector2(jitter_x, -20))
	
	modulate = Color(1, 0, 0, 0.5)  # Flash red on damage
	await get_tree().create_timer(0.1).timeout  # Wait for 0.1 seconds
	modulate = Color(1, 1, 1)  # Reset color
	if HP <= 0:
		die()
