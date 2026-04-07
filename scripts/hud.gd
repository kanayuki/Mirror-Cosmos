## HUD — mode indicator, mirror count, level name, log count, contextual hints.
extends CanvasLayer

@onready var _level_label:  Label = $VBox/LevelLabel
@onready var _mode_label:   Label = $VBox/ModeLabel
@onready var _mirror_label: Label = $VBox/MirrorLabel
@onready var _hint_label:   Label = $VBox/HintLabel
@onready var _log_label:    Label = $VBox/LogLabel

func _ready() -> void:
	GameManager.mode_changed.connect(func(_m): _refresh())
	GameManager.mirror_placed.connect(func(_d): _refresh())
	GameManager.mirror_removed.connect(func(_p): _refresh())
	GameManager.level_loaded.connect(func(_d): _refresh())
	LogManager.log_count_changed.connect(func(_n): _refresh())
	GameManager.puzzle_solved.connect(_on_puzzle_solved)
	_refresh()

func _on_puzzle_solved() -> void:
	_hint_label.text    = "★  已解谜！"
	_hint_label.modulate = Color(1.0, 0.9, 0.2)
	await get_tree().create_timer(2.2).timeout
	_refresh()

func _refresh() -> void:
	var ld      := GameManager.current_level_data
	var placed  := GameManager.placed_mirrors.size()
	var max_m   := ld.max_mirrors if ld else 0
	var log_cnt := LogManager.count()

	_level_label.text  = ld.level_name if ld else ""
	_log_label.text    = "日志  %d" % log_cnt if log_cnt > 0 else ""

	match GameManager.current_mode:
		GameManager.Mode.DESIGN:
			_mode_label.text   = "[ 设计模式 ]"
			_mirror_label.text = "镜面  %d / %d" % [placed, max_m]
			_hint_label.text   = "左键放置  ·  右键删除  ·  再次点击旋转  ·  Tab 进入探索"
			_hint_label.modulate = Color.WHITE
		GameManager.Mode.EXPLORE:
			_mode_label.text   = "[ 探索模式 ]"
			_mirror_label.text = ""
			_hint_label.text   = "WASD 移动  ·  空格跳跃  ·  Tab 返回设计  ·  L 查看日志"
			_hint_label.modulate = Color.WHITE
