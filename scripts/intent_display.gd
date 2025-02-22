extends Node2D

#@onready var intent_sprite = $IntentSprite
@onready var value_label = $ValueLabel

func display_intent(intent_type, value):
	match intent_type:
		"attack":
			#intent_sprite.texture = load("res://assets/attack_intent.png")
			value_label.text = "ATK: " + str(value)
		"block":
			#intent_sprite.texture = load("res://assets/block_intent.png")
			value_label.text = "BLK: " + str(value)
