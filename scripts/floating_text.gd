# floating_text.gd
extends Node2D


@onready var label = $Label

func show_value(value: int, is_damage: bool):
	if is_damage:
		label.add_theme_color_override("font_color", Color(1, 0, 0))
		label.text = str(-value)
	else:
		label.add_theme_color_override("font_color", Color(0, 1, 0))
		label.text = "+" + str(value)
	
	animate_and_destroy()

func show_status_effect(text: String, color: Color):
	label.text = text
	label.modulate = color
	animate_and_destroy()

func animate_and_destroy():
	# Animate
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 50, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
