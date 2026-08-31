class_name HealthPickup
extends Area2D

## ASHEN CROWN — reusable health pickup (secret-room reward / scattered heal).
## Heals the player on contact (one-shot). Renders a soft procedural glow so it
## needs no image assets.

@export var heal_amount: int = 25
@export var glow_color: Color = Color(0.35, 0.9, 0.5)

var _collected: bool = false
var _glow: ColorRect
var _time: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player body
	body_entered.connect(_on_body_entered)
	_build_visual()

func _build_visual() -> void:
	_glow = ColorRect.new()
	_glow.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.6)
	_glow.size = Vector2(28, 28)
	_glow.position = Vector2(-14, -14)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)
	# Bright center dot.
	var core := ColorRect.new()
	core.color = Color(1, 1, 1, 0.9)
	core.size = Vector2(10, 10)
	core.position = Vector2(-5, -5)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(core)

func _process(delta: float) -> void:
	_time += delta
	if _glow:
		_glow.modulate = Color(1, 1, 1, 0.5 + 0.3 * sin(_time * 5.0))

func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is PlayerController):
		return
	_collected = true
	var health: Node = body.get_node_or_null("HealthComponent")
	if health:
		var max_hp: int = health.get("max_health")
		var cur: int = health.get("current_health")
		health.set("current_health", min(max_hp, cur + heal_amount))
		if health.has_signal("health_changed"):
			health.health_changed.emit(min(max_hp, cur + heal_amount), max_hp)
	queue_free()
