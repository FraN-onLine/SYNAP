extends Control

@onready var icon = $Sprite2D
@onready var cd_bar: = $TextureProgressBar

var cooldown := 0.0
var max_cooldown := 0.0

func set_value(skill_cd, value):
	cd_bar.max_value = skill_cd
	cd_bar.value = value
	cooldown = value
	max_cooldown = skill_cd
	if value <= 0:
		$Label.text = ""


func start_cooldown(time: float) -> void:
	print("timey")
	max_cooldown = time
	cooldown = time
	cd_bar.visible = true
	cd_bar.max_value = time
	cd_bar.value = max_cooldown
	$Label.text = str(cooldown, "%.1f") + "s"

func _process(delta: float) -> void:
	if cooldown > 0:
		$Label.text = String.num(cooldown, 1) + "s"
		cooldown -= delta
		cd_bar.value = cooldown
		if cooldown <= 0:
			cd_bar.visible = false
			$Label.text = "Ready!"
			#wait 1s then clear text
			await get_tree().create_timer(0.6).timeout
			$Label.text = ""
