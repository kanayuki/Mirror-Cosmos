## HUD — displays current mode, mirror count, and contextual hints.
extends CanvasLayer

@onready var mode_label:   Label = $VBox/ModeLabel
@onready var mirror_label: Label = $VBox/MirrorLabel
@onready var hint_label:   Label = $VBox/HintLabel

func _ready() -> void:
	GameManager.mode_changed.connect(_on_mode_changed)
	GameManager.mirror_placed.connect(_on_mirrors_changed)
	GameManager.mirror_removed.connect(_on_mirrors_changed)
	GameManager.puzzle_solved.connect(_on_puzzle_solved)
	_refresh()

func _on_mode_changed(_mode: GameManager.Mode) -> void:
	_refresh()

func _on_mirrors_changed(_arg = null) -> void:
	_refresh()

func _on_puzzle_solved() -> void:
	hint_label.text = "★  Puzzle Solved!  ★"
	hint_label.modulate = Color(1.0, 0.9, 0.2)
	await get_tree().create_timer(2.0).timeout
	_refresh()

func _refresh() -> void:
	var ld := GameManager.current_level_data
	var placed := GameManager.placed_mirrors.size()
	var max_m  := ld.max_mirrors if ld else 0

	match GameManager.current_mode:
		GameManager.Mode.DESIGN:
			mode_label.text  = "[ DESIGN MODE ]"
			mirror_label.text = "Mirrors: %d / %d" % [placed, max_m]
			hint_label.text  = "Left-click: place  •  Right-click: remove  •  R: rotate  •  Tab: explore"
			hint_label.modulate = Color.WHITE
		GameManager.Mode.EXPLORE:
			mode_label.text  = "[ EXPLORE MODE ]"
			mirror_label.text = ""
			hint_label.text  = "WASD: move  •  Space: jump  •  Tab: return to design"
			hint_label.modulate = Color.WHITE
