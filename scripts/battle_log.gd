extends Control

@onready var log_text = $ScrollContainer/VBoxContainer/MarginContainer/RichTextLabel
@onready var scroll = $ScrollContainer

var max_lines = 10

func add_entry(text: String, type: String = "normal"):
	var timestamp = Time.get_time_string_from_system().substr(0,8)
	var color_code = ""
	
	match type:
		"damage":
			color_code = "[color=red]"
		"block":
			color_code = "[color=yellow]"
		"heal":
			color_code = "[color=green]"
		"enemy":
			color_code = "[color=purple]"
		_:
			color_code = "[color=white]"
	
	var entry = color_code + "[" + timestamp + "] " + text + "[/color]\n"
	log_text.append_text(entry)
	
	# Auto-scroll to bottom
	await get_tree().create_timer(0.1).timeout
	log_text.scroll_to_line(log_text.get_line_count())
	
	# Force scroll to bottom
	await get_tree().create_timer(0.05).timeout
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
