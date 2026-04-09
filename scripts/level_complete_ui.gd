## Level complete overlay — shown after puzzle_solved signal.
## Stars pop in one by one with a scale-bounce animation.
extends CanvasLayer

@onready var _panel:     Control = $Panel
@onready var _stats:     Label   = $Panel/VBox/Stats
@onready var _btn_next:  Button  = $Panel/VBox/BtnNext
@onready var _btn_retry: Button  = $Panel/VBox/BtnRetry
@onready var _stars: Array[Label] = [
	$Panel/VBox/StarRow/Star1,
	$Panel/VBox/StarRow/Star2,
	$Panel/VBox/StarRow/Star3,
]

func _ready() -> void:
	_panel.modulate.a = 0.0
	visible = false
	GameManager.puzzle_solved.connect(_on_puzzle_solved)
	GameManager.level_loaded.connect(func(_d): _hide_panel())
	_btn_next.pressed.connect(_on_next_pressed)
	_btn_retry.pressed.connect(_on_retry_pressed)

func _on_puzzle_solved() -> void:
	var ld     := GameManager.current_level_data
	var placed := GameManager.placed_mirrors.size()
	var par    := ld.par_mirrors if ld else placed
	var count  := _calc_stars(placed, par)

	_stats.text = "用了 %d 面镜子  /  最优解 %d" % [placed, par]
	_btn_next.visible = GameManager.has_next_level()

	# Set initial state: earned stars ready to pop, unearned stars pre-greyed
	for i in _stars.size():
		if i < count:
			_stars[i].scale    = Vector2(1.8, 1.8)
			_stars[i].modulate = Color(1.0, 0.85, 0.2, 0.0)
		else:
			_stars[i].scale    = Vector2.ONE
			_stars[i].modulate = Color(0.30, 0.30, 0.30, 0.45)

	visible = true
	AudioManager.play_sfx("level_complete")
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.30)
	tw.tween_callback(func(): _animate_stars(count))

func _animate_stars(count: int) -> void:
	for i in count:
		var s := _stars[i]
		var tw := create_tween()
		tw.tween_interval(0.20 * i)
		tw.tween_callback(func():
			var ptw := create_tween().set_parallel()
			ptw.tween_property(s, "modulate:a", 1.0, 0.18)
			ptw.tween_property(s, "scale", Vector2.ONE, 0.28) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)

func _on_next_pressed() -> void:
	# Do NOT call _hide_panel() here: advance_level() emits level_loaded,
	# which is already connected to _hide_panel() — two tweens would compete.
	GameManager.advance_level()

func _on_retry_pressed() -> void:
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
