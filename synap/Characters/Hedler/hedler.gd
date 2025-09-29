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

	await sprite.animation_finished

	var lantern = Lantern.instantiate()
	get_parent().add_child(lantern)
	lantern.global_position = global_position

	attackState = AttackState.IDLE
	Partystate.can_switch = true
