## SettingsManager — Autoload singleton for user preferences.
## Persists to user://settings.json.
## Applied immediately on load so the window state is correct from frame 1.
extends Node

const SETTINGS_PATH := "user://settings.json"

var master_volume:  float = 1.0
var sfx_volume:     float = 1.0
var ambient_volume: float = 0.60
var fullscreen:     bool  = false

func _ready() -> void:
	_load()
	_apply()

# ── Public API ─────────────────────────────────────────────────────────────
func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	AudioManager.set_master_volume(master_volume)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	AudioManager.set_sfx_volume(sfx_volume)

func set_ambient_volume(v: float) -> void:
	ambient_volume = clampf(v, 0.0, 1.0)
	AudioManager.set_ambient_volume(ambient_volume)

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled \
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

func save() -> void:
	var data := {
		"master_volume":  master_volume,
		"sfx_volume":     sfx_volume,
		"ambient_volume": ambient_volume,
		"fullscreen":     fullscreen,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SettingsManager: cannot write to %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))

# ── Internal ───────────────────────────────────────────────────────────────
func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var d := parsed as Dictionary
	master_volume  = clampf(float(d.get("master_volume",  1.0)),  0.0, 1.0)
	sfx_volume     = clampf(float(d.get("sfx_volume",     1.0)),  0.0, 1.0)
	ambient_volume = clampf(float(d.get("ambient_volume", 0.60)), 0.0, 1.0)
	fullscreen     = bool(d.get("fullscreen", false))

func _apply() -> void:
	# AudioManager may not be ready yet (autoload order); defer audio application
	call_deferred("_apply_audio")
	set_fullscreen(fullscreen)

func _apply_audio() -> void:
	AudioManager.set_master_volume(master_volume)
	AudioManager.set_sfx_volume(sfx_volume)
	AudioManager.set_ambient_volume(ambient_volume)
