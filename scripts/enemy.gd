# enemy.gd
extends Node2D

enum Intent {
	ATTACK,
	BLOCK,
	ATTACK_BLOCK
}

var health: int
var block: int
var current_intent: Intent
var attack_value: int
var block_value: int
@onready var stats_display = $StatsDisplay
@onready var intent_display = $IntentDisplay


func _ready():
	health = 75
	block = 0
	set_next_intent()
	update_displays()

func update_displays():
	stats_display.update_stats(health, block)
	update_intent_display()

func set_next_intent():
	# Simple AI for now
	current_intent = Intent.values()[randi() % Intent.size()]
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
	update_intent_display()

func update_intent_display():
	match current_intent:
		Intent.ATTACK:
			intent_display.display_intent("attack", attack_value)
		Intent.BLOCK:
			intent_display.display_intent("block", block_value)
		Intent.ATTACK_BLOCK:
			intent_display.display_intent("attack", attack_value)

var floating_text_scene = preload("res://scenes/floating_text.tscn")

func take_damage(amount: int):
	if block > 0:
		var blocked = min(block, amount)
		show_floating_text(blocked, false)  # Show blocked amount
		block -= blocked
		amount -= blocked
		
	if amount > 0:
		health -= amount
		show_floating_text(amount, true)  # Show damage
	
	update_displays()

func add_block(amount: int):
	block += amount
	show_floating_text(amount, false)
	update_displays()

func show_floating_text(value: int, is_damage: bool):
	var floating_text = floating_text_scene.instantiate()
	add_child(floating_text)
	floating_text.show_value(value, is_damage)
