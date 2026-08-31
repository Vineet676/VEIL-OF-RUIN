class_name BaseEnemy
extends CharacterBody2D

## Reusable enemy base (CharacterBody2D) shared by Guard, Broken, Machine, bosses.
## Provides: health, hurtbox, knockback, hurt/stagger interruption, death,
## a guarded state machine, target tracking and facing — without duplicating
## health/damage logic per enemy.

enum EnemyState { IDLE, PATROL, DETECT, CHASE, ATTACK, HURT, STAGGER, DEAD }

signal state_changed(new_state: int, old_state: int)
signal died

# --- Tuning (exposed) -------------------------------------------------------
@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var gravity: float = 980.0
@export var detection_range: float = 320.0
@export var knockback_resistance: float = 0.6
@export var knockback_friction: float = 900.0
@export var hurt_time: float = 0.25
@export var stagger_time: float = 0.7
@export var death_free_time: float = 2.2

# --- Runtime state ----------------------------------------------------------
var state: int = EnemyState.IDLE
var facing: int = 1
var target: Node2D = null
var hurt_timer: float = 0.0
var stagger_timer: float = 0.0
var death_timer: float = 0.0
var _prev_state: int = EnemyState.IDLE

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	health.max_health = max_health
	health.current_health = max_health
	health.died.connect(_on_health_died)
	health.damaged.connect(_on_health_damaged)
	hurtbox.damage_received.connect(_on_damage_received)
	if target == null:
		target = _acquire_target()
	_set_state(EnemyState.IDLE)

func _physics_process(delta: float) -> void:
	if not _has_target():
		target = _acquire_target()
	if state == EnemyState.DEAD:
		_tick_death(delta)
		return
	_tick_timers(delta)
	_apply_gravity(delta)
	if state == EnemyState.HURT or state == EnemyState.STAGGER:
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
	_tick_state(delta)
	move_and_slide()
	_apply_facing()

# --------------------------------------------------------------------------
# Virtual hooks for subclasses
# --------------------------------------------------------------------------
func _tick_state(_delta: float) -> void:
	pass

## Play / update the correct animation for the current state.
func _play_state_animation(_new_state: int) -> void:
	pass

# --------------------------------------------------------------------------
# Timers / physics helpers
# --------------------------------------------------------------------------
func _tick_timers(delta: float) -> void:
	if state == EnemyState.HURT:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			_set_state(_prev_state)
	if state == EnemyState.STAGGER:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			_set_state(_prev_state)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _apply_facing() -> void:
	anim.flip_h = facing < 0

# --------------------------------------------------------------------------
# Target helpers
# --------------------------------------------------------------------------
func _distance_to_target() -> float:
	if target == null or not is_instance_valid(target):
		return INF
	return global_position.distance_to(target.global_position)

func _has_target() -> bool:
	return target != null and is_instance_valid(target)

## Robustly find the player: prefer the "player" group, fall back to searching
## the tree for a PlayerController CharacterBody2D.
func _acquire_target() -> Node2D:
	var p: Node = get_tree().get_first_node_in_group("player")
	if p is Node2D:
		return p
	for node in get_tree().root.find_children("*", "CharacterBody2D", true, false):
		if node != self and node is PlayerController:
			return node
	return null

func _face_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	facing = 1 if target.global_position.x >= global_position.x else -1

func _facing_toward_target() -> bool:
	if target == null or not is_instance_valid(target):
		return true
	return (target.global_position.x >= global_position.x) == (facing >= 0)

# --------------------------------------------------------------------------
# State machine (guarded)
# --------------------------------------------------------------------------
func _set_state(new_state: int) -> void:
	if state == EnemyState.DEAD and new_state != EnemyState.DEAD:
		return  # DEAD is terminal; no transition out
	if new_state == state:
		return
	var old := state
	state = new_state
	state_changed.emit(new_state, old)
	_play_state_animation(new_state)

# --------------------------------------------------------------------------
# Damage / hurt / stagger / death
# --------------------------------------------------------------------------
func _on_damage_received(damage: DamageInfo) -> void:
	if state == EnemyState.DEAD:
		return
	var kb: Vector2 = damage.knockback * (1.0 - knockback_resistance)
	if kb.length() > 0.0:
		velocity = kb
	health.take_damage(damage)

func _on_health_damaged(_damage: DamageInfo) -> void:
	if state == EnemyState.DEAD:
		return
	_remember_interrupt_state()
	_set_state(EnemyState.HURT)
	hurt_timer = hurt_time
	anim.modulate = Color(1.0, 0.45, 0.45)
	create_tween().tween_property(anim, "modulate", Color.WHITE, 0.25)

## Called by the player's parry to interrupt and stagger this enemy.
func on_stagger(direction: Vector2) -> void:
	if state == EnemyState.DEAD:
		return
	_remember_interrupt_state()
	_set_state(EnemyState.STAGGER)
	stagger_timer = stagger_time
	velocity = direction

func _remember_interrupt_state() -> void:
	if state == EnemyState.HURT or state == EnemyState.STAGGER:
		return
	_prev_state = state

func _on_health_died() -> void:
	_set_state(EnemyState.DEAD)
	_disable_combat()
	_play_state_animation(EnemyState.DEAD)
	death_timer = death_free_time
	died.emit()

func _disable_combat() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hurtbox.monitoring = false
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		if child is Hitbox:
			child.disable()

func _tick_death(delta: float) -> void:
	death_timer -= delta
	velocity = Vector2.ZERO
	if not is_on_floor():
		_apply_gravity(delta)
	move_and_slide()
	if death_timer <= 0.0:
		queue_free()
