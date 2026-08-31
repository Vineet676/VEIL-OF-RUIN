class_name Player
extends CharacterBody2D

## Player controller for the 2D Metroidvania.
## Supports Scavenger and Initiate archetype paths.

enum PathType {
	SCAVENGER,
	INITIATE
}

@export_group("Archetype")
@export var current_path: PathType = PathType.SCAVENGER

@export_group("Movement Parameters")
@export var move_speed: float = 160.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0
@export var jump_velocity: float = -320.0
@export var jump_cut_multiplier: float = 0.5
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# Get gravity from project settings to match Godot defaults
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# Timers for responsive platforming feel
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump(delta)
	handle_horizontal_movement(delta)
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time

func handle_jump(delta: float) -> void:
	# Jump buffer countdown
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Input detection (supports custom action 'jump' or built-in 'ui_accept')
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	# Execute jump if buffered and coyote time is active
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Variable jump height: release button early to cut jump short
	if (Input.is_action_just_released("jump") or Input.is_action_just_released("ui_accept")) and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		# Fallback to UI actions if custom inputs are not yet mapped
		direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		# Flip sprite based on movement direction
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
