extends Node2D


var card_db_ref
const CARD_SCENE_PATH = "res://scenes/card.tscn"
var player_deck = ["c", "d", "c", "e", "f", "e", "f", "d"]
var discard_pile = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_db_ref = preload("res://scripts/card_db.gd")
	$DeckCounter.text = str(player_deck.size())
	
	player_deck.shuffle()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_card():
	 # If deck is empty, reshuffle discard pile into deck
	if player_deck.size() == 0 and discard_pile.size() > 0:
		player_deck = discard_pile.duplicate()
		discard_pile.clear()
		player_deck.shuffle()
		
		# Update visuals
		$DeckImage.visible = true
		$DeckCounter.visible = true
		$Area2D/CollisionShape2D.disabled = false
		#battle_log.add_entry("Reshuffling discard pile into deck", "normal")

	if player_deck.size() > 0:
		var card_drawn = player_deck[0]
		player_deck.erase(card_drawn)
		
		if player_deck.size() == 0:
			$Area2D/CollisionShape2D.disabled = true
			$DeckImage.visible = false
			$DeckCounter.visible = false

		print("value: ", card_db_ref.CARDS[card_drawn].cost)
		$DeckCounter.text = str(player_deck.size())
		var card_scene = preload(CARD_SCENE_PATH)
		
		var new_card = card_scene.instantiate()
		var card_data = card_db_ref.CARDS[card_drawn]
		
		new_card.set_card_id(card_drawn)  # Set the card's ID
		new_card.set_note(card_data.name)  # Set the note property
		new_card.set_energy_cost(card_data.cost)  # Set energy cost
		new_card.set_power(card_data.power)  # Set power
		new_card.set_cooldown(card_data.cooldown)  # Set cooldown
		new_card.get_node("CostLabel").text = str(card_data.cost)
		new_card.get_node("NameLabel").text = card_data.name

		var color = card_db_ref.CARDS[card_drawn].color
		var texture = str("res://assets/cards/note_card-", color, ".png")
		new_card.get_node("CostLabel").text = str(card_db_ref.CARDS[card_drawn].cost)
		new_card.get_node("PowerLabel").text = str(card_db_ref.CARDS[card_drawn].power)
		new_card.get_node("CooldownLabel").text = str(card_db_ref.CARDS[card_drawn].cooldown)
		new_card.get_node("NameLabel").text = card_db_ref.CARDS[card_drawn].name
		new_card.get_node("CardImage").texture = load(texture)
		$"../CardManager".add_child(new_card)
		new_card.name = 'card'
		$"../PlayerHand".add_card_to_hand(new_card)

		return new_card
	return null

func add_to_discard(card_id: String):
	discard_pile.append(card_id)
