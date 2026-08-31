class_name Hazard
extends Area2D

## ASHEN CROWN — reusable environmental hazard (spikes, thorns, toxic pools).
## Damages Cael on overlap. Damage is throttled by this component's interval
## AND by the target's HealthComponent invulnerability, so it never applies
## unlimited damage each frame.

@export var damage: int = 10
@export var knockback := Vector2(0, -220)
@export var hit_interval: float = 0.5
## If true, any contact instantly kills the player (spikes). Bypasses parry.
@export var lethal: bool = false

var _timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 16  # player hurtbox layer

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	for area in get_overlapping_areas():
		if area is Hurtbox and area.get_parent() is PlayerController:
			var info := DamageInfo.new()
			info.amount = 9999 if lethal else damage
			info.knockback = knockback
			info.source = self
			area.receive_damage(info)
			_timer = hit_interval
			break