class_name KillZone
extends Area2D

## ASHEN CROWN — kill plane / fall-death zone.
## Placed beneath each stage's floor gaps. When Cael (the player body) enters
## the zone, it deals lethal damage, triggering the existing death/respawn flow
## via HealthComponent -> GameManager. A one-shot trigger avoids repeat hits.

var _killed: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player body layer
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _killed:
		return
	if body is PlayerController:
		_killed = true
		var health: Node = body.get_node_or_null("HealthComponent")
		if health and health.has_method("take_damage"):
			var info := DamageInfo.new()
			info.amount = 9999
			info.knockback = Vector2.ZERO
			info.source = self
			health.take_damage(info)
		# Re-arm after a short window so respawned player is not re-killed instantly
		# while still above the zone (respawn happens at a safe checkpoint/start).
		get_tree().create_timer(1.0).timeout.connect(func() -> void: _killed = false)
