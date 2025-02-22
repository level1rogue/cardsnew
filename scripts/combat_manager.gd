extends Node

enum CombatPhase {
    PLAYER_TURN,
    ENEMY_TURN,
    TURN_RESOLUTION
}

var current_phase = CombatPhase.PLAYER_TURN
var player_health = 100
var player_block = 0
var player_energy = 3
var player_max_energy = 3
var enemy_health = 75
var enemy_block = 0
var enemy_intent = null

signal stats_changed

func _ready():
    reset_player_energy()

func reset_player_energy():
    player_energy = player_max_energy
    emit_signal("stats_changed")

func spend_energy(amount: int) -> bool:
    if player_energy >= amount:
        player_energy -= amount
        emit_signal("stats_changed")
        return true
    return false