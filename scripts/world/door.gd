class_name Door
extends StaticBody2D
## ASHEN CROWN — a basic door/gate.
## Blocks the way until opened (by a linked Switch or directly). Opening moves
## the door up and out of the way so the player can pass.

signal opened

@export var open_offset: Vector2 = Vector2(0, -120)
@export var open_speed: float = 3.0

var is_open: bool = false

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")
@onready var _shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

## Open the door. Safe to call repeatedly.
func open() -> void:
	if is_open:
		return
	is_open = true
	opened.emit()
	if _shape:
		_shape.set_deferred("disabled", true)
	if _sprite:
		_sprite.z_index = -10
	# Move the whole door upward so it visually leaves the way.
	var tween := create_tween()
	tween.tween_property(self, "position", position + open_offset, open_speed) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)