## AudioManager — Autoload singleton for all in-game audio.
##
## SFX pool: 4 concurrent AudioStreamPlayers on the "SFX" bus.
## Ambient: one looping player on the "Ambient" bus.
##
## Audio files live in res://audio/sfx/ and res://audio/ambient/.
## If a file is missing the call is silently ignored — safe to ship
## without audio assets and drop them in later.
extends Node

const SFX_POOL_SIZE := 4

const SFX_PATHS: Dictionary = {
	"mirror_place":       "res://audio/sfx/mirror_place.ogg",
	"mirror_remove":      "res://audio/sfx/mirror_remove.ogg",
	"mirror_rotate":      "res://audio/sfx/mirror_rotate.ogg",
	"beam_solved":        "res://audio/sfx/beam_solved.ogg",
	"fragment_collect":   "res://audio/sfx/fragment_collect.ogg",
	"mode_switch":        "res://audio/sfx/mode_switch.ogg",
	"ui_click":           "res://audio/sfx/ui_click.ogg",
	"level_complete":     "res://audio/sfx/level_complete.ogg",
}

const AMBIENT_PATH := "res://audio/ambient/space_ambient.ogg"

var _sfx_pool:      Array[AudioStreamPlayer] = []
var _ambient:       AudioStreamPlayer        = null
var _sfx_cache:     Dictionary               = {}  # key → AudioStream

func _ready() -> void:
	_ensure_buses()
	_preload_sfx()
	_setup_players()
	_connect_signals()

# ── Setup ──────────────────────────────────────────────────────────────────
func _ensure_buses() -> void:
	for bus_name: String in ["SFX", "Ambient"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func _preload_sfx() -> void:
	for key: String in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx_cache[key] = ResourceLoader.load(path)

func _setup_players() -> void:
	# SFX pool
	for _i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	# Ambient loop
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = "Ambient"
	_ambient.volume_db = -6.0
	add_child(_ambient)
	if ResourceLoader.exists(AMBIENT_PATH):
		_ambient.stream = ResourceLoader.load(AMBIENT_PATH)
		_ambient.finished.connect(_ambient.play)  # loop manually
		_ambient.play()

func _connect_signals() -> void:
	GameManager.mirror_placed.connect(func(_d):  play_sfx("mirror_place"))
	GameManager.mirror_removed.connect(func(_p): play_sfx("mirror_remove"))
	GameManager.mirror_rotated.connect(func(_d): play_sfx("mirror_rotate"))
	GameManager.puzzle_solved.connect(func():    play_sfx("beam_solved"))
	GameManager.mode_changed.connect(func(_m):   play_sfx("mode_switch"))
	LogManager.log_collected.connect(func(_e):   play_sfx("fragment_collect"))
	# "level_complete" is triggered by LevelCompleteUI when the panel shows,
	# NOT here — connecting to level_loaded would play it on every load including game start.

# ── Public API ─────────────────────────────────────────────────────────────
func play_sfx(key: String) -> void:
	if key not in _sfx_cache:
		return
	# Find a free player; fall back to interrupting the first one
	var player := _sfx_pool.filter(func(p: AudioStreamPlayer): return not p.playing)
	var p: AudioStreamPlayer = player[0] if not player.is_empty() else _sfx_pool[0]
	p.stream = _sfx_cache[key]
	p.play()

func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(0,
		linear_to_db(maxf(linear, 0.001)))

func set_sfx_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))

func set_ambient_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index("Ambient")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))
