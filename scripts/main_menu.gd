## Main menu — entry point of the game.
## Handles New Game, Continue (if save exists), and Quit.
extends Control

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _btn_new:      Button = $Center/VBox/BtnNew
@onready var _btn_continue: Button = $Center/VBox/BtnContinue
@onready var _btn_quit:     Button = $Center/VBox/BtnQuit
@onready var _version:      Label  = $VersionLabel
@onready var _fade:         ColorRect = $FadeOverlay

func _ready() -> void:
	_btn_new.pressed.connect(_on_new_game)
	_btn_continue.pressed.connect(_on_continue)
	_btn_quit.pressed.connect(func(): get_tree().quit())

	_btn_continue.disabled = not SaveSystem.has_save()
	_version.text = "v0.3-dev"

	# Fade in from black on scene start
	_fade.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.4)

func _on_new_game() -> void:
	SaveSystem.delete_save()
	_load_game(0)

func _on_continue() -> void:
	var idx := SaveSystem.load_level_index()
	_load_game(idx)

func _load_game(level_index: int) -> void:
	_btn_new.disabled     = true
	_btn_continue.disabled = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.3)
	tw.tween_callback(func():
		SaveSystem.pending_level_index = level_index
		get_tree().change_scene_to_file(GAME_SCENE)
	)
