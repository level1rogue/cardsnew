# enemy.gd
extends Node2D

enum Intent {
	ATTACK,
	BLOCK,
	ATTACK_BLOCK
}

signal log_message(text: String, type: String)

var health: int
var block: int
var current_intent: Intent
var attack_value: int
var block_value: int
var vulnerability_turns: int = 0  # Increases damage taken
var weak_turns: int = 0      # Reduces damage dealt

@onready var stats_display = $StatsDisplay
@onready var intent_display = $IntentDisplay
var floating_text_scene = preload("res://scenes/floating_text.tscn")

func _ready():
	health = 30
	block = 0
	vulnerability_turns = 0
	weak_turns = 0
	set_next_intent()
	update_displays()
	

func update_displays():
	stats_display.update_stats(health, block, -1, vulnerability_turns, weak_turns)
	update_intent_display()

func set_next_intent():
	# Simple AI for now
	current_intent = Intent.values()[randi() % Intent.size()]
	
	# Get base values
	match current_intent:
		Intent.ATTACK:
			attack_value = 12
			block_value = 0
		Intent.BLOCK:
			attack_value = 0
			block_value = 8
		Intent.ATTACK_BLOCK:
			attack_value = 4
			block_value = 4
			
	# Apply weak (flat 25% reduction)
	if weak_turns > 0:
		attack_value = int(attack_value * 0.75)
   	
	update_intent_display()

func update_intent_display():
	match current_intent:
		Intent.ATTACK:
			intent_display.display_intent("attack", attack_value)
		Intent.BLOCK:
			intent_display.display_intent("block", block_value)
		Intent.ATTACK_BLOCK:
			intent_display.display_intent("attack", attack_value)

func add_vulnerability(amount: int):
	# amount here represents number of turns
	vulnerability_turns = max(vulnerability_turns, amount)  # Take the longer duration
	update_displays()

func recalculate_attack_value():
	var original_value = 0
	# Get base value based on current intent
	match current_intent:
		Intent.ATTACK:
				original_value = 12
				attack_value = original_value
		Intent.ATTACK_BLOCK:
				original_value = 4
				attack_value = original_value
		_:
				original_value = 0
				attack_value = original_value
	
	# Apply weak (flat 25% reduction)
	if weak_turns > 0:
		emit_signal("log_message", "Enemy has weak (" + str(weak_turns) + " turns)", "debuff")
		emit_signal("log_message", "Attack " + str(original_value) + " -> " + str(int(original_value * 0.75)) + " (75%)", "debuff")
		attack_value = int(attack_value * 0.75)
	
	update_intent_display()

func add_weak(amount: int):
	# amount here represents number of turns
	weak_turns = max(weak_turns, amount)  # Take the longer duration
	recalculate_attack_value()  # Recalculate attack value when weak is applied
	update_displays()

func take_damage(damage: int):
	  
	# Apply block
	if block > 0:
		var blocked = min(block, damage)
		block -= blocked
		damage -= blocked
	
	health -= damage
	show_floating_text(damage, true)  # Show damage
	update_displays()

func add_block(amount: int):
	block += amount
	show_floating_text(amount, false)
	update_displays()

func show_floating_text(value: int, is_damage: bool):
	var floating_text = floating_text_scene.instantiate()
	add_child(floating_text)
	floating_text.show_value(value, is_damage)

func end_turn():
	# Reduce turn counters for status effects
	if vulnerability_turns > 0:
			vulnerability_turns -= 1
	if weak_turns > 0:
			weak_turns -= 1
	# Update displays to show reduced status effects
	update_displays()
