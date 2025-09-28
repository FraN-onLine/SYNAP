extends Node2D

@onready var sprite = $"Pocholo's Shield"


func _ready():
	Partystate.damage_mitigated.connect(play_mitigated_anim)

func _process(delta: float) -> void:
	if Partystate.damage_immune_triggers > 0:
		sprite.visible = true
	else:
		sprite.visible = false

func play_mitigated_anim() -> void:
	if not visible: return
	sprite.play("mitigated")
	await sprite.animation_finished
	sprite.play("idle")
