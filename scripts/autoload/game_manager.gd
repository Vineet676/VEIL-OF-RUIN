extends Node

## ASHEN CROWN — lightweight game/stage state autoload.
## Tracks the current stage, the player, the active checkpoint and handles
## stage transitions + player respawn. Deliberately small; does not own
## dialogue, save files, audio or difficulty (those are later phases).

signal stage_changed(stage_id: String)
signal checkpoint_activated(position: Vector2)

## Ordered stage progression. The final entry (crown_arena) is the terminus.
const STAGE_ORDER: Array[String] = [
	"stage_1", "stage_2", "stage_3", "stage_4", "stage_5", "crown_arena"
]

const STAGE_SCENES: Dictionary = {
	"stage_1": "res://scenes/stages/stage_1_scavenger/stage_1_scavenger.tscn",
	"stage_2": "res://scenes/stages/stage_2_citadel/stage_2_citadel.tscn",
	"stage_3": "res://scenes/stages/stage_3_collapse/stage_3_collapse.tscn",
	"stage_4": "res://scenes/stages/stage_4_descent/stage_4_descent.tscn",
	"stage_5": "res://scenes/stages/stage_5_chamber/stage_5_chamber.tscn",
	"crown_arena": "res://scenes/stages/crown_arena/crown_arena.tscn",
}

@export var respawn_delay: float = 1.2

## Metroidvania foundation: ability flags the player can unlock (later phases
## grant them via pickups/bosses). Locked gates/doors can check these.
var has_dash: bool = false
var has_double_jump: bool = false
var has_wall_jump: bool = false

## Convenience for gates: true if the player possesses a given ability name.
func has_ability(ability: String) -> bool:
	match ability:
		"dash":
			return has_dash
		"double_jump":
			return has_double_jump
		"wall_jump":
			return has_wall_jump
	return false

## Grant an ability by name (called by ability shrines / pickups). Extensible
## for future abilities.
func grant_ability(ability: String) -> void:
	match ability:
		"dash":
			has_dash = true
		"double_jump":
			has_double_jump = true
		"wall_jump":
			has_wall_jump = true

var current_stage: String = ""
var has_checkpoint: bool = false
var checkpoint_pos := Vector2.ZERO

var _player: PlayerController = null
var _default_spawn := Vector2.ZERO
var _respawn_timer: Timer

func _ready() -> void:
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_respawn_player)
	add_child(_respawn_timer)

## Called by the player (or stage) when a player enters the tree.
func register_player(player: PlayerController) -> void:
	_player = player
	_default_spawn = player.global_position
	has_checkpoint = false
	if not player.health.died.is_connected(_on_player_died):
		player.health.died.connect(_on_player_died)

## Called by a Checkpoint on activation.
func activate_checkpoint(position: Vector2) -> void:
	checkpoint_pos = position
	has_checkpoint = true
	checkpoint_activated.emit(position)

func _on_player_died() -> void:
	if _respawn_timer.is_stopped():
		_respawn_timer.start(respawn_delay)

func _respawn_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var pos: Vector2 = checkpoint_pos if has_checkpoint else _default_spawn
	_player.global_position = pos
	_player.respawn()

## Transition to a named stage, loading its scene.
func goto_stage(stage_id: String) -> void:
	if not STAGE_SCENES.has(stage_id):
		push_error("GameManager: unknown stage '%s'" % stage_id)
		return
	current_stage = stage_id
	stage_changed.emit(stage_id)
	# Defer the scene change so it never happens inside a physics callback
	# (stage transitions can be triggered from _physics_process / body_entered,
	# which would otherwise error removing CollisionObjects mid-physics).
	call_deferred("_change_scene_to", stage_id)

func _change_scene_to(stage_id: String) -> void:
	get_tree().change_scene_to_file(STAGE_SCENES[stage_id])

## Advance to the next stage in the linear progression.
func transition_next() -> void:
	var idx: int = STAGE_ORDER.find(current_stage)
	if idx < 0:
		goto_stage(STAGE_ORDER[0])
		return
	if idx + 1 < STAGE_ORDER.size():
		goto_stage(STAGE_ORDER[idx + 1])
	else:
		# Terminus reached (crown_arena). Victory/ending handled in a later phase.
		pass

func current_stage_index() -> int:
	return STAGE_ORDER.find(current_stage)
