class_name Hurtbox
extends Area2D

## Reusable hurtbox (Area2D-based). Detects incoming active Hitboxes.
## The owning entity decides what to do (take damage, parry, etc.) via signals.

signal hitbox_entered(hitbox: Hitbox)
signal damage_received(damage: DamageInfo)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = true

func can_receive_damage() -> bool:
	return true

## Called by a Hitbox when it lands a hit on this hurtbox.
func receive_damage(damage: DamageInfo) -> void:
	damage_received.emit(damage)

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox and area.is_active():
		hitbox_entered.emit(area)
