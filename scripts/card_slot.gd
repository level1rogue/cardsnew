extends Control

var card_in_slot = false
var occupied_card = null
var octave: int
var voice: String
var last_action: String = "none"  # "none", "used"
@onready var panel = $Panel
@onready var lock_image = $Panel/LockImage
@onready var mult_label = $MultLabel  # Reference to the Label node
var voice_stats = preload("res://scripts/voice_stats.gd").new()

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

  # Set the multiplier text
	var multiplier = get_slot_multiplier()
	mult_label.text = "x" + str(multiplier)

	update_slot_availability()

func get_slot_multiplier() -> float:
	var voice_multipliers = voice_stats.get_multipliers(voice)
	if is_attack_slot():
		return voice_multipliers.attack_multiplier
	else:
		return voice_multipliers.block_multiplier

func is_attack_slot() -> bool:
	return name.ends_with("A")

func can_play_card() -> bool:
  # If the slot wasn't used last turn, it's available
	if last_action == "none":
		return true
  # If it was used, it's locked
	return false

func update_slot_availability():
	if can_play_card():
		lock_image.visible = false
		panel.modulate = Color(1, 1, 1, 1)
	else:
		lock_image.visible = true
		panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
		

func record_action():
	if card_in_slot:
		last_action = "used"
		#print(voice + " recorded action: " + (if is_attack_slot(): "attack" else "block"))
	else:
		last_action = "none"

func reset_action():
	last_action = "none"
	print(voice + " reset action")  # Debug print
	update_slot_availability()
