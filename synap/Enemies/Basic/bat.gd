extends CharacterBody2D

# ---- Tuning ----
@export var speed: float = 80.0              # normal hover chase speed
@export var dash_speed: float = 220       # dash/zoom speed
@export var dash_distance: float = 60   # how far to travel through/overshoot
@export var attack_range: float = 24.0       # start dash when this close
@export var dash_cooldown: float = 1.0       # time between dashes
@export var recover_time: float = 0.25       # short idle after dash

@export var damage: int = 5

@export var HP_Max: int = 30
var HP: int = 30
@onready var health_bar: TextureProgressBar = $Healthbar
@export var damage_popup_scene: PackedScene

# ---- Nodes ----
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_hitbox: Area2D = $DashHitbox
@onready var dash_shape: CollisionShape2D = $DashHitbox/CollisionShape2D

# ---- Target / State ----
var player: Node = null

enum State { CHASE, DASH, RECOVER }
var state: int = State.CHASE

var dash_dir: Vector2 = Vector2.ZERO
var dash_left: float = 0.0
var dash_cd_timer: float = 0.0
var hit_this_dash: bool = false
var is_dead: bool = false

func _ready():
	sprite.play("idle")
	health_bar.init_health(HP_Max)

	# Hitbox off by default
	if dash_shape:
		dash_shape.disabled = true

	# Damage on contact during dash
	if dash_hitbox and not dash_hitbox.is_connected("body_entered", Callable(self, "_on_dash_hitbox_body_entered")):
		dash_hitbox.connect("body_entered", Callable(self, "_on_dash_hitbox_body_entered"))

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	dash_cd_timer += delta

	# Acquire player
	if not player or not player.is_inside_tree() or not player.is_in_group("player"):
		player = get_tree().get_first_node_in_group("player")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match state:
		State.CHASE:
			_state_chase(delta)
		State.DASH:
			_state_dash(delta)
		State.RECOVER:
			_state_recover(delta)

	# Visual facing
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0

	move_and_slide()

# ----- States -----

func _state_chase(delta: float) -> void:
	# Free-flight toward player (no gravity)
	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > 1.0:
		velocity = to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO

	# Anim
	if sprite.animation != "hover" and sprite.animation != "walk":
		# fallback to "walk" if you don't have "hover"
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("hover"):
			sprite.play("hover")
		else:
			sprite.play("walk")

	# Start dash when in range and cooldown ready
	if dist <= attack_range and dash_cd_timer >= dash_cooldown:
		_start_dash(to_player.normalized())

func _state_dash(delta: float) -> void:
	velocity = dash_dir * dash_speed
	dash_left -= dash_speed * delta
	if dash_left <= 0.0:
		_end_dash_to_recover()

func _state_recover(delta: float) -> void:
	velocity = Vector2.ZERO
	# idle anim
	if sprite.animation != "idle":
		sprite.play("idle")
	# do nothing; the async timer will switch us back to CHASE

# ----- Transitions -----

func _start_dash(dir: Vector2) -> void:
	state = State.DASH
	dash_cd_timer = 0.0
	hit_this_dash = false
	dash_dir = dir
	dash_left = dash_distance

	# Enable dash hitbox
	if dash_shape:
		dash_shape.disabled = false

	# Anim
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("dash"):
		sprite.play("dash")
	else:
		# fall back to hover/walk if no dash anim
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("hover"):
			sprite.play("hover")
		else:
			sprite.play("walk")

func _end_dash_to_recover() -> void:
	# Disable hitbox, start brief recover
	if dash_shape:
		dash_shape.disabled = true
	state = State.RECOVER
	_start_recover_timer()

func _start_recover_timer() -> void:
	# brief idle window before chasing again
	await get_tree().create_timer(recover_time).timeout
	if is_dead:
		return
	state = State.CHASE

# ----- Damage on dash contact -----

func _on_dash_hitbox_body_entered(body: Node) -> void:
	if state != State.DASH:
		return
	if hit_this_dash:
		return
	if body.is_in_group("enemies"): # optional: don't hit other mobs
		return
	if body and body.has_method("take_damage"):
		body.take_damage(damage)
		hit_this_dash = true

# ----- Health / death -----

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
