extends Character

@export var launch_force: float = -900# negative Y = up
@onready var launch_hitbox: Area2D = $Skill
@onready var launch_shape: CollisionShape2D = $Skill/CollisionShape2D
var i = 0
	
func _ready():
	$AttackArea1.body_entered.connect(_on_attack_area_entered.bind(0))
	$AttackArea2.body_entered.connect(_on_attack_area_entered.bind(1))
	$AttackArea3.body_entered.connect(_on_attack_area_entered.bind(2))
	$"../../UI".get_node("Healthbar").init_health(MaxHP)
	attack_areas= [
	$AttackArea1,
	$AttackArea2,
	$AttackArea3
	]
	attack_damage =  [10, 10, 15]
	combo_count = 3
	if not launch_hitbox.is_connected("body_entered", Callable(self, "_on_launch_hitbox_body_entered")):
		launch_hitbox.connect("body_entered", Callable(self, "_on_launch_hitbox_body_entered"))
	launch_shape.disabled = true


func skill():
	Partystate.can_switch = false
	emit_signal("skill_used", character_data.skill_cooldown)

	attackState = AttackState.ATTACKING
	sprite.play("skill") # your launch animation name here

	# Enable hitbox briefly
	await await_animation_frame("skill", 8)
	launch_shape.disabled = false

	# Wait until frame 10
	await await_animation_frame("skill", 12)
	launch_shape.disabled = true

	# End skill
	await sprite.animation_finished
	attackState = AttackState.IDLE
	Partystate.can_switch = true

func _on_launch_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(25)
			#launch enemy
			i = 0
			while i != 12:
				if body:
					i += 1
					body.global_position.y -= i
					#push away from player's direction
					body.global_position.x += global_position.direction_to(body.global_position).x * 5
					await get_tree().create_timer(0.012).timeout
