class_name Switch
extends Interactable
## ASHEN CROWN — a basic wall/floor switch.
## Interacting toggles any linked Door(s) open (one-shot). Visual state flips.

signal toggled(open: bool)

@export var target_door_path: NodePath = NodePath("")
@export var switch_on_sprite: Texture2D = null
@export var switch_off_sprite: Texture2D = null

var _active: bool = false

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

func _ready() -> void:
	super._ready()
	prompt = "Press"

func _on_interact(_interactor: Node) -> void:
	if _active:
		return
	_active = true
	if _sprite and switch_on_sprite:
		_sprite.texture = switch_on_sprite
	if target_door_path and not target_door_path.is_empty():
		var door: Node = get_node_or_null(target_door_path)
		if door and door.has_method("open"):
			door.call("open")
	toggled.emit(true)