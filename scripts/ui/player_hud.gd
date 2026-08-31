class_name PlayerHud
extends CanvasLayer

## Top-left HUD showing Cael's current / maximum health.
## Lives as a child of the Player so it is present in every stage and updates
## through the HealthComponent's health_changed signal (including after respawn).

@onready var health_bar: ProgressBar = $Root/HealthBar
@onready var hp_value: Label = $Root/HpValue

var _health: HealthComponent = null

func _ready() -> void:
	# Defer so the whole player tree (including HealthComponent) is ready first.
	call_deferred("_setup")

func _setup() -> void:
	var player := get_parent()
	if player == null:
		return
	_health = player.get_node_or_null("HealthComponent")
	if _health != null:
		_health.health_changed.connect(_on_health_changed)
		_on_health_changed(_health.current_health, _health.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
	if health_bar == null or hp_value == null:
		return
	health_bar.max_value = float(maximum)
	health_bar.value = float(current)
	hp_value.text = "%d / %d" % [current, maximum]
