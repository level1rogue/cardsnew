extends Node2D

var COLLISION_MASK_CARD = 1
var COLLISION_MASK_CARD_SLOT = 2

var screen_size
var card_being_dragged
var is_hovering_over_card = false

var player_hand_reference


func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect('left_mous_button_released', on_left_click_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))
		#var card_slot_found = raycast_check_for_card_slot()
		#if card_slot_found and not card_slot_found.card_in_slot:
			#print('card slot found: ', card_slot_found.get_node("GlowShape").visible)
			## change card slot appearance
			#card_slot_found.get_node("GlowShape").visible = true
		#

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1,1)
	
func finish_drag():
	card_being_dragged.scale = Vector2(1.05, 1.05)
	var card_slot_found = raycast_check_for_card_slot()
	 # First, find if the card was in a slot before and clear that slot
	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.occupied_card == card_being_dragged:
			slot.card_in_slot = false
			slot.occupied_card = null
			slot.update_action_label()
	
	# Then handle placing in new slot or returning to hand
	if card_slot_found and not card_slot_found.card_in_slot and card_slot_found.can_play_card():
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		# Calculate center position of the slot
		var slot_center = card_slot_found.global_position + Vector2(card_slot_found.size.x/2, card_slot_found.size.y/2)
		card_being_dragged.position = slot_center
		card_slot_found.card_in_slot = true
		card_slot_found.occupied_card = card_being_dragged
		card_slot_found.update_action_label()
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged)
	
	card_being_dragged = null
			
func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_click_released():
	if card_being_dragged:
		finish_drag()
	
func on_hovered_over_card(card):
	if !is_hovering_over_card:
		is_hovering_over_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_over_card = false

	
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1,1)
		card.z_index = 1
		

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null
	
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_highest_z_index(result)
		#return result[0].collider.get_parent()
	return null
	
func get_highest_z_index(cards):
	var highest_z_card =cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
	
