extends Control

signal reward_selected

func _ready():
	$VBoxContainer/Button.pressed.connect(_on_continue_pressed)
	# Create and set a solid style for the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 1.0)  # Dark gray, fully opaque
	$Panel.add_theme_stylebox_override("panel", style)


func _on_continue_pressed():
	# Return to map or next battle
	emit_signal("reward_selected")
