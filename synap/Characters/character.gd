extends CharacterBody2D

class_name Character 

enum AttackState { IDLE, ATTACKING, RECOVERY }
var attack_state = AttackState.IDLE

@export var character_data: char_data
@export var obtained = true
var is_dead = false
@export var unit_name = "Name"
@export var character_profile: Texture
var slot_index: int = 0
var speed: float = 150.0
var gravity: float = 900.0
var attack_cooldown: float = 0.15
var attack_damage: Array[int]
var crit_rate = 0.05

@export var MaxHP = 200
var HP = 200
var combo_step: int = 0
var combo_count = 2
var queue_next_attack: bool = false
var attack_cd_timer: float = 0.0
var dashing = false
var dash_speed: float = 220.0
var dash_cd_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var attack_areas: Array[Area2D]

func _ready():
	obtained = character_data.obtained
	is_dead = character_data.is_dead
	unit_name = character_data.unit_name
	character_profile = character_data.character_profile
	slot_index = character_data.slot_index
	speed = character_data.speed
	gravity = character_data.gravity
	attack_cooldown = character_data.attack_cooldown
	attack_damage = character_data.attack_damage
	crit_rate = character_data.crit_rate
	MaxHP = character_data.MaxHP
	HP = character_data.HP
	combo_count = character_data.combo_count
	$"../UI".get_node("Healthbar").init_health(MaxHP)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var direction_x := 0.0

	if not attackState == AttackState.ATTACKING and not dashing:
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
	if not dashing:
		velocity.x = direction_x * speed

	# Dash input
	if Input.is_action_just_pressed("ui_accept") and dash_cd_timer <= 0 and not dashing:
		if attackstate == AttackState.ATTACKING:
			_disable_all_attack_areas()
			attackState = AttackState.IDLE
		_start_dash(direction_x if direction_x != 0 else (-1 if sprite.flip_h else 1))

	# Skill input
	if Input.is_action_just_pressed("skill_tapped") and not attacking and not dashing:
		skill()

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
	if dash_cd_timer > 0:
		dash_cd_timer -= delta
	# Attack input
	if Input.is_action_just_pressed("basic_attack") and attack_cd_timer <= 0 and not dashing:
		_handle_attack()

	# Idle/walk anim
	if not attacking and not dashing:
		if direction_x != 0:
			if sprite.animation != "walk":
				sprite.play("walk")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")


func _handle_attack() -> void:
	if attack_cd_timer > 0: 
		return  # still cooling down

	# if currently mdid-combo, don't just spam queue here
	# queue_next_attack will be set ONLY if we are in the cancel window
	if attacking:
		return  

	# if not attacking → start combo
	attacking = true
	combo_step = 1
	attack_cd_timer = attack_cooldown
	_play_attack(combo_step)


func get_anim_length(anim_name: String) -> float:
	# Guard: if sprite_frames missing or fps is 0, return small fallback
	if not sprite.sprite_frames:
		return 0.3
	var frames := sprite.sprite_frames.get_frame_count(anim_name)
	var fps := sprite.sprite_frames.get_animation_speed(anim_name)
	if fps <= 0:
		fps = 12.0
	if frames <= 0:
		frames = 1
	return frames / float(fps)


func _play_attack(step: int) -> void:
	var anim_name := "attack-%d" % step
	sprite.play(anim_name)
	_enable_attack_area(step)

	# Ensure signal is connected exactly once
	if sprite.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		sprite.disconnect("animation_finished", Callable(self, "_on_attack_finished"))
	sprite.connect("animation_finished", Callable(self, "_on_attack_finished"))

	# Start the cancel / buffer window asynchronously (non-blocking)
	var anim_len := get_anim_length(anim_name)
	if anim_len <= 0:
		return
	var cancel_time := anim_len * 0.6  # open window at 60% through animation
	_open_queue_window(cancel_time)


# non-blocking queue window: checks input each frame (yields to engine)
func _open_queue_window(delay: float) -> void:
	# wait until the cancel window start
	await get_tree().create_timer(delay).timeout

	# if attack was cancelled (dash) before window opens, bail out
	if not attacking:
		return

	# allow queuing only while the animation is still playing
	# we poll input once per frame so we don't block the engine
	while attacking and sprite.is_playing():
		if Input.is_action_just_pressed("basic_attack"):
			# only allow queueing if there's more combo steps left
			if combo_step < combo_count:
				queue_next_attack = true
			break
		# yield one frame — this prevents freezing
		await get_tree().process_frame

	# once loop exits, no longer accepting queue via this window
	# (queue_next_attack may be true if input was detected)
	return


func _on_attack_finished() -> void:
	_disable_all_attack_areas()

	# If player buffered the next attack during the cancel window, chain it
	if queue_next_attack and combo_step < combo_count:
		queue_next_attack = false
		combo_step += 1
		_play_attack(combo_step)
		return

	# Otherwise we start the grace window where player can still continue the combo
	attacking = false

	var grace := 1.0
	var step_after := combo_step
	while grace > 0.0 and not attacking:
		# check input once per small tick (non-blocking)
		if Input.is_action_just_pressed("basic_attack") and step_after < combo_count:
			# resume combo
			combo_step = step_after + 1
			attacking = true
			_play_attack(combo_step)
			return
		await get_tree().create_timer(0.05).timeout
		grace -= 0.05

	# no follow-up pressed: fully reset combo
	combo_step = 0
	if not dashing:
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
	if is_dead:
		return
	HP -= amount
	character_data.HP = HP # <-- update resource
	$"../../UI".get_node("Healthbar")._set_health(HP)
	$"../../UI".get_node("HPLabel").text = "HP: " + str(HP) + "/" + str(MaxHP)
	modulate = Color(1, 0, 0, 0.75)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	if HP <= 0:
		is_dead = true
		character_data.is_dead = true # <-- update resource
		die()

func _start_dash(direction: int) -> void:
	dashing = true
	dash_cd_timer = 2.0
	velocity.x = direction * dash_speed
	sprite.play("dash")
	if sprite.is_connected("animation_finished", Callable(self, "_stop_dash")):
		sprite.disconnect("animation_finished", Callable(self, "_stop_dash"))
	sprite.connect("animation_finished", Callable(self, "_stop_dash"))

func _stop_dash() -> void:
	dashing = false
	velocity.x = 0
	if not attacking:
		sprite.play("idle")
	if sprite.is_connected("animation_finished", Callable(self, "_stop_dash")):
		sprite.disconnect("animation_finished", Callable(self, "_stop_dash"))

func skill():
	attacking = true
	sprite.play("skill")
	await sprite.animation_finished
	attacking = false
	print("Skill activated!")

func die() -> void:
	is_dead = true
	character_data.is_dead = true # <-- update resource
	sprite.play("death")
	await sprite.animation_finished
	queue_free()  # or handle respawn here
