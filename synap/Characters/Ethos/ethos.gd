extends Character

@onready var skill_area: Area2D = $Skill
@onready var skill_shape: CollisionShape2D = $Skill/CollisionShape2D

func _ready():
	$AttackArea1.body_entered.connect(_on_attack_area_entered.bind(0))
	$AttackArea2.body_entered.connect(_on_attack_area_entered.bind(1))
	$"../../UI".get_node("Healthbar").init_health(MaxHP)
	attack_areas= [
	$AttackArea1,
	$AttackArea2
	]
	attack_damage =  [10,10]
	combo_count = 2

	if not skill_area.is_connected("body_entered", Callable(self, "_on_skill_area_body_entered")):
		skill_area.connect("body_entered", Callable(self, "_on_skill_area_body_entered"))
	skill_shape.disabled = true


func skill():
	Partystate.can_switch = false
	take_damage(10) #cost of using skill
	emit_signal("skill_used", character_data.skill_cooldown)

	attackState = AttackState.ATTACKING
	sprite.play("skill") # your launch animation name here

	# Enable hitbox briefly
	await await_animation_frame("skill", 8)
	skill_shape.disabled = false

	# Wait until frame 10
	await await_animation_frame("skill", 12)
	skill_shape.disabled = true

	# End skill
	await sprite.animation_finished
	attackState = AttackState.IDLE
	Partystate.can_switch = true

func _on_skill_area_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(35)
		
