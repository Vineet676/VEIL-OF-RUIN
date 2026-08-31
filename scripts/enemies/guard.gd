class_name Guard
extends BaseEnemy

## The Guard: a slow melee enemy that patrols, detects the player within a
## finite range, chases, and performs a telegraphed spear-thrust attack with a
## startup/active/recovery window and a cooldown.

# --- Guard tuning -----------------------------------------------------------
@export var patrol_left: float = 300.0
@export var patrol_right: float = 700.0
@export var attack_range: float = 110.0
@export var attack_startup: float = 0.5
@export var attack_active: float = 0.18
@export var attack_recovery: float = 0.3
@export var attack_cooldown: float = 1.2
@export var detect_pause: float = 0.4
@export var idle_pause: float = 0.6

var _attack_phase: int = 0            # 0 startup, 1 active, 2 recovery
var _attack_phase_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _detect_timer: float = 0.0
var _idle_timer: float = 0.0

@onready var attack_hitbox: Hitbox = $AttackHitbox

func _ready() -> void:
	super._ready()
	_idle_timer = idle_pause

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _tick_state(delta: float) -> void:
	_attack_cooldown_timer = max(0.0, _attack_cooldown_timer - delta)
	match state:
		EnemyState.IDLE:
			_tick_idle(delta)
		EnemyState.PATROL:
			_tick_patrol(delta)
		EnemyState.DETECT:
			_tick_detect(delta)
		EnemyState.CHASE:
			_tick_chase(delta)
		EnemyState.ATTACK:
			_tick_attack(delta)

func _tick_idle(delta: float) -> void:
	velocity.x = 0.0
	if _can_detect():
		_detect_pause_start()
		return
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_set_state(EnemyState.PATROL)

func _tick_patrol(_delta: float) -> void:
	if _can_detect():
		_detect_pause_start()
		return
	var lo: float = min(patrol_left, patrol_right)
	var hi: float = max(patrol_left, patrol_right)
	if global_position.x <= lo:
		facing = 1
	elif global_position.x >= hi:
		facing = -1
	velocity.x = facing * move_speed

func _tick_detect(delta: float) -> void:
	velocity.x = 0.0
	_face_target()
	_detect_timer -= delta
	if _detect_timer <= 0.0:
		_set_state(EnemyState.CHASE)

func _tick_chase(_delta: float) -> void:
	if not _has_target():
		_set_state(EnemyState.IDLE)
		return
	var dist: float = _distance_to_target()
	if dist > detection_range:
		_idle_timer = idle_pause
		_set_state(EnemyState.IDLE)
		return
	_face_target()
	if dist <= attack_range and _attack_cooldown_timer <= 0.0:
		_start_attack()
		return
	velocity.x = facing * move_speed

func _tick_attack(_delta: float) -> void:
	velocity.x = 0.0
	_face_target()
	_attack_phase_timer -= _delta
	if _attack_phase == 0:  # startup / telegraph
		if _attack_phase_timer <= 0.0:
			_attack_phase = 1
			_attack_phase_timer = attack_active
			attack_hitbox.enable()
	elif _attack_phase == 1:  # active
		if _attack_phase_timer <= 0.0:
			_attack_phase = 2
			_attack_phase_timer = attack_recovery
			attack_hitbox.disable()
	else:  # recovery
		if _attack_phase_timer <= 0.0:
			_attack_cooldown_timer = attack_cooldown
			_set_state(EnemyState.CHASE)

# --- Helpers ----------------------------------------------------------------
func _can_detect() -> bool:
	return _has_target() and _distance_to_target() <= detection_range

func _detect_pause_start() -> void:
	_detect_timer = detect_pause
	_face_target()
	_set_state(EnemyState.DETECT)

func _start_attack() -> void:
	_set_state(EnemyState.ATTACK)
	_attack_phase = 0
	_attack_phase_timer = attack_startup
	velocity.x = 0.0
	_face_target()

func _play_state_animation(new_state: int) -> void:
	if not is_inside_tree():
		return
	match new_state:
		EnemyState.IDLE, EnemyState.DETECT:
			anim.play("idle")
		EnemyState.PATROL, EnemyState.CHASE:
			anim.play("walk")
		EnemyState.ATTACK:
			anim.play("attack")
		EnemyState.HURT, EnemyState.STAGGER:
			attack_hitbox.disable()
			anim.play("hurt")
		EnemyState.DEAD:
			attack_hitbox.disable()
			anim.play("die")

func _apply_facing() -> void:
	super._apply_facing()
	if is_instance_valid(attack_hitbox):
		attack_hitbox.position.x = facing * abs(attack_hitbox.position.x)
