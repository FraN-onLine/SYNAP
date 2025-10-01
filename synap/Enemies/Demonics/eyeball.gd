extends CharacterBody2D

# ---- Tuning ----
@export var hover_speed: float = 80.0
@export var shoot_cooldown: float = 5.0
@export var hover_height: float = 50.0   # always float above ground
@export var move_away_distance: float = 120.0

@export var bullet_scene: PackedScene
@export var HP_Max: int = 40
var HP: int = 40
@export var damage: int = 5
@export var damage_popup_scene: PackedScene

# ---- Nodes ----
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $Healthbar
@onready var ground_ray: RayCast2D = $GroundRayCast

# ---- Target / State ----
var player: Node = null
var is_dead := false
var cd_timer := 0.0
var state := "CHASE" # or "SHOOT" / "EVADE"

func _ready():
	HP = HP_Max
	health_bar.init_health(HP_Max)
	sprite.play("hover")
	ground_ray.enabled = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	cd_timer += delta

	if not player or not player.is_inside_tree():
		player = get_tree().get_first_node_in_group("player")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match state:
		"CHASE":
			_state_chase(delta)
		"SHOOT":
			_state_shoot(delta)
		"EVADE":
			_state_evade(delta)

	# Flip sprite
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0

	move_and_slide()

# ---- States ----

func _state_chase(delta: float) -> void:
	# follow horizontally, keep float height
	var target = player.global_position
	var to_player = target - global_position

	# maintain hover above ground
	if ground_ray.is_colliding():
		var ground_y = ground_ray.get_collision_point().y
		var desired_y = ground_y - hover_height
		to_player.y = desired_y - global_position.y

	velocity = to_player.normalized() * hover_speed

	# attack if cooldown ready
	if cd_timer >= shoot_cooldown:
		state = "SHOOT"
		velocity = Vector2.ZERO
		sprite.play("attack")

func _state_shoot(delta: float) -> void:
	# Fire once then go to evade
	if sprite.frame == sprite.sprite_frames.get_frame_count("attack") - 1:
		_fire_bullet()
		cd_timer = 0.0
		state = "EVADE"

func _state_evade(delta: float) -> void:
	# move away from player briefly
	var away = (global_position - player.global_position).normalized()
	velocity = away * hover_speed
	if cd_timer >= 1.0: # after 1 sec, chase again
		state = "CHASE"

# ---- Attack ----
func _fire_bullet():
	if not bullet_scene: return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector2(0, 8)
	if bullet.has_method("setup"):
		bullet.setup(Vector2.DOWN, damage)

# ---- Damage ----
func take_damage(amount: int) -> void:
	HP -= amount
	health_bar.value = HP

	if damage_popup_scene:
		var popup = damage_popup_scene.instantiate()
		get_tree().current_scene.add_child(popup)
		var jitter_x := randf_range(-6, 6)
		popup.show_damage(amount, global_position + Vector2(jitter_x, -20))

	modulate = Color(1, 0, 0, 0.5)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if HP <= 0:
		die()

func die():
	if is_dead: return
	is_dead = true
	velocity = Vector2.ZERO

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	queue_free()
