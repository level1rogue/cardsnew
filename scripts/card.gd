extends Node2D

signal hovered
signal hovered_off

var in_hand_position
var note: String 
var energy_cost: int
var power: int
var card_id: String
var cooldown: int

func set_card_id(id: String):
	card_id = id

func highlight():
	modulate = Color(1.5, 1.5, 1.5)
	scale = Vector2(1.1, 1.1)

func unhighlight():
	modulate = Color(1, 1, 1)
	scale = Vector2(1, 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_card_signals(self)

func set_energy_cost(cost: int):
	energy_cost = cost

func set_power(value: int):
	power = value

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

func set_note(new_note: String) -> void:
	note = new_note

func set_cooldown(new_cooldown: int) -> void:
	cooldown = new_cooldown
