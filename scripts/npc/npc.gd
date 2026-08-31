class_name NPC
extends Interactable
## ASHEN CROWN — NPC foundation.
## An interactable NPC: idle/patrol movement, facing (sprite flip), a small
## interaction cooldown, and a dialogue payload handed to DialogueManager.
## Place a Sprite2D (named "Sprite") and a CollisionShape2D as children.

signal dialogue_requested(lines: Array)

## Dialogue payload (same format as DialogueManager expects).
@export var dialogue_lines: Array = []

## Optional patrol. If patrol_left == patrol_right the NPC stays idle.
@export var patrol_left: float = 0.0
@export var patrol_right: float = 0.0
@export var patrol_speed: float = 24.0

## Facing: 1 = right, -1 = left. Flip the sprite accordingly.
@export var start_facing: int = 1

## Min seconds between consecutive interactions (prevents E spamming).
@export var interact_cooldown: float = 0.6

var _dir: int = 1
var _home: float = 0.0
var _cooldown: float = 0.0

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

func _ready() -> void:
	super._ready()
	prompt = "Talk"
	_home = global_position.x
	if start_facing < 0:
		_dir = -1
	if patrol_left == 0.0 and patrol_right == 0.0:
		patrol_left = _home
		patrol_right = _home
	_apply_facing()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if patrol_right > patrol_left:
		global_position.x += _dir * patrol_speed * delta
		if global_position.x >= patrol_right:
			global_position.x = patrol_right
			_dir = -1
		elif global_position.x <= patrol_left:
			global_position.x = patrol_left
			_dir = 1
		_apply_facing()

func _apply_facing() -> void:
	if _sprite:
		_sprite.flip_h = _dir < 0

func _on_interact(interactor: Node) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = interact_cooldown
	if interactor is PlayerController:
		# Face the player when they talk to us.
		if _sprite:
			_sprite.flip_h = interactor.global_position.x < global_position.x
	if not dialogue_lines.is_empty():
		var nodes: Array[Node] = get_tree().get_nodes_in_group("dialogue_manager")
		var dm: Node = nodes[0] if not nodes.is_empty() else null
		dialogue_requested.emit(dialogue_lines)
		if dm:
			dm.call("start_dialogue", dialogue_lines)