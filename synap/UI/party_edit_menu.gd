extends Control

@onready var party_slots_container = $PartySlots
@onready var bench_container = $BenchList
@onready var close_button = $CloseButton

var temp_party: Array[PackedScene] = [null, null, null]

func _ready() -> void:
	# Initialize with current party data
	temp_party = Partystate.party.duplicate()

	_update_party_slots()
	_update_bench_list()

	close_button.pressed.connect(_on_close_pressed)

func _update_party_slots() -> void:
	for i in range(3):
		var btn: Button = party_slots_container.get_child(i)
		var scene = temp_party[i]
		if scene:
			btn.text = scene.resource_path.get_file().get_basename() # display name (or custom name)
		else:
			btn.text = "[Empty]"

		btn.disconnect_all("pressed")
		btn.pressed.connect(func():
			_on_party_slot_pressed(i)
		)

func _update_bench_list() -> void:
	bench_container.queue_free_children() # helper function below

	for char_scene in Partystate.obtained_characters:
		if temp_party.has(char_scene):
			continue # don't show if already in party

		var btn := Button.new()
		btn.text = char_scene.resource_path.get_file().get_basename()
		btn.pressed.connect(func():
			_on_bench_character_pressed(char_scene)
		)
		bench_container.add_child(btn)

func _on_party_slot_pressed(index: int) -> void:
	var removed = temp_party[index]
	if removed:
		# remove from party, goes back to bench
		temp_party[index] = null
		_update_party_slots()
		_update_bench_list()

func _on_bench_character_pressed(scene: PackedScene) -> void:
	# find first empty party slot
	for i in range(3):
		if temp_party[i] == null:
			temp_party[i] = scene
			_update_party_slots()
			_update_bench_list()
			return

	# optional: if all filled, replace selected slot logic can go here

func _on_close_pressed() -> void:
	# Apply to global state
	Partystate.set_party(temp_party)
	hide()
