class_name Interactable
extends Area2D

## ASHEN CROWN — reusable world-interaction foundation (E = interact).
## Base class for checkpoints, NPCs, doors, switches and story objects.
## The player's InteractArea detects overlapping Interactables and calls
## interact() when the player presses E.

signal interacted(interactor: Node)

@export var prompt: String = "Interact"
@export var auto_prompt: bool = true

func _ready() -> void:
	# Interactables sit on their own interaction layer so the player can find
	# them, but they do not need to detect anything themselves.
	collision_layer = 32
	collision_mask = 0

## Called by the player when they press E while overlapping this interactable.
func interact(interactor: Node) -> void:
	interacted.emit(interactor)
	_on_interact(interactor)

## Virtual hook for subclasses.
func _on_interact(_interactor: Node) -> void:
	pass
