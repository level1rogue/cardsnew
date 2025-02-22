extends Control

@onready var health_label = $VBoxContainer/HealthLabel
@onready var block_label = $VBoxContainer/BlockLabel
@onready var energy_label = $VBoxContainer/EnergyLabel  # Only for player


func _ready():
	# Hide energy label by default (only show for player)
	if energy_label:
		energy_label.visible = false

# Function called to update the display
func update_stats(health: int, block: int, energy: int = -1):
	if health_label:
		health_label.text = "HP: " + str(health)
	if block_label:
		block_label.text = "Block: " + str(block)
	if energy_label and energy >= 0:  # Only show energy for player
		energy_label.text = "Energy: " + str(energy)
		energy_label.visible = true
