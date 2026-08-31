class_name AbilityShrine
extends Interactable

## Reusable ability-grant shrine. Stand near it and press E to unlock the given
## ability in GameManager (has_dash / has_double_jump / has_wall_jump, or a
## future ability via grant_ability). Used by the Phase 4 test area to prove
## that ability gates unlock once the matching ability is obtained.

@export var ability: String = "double_jump"

@onready var visual: Sprite2D = $Visual

var _used: bool = false

func _ready() -> void:
	super._ready()
	prompt = "Unlock %s" % ability

func _on_interact(_interactor: Node) -> void:
	if _used:
		return
	_used = true
	var gm: Node = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("grant_ability"):
		gm.grant_ability(ability)
	prompt = ""
	# Brighten + fade the shrine to signal it has been consumed.
	var tw := create_tween()
	tw.tween_property(visual, "modulate", Color(1.6, 1.6, 0.8), 0.3)
	tw.tween_property(visual, "modulate:a", 0.4, 0.6)
