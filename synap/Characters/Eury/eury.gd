extends CharacterBody2D

@export var speed: float = 150.0
@export var gravity: float = 900.0
@export var attack_cooldown: float = 0.1

@export var HP_Max = 200
var HP = 200
var combo_step: int = 0
var attacking: bool = false
var queue_next_attack: bool = false
var attack_cd_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    HP = HP_Max

func _physics_process(delta: float) -> void:
    var direction_x := 0.0

    if not attacking:
        if Input.is_action_pressed("move_right"):
            direction_x += 1
        if Input.is_action_pressed("move_left"):
            direction_x -= 1

    # Apply gravity
    velocity.y += gravity * delta

    # Move horizontally
    velocity.x = direction_x * speed
    move_and_slide()

    # Flip sprite when moving left
    if direction_x != 0:
        sprite.flip_h = direction_x < 0

    # Timers
    if attack_cd_timer > 0:
        attack_cd_timer -= delta

    # Handle attack input
    if Input.is_action_just_pressed("basic_attack") and attack_cd_timer <= 0:
        _handle_attack()

    # Idle/walk animation
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
        if combo_step < 3:
            queue_next_attack = true


func _play_attack(step: int) -> void:
    var anim_name = "attack-%d" % step
    sprite.play(anim_name)
    if sprite.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
        sprite.disconnect("animation_finished", Callable(self, "_on_attack_finished"))
    sprite.connect("animation_finished", Callable(self, "_on_attack_finished"))


func _on_attack_finished() -> void:
    if queue_next_attack and combo_step < 3:
        queue_next_attack = false
        combo_step += 1
        _play_attack(combo_step)
    else:
        attacking = false
        combo_step = 0
        sprite.play("idle")

func take_damage(amount):
    HP -= amount
    if HP <= 0:
        die()

func die() -> void:
    print("Player died!")
    # Play death animation if you have one
    queue_free()  # or handle respawn here
