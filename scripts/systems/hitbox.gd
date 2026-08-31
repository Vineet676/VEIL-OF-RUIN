class_name Hitbox
extends Area2D

## Reusable attack hitbox (Area2D-based).
## Only registers hits while `enable()` has been called (active window).
## Prevents hitting the same target more than once per activation.

signal hit_landed(target: Node2D, damage: DamageInfo)

@export var base_damage: int = 1
@export var knockback_force: float = 0.0
@export var start_enabled: bool = false

var _hit_this_activation: Array = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false
	if start_enabled:
		enable()

## Begin the active window. Clears already-hit tracking so a new swing can hit again.
func enable() -> void:
	_hit_this_activation.clear()
	monitoring = true

func disable() -> void:
	monitoring = false

func is_active() -> bool:
	return monitoring

func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return
	if area in _hit_this_activation:
		return
	if not area.can_receive_damage():
		return
	_hit_this_activation.append(area)

	# Damage source is the owning body (not this Area2D) so the player's parry
	# stagger can reach the attacker root via on_stagger().
	var source := get_parent() as Node2D
	var damage := DamageInfo.new(base_damage, source, Vector2.ZERO, global_position)
	# Knockback points away from this hitbox, toward the target's side.
	damage.knockback = (Vector2.LEFT if area.global_position.x < global_position.x else Vector2.RIGHT) * knockback_force

	hit_landed.emit(area, damage)
	area.receive_damage(damage)
