extends Node2D

const ANIMATION_SPEEDS = {
	"quick": 0.2,
	"normal": 0.5,
	"slow": 0.8
}
var current_speed = "normal"

const CardSlot = preload("res://scripts/card_slot.gd")

@onready var combat_manager = $CombatManager
@onready var enemy = $Enemy
@onready var play_button = $Button
@onready var player_stats = $PlayerStats
@onready var sampler = $SamplerInstrument
@onready var battle_log = $BattleLog
@onready var camera = $Camera2D

var voice_stats = preload("res://scripts/voice_stats.gd").new()
var floating_text_scene = preload("res://scenes/floating_text.tscn")

var reward_screen_scene = preload("res://scenes/reward_screen.tscn")

func _ready():
	if !combat_manager:
		push_error("CombatManager node not found!")
		return

	combat_manager.connect("stats_changed", _on_stats_changed)
	_on_stats_changed()  # Initial update
	play_button.pressed.connect(_on_button_pressed)
	start_player_turn()
	enemy.log_message.connect(_on_enemy_log_message)

func _on_enemy_log_message(text: String, type: String):
	battle_log.add_entry(text, type)

func shake_camera(duration: float, strength: float, speed: float):
	var initial_offset = camera.offset
	var elapsed_time = 0.0
	
	while elapsed_time < duration:
		elapsed_time += speed * get_process_delta_time()
		var offset = Vector2()
		offset.x = randf_range(-strength, strength)
		offset.y = randf_range(-strength, strength)
		camera.offset = offset
		await get_tree().create_timer(0.01).timeout
	
	# Reset camera position
	camera.offset = initial_offset

func _on_stats_changed():
	player_stats.update_stats(
		combat_manager.player_health,
		combat_manager.player_block,
		combat_manager.player_energy
	)
		
func start_player_turn():
	combat_manager.player_block = 0  # Reset block
	combat_manager.reset_player_energy()  # Reset energy
	play_button.disabled = false  # Re-enable play button

	# Draw new hand
	$PlayerHand.draw_starting_hand()
	
	battle_log.add_entry("Player turn started", "normal")
	update_slot_availability()


func _on_button_pressed():
	var total_energy_cost = calculate_total_energy_cost()
	
	# Check if we have enough energy
	if total_energy_cost > combat_manager.player_energy:
			print("Not enough energy!")
			return
			
	# Spend energy
	combat_manager.spend_energy(total_energy_cost)
	
	# Play notes and resolve actions
	play_card_notes()
	resolve_player_actions()
	
	# Discard remaining cards in hand
	$PlayerHand.discard_hand()
	
	# Disable play button until next turn
	play_button.disabled = true
	

func calculate_total_energy_cost() -> int:
	var total_cost = 0
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.card_in_slot and slot.occupied_card:
			total_cost += slot.occupied_card.energy_cost
	return total_cost

func play_card_notes():
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.card_in_slot and slot.occupied_card:
			sampler.play_note(slot.occupied_card.note, slot.octave)
	
func calculate_slot_effect(card, slot) -> Dictionary:
	print("Card: ", card)  # See what properties are available
	print("Card power: ", card.power)  # See if power is accessible
	
	var base_value = card.power  # Base value for all effects
	var multiplier = slot.get_slot_multiplier()
	var effect_value = int(base_value * multiplier)
	
	match slot.slot_type:
		CardSlot.SlotType.ATTACK:
			return {"type": "attack", "value": effect_value}
		CardSlot.SlotType.BLOCK:
			return {"type": "block", "value": effect_value}
		CardSlot.SlotType.UTILITY:
			var effect_type = "vulnerability" if slot.name.ends_with("A") else "weak"
			return {"type": effect_type, "value": effect_value}
	
	return {"type": "none", "value": 0}

	
func resolve_player_actions():
	var effects = {
		"attack": 0,
		"block": 0,
		"vulnerability": 0,
		"weak": 0
	}

	battle_log.add_entry("Playing cards...", "normal")
	
	# Play cards one by one with visual feedback
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.card_in_slot and slot.occupied_card:
			# Highlight active slot
			slot.highlight_active()
			await get_tree().create_timer(ANIMATION_SPEEDS[current_speed]).timeout
			
			# Play note and show effect
			sampler.play_note(slot.occupied_card.note, slot.octave)
			var effect = calculate_slot_effect(slot.occupied_card, slot)
			effects[effect.type] += effect.value  # Add this line back
			slot.record_action()
			slot.update_action_label()
			
			battle_log.add_entry(
				voice_stats.get_multipliers(slot.voice).name + 
				" voice applies " + str(effect.value) + " " + effect.type,
				effect.type
			)
			
			await get_tree().create_timer(ANIMATION_SPEEDS[current_speed]).timeout
			slot.unhighlight()
	
	# Apply effects in order
	if effects.vulnerability > 0:
		print("vulnerability")
		apply_vulnerability(effects.vulnerability)
	if effects.weak > 0:
		print("weak")
		apply_weak(effects.weak)
	if effects.block > 0:
			combat_manager.player_block += effects.block
			show_player_floating_text(effects.block, false)
	if effects.attack > 0:
			await get_tree().create_timer(0.5).timeout
			apply_damage_to_enemy(effects.attack)
	
	update_slot_availability()  # Update after recording actions
	
	# Second pass: Reset unused voices
	# for slot in get_tree().get_nodes_in_group("card_slots"):
	# 	if not slot.voice in voice_actions:
	# 		slot.reset_action()
	# 		battle_log.add_entry(voice_stats.get_multipliers(slot.voice).name + 
	# 			" voice rests this turn", "normal")
	
	
	
	# Clear cards from slots
	clear_played_cards()
	
	# Start enemy turn after delay
	await get_tree().create_timer(1.0).timeout
	start_enemy_turn()

func update_slot_availability(): #FIXME: Slots don't update correctly
	for slot in get_tree().get_nodes_in_group("card_slots"):
		slot.update_slot_availability()
				
func apply_damage_to_enemy(damage: int):
	var initial_health = enemy.health
	var initial_block = enemy.block

	var base_duration = 0.2
	var max_duration = 1.2
	var duration = min(base_duration + (damage * 1.5), max_duration)

	var base_strength = 2
	var strength = base_strength + (damage * 0.5)  # Increases with damage

	shake_camera(duration, strength, 8)  # Fixed speed of 8

	# Log the initial damage value
	battle_log.add_entry("Base damage: " + str(damage), "normal")
	
	# Calculate vulnerability-modified damage before applying
	var modified_damage = damage
	if enemy.vulnerability_turns > 0:
		modified_damage = int(damage * 1.5)
		battle_log.add_entry("Vulnerability +" + str(enemy.vulnerability_turns) + 
			" turns: " + str(damage) + " -> " + str(modified_damage), "debuff")
	
	enemy.take_damage(modified_damage)
	
	var damage_blocked = min(initial_block, modified_damage)
	var damage_dealt = min(initial_health - enemy.health, modified_damage - damage_blocked)
	
	if damage_blocked > 0:
		battle_log.add_entry("Enemy blocked " + str(damage_blocked) + " damage", "block")
	if damage_dealt > 0:
		battle_log.add_entry("Enemy took " + str(damage_dealt) + " final damage", "damage")
		# Check for enemy death
		if enemy.health <= 0:
				await get_tree().create_timer(1.0).timeout  # Short delay
				show_victory_screen()


func apply_damage_to_player(damage: int):
	var initial_health = combat_manager.player_health
	var initial_block = combat_manager.player_block
	var final_damage = damage
	
	if combat_manager.player_block > 0:
		var blocked = min(combat_manager.player_block, damage)
		show_player_floating_text(blocked, false)
		combat_manager.player_block -= blocked
		final_damage -= blocked
		battle_log.add_entry("Player blocked " + str(blocked) + " damage", "block")
	
	if final_damage > 0:
		combat_manager.player_health -= final_damage
		show_player_floating_text(final_damage, true)
		battle_log.add_entry("Player took " + str(final_damage) + " damage", "damage")
	
	_on_stats_changed()


func show_player_floating_text(value: int, is_damage: bool):
	var floating_text = floating_text_scene.instantiate()
	$PlayerStats.add_child(floating_text)  # Adjust position as needed
	floating_text.show_value(value, is_damage)

func clear_played_cards():
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.card_in_slot and slot.occupied_card:
			# Add to discard pile before destroying
			$Deck.add_to_discard(slot.occupied_card.card_id)
			slot.occupied_card.queue_free()
			slot.card_in_slot = false
			slot.occupied_card = null
			slot.update_action_label()

func start_enemy_turn():
	battle_log.add_entry("Enemy turn started", "enemy")
	var enemy_action = enemy.current_intent
	
	match enemy_action:
		enemy.Intent.ATTACK:
			battle_log.add_entry("Enemy intends to attack", "enemy")
			battle_log.add_entry("Base attack: " + str(enemy.attack_value), "enemy")
			if enemy.weak_turns > 0:
				battle_log.add_entry("Weak active (" + str(enemy.weak_turns) + " turns)", "debuff")
			await get_tree().create_timer(0.5).timeout
			apply_damage_to_player(enemy.attack_value)
		enemy.Intent.BLOCK:
			battle_log.add_entry("Enemy blocks for " + str(enemy.block_value), "enemy")
			enemy.add_block(enemy.block_value)
		enemy.Intent.ATTACK_BLOCK:
			battle_log.add_entry("Enemy blocks for " + str(enemy.block_value) + " and attacks for " + str(enemy.attack_value), "enemy")
			enemy.add_block(enemy.block_value)
			await get_tree().create_timer(0.5).timeout
			apply_damage_to_player(enemy.attack_value)
	
	await get_tree().create_timer(1.0).timeout
	enemy.end_turn()  # This will reduce status effect counters
	enemy.set_next_intent()
	battle_log.add_entry("Enemy prepares next action", "enemy")

		
	# Reset ALL slots at the start of turn
	for slot in get_tree().get_nodes_in_group("card_slots"):
		slot.reset_action()
	
	start_player_turn()

func apply_vulnerability(amount: int):
	enemy.add_vulnerability(amount)
	battle_log.add_entry("Enemy gained " + str(amount) + " Vulnerability", "debuff")
	show_enemy_floating_text(amount, "vulnerability")

func apply_weak(amount: int):
	enemy.add_weak(amount)
	battle_log.add_entry("Enemy gained " + str(amount) + " weak", "debuff")
	show_enemy_floating_text(amount, "weak")

func show_enemy_floating_text(value: int, effect_type: String):
	var floating_text = floating_text_scene.instantiate()
	enemy.add_child(floating_text)
	
	match effect_type:
		"vulnerability":
			floating_text.show_status_effect(str(value) + " VUL", Color(0.8, 0.35, 0.36))
		"weak":
			floating_text.show_status_effect(str(value) + " WEAK", Color(0.83, 0.65, 0.13))

func show_victory_screen():
	battle_log.add_entry("Victory!", "normal")
	
	# Instance and show reward screen
	var reward_screen = reward_screen_scene.instantiate()
	add_child(reward_screen)
	
	# Make it cover the whole screen
	reward_screen.anchors_preset = Control.PRESET_FULL_RECT
	
	# Connect signals
	reward_screen.reward_selected.connect(_on_reward_selected)
	
	# Disable battle UI
	play_button.disabled = true
	# Could fade out battle elements here

func _on_reward_selected():
	# Handle reward selection and transition to next scene
	# For now, just restart battle
	get_tree().reload_current_scene()
