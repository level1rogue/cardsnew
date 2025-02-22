extends Control

var card_in_slot = false
var occupied_card = null
var octave: int
var voice: String
var last_action: String = "none"  # "attack", "block", "none"
@onready var panel = $Panel

func _ready():
	add_to_group("card_slots")
	# Set up voice and octave based on node name
	var slot_name = name  # e.g. "CardSlot1A"
	var voice_number = int(slot_name.substr(8, 1))  # Gets the number after "CardSlot"
	var is_higher_octave = slot_name.ends_with("A")
	
	match voice_number:
		1:  # Bass
			voice = "bass"
			octave = 2 if is_higher_octave else 1
		2:  # Tenor
			voice = "tenor"
			octave = 3 if is_higher_octave else 2
		3:  # Alto
			voice = "alto"
			octave = 3 if is_higher_octave else 2
		4:  # Soprano
			voice = "soprano"
			octave = 4 if is_higher_octave else 3

	update_slot_availability()

func is_attack_slot() -> bool:
	return name.ends_with("A")

func can_play_card() -> bool:
	if last_action == "none":
		return true
	elif is_attack_slot():
		return last_action != "attack"
	else:
		return last_action != "block"

func update_slot_availability():
	if can_play_card():
		modulate = Color(.1, .1, .1, .1)  # Normal
		panel.modulate = Color(1, 1, 1, 1)
	else:
		panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
		modulate = Color(1, 1, 1, 1)  # Grayed out

func record_action():
	if card_in_slot:
		last_action = "attack" if is_attack_slot() else "block"
	else:
		last_action = "none"

func reset_action():
	last_action = "none"
	update_slot_availability()
