extends Area2D

@export var next_scene_path: String = "res://Areas/hall_2.tscn"

@onready var prompt_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_area: bool = false
var is_unlocked: bool = false

func _ready() -> void:
	visible = false
	prompt_sprite.visible = false
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func unlock() -> void:
	is_unlocked = true
	visible = true
	$Door.play("spawn")
	

func _on_body_entered(body: Node) -> void:
	if is_unlocked and body.is_in_group("player"):
		player_in_area = true
		prompt_sprite.visible = true
		prompt_sprite.play("default")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		prompt_sprite.visible = false
		prompt_sprite.stop()

func _process(_delta: float) -> void:
	if player_in_area and is_unlocked and Input.is_action_just_pressed("interact"):
		_change_scene()

func _change_scene() -> void:
	Stagestate.current_room += 1
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
