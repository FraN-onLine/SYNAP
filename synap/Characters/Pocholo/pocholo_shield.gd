extends Node2D

@onready var sprite = $"Pocholo's Shield"
func _ready():
	Partystate.damage_mitigated.connect(play_mitigated_anim)

func play_mitigated_anim() -> void:
	if not visible: return
	sprite.play("mitigated")
	Partystate.is_in_immunity_state = true
	await sprite.animation_finished
	sprite.play("idle")
	Partystate.is_in_immunity_state = false
	if Partystate.damage_immune_triggers <= 0:
		sprite.play("break")
		await sprite.animation_finished
		queue_free()
