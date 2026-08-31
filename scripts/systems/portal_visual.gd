class_name PortalVisual
extends Node2D

## ASHEN CROWN — procedural portal/gate visual (no image assets required).
## A dark gothic arch frame with a swirling, pulsing energy rift in the middle.
## Builds everything with ColorRect/Polygon2D so it renders without textures.

@export var arch_width: float = 150.0
@export var arch_height: float = 300.0
@export var rift_color: Color = Color(0.45, 0.2, 0.75)
@export var rim_color: Color = Color(0.7, 0.5, 1.0)
@export var stone_color: Color = Color(0.12, 0.11, 0.15)

var _time: float = 0.0
var _rift: ColorRect
var _rim_top: ColorRect
var _rim_bottom: ColorRect
var _glow: Polygon2D

func _ready() -> void:
	_build()

func _build() -> void:
	# Frame posts (left / right).
	var post_w: float = 22.0
	var lpost := _make_rect(Color(stone_color.r, stone_color.g, stone_color.b, 1.0))
	lpost.size = Vector2(post_w, arch_height)
	lpost.position = Vector2(-arch_width * 0.5 - post_w, -arch_height * 0.5)
	add_child(lpost)
	var rpost := _make_rect(Color(stone_color.r, stone_color.g, stone_color.b, 1.0))
	rpost.size = Vector2(post_w, arch_height)
	rpost.position = Vector2(arch_width * 0.5, -arch_height * 0.5)
	add_child(rpost)
	# Arch lintel (top).
	var lintel := _make_rect(Color(stone_color.r, stone_color.g, stone_color.b, 1.0))
	lintel.size = Vector2(arch_width + post_w * 2.0, 26.0)
	lintel.position = Vector2(-arch_width * 0.5 - post_w, -arch_height * 0.5 - 26.0)
	add_child(lintel)
	# Rift (the portal energy).
	_rift = _make_rect(Color(rift_color.r, rift_color.g, rift_color.b, 0.85))
	_rift.size = Vector2(arch_width - 8.0, arch_height - 34.0)
	_rift.position = Vector2(-(_rift.size.x) * 0.5, -(_rift.size.y) * 0.5 + 4.0)
	add_child(_rift)
	# Rim glow bars on the rift edges.
	_rim_top = _make_rect(Color(rim_color.r, rim_color.g, rim_color.b, 0.9))
	_rim_top.size = Vector2(arch_width - 8.0, 8.0)
	_rim_top.position = Vector2(-(arch_width - 8.0) * 0.5, -(_rift.size.y) * 0.5 + 4.0)
	add_child(_rim_top)
	_rim_bottom = _make_rect(Color(rim_color.r, rim_color.g, rim_color.b, 0.9))
	_rim_bottom.size = Vector2(arch_width - 8.0, 8.0)
	_rim_bottom.position = Vector2(-(arch_width - 8.0) * 0.5, (_rift.size.y) * 0.5 - 4.0)
	add_child(_rim_bottom)
	# Soft glow behind (drawn as a translucent rounded polygon).
	_glow = Polygon2D.new()
	_glow.polygon = PackedVector2Array([
		Vector2(-arch_width * 0.8, -arch_height * 0.5),
		Vector2(arch_width * 0.8, -arch_height * 0.5),
		Vector2(arch_width * 0.8, arch_height * 0.5),
		Vector2(-arch_width * 0.8, arch_height * 0.5),
	])
	_glow.color = Color(rift_color.r, rift_color.g, rift_color.b, 0.25)
	add_child(_glow)

func _make_rect(col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _process(delta: float) -> void:
	_time += delta
	if _rift == null:
		return
	# Pulse the rift opacity and shift hue slightly for a living look.
	var pulse := 0.7 + 0.3 * sin(_time * 4.0)
	_rift.modulate = Color(1, 1, 1, 0.6 + 0.4 * pulse)
	var rim_pulse := 0.8 + 0.2 * sin(_time * 6.0 + 1.0)
	_rim_top.modulate = Color(1, 1, 1, rim_pulse)
	_rim_bottom.modulate = Color(1, 1, 1, rim_pulse)
