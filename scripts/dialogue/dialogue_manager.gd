class_name DialogueManager
extends Node
## ASHEN CROWN — reusable dialogue system.
## Single autoload ("DialogueManager") that owns one on-screen dialogue box.
## It supports a speaker name, multiple lines, and optional branching choices.
## While active it pauses the whole tree (player/enemies freeze) so the player
## cannot move or attack; the box itself keeps processing (process_mode ALWAYS).

signal dialogue_started
signal dialogue_ended

## The active line set. Each entry:
##   { "speaker": String, "text": String, "choices": [ { "text": String, "next": int } ] }
## "choices" is optional. "next" is an index into the line set, or -1 to close.
var active_lines: Array = []
var _index: int = 0

var _ui: CanvasLayer = null
var _panel: PanelContainer = null
var _speaker_label: Label = null
var _text_label: Label = null
var _choices_box: VBoxContainer = null
var _hint_label: Label = null
var _choice_labels: Array[Label] = []

var _selection: int = 0
var _choice_map: Array[Dictionary] = []

## True while a dialogue is open (gameplay is paused).
var is_active: bool = false

func _ready() -> void:
	# Must keep receiving input and stay visible even while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_manager")
	_build_ui()

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 20
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -430.0
	_panel.offset_right = 430.0
	_panel.offset_top = -220.0
	_panel.offset_bottom = -40.0
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.04, 0.07, 0.95)
	st.border_color = Color(0.78, 0.62, 0.22, 1.0)
	st.set_border_width_all(3)
	st.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", st)
	_ui.add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 18)
	_speaker_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.3))
	v.add_child(_speaker_label)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(820, 96)
	_text_label.add_theme_font_size_override("font_size", 17)
	_text_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.86))
	v.add_child(_text_label)

	_choices_box = VBoxContainer.new()
	_choices_box.visible = false
	_choices_box.add_theme_constant_override("separation", 2)
	v.add_child(_choices_box)

	_hint_label = Label.new()
	_hint_label.text = "E — continue"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	v.add_child(_hint_label)

	_ui.visible = false

## Start a dialogue. lines: Array[Dictionary] as documented above.
func start_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return
	active_lines = lines
	_index = 0
	_selection = 0
	is_active = true
	get_tree().paused = true
	_show_line()
	_ui.visible = true
	dialogue_started.emit()

func _show_line() -> void:
	if _index < 0 or _index >= active_lines.size():
		_end_dialogue()
		return
	var line: Dictionary = active_lines[_index]
	_speaker_label.text = line.get("speaker", "")
	_text_label.text = line.get("text", "")
	var choices: Array = line.get("choices", [])
	_choices_box.visible = not choices.is_empty()
	_hint_label.text = "E — continue" if choices.is_empty() else "W/S select — E confirm"
	for c in _choice_labels:
		if is_instance_valid(c):
			c.queue_free()
	_choice_labels.clear()
	_choice_map.clear()
	_selection = 0
	for c in choices:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.9))
		_choices_box.add_child(lbl)
		_choice_labels.append(lbl)
		_choice_map.append(c)
	_refresh_selection()

func _refresh_selection() -> void:
	for i in _choice_labels.size():
		var lbl := _choice_labels[i]
		lbl.text = ("> " if i == _selection else "  ") + str(_choice_map[i].get("text", ""))
		lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.5) if i == _selection else Color(0.82, 0.82, 0.9))

func _advance() -> void:
	var choices: Array = active_lines[_index].get("choices", [])
	if not choices.is_empty() and not _choice_map.is_empty():
		var target: int = int(_choice_map[_selection].get("next", -1))
		_index = target
		if target < 0:
			_end_dialogue()
		else:
			_show_line()
		return
	_index += 1
	if _index >= active_lines.size():
		_end_dialogue()
	else:
		_show_line()

func _end_dialogue() -> void:
	is_active = false
	_ui.visible = false
	get_tree().paused = false
	dialogue_ended.emit()

func _process(_delta: float) -> void:
	if not is_active:
		return
	if _choice_labels.is_empty():
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_advance()
	else:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
			_selection = (_selection - 1 + _choice_labels.size()) % _choice_labels.size()
			_refresh_selection()
		elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_down"):
			_selection = (_selection + 1) % _choice_labels.size()
			_refresh_selection()
		elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_advance()