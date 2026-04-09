## Pause menu — shown with Escape key during gameplay.
## Does not use SceneTree.paused to avoid stopping tweens/signals;
## instead it blocks input via its own _unhandled_input.
## Also hosts volume sliders and fullscreen toggle (saved on close).
extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _panel:         Control     = $Panel
@onready var _btn_resume:    Button      = $Panel/VBox/BtnResume
@onready var _btn_restart:   Button      = $Panel/VBox/BtnRestart
@onready var _btn_menu:      Button      = $Panel/VBox/BtnMenu
@onready var _master_slider: HSlider    = $Panel/VBox/MasterRow/MasterSlider
@onready var _sfx_slider:    HSlider    = $Panel/VBox/SfxRow/SfxSlider
@onready var _amb_slider:    HSlider    = $Panel/VBox/AmbRow/AmbSlider
@onready var _fs_check:      CheckButton = $Panel/VBox/FsRow/FsCheck

var _open: bool = false

func _ready() -> void:
	visible = false
	_btn_resume.pressed.connect(_close)
	_btn_restart.pressed.connect(_on_restart)
	_btn_menu.pressed.connect(_on_main_menu)

	# Initialise controls from current settings
	_master_slider.value = SettingsManager.master_volume
	_sfx_slider.value    = SettingsManager.sfx_volume
	_amb_slider.value    = SettingsManager.ambient_volume
	_fs_check.button_pressed = SettingsManager.fullscreen

	# Wire sliders — apply immediately so player hears the change in real time
	_master_slider.value_changed.connect(func(v): SettingsManager.set_master_volume(v))
	_sfx_slider.value_changed.connect(func(v):    SettingsManager.set_sfx_volume(v))
	_amb_slider.value_changed.connect(func(v):    SettingsManager.set_ambient_volume(v))
	_fs_check.toggled.connect(func(on):           SettingsManager.set_fullscreen(on))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _open:
			_close()
		elif not GameManager.is_transitioning:
			_open_menu()
		get_viewport().set_input_as_handled()

func _open_menu() -> void:
	_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)

func _close() -> void:
	_open = false
	SettingsManager.save()  # Persist any changes made while paused
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		if GameManager.current_mode == GameManager.Mode.EXPLORE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	)

func _on_restart() -> void:
	_open = false
	visible = false
	GameManager.load_level_by_index(GameManager.current_level_index)

func _on_main_menu() -> void:
	_open = false
	visible = false
	SettingsManager.save()
	SaveSystem.save(GameManager.current_level_index)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
