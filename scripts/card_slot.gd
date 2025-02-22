extends Node2D

var card_in_slot = false
var occupied_card = null
var octave: int
var voice: String

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
