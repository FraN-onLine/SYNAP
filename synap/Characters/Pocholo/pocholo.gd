extends Character

@onready var pocholo_shield = preload("res://Characters/Pocholo/Pocholo Shield.tscn")

func _ready():
	$AttackArea1.body_entered.connect(_on_attack_area_entered.bind(0))
	$AttackArea2.body_entered.connect(_on_attack_area_entered.bind(1))
	$"../../UI".get_node("Healthbar").init_health(MaxHP)
	attack_areas= [
	$AttackArea1,
	$AttackArea2
	]
	attack_damage =  [8,12]
	combo_count = 2

func skill():
	Partystate.can_switch = false
	emit_signal("skill_used", character_data.skill_cooldown)
	attackState = AttackState.ATTACKING
	sprite.play("skill")

	await sprite.animation_finished
	Partystate.damage_immune_triggers = 3
	#instance to current character
	var shield_instance = pocholo_shield.instantiate()
	add_child(shield_instance)
	Partystate.current_shield = shield_instance

	attackState = AttackState.IDLE
	Partystate.can_switch = true
