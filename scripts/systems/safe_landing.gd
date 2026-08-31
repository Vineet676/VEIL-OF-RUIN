class_name SafeLanding
extends Area2D

## ASHEN CROWN — marks a landing surface as a safe (no fall damage) zone.
## While the player overlaps this zone, fall damage is disabled, so a secret
## falling-pit drop never deals lethal fall damage on landing here.

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player body
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		body.add_to_group("fall_damage_disabled")

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController and body.is_in_group("fall_damage_disabled"):
		body.remove_from_group("fall_damage_disabled")
