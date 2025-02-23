extends Control

enum SlotType { ATTACK, BLOCK, UTILITY }
var slot_type: SlotType

var card_in_slot = false
var occupied_card = null
var octave: int
var voice: String
var last_action: String = "none"  # "none", "used"
var internal_cooldown: int = 0  # For tracking actual countdown
var display_cooldown: int = 0   # For display purposes

@onready var panel = $Panel
@onready var typePanel = $TypePanel
@onready var lock_image = $Panel/LockImage
@onready var lock_label = $Panel/LockLabel
@onready var mult_label = $MultLabel  # Reference to the Label node
@onready var action_label = $Action/ActionLabel
var voice_stats = preload("res://scripts/voice_stats.gd").new()
const Styles = preload("res://lib/styles.gd")


func _ready():
	add_to_group("card_slots")
	# Set up voice and octave based on node name
	var slot_name = name  # e.g. "CardSlot1A"
	var voice_number = int(slot_name.substr(8, 1))  # Gets the number after "CardSlot"
	var is_front_row = slot_name.ends_with("A")

	if is_front_row:
		action_label.position.y = -35  # Adjust value as needed
	else:
		action_label.position.y = 70   # Adjust value as needed

	# Reset modulate values to full brightness
	panel.modulate = Color(1, 1, 1, 1)
	panel.self_modulate = Color(1, 1, 1, 1)
	typePanel.modulate = Color(1, 1, 1, 1)

	match voice_number:
		1:  # Bass
			voice = "bass"
			octave = 2 if is_front_row else 1
		2:  # Tenor
			voice = "tenor"
			octave = 3 if is_front_row else 2
		3:  # Alto
			voice = "alto"
			octave = 3 if is_front_row else 2
		4:  # Soprano
			voice = "soprano"
			octave = 4 if is_front_row else 3

   # Set slot type based on voice and position
	var voice_data = voice_stats.get_multipliers(voice)
	var slot_type_str = voice_data["front_slot" if is_front_row else "back_slot"]
	match slot_type_str:
		"attack": slot_type = SlotType.ATTACK
		"block": slot_type = SlotType.BLOCK
		"utility": slot_type = SlotType.UTILITY
	
  # Create a new StyleBoxFlat for the panel
	var style = StyleBoxFlat.new()
	style.set_border_width_all(6)  # Set border width
	style.bg_color = Color(0, 0, 0, 0)  # Transparent

	# Set slot color based on type
	match slot_type:
		SlotType.ATTACK:
			style.border_color = Styles.COLORS.attack
			action_label.add_theme_color_override("font_color", Styles.COLORS.attack)
		SlotType.BLOCK:
			style.border_color = Styles.COLORS.block
			action_label.add_theme_color_override("font_color", Styles.COLORS.block)
		SlotType.UTILITY:
			style.border_color = Styles.COLORS.utility
			action_label.add_theme_color_override("font_color", Styles.COLORS.utility)
	# Set the panel style
	typePanel.add_theme_stylebox_override("panel", style)
	# Set the multiplier text
	var multiplier = get_slot_multiplier()
	mult_label.text = "x" + str(multiplier)

	update_slot_availability()
  
func update_action_label():
	if card_in_slot and occupied_card:
		var total_effect = int(occupied_card.power * get_slot_multiplier())
		action_label.text = str(total_effect)
		action_label.visible = true
	else:
		action_label.visible = false

func highlight_active():
	# Highlight slot as before
	var style = typePanel.get_theme_stylebox("panel") as StyleBoxFlat
	var highlight_style = StyleBoxFlat.new()
	highlight_style.set_border_width_all(8)
	highlight_style.bg_color = Color(0, 0, 0, 0)
	
	match slot_type:
		SlotType.ATTACK:
			highlight_style.border_color = Styles.COLORS.attack * 1.5
		SlotType.BLOCK:
			highlight_style.border_color = Styles.COLORS.block * 1.5
		SlotType.UTILITY:
			highlight_style.border_color = Styles.COLORS.utility * 1.5
	
	typePanel.add_theme_stylebox_override("panel", highlight_style)
	action_label.scale = Vector2(1.2, 1.2)
	
	# Also highlight the card if there is one
	if occupied_card:
		occupied_card.modulate = Color(1.5, 1.5, 1.5)
		occupied_card.scale = Vector2(1.1, 1.1)

func unhighlight():
	# Reset slot style
	var style = StyleBoxFlat.new()
	style.set_border_width_all(6)
	style.bg_color = Color(0, 0, 0, 0)
	
	match slot_type:
		SlotType.ATTACK:
			style.border_color = Styles.COLORS.attack
		SlotType.BLOCK:
			style.border_color = Styles.COLORS.block
		SlotType.UTILITY:
			style.border_color = Styles.COLORS.utility
			
	typePanel.add_theme_stylebox_override("panel", style)
	action_label.scale = Vector2(1, 1)
	
	# Reset card if there is one
	if occupied_card:
		occupied_card.modulate = Color(1, 1, 1)
		occupied_card.scale = Vector2(1, 1)
		
func get_slot_multiplier() -> float:
	var voice_multipliers = voice_stats.get_multipliers(voice)
	var is_front = name.ends_with("A")
	
	match slot_type:
		SlotType.ATTACK:
			return voice_multipliers.get(
				"attack_multiplier_" + ("front" if is_front else "back"),
				1.0
			)
		SlotType.BLOCK:
			return voice_multipliers.get(
				"block_multiplier_" + ("front" if is_front else "back"),
				1.0
			)
		SlotType.UTILITY:
			return voice_multipliers.get(
				"utility_multiplier_" + ("front" if is_front else "back"),
				1.0
			)
	return 1.0
	
func is_attack_slot() -> bool:
	return name.ends_with("A")

func can_play_card() -> bool:
	return internal_cooldown <= 0

func update_slot_availability():
	if can_play_card():
		lock_image.visible = false
		lock_label.visible = false
		panel.modulate = Color(1, 1, 1, 1)
		typePanel.modulate.a = 1
	else:
		lock_image.visible = true
		lock_label.visible = true
		panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
		typePanel.modulate.a = 0.3
		

func record_action():
	if card_in_slot:
		last_action = "used"
		internal_cooldown = occupied_card.cooldown + 1
		display_cooldown = occupied_card.cooldown
		lock_label.text = str(display_cooldown)
		#print(voice + " recorded action: " + (if is_attack_slot(): "attack" else "block"))
	else:
		last_action = "none"

func reset_action():
	if internal_cooldown > 0:
		print(voice + " BEFORE reset - internal: " + str(internal_cooldown) + ", display: " + str(display_cooldown))
		internal_cooldown -= 1
		display_cooldown = (internal_cooldown - 1) if internal_cooldown > 0 else 0
		lock_label.text = str(display_cooldown)
		print(voice + " AFTER reset - internal: " + str(internal_cooldown) + ", display: " + str(display_cooldown))
	   
		if internal_cooldown <= 0:
			last_action = "none"
	print(voice + " reset action, cooldown: " + str(internal_cooldown))  # debug print
	update_slot_availability()
