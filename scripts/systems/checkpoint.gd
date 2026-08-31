class_name Checkpoint
extends Interactable

## ASHEN CROWN — reusable checkpoint (save point).
## On activation (E) it records Cael's respawn position with GameManager,
## plays a one-shot activation animation and stays lit.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var activated: bool = false

func _ready() -> void:
	super._ready()
	prompt = "Activate checkpoint"
	anim.play("idle")
	anim.modulate = Color(0.55, 0.55, 0.6)

func _on_interact(interactor: Node) -> void:
	if activated:
		return
	activated = true
	# Record the player's standing position (feet on the ground) as the respawn
	# point, since the player's node origin sits above its feet.
	get_tree().root.get_node("GameManager").call("activate_checkpoint", interactor.global_position)
	anim.play("activate")
	anim.modulate = Color(1.0, 1.0, 1.0)