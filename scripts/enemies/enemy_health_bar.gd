class_name EnemyHealthBar
extends Node2D

## Small world-space health bar shown above an enemy. Reads its parent's
## HealthComponent and scales the fill to reflect current health. Hidden once
## the enemy dies. Positioned above the enemy by the owning scene.

@onready var back: ColorRect = $Back
@onready var fill: ColorRect = $Fill

var _health: HealthComponent = null

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	var owner_node := get_parent()
	if owner_node == null:
		return
	_health = owner_node.get_node_or_null("HealthComponent")
	if _health != null:
		_health.health_changed.connect(_on_health_changed)
		_health.died.connect(_on_died)
		_on_health_changed(_health.current_health, _health.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
	if fill == null or back == null or maximum <= 0:
		return
	var ratio: float = clampf(float(current) / float(maximum), 0.0, 1.0)
	# Keep the fill anchored to the left by scaling its width around the left edge.
	fill.size.x = back.size.x * ratio
	fill.position.x = back.position.x - (back.size.x - fill.size.x) * 0.5

func _on_died() -> void:
	visible = false
