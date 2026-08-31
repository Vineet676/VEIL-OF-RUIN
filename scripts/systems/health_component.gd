class_name HealthComponent
extends Node

## Reusable health system usable by the player, enemies and bosses.
## Owns current/max health, damage intake, temporary invulnerability and death.

signal health_changed(current: int, maximum: int)
signal damaged(damage: DamageInfo)
signal died
signal invulnerability_changed(invulnerable: bool)

@export var max_health: int = 100
@export var invulnerability_time: float = 0.0

var current_health: int = 100
var invulnerable: bool = false

var _invuln_timer: Timer

func _ready() -> void:
	current_health = max_health
	_invuln_timer = Timer.new()
	_invuln_timer.one_shot = true
	_invuln_timer.timeout.connect(_on_invuln_timeout)
	add_child(_invuln_timer)
	health_changed.emit(current_health, max_health)

## Applies damage. Respects invulnerability and death. Returns true if the hit landed.
func take_damage(damage: DamageInfo) -> bool:
	if invulnerable or current_health <= 0:
		return false
	current_health = max(0, current_health - damage.amount)
	health_changed.emit(current_health, max_health)
	damaged.emit(damage)
	if current_health <= 0:
		died.emit()
	else:
		_start_invulnerability()
	return true

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

## Force a temporary invulnerability (used by dash i-frames). Overrides the timer.
func set_invulnerable(duration: float) -> void:
	if duration <= 0.0:
		return
	invulnerable = true
	invulnerability_changed.emit(true)
	_invuln_timer.start(duration)

func _start_invulnerability() -> void:
	if invulnerability_time <= 0.0:
		return
	set_invulnerable(invulnerability_time)

func _on_invuln_timeout() -> void:
	invulnerable = false
	invulnerability_changed.emit(false)
