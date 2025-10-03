extends Character

const Lantern = preload("res://Characters/Hedler/Hedler-lantern.tscn")

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
	attack_damage =  [8,8, 12]
	combo_count = 3

func skill():
	Partystate.can_switch = false
	emit_signal("skill_used", character_data.skill_cooldown)
	attackState = AttackState.ATTACKING
	sprite.play("skill")

	await await_animation_frame("skill", 4)

	var lantern = Lantern.instantiate()
	get_parent().add_child(lantern)
	#slightly infront of where helder is facing
	lantern.global_position = global_position + Vector2(20 if sprite.flip_h == false else -20, -5)
	
	await sprite.animation_finished

	attackState = AttackState.IDLE
	Partystate.can_switch = true
