class_name AbilityGate
extends StaticBody2D

## Reusable metroidvania ability gate. A solid barrier that remains locked until
## the player owns the required ability (checked against GameManager). When the
## ability is unlocked the collision is disabled and the barrier fades out.
## Works with any ability name via GameManager.has_ability().

@export var required_ability: String = "double_jump"

@onready var barrier_collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Visual

var _opened: bool = false

func _ready() -> void:
	_check_ability()

func _physics_process(_delta: float) -> void:
	# Re-check so a gate that is granted an ability mid-level opens on the spot.
	if not _opened:
		_check_ability()

func _check_ability() -> void:
	var gm: Node = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_ability(required_ability):
		_open()

func _open() -> void:
	if _opened:
		return
	_opened = true
	barrier_collision.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(visual, "modulate:a", 0.0, 0.5)
	tw.tween_callback(visual.set.bind("visible", false))
