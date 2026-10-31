## Main menu — entry point of the game.
## Handles New Game, Continue (if save exists), and Quit.
## Animations: fade-in, title pulse, button staggered entrance, programmatic star field.
extends Control

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _btn_new:      Button    = $Center/VBox/BtnNew
@onready var _btn_continue: Button    = $Center/VBox/BtnContinue
@onready var _btn_quit:     Button    = $Center/VBox/BtnQuit
@onready var _version:      Label     = $VersionLabel
@onready var _fade:         ColorRect = $FadeOverlay
@onready var _title:        Label     = $TitleLabel
@onready var _subtitle:     Label     = $SubtitleLabel

func _ready() -> void:
	_btn_new.pressed.connect(_on_new_game)
	_btn_continue.pressed.connect(_on_continue)
	_btn_quit.pressed.connect(func(): get_tree().quit())
	_btn_continue.disabled = not SaveSystem.has_save()
	_version.text = "v0.3-dev"

	_spawn_stars()

	# Hide buttons for staggered entrance
	for btn: Button in [_btn_new, _btn_continue, _btn_quit]:
		btn.modulate.a = 0.0

	# Fade in from black, then trigger UI animations
	_fade.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.6)
	tw.tween_callback(_animate_ui)

func _animate_ui() -> void:
	# Title breathes slowly (loops forever)
	var title_tw := create_tween().set_loops()
	title_tw.tween_property(_title, "modulate:a", 0.72, 2.2).set_trans(Tween.TRANS_SINE)
	title_tw.tween_property(_title, "modulate:a", 1.0,  2.2).set_trans(Tween.TRANS_SINE)

	# Buttons fade in staggered
	var btns: Array[Button] = [_btn_new, _btn_continue, _btn_quit]
	for i in btns.size():
		var btw := create_tween()
		btw.tween_interval(0.12 * i)
		btw.tween_property(btns[i], "modulate:a", 1.0, 0.30)

func _spawn_stars() -> void:
	var p := CPUParticles2D.new()
	add_child(p)
	move_child(p, 1)  # Between Background ColorRect and title labels
	p.position             = Vector2(960, 540)  # 1920×1080 centre
	p.emitting             = true
	p.amount               = 100
	p.lifetime             = 8.0
	p.preprocess           = 6.0
	p.emission_shape       = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1000, 580)
	p.direction            = Vector2(0.0, 0.0)
	p.spread               = 180.0
	p.gravity              = Vector2(0.0, 0.0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 8.0
	p.scale_amount_min     = 0.6
	p.scale_amount_max     = 2.8
	p.color                = Color(0.55, 0.82, 1.0, 0.65)

func _on_new_game() -> void:
	SaveSystem.delete_save()
	_load_game(0)

func _on_continue() -> void:
	var idx := SaveSystem.load_level_index()
	_load_game(idx)

func _load_game(level_index: int) -> void:
	_btn_new.disabled      = true
	_btn_continue.disabled = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.3)
	tw.tween_callback(func():
		SaveSystem.pending_level_index = level_index
		get_tree().change_scene_to_file(GAME_SCENE)
	)
