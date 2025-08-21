extends CharacterBody2D

class_name Character 

@export var obtained = true
@export var is_dead = false
@export var unit_name = "Name"
@export var character_profile: Sprite2D = null
@export var slot_index: int = 0
@export var speed: float = 150.0
@export var gravity: float = 900.0
@export var attack_cooldown: float = 0.15
@export var attack_damage: Array[int]
@export var crit_rate = 0.05

@export var MaxHP = 200
@export var HP = 200
var combo_step: int = 0
var combo_count = 2
var attacking: bool = false
var queue_next_attack: bool = false
var attack_cd_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var attack_areas: Array[Area2D]

func _ready():
	$"../UI".get_node("Healthbar").init_health(MaxHP)


func _physics_process(delta: float) -> void:
	var direction_x := 0.0

	if not attacking:
		if Input.is_action_pressed("move_right"):
			direction_x += 1
		if Input.is_action_pressed("move_left"):
			direction_x -= 1

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Horizontal movement
	velocity.x = direction_x * speed
	move_and_slide()

	# Flip sprite
	if direction_x != 0:
		sprite.flip_h = direction_x < 0
		for area in attack_areas:
			if area:
				var shape = area.get_node_or_null("CollisionShape2D")
				if shape:
					var pos = shape.position
					pos.x = abs(pos.x) * (-1 if direction_x < 0 else 1)
					shape.position = pos

	# Cooldowns
	if attack_cd_timer > 0:
		attack_cd_timer -= delta

	# Attack input
	if Input.is_action_just_pressed("basic_attack") and attack_cd_timer <= 0:
		_handle_attack()

	# Idle/walk anim
	if not attacking:
		if direction_x != 0:
			if sprite.animation != "walk":
				sprite.play("walk")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")


func _handle_attack() -> void:
	attack_cd_timer = attack_cooldown

	if not attacking:
		attacking = true
		combo_step = 1
		_play_attack(combo_step)
	else:
		if combo_step < combo_count:
			queue_next_attack = true


func _play_attack(step: int) -> void:
	var anim_name = "attack-%d" % step
	sprite.play(anim_name)

	# Enable matching hitbox
	_enable_attack_area(step)

		# Clean signal connections
	if sprite.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		sprite.disconnect("animation_finished", Callable(self, "_on_attack_finished"))
	sprite.connect("animation_finished", Callable(self, "_on_attack_finished"))


func _on_attack_finished() -> void:
	# Disable hitbox when done
	_disable_all_attack_areas()

	if queue_next_attack and combo_step < combo_count:
		queue_next_attack = false
		combo_step += 1
		_play_attack(combo_step)
	else:
		attacking = false
		combo_step = 0
		sprite.play("idle")

func _enable_attack_area(step: int) -> void:
	print("attack")
	_disable_all_attack_areas()
	var idx = step - 1
	if idx >= 0 and idx < attack_areas.size():
		attack_areas[idx].get_node("CollisionShape2D").disabled = false

func _disable_all_attack_areas() -> void:
	for area in attack_areas:
		if area:
			var shape = area.get_node_or_null("CollisionShape2D")
			if shape:
				shape.disabled = true

func _on_attack_area_entered(body: Node, idx: int) -> void:
	if combo_step - 1 == idx and body.has_method("take_damage") and !body.is_in_group("player"):
		body.take_damage(attack_damage[idx])

func take_damage(amount):
	HP -= amount
	$"../UI".get_node("Healthbar")._set_health(HP)
	$"../UI".get_node("HPLabel").text = "HP: " + str(HP) + "/" + str(MaxHP)
	modulate = Color(1, 0, 0, 0.75)  # Flash red on damage
	await get_tree().create_timer(0.1).timeout  # Wait for 0.1 seconds
	modulate = Color(1, 1, 1)  # Reset color
	if HP <= 0:
		die()

func die() -> void:
	print("Player died!")
	# Play death animation if you have one
	queue_free()  # or handle respawn here
