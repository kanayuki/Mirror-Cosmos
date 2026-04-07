## Level complete overlay — shown after puzzle_solved signal.
## Fades in, displays stats, offers Next Level or Return to Design.
extends CanvasLayer

@onready var _panel:       Control = $Panel
@onready var _title:       Label   = $Panel/VBox/Title
@onready var _stats:       Label   = $Panel/VBox/Stats
@onready var _btn_next:    Button  = $Panel/VBox/BtnNext
@onready var _btn_retry:   Button  = $Panel/VBox/BtnRetry

func _ready() -> void:
	_panel.modulate.a = 0.0
	visible = false
	GameManager.puzzle_solved.connect(_on_puzzle_solved)
	GameManager.level_loaded.connect(func(_d): _hide_panel())
	_btn_next.pressed.connect(_on_next_pressed)
	_btn_retry.pressed.connect(_on_retry_pressed)

func _on_puzzle_solved() -> void:
	var ld := GameManager.current_level_data
	var placed := GameManager.placed_mirrors.size()
	var par    := ld.par_mirrors if ld else placed
	var stars  := _calc_stars(placed, par)

	_title.text = "★ " + "★".repeat(stars) + "  Solved!"
	_stats.text = "Mirrors used: %d  /  Par: %d" % [placed, par]
	_btn_next.visible = GameManager.has_next_level()

	visible = true
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.35)

func _on_next_pressed() -> void:
	_hide_panel()
	GameManager.advance_level()

func _on_retry_pressed() -> void:
	_hide_panel()
	# Reload current level (clears mirrors, returns to design)
	GameManager.load_level_by_index(GameManager.current_level_index)

func _hide_panel() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): visible = false)

func _calc_stars(used: int, par: int) -> int:
	if used <= par:
		return 3
	elif used <= par + 1:
		return 2
	else:
		return 1
