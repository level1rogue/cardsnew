extends Node

var voice_stats = {
	"bass": {
		"front_slot": "block",
		"back_slot": "block",
		"attack_multiplier": 1.0,
		"block_multiplier_front": 1.5,
		"block_multiplier_back": 2.0,
		"utility_multiplier": 1.0,
		"name": "Bass"
	},
	"tenor": {
		"front_slot": "utility",
		"back_slot": "block",
		"attack_multiplier": 1.5,
		"block_multiplier": 1.5,
		"utility_multiplier": 1.5,
		"name": "Tenor"
	},
	"alto": {
		"front_slot": "attack",
		"back_slot": "utility",
		"attack_multiplier": 2.0,
		"block_multiplier": 1.0,
		"utility_multiplier": 1.5,
		"name": "Alto"
	},
	"soprano": {
		"front_slot": "attack",
		"back_slot": "attack",
		"attack_multiplier_front": 2.5,
		"attack_multiplier_back": 2.0,
		"utility_multiplier": 1.0,
		"name": "Soprano"
	}
}

func get_multipliers(voice: String) -> Dictionary:
	if voice in voice_stats:
		return voice_stats[voice]
	return {"front_slot": "utility", "back_slot": "utility", "attack_multiplier": 1.0, "block_multiplier": 1.0, "utility_multiplier": 1.0, "name": "Default"}