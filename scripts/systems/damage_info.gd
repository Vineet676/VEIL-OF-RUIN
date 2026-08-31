class_name DamageInfo
extends RefCounted

## Reusable damage payload passed between Hitboxes, Hurtboxes and HealthComponents.
## Enemies and bosses can reuse this directly.

var amount: int = 0
var source: Node2D = null
var knockback: Vector2 = Vector2.ZERO
var hit_position: Vector2 = Vector2.ZERO
var is_critical: bool = false

func _init(
	p_amount: int = 0,
	p_source: Node2D = null,
	p_knockback: Vector2 = Vector2.ZERO,
	p_hit_position: Vector2 = Vector2.ZERO,
	p_is_critical: bool = false
) -> void:
	amount = p_amount
	source = p_source
	knockback = p_knockback
	hit_position = p_hit_position
	is_critical = p_is_critical
