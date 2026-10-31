## LevelIntroCard — brief name overlay shown each time a level loads.
## Fades in quickly, holds, then fades out — non-blocking (no input consumed).
extends CanvasLayer

@onready var _panel:      Control = $Panel
@onready var _chapter:    Label   = $Panel/VBox/ChapterLabel
@onready var _level_name: Label   = $Panel/VBox/LevelName

var _tween: Tween = null

func _ready() -> void:
	visible = false
	GameManager.level_loaded.connect(_on_level_loaded)

func _on_level_loaded(data: LevelData) -> void:
	_chapter.text    = _chapter_text(GameManager.current_level_index)
	_level_name.text = data.level_name
	_show()

func _show() -> void:
	# Cancel any in-progress card from a rapid level reload
	if _tween != null:
		_tween.kill()

	visible = true
	_panel.modulate.a = 0.0

	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.30)
	_tween.tween_interval(1.40)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.50)
	_tween.tween_callback(func(): visible = false)

func _chapter_text(index: int) -> String:
	# Chapter labels — extend as more chapters are added
	match index:
		0, 1, 2, 3: return "第一章  ·  月球基地"
		_:           return "未知章节"
