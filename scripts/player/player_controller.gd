class_name PlayerController
extends CharacterBody2D

## ASHEN CROWN - Cael player controller.
## Action-platformer movement + combat built on a lightweight state machine.
## Combat foundations are shared components (HealthComponent / Hitbox / Hurtbox).

signal state_changed(new_state: int, old_state: int)
signal attack_performed(combo_step: int)
signal attack_ended(combo_step: int)
signal parry_successful
signal parry_finished
signal dash_performed

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	WALL_SLIDE,
	WALL_JUMP,
	DASH,
	ATTACK,
	PARRY,
	SLIDE,
	SPECIAL,
	HURT,
	DEAD
}

# --- Movement ---------------------------------------------------------------
@export_group("Movement")
@export var max_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var air_acceleration: float = 1200.0
@export var friction: float = 2400.0
@export var air_friction: float = 600.0

# --- Jump --------------------------------------------------------------------
@export_group("Jump")
@export var jump_velocity: float = -620.0
@export var jump_cut_multiplier: float = 0.4
@export var gravity_multiplier: float = 1.2
@export var fall_gravity_multiplier: float = 2.0
@export var terminal_velocity: float = 1000.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12

# --- Wall --------------------------------------------------------------------
@export_group("Wall")
@export var wall_slide_speed: float = 120.0
@export var wall_jump_horiz: float = 420.0
@export var wall_jump_vert: float = -600.0
@export var wall_stick_time: float = 0.12
@export var wall_jump_lock_time: float = 0.15
@export var wall_jump_cooldown: float = 0.25

# --- Dash --------------------------------------------------------------------
@export_group("Dash")
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.5
@export var dash_invuln_time: float = 0.18
@export var air_dash_limit: int = 1

# --- Attack ------------------------------------------------------------------
@export_group("Attack")
@export var attack_damage: int = 1
@export var attack_knockback: float = 260.0
@export var attack_total_time: float = 0.4
@export var attack_active_start: float = 0.12
@export var attack_active_end: float = 0.22
@export var combo_window: float = 0.18
@export var attack_move_multiplier: float = 0.35
@export var attack_knockback_self: float = 90.0

# --- Parry -------------------------------------------------------------------
@export_group("Parry")
@export var parry_startup: float = 0.05
@export var parry_active: float = 0.12
@export var parry_recovery: float = 0.18
@export var parry_cooldown: float = 0.4

# --- Slide -------------------------------------------------------------------
@export_group("Slide")
@export var slide_speed: float = 620.0
@export var slide_duration: float = 0.45
@export var slide_cooldown: float = 0.6
@export var slide_slide_shape_height: float = 62.0   # lowered capsule height while sliding
@export var slide_normal_shape_height: float = 120.0 # standing capsule height

# --- Special Attack -----------------------------------------------------------
@export_group("Special")
@export var special_damage: int = 5
@export var special_startup: float = 0.30
@export var special_active: float = 0.12
@export var special_recovery: float = 0.35
@export var special_cooldown: float = 2.2
@export var special_knockback: float = 520.0
@export var special_range: float = 170.0   # hitbox is scaled larger for special

# --- Hurt --------------------------------------------------------------------
@export_group("Hurt")
@export var hurt_time: float = 0.35
@export var hurt_launch_y: float = -220.0

# Internal state
var state: int = State.IDLE
var facing: int = 1
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_stick_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0
var wall_jump_cooldown_timer: float = 0.0

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var air_dashes_used: int = 0

# Double jump tracking. On the ground jumps_used resets to 0; the first jump
# sets it to 1 and a mid-air second jump sets it to 2 (maximum two jumps).
var jumps_used: int = 0

var combo_step: int = 0
var combo_buffer: bool = false
var attack_timer: float = 0.0

var parry_timer: float = 0.0
var parry_cooldown_timer: float = 0.0

# Slide state
var slide_timer: float = 0.0
var slide_cooldown_timer: float = 0.0

# Special attack state
var special_timer: float = 0.0
var special_cooldown_timer: float = 0.0

# Fall-damage tracking
var _fall_start_y: float = 0.0
var _was_on_floor: bool = true

var hurt_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interact_area: Area2D = $InteractArea
@onready var interact_prompt: Label = $InteractPrompt

const INTERACT_COOLDOWN: float = 0.25
var _interact_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("player")
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hurtbox.damage_received.connect(_on_hurtbox_damage)

	attack_hitbox.hit_landed.connect(_on_attack_landed)
	_set_state(State.IDLE)
	# Register with the GameManager autoload so death/respawn and stage state work.
	var gm: Node = get_tree().root.get_node_or_null("GameManager")
	if gm != null:
		gm.call("register_player", self)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if _interact_cooldown > 0.0:
		_interact_cooldown -= delta
	_buffer_inputs()
	_handle_jump_cut()

	match state:
		State.IDLE, State.RUN:
			_handle_ground_movement(delta)
		State.JUMP, State.FALL:
			_handle_air_movement(delta)
		State.WALL_SLIDE:
			_handle_wall_slide(delta)
		State.WALL_JUMP:
			_handle_wall_jump(delta)
		State.DASH:
			_handle_dash(delta)
		State.ATTACK:
			_handle_attack(delta)
		State.PARRY:
			_handle_parry(delta)
		State.SLIDE:
			_handle_slide(delta)
		State.SPECIAL:
			_handle_special(delta)
		State.HURT:
			_handle_hurt(delta)
		State.DEAD:
			_handle_dead(delta)

	move_and_slide()
	_update_animation()
	_handle_interact()

# --------------------------------------------------------------------------
# Timers & input buffering
# --------------------------------------------------------------------------
func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	wall_stick_timer = max(0.0, wall_stick_timer - delta)
	wall_jump_lock_timer = max(0.0, wall_jump_lock_timer - delta)
	wall_jump_cooldown_timer = max(0.0, wall_jump_cooldown_timer - delta)
	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	parry_cooldown_timer = max(0.0, parry_cooldown_timer - delta)
	slide_cooldown_timer = max(0.0, slide_cooldown_timer - delta)
	special_cooldown_timer = max(0.0, special_cooldown_timer - delta)

	# Track fall distance for fall damage.
	if is_on_floor():
		if not _was_on_floor:
			_resolve_fall_landing()
		_was_on_floor = true
		_fall_start_y = global_position.y
	else:
		if _was_on_floor:
			_fall_start_y = global_position.y
		_was_on_floor = false

	if is_on_floor():
		air_dashes_used = 0
		jumps_used = 0

func _buffer_inputs() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Combo buffer: LMB pressed during the recovery window of an attack queues the next step.
	if Input.is_action_just_pressed("light_attack") and state == State.ATTACK and attack_timer >= attack_total_time - combo_window:
		combo_buffer = true

func _handle_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

# --------------------------------------------------------------------------
# Wall helpers
# --------------------------------------------------------------------------
func _wall_dir() -> int:
	if wall_check_left.is_colliding():
		return -1
	if wall_check_right.is_colliding():
		return 1
	return 0

func _can_wall_action() -> bool:
	return wall_jump_lock_timer <= 0.0 and wall_jump_cooldown_timer <= 0.0

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := gravity
	if velocity.y > 0.0:
		g = gravity * fall_gravity_multiplier
	else:
		g = gravity * gravity_multiplier
	velocity.y = min(velocity.y + g * delta, terminal_velocity)

# --------------------------------------------------------------------------
# Ground movement (IDLE / RUN)
# --------------------------------------------------------------------------
func _handle_ground_movement(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")

	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, acceleration * delta)
		if state != State.RUN:
			_set_state(State.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		if state != State.IDLE:
			_set_state(State.IDLE)

	if state == State.RUN:
		facing = 1 if dir > 0 else -1

	if _can_jump():
		_do_jump()
		return

	if not is_on_floor():
		_set_state(State.FALL)
		return

	_try_attack_or_parry_or_dash()

# --------------------------------------------------------------------------
# Air movement (JUMP / FALL)
# --------------------------------------------------------------------------
func _handle_air_movement(delta: float) -> void:
	_apply_gravity(delta)
	var dir := Input.get_axis("move_left", "move_right")

	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, air_acceleration * delta)
		facing = 1 if dir > 0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_friction * delta)

	var wdir := _wall_dir()
	if wdir != 0 and velocity.y > 0.0 and _can_wall_action() and not is_on_floor():
		wall_stick_timer = wall_stick_time
		_set_state(State.WALL_SLIDE)
		return

	# Wall jump from the air when buffering jump while touching a wall.
	if wdir != 0 and jump_buffer_timer > 0.0 and _can_wall_action():
		_do_wall_jump(wdir)
		return

	# Double jump: a buffered jump while airborne (not hugging a wall) with a
	# jump still available triggers the second jump.
	if jump_buffer_timer > 0.0 and _can_double_jump():
		_do_double_jump()
		return

	if is_on_floor():
		_set_state(State.IDLE if Input.get_axis("move_left", "move_right") == 0.0 else State.RUN)
		return

	if velocity.y < 0.0 and state != State.JUMP:
		_set_state(State.JUMP)
	elif velocity.y >= 0.0 and state != State.FALL:
		_set_state(State.FALL)

	_try_attack_or_parry_or_dash()

# --------------------------------------------------------------------------
# Wall slide
# --------------------------------------------------------------------------
func _handle_wall_slide(delta: float) -> void:
	_apply_gravity(delta)
	velocity.y = min(velocity.y, wall_slide_speed)

	var dir := Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, dir * max_speed, acceleration * delta)

	if jump_buffer_timer > 0.0:
		var wdir := _wall_dir()
		if wdir != 0:
			_do_wall_jump(wdir)
			return

	wall_stick_timer -= delta
	if _wall_dir() == 0 or wall_stick_timer <= 0.0:
		_set_state(State.FALL)
		return

	if is_on_floor():
		_set_state(State.IDLE if Input.get_axis("move_left", "move_right") == 0.0 else State.RUN)
		return

	_try_attack_or_parry_or_dash()

# --------------------------------------------------------------------------
# Wall jump (brief control-lock state)
# --------------------------------------------------------------------------
func _handle_wall_jump(delta: float) -> void:
	_apply_gravity(delta)
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, air_acceleration * 0.35 * delta)

	if is_on_floor():
		_set_state(State.IDLE if Input.get_axis("move_left", "move_right") == 0.0 else State.RUN)
	elif velocity.y >= 0.0:
		_set_state(State.FALL)
	else:
		_set_state(State.JUMP)

# --------------------------------------------------------------------------
# Dash
# --------------------------------------------------------------------------
func _handle_dash(delta: float) -> void:
	dash_timer += delta
	velocity.x = facing * dash_speed
	velocity.y = 0.0

	if dash_timer >= dash_duration:
		velocity.x *= 0.4
		if is_on_floor():
			_set_state(State.IDLE if Input.get_axis("move_left", "move_right") == 0.0 else State.RUN)
		else:
			_set_state(State.FALL)

# --------------------------------------------------------------------------
# Attack (3-hit combo)
# --------------------------------------------------------------------------
func _handle_attack(delta: float) -> void:
	attack_timer += delta

	# Movement allowed but restricted during the strongest (active) frames.
	var in_active := attack_timer >= attack_active_start and attack_timer <= attack_active_end
	var move_mult := (1.0 if not in_active else attack_move_multiplier)
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed * move_mult, acceleration * delta * 0.7)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Hitbox active window.
	if in_active and not attack_hitbox.is_active():
		attack_hitbox.enable()
	elif not in_active and attack_hitbox.is_active():
		attack_hitbox.disable()

	if attack_timer >= attack_total_time:
		attack_hitbox.disable()
		if combo_buffer and combo_step < 3:
			_start_attack(combo_step + 1)
		else:
			attack_ended.emit(combo_step)
			combo_step = 0
			combo_buffer = false
			_return_to_movement()

# --------------------------------------------------------------------------
# Parry
# --------------------------------------------------------------------------
func _handle_parry(delta: float) -> void:
	parry_timer += delta
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	var total := parry_startup + parry_active + parry_recovery
	if parry_timer >= total:
		parry_finished.emit()
		parry_cooldown_timer = parry_cooldown
		_return_to_movement()

# --------------------------------------------------------------------------
# Slide
# --------------------------------------------------------------------------
func _handle_slide(delta: float) -> void:
	slide_timer += delta
	velocity.x = facing * slide_speed
	if not is_on_floor():
		_end_slide()
		_set_state(State.FALL)
		return
	if slide_timer >= slide_duration:
		_end_slide()

# --------------------------------------------------------------------------
# Special attack
# --------------------------------------------------------------------------
func _handle_special(delta: float) -> void:
	special_timer += delta
	velocity.x = move_toward(velocity.x, 0.0, friction * delta * 0.5)
	var active := special_timer >= special_startup and special_timer <= special_startup + special_active
	if active:
		if not attack_hitbox.is_active():
			attack_hitbox.base_damage = special_damage
			attack_hitbox.knockback_force = special_knockback
			attack_hitbox.position.x = facing * special_range
			attack_hitbox.enable()
	elif attack_hitbox.is_active():
		attack_hitbox.disable()
	var total := special_startup + special_active + special_recovery
	if special_timer >= total:
		attack_hitbox.disable()
		attack_hitbox.base_damage = attack_damage
		attack_hitbox.knockback_force = attack_knockback
		attack_hitbox.position.x = facing * abs(attack_hitbox.position.x)
		special_cooldown_timer = special_cooldown
		_return_to_movement()

# --------------------------------------------------------------------------
# Hurt
# --------------------------------------------------------------------------
func _handle_hurt(delta: float) -> void:
	hurt_timer -= delta
	_apply_gravity(delta)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if hurt_timer <= 0.0:
		_return_to_movement()

# --------------------------------------------------------------------------
# Dead
# --------------------------------------------------------------------------
func _handle_dead(_delta: float) -> void:
	velocity = Vector2.ZERO

# --------------------------------------------------------------------------
# Actions
# --------------------------------------------------------------------------
func _can_jump() -> bool:
	return coyote_timer > 0.0 and jump_buffer_timer > 0.0

func _do_jump() -> void:
	jumps_used = 1
	velocity.y = jump_velocity
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_set_state(State.JUMP)

## True if the player may perform a double jump right now: airborne, not hugging
## a wall, and still under the two-jump limit.
func _can_double_jump() -> bool:
	return not is_on_floor() and _wall_dir() == 0 and jumps_used < 2

func _do_double_jump() -> void:
	jumps_used += 1
	velocity.y = jump_velocity
	jump_buffer_timer = 0.0
	_set_state(State.JUMP)

func _do_wall_jump(wdir: int) -> void:
	velocity = Vector2(-wdir * wall_jump_horiz, wall_jump_vert)
	facing = -wdir
	jump_buffer_timer = 0.0
	wall_jump_lock_timer = wall_jump_lock_time
	wall_jump_cooldown_timer = wall_jump_cooldown
	_set_state(State.WALL_JUMP)

func _start_dash() -> void:
	if dash_cooldown_timer > 0.0:
		return
	if not is_on_floor() and air_dashes_used >= air_dash_limit:
		return
	attack_hitbox.disable()
	dash_timer = 0.0
	dash_cooldown_timer = dash_cooldown
	health.set_invulnerable(dash_invuln_time)
	velocity = Vector2(facing * dash_speed, 0.0)
	dash_performed.emit()
	_set_state(State.DASH)

func _start_attack(step: int) -> void:
	combo_step = step
	combo_buffer = false
	attack_timer = 0.0
	attack_hitbox.disable()
	# Ensure normal attacks never inherit special-attack damage/knockback.
	attack_hitbox.base_damage = attack_damage
	attack_hitbox.knockback_force = attack_knockback
	velocity.x *= 0.5
	attack_performed.emit(step)
	anim.play("attack")
	_set_state(State.ATTACK)

func _start_parry() -> void:
	if parry_cooldown_timer > 0.0:
		return
	attack_hitbox.disable()
	parry_timer = 0.0
	velocity.x = 0.0
	_set_state(State.PARRY)

func _start_slide() -> void:
	attack_hitbox.disable()
	slide_timer = 0.0
	slide_cooldown_timer = slide_cooldown
	velocity = Vector2(facing * slide_speed, 0.0)
	# Lower the capsule so Cael can pass under low obstacles.
	if body_shape and body_shape.shape is CapsuleShape2D:
		(body_shape.shape as CapsuleShape2D).height = slide_slide_shape_height
		body_shape.position.y = 100.0 - (slide_normal_shape_height - slide_slide_shape_height) * 0.5
	_set_state(State.SLIDE)

func _end_slide() -> void:
	if body_shape and body_shape.shape is CapsuleShape2D:
		(body_shape.shape as CapsuleShape2D).height = slide_normal_shape_height
		body_shape.position.y = 100.0

func _start_special() -> void:
	attack_hitbox.disable()
	special_timer = 0.0
	velocity.x *= 0.3
	_set_state(State.SPECIAL)

func _resolve_fall_landing() -> void:
	# Fall damage is distance-based. Tiny drops deal none; secret-drop landings
	# are marked with the "safe_landing" group so they are exempt.
	if _was_on_floor:
		return
	if is_in_group("fall_damage_disabled"):
		_fall_start_y = global_position.y
		return
	var dist := _fall_start_y - global_position.y
	if dist < 280.0:
		_fall_start_y = global_position.y
		return
	var fall_dmg := 0
	if dist >= 280.0 and dist < 420.0:
		fall_dmg = 5
	elif dist >= 420.0 and dist < 600.0:
		fall_dmg = 12
	else:
		fall_dmg = 25
	var info := DamageInfo.new()
	info.amount = fall_dmg
	info.knockback = Vector2.ZERO
	info.source = self
	health.take_damage(info)
	_fall_start_y = global_position.y

func _try_attack_or_parry_or_dash() -> void:
	if Input.is_action_just_pressed("light_attack"):
		_start_attack(1)
	elif Input.is_action_just_pressed("parry"):
		_start_parry()
	elif Input.is_action_just_pressed("dash"):
		_start_dash()
	elif Input.is_action_just_pressed("slide") and is_on_floor() and slide_cooldown_timer <= 0.0:
		_start_slide()
	elif Input.is_action_just_pressed("skill_1") and special_cooldown_timer <= 0.0:
		_start_special()

# --------------------------------------------------------------------------
# Interaction (E)
# --------------------------------------------------------------------------
func _handle_interact() -> void:
	# No interactions while a dialogue is open (gameplay paused anyway).
	var dm: Node = get_tree().get_first_node_in_group("dialogue_manager")
	if dm and dm.get("is_active"):
		interact_prompt.visible = false
		return
	var nearest: Interactable = _nearest_interactable()
	if nearest != null:
		interact_prompt.visible = nearest.prompt != "" if nearest.auto_prompt else false
		if Input.is_action_just_pressed("interact") and _can_interact() and _interact_cooldown <= 0.0:
			_interact_cooldown = INTERACT_COOLDOWN
			nearest.interact(self)
	else:
		interact_prompt.visible = false

func _can_interact() -> bool:
	return state != State.DEAD and state != State.HURT

func _nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_dist: float = INF
	for area in interact_area.get_overlapping_areas():
		if area is Interactable:
			var d: float = global_position.distance_squared_to(area.global_position)
			if d < best_dist:
				best_dist = d
				best = area
	return best

## Revive Cael at a given position after death (called by GameManager).
func respawn() -> void:
	if not is_inside_tree():
		return
	health.current_health = health.max_health
	health.invulnerable = false
	health.health_changed.emit(health.current_health, health.max_health)
	velocity = Vector2.ZERO
	hurt_timer = 0.0
	dash_cooldown_timer = 0.0
	attack_hitbox.disable()
	_set_state(State.IDLE)

func _return_to_movement() -> void:
	if is_on_floor():
		var dir := Input.get_axis("move_left", "move_right")
		_set_state(State.RUN if dir != 0.0 else State.IDLE)
	else:
		_set_state(State.FALL if velocity.y >= 0.0 else State.JUMP)

# --------------------------------------------------------------------------
# Damage / health handling
# --------------------------------------------------------------------------
func _on_hurtbox_damage(damage: DamageInfo) -> void:
	# Lethal environmental hazards (spikes) cannot be parried — instant death.
	if damage.source is Hazard and damage.source.get("lethal"):
		_take_damage(damage)
		return
	# A hit landing during the parry's active window is negated with a parry response.
	if state == State.PARRY and _in_parry_active_window():
		_do_parry_success(damage)
		return
	_take_damage(damage)

func _do_parry_success(damage: DamageInfo) -> void:
	parry_successful.emit()
	# Stagger the attacker: push it back along its incoming direction.
	var source: Node = damage.source
	if source is Node2D:
		var src: Node2D = source as Node2D
		var away: Vector2 = (global_position - src.global_position).normalized()
		if away.length() < 0.01:
			away = Vector2.LEFT if facing > 0 else Vector2.RIGHT
		_stagger_attacker(src, away)
	# Shorten the rest of the parry into a snappy response.
	parry_timer = parry_startup + parry_active

func _in_parry_active_window() -> bool:
	return parry_timer >= parry_startup and parry_timer <= parry_startup + parry_active

func _stagger_attacker(target: Node2D, direction: Vector2) -> void:
	# If the attacker exposes a stagger interface, use it (enemies later).
	if target.has_method("on_stagger"):
		target.call("on_stagger", direction * 300.0)
	elif target is CharacterBody2D:
		target.velocity = direction * 300.0

func _take_damage(damage: DamageInfo) -> void:
	if state == State.DEAD:
		return
	health.take_damage(damage)

func _on_damaged(damage: DamageInfo) -> void:
	if state == State.DEAD:
		return
	attack_hitbox.disable()
	_end_slide()
	hurt_timer = hurt_time
	velocity = damage.knockback
	if velocity.y >= 0.0:
		velocity.y = hurt_launch_y
	_set_state(State.HURT)

func _on_died() -> void:
	attack_hitbox.disable()
	_end_slide()
	velocity = Vector2.ZERO
	_set_state(State.DEAD)

func _on_health_changed(_current: int, _maximum: int) -> void:
	pass

func _on_attack_landed(_target: Node2D, _damage: DamageInfo) -> void:
	# Slight forward lunge on landing a hit.
	if state == State.ATTACK:
		velocity.x = facing * attack_knockback_self * 0.5

# --------------------------------------------------------------------------
# State & animation
# --------------------------------------------------------------------------
func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	state_changed.emit(new_state, old)

func _state_to_anim() -> StringName:
	match state:
		State.IDLE:
			return &"idle"
		State.RUN:
			return &"run"
		State.JUMP:
			return &"jump"
		State.FALL:
			return &"fall"
		State.WALL_SLIDE:
			return &"wall_slide"
		State.WALL_JUMP:
			return &"wall_jump"
		State.DASH:
			return &"dash"
		State.ATTACK:
			return &"attack"
		State.PARRY:
			return &"parry"
		State.SLIDE:
			return &"slide"
		State.SPECIAL:
			return &"special"
		State.HURT:
			return &"hurt"
		State.DEAD:
			return &"dead"
	return &"idle"

func _update_animation() -> void:
	anim.flip_h = facing < 0
	# Keep the attack hitbox on the correct side of the player.
	attack_hitbox.position.x = facing * abs(attack_hitbox.position.x)
	# Attack controls its own animation start per combo step.
	if state == State.ATTACK:
		return
	var target := _state_to_anim()
	if anim.animation != target:
		anim.play(target)
