class_name TestDummy
extends StaticBody2D

## A reusable combat test target (not an enemy). Lets us verify the player's
## attack hitbox, 3-hit combo, knockback and damage pipeline during Phase 1.

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Polygon2D = $Visual

var _base_color: Color = Color.WHITE
var _dead: bool = false
var _flash_tween: Tween

func _ready() -> void:
	_base_color = visual.color
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hurtbox.damage_received.connect(_on_hurtbox_damage)

func _on_hurtbox_damage(damage: DamageInfo) -> void:
	health.take_damage(damage)

func _on_damaged(_damage: DamageInfo) -> void:
	if _dead:
		return
	if _flash_tween:
		_flash_tween.kill()
	visual.color = Color(1.0, 0.45, 0.45)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.08)
	_flash_tween.tween_callback(func() -> void:
		if not _dead:
			visual.color = _base_color
	)

func _on_died() -> void:
	_dead = true
	if _flash_tween:
		_flash_tween.kill()
	visual.color = Color(0.22, 0.22, 0.28)
