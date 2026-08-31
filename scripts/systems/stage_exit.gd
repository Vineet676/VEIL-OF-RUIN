class_name StageExit
extends Area2D

## ASHEN CROWN — reusable stage transition zone.
## When Cael enters this area, the game transitions to the next stage.
## A trigger flag prevents duplicate transitions.

@export var next_stage: String = ""
@export var auto_advance: bool = true

var _triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player body
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	# Position-based transition: independent of grounded state. The moment the
	# player's horizontal position passes the exit plane, transition — so jumping,
	# double-jumping, dashing or falling through the zone always works.
	if _triggered or not auto_advance:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.global_position.x >= _boundary_x():
		_trigger()

## Left edge of the exit zone = the horizontal boundary that ends the stage.
func _boundary_x() -> float:
	var half_w: float = 45.0
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is RectangleShape2D:
		half_w = (cs.shape as RectangleShape2D).size.x * 0.5
	return global_position.x - half_w

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not auto_advance:
		return
	if body is PlayerController:
		_trigger()

func _trigger() -> void:
	if _triggered:
		return
	_triggered = true
	var gm: Node = get_tree().root.get_node("GameManager")
	if next_stage.is_empty():
		gm.call("transition_next")
	else:
		gm.call("goto_stage", next_stage)
