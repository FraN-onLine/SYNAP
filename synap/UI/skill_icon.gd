extends Control

@onready var icon = $Sprite2D
@onready var cd_bar: = $TextureProgressBar

var cooldown := 0.0
var max_cooldown := 0.0

func start_cooldown(time: float) -> void:
	print("timey")
	max_cooldown = time
	cooldown = time
	cd_bar.visible = true
	cd_bar.max_value = time
	cd_bar.value = max_cooldown
	$Label.text = str(cooldown, "%.1f") + "s"

func _process(delta: float) -> void:
	$Label.text = String.num(cooldown, 1) + "s"
	if cooldown > 0:
		cooldown -= delta
		cd_bar.value = cooldown
		if cooldown <= 0:
			cd_bar.visible = false
