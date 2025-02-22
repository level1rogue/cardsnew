extends Node2D

const CARD_WIDTH = 120
const HAND_POS_Y = 920
const ANIM_TIME = 0.2

var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	 
	

func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0,card)
		update_hand_positions()
	else:
		animate_card_to_position(card, card.in_hand_position)
func update_hand_positions():
	for i in range(player_hand.size()):
		var new_position = Vector2(calc_card_position(i), HAND_POS_Y)
		var card = player_hand[i]
		card.in_hand_position = new_position
		animate_card_to_position(card, new_position)
		
func calc_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset
	
func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, ANIM_TIME)
	
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
