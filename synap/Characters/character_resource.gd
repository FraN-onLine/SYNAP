extends Resource

class_name char_data

signal died

@export var obtained = true
@export var is_dead = false
@export var unit_name = "Name"
@export var character_profile: Texture
@export var slot_index: int = 0
@export var speed: float = 150.0
@export var gravity: float = 900.0
@export var attack_cooldown: float = 0.15
@export var attack_damage: Array[int]
@export var crit_rate = 0.05
@export var MaxHP = 200
@export var HP = 200
@export var combo_count = 2
