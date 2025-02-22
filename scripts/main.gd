extends Node2D

@onready var combat_manager = $CombatManager
@onready var enemy = $Enemy
@onready var play_button = $Button
@onready var player_stats = $PlayerStats
@onready var sampler = $SamplerInstrument
@onready var battle_log = $BattleLog

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
	
	# Reset only slots that weren't used last turn
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.last_action == "none":
			slot.reset_action()
	
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
	
func calculate_attack_value(card, slot) -> int:
	var base_attack = 5  # Base attack value
	var multiplier = voice_stats.get_multipliers(slot.voice).attack_multiplier
	return int(base_attack * multiplier)


func calculate_block_value(card, slot) -> int:
	var base_block = 3  # Base block value
	var multiplier = voice_stats.get_multipliers(slot.voice).block_multiplier
	return int(base_block * multiplier)

	
func resolve_player_actions():
	var total_attack = 0
	var total_block = 0

	battle_log.add_entry("Playing cards...", "normal")
	play_card_notes()

	# Track which voices were used this turn
	var voice_actions = {}  # Dictionary to track voice actions
	
	# First pass: Record actions and calculate effects
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.card_in_slot and slot.occupied_card:
			voice_actions[slot.voice] = slot.is_attack_slot()
			slot.record_action()
			
			if slot.is_attack_slot():
				var damage = calculate_attack_value(slot.occupied_card, slot)
				total_attack += damage
				battle_log.add_entry(voice_stats.get_multipliers(slot.voice).name + 
					" voice attacks for " + str(damage), "damage")
			else:
				var block = calculate_block_value(slot.occupied_card, slot)
				total_block += block
				battle_log.add_entry(voice_stats.get_multipliers(slot.voice).name + 
					" voice blocks for " + str(block), "block")
	update_slot_availability()  # Update after recording actions
	
	# Second pass: Reset unused voices
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if not slot.voice in voice_actions:
			slot.reset_action()
			battle_log.add_entry(voice_stats.get_multipliers(slot.voice).name + 
				" voice rests this turn", "normal")
	update_slot_availability()  # Update after recording actions
	
	# Apply block first
	if total_block > 0:
		combat_manager.player_block += total_block
		show_player_floating_text(total_block, false)
		battle_log.add_entry("Player gained " + str(total_block) + " block", "block")
		_on_stats_changed()  # Update UI
	
	# Then apply damage after a short delay
	if total_attack > 0:
		await get_tree().create_timer(0.5).timeout
		battle_log.add_entry("Player attacks for " + str(total_attack) + " damage", "damage")
		apply_damage_to_enemy(total_attack)
	
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
	
	enemy.take_damage(damage)
	
	var damage_blocked = min(initial_block, damage)
	var damage_dealt = min(initial_health - enemy.health, damage - damage_blocked)
	
	if damage_blocked > 0:
		battle_log.add_entry("Enemy blocked " + str(damage_blocked) + " damage", "block")
	if damage_dealt > 0:
		battle_log.add_entry("Enemy took " + str(damage_dealt) + " damage", "damage")

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

func start_enemy_turn():
	battle_log.add_entry("Enemy turn started", "enemy")
	var enemy_action = enemy.current_intent
	
	match enemy_action:
		enemy.Intent.ATTACK:
			battle_log.add_entry("Enemy attacks for " + str(enemy.attack_value), "enemy")
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
	enemy.set_next_intent()
	battle_log.add_entry("Enemy prepares next action", "enemy")
	start_player_turn()

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
