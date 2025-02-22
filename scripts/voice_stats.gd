extends Node

var voice_stats = {
	"bass": {
		"attack_multiplier": 1.0,
		"block_multiplier": 2.0,
		"name": "Bass"
	},
	"tenor": {
		"attack_multiplier": 1.5,
		"block_multiplier": 1.5,
		"name": "Tenor"
	},
	"alto": {
		"attack_multiplier": 2.0,
		"block_multiplier": 1.0,
		"name": "Alto"
	},
	"soprano": {
		"attack_multiplier": 2.5,
		"block_multiplier": 0.5,
		"name": "Soprano"
	}
}

func get_multipliers(voice: String) -> Dictionary:
	if voice in voice_stats:
		return voice_stats[voice]
	return {"attack_multiplier": 1.0, "block_multiplier": 1.0, "name": "Unknown"}