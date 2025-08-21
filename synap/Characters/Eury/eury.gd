extends Character

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
