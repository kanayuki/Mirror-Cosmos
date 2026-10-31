## LogViewer — modal overlay for reading collected log entries.
## Toggle with the "open_log" action (default: L key).
## Pauses under cursor input; does not pause physics.
extends CanvasLayer

@onready var _panel:       PanelContainer = $Panel
@onready var _count_label: Label          = $Panel/VBox/Header/CountLabel
@onready var _play_btn:    Button         = $Panel/VBox/Header/PlayBtn
@onready var _log_list:    ItemList       = $Panel/VBox/Body/LogList
@onready var _log_text:    RichTextLabel  = $Panel/VBox/Body/LogText
@onready var _close_btn:   Button         = $Panel/VBox/Header/CloseBtn
@onready var _notify:      Label          = $NotifyLabel

var _entries: Array[LogEntry] = []
var _voice_player: AudioStreamPlayer = null

func _ready() -> void:
	visible = false
	LogManager.log_collected.connect(_on_log_collected)
	_log_list.item_selected.connect(_on_item_selected)
	_close_btn.pressed.connect(func(): _close())
	_play_btn.pressed.connect(_on_play_pressed)
	_notify.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		# Consume all unhandled input while open to prevent mode switches etc.
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("open_log") or event.is_action_pressed("ui_cancel"):
			_close()
		return
	if event.is_action_pressed("open_log"):
		_toggle()

func _toggle() -> void:
	visible = not visible
	if visible:
		_refresh()

func _close() -> void:
	_stop_voice()
	visible = false

# ── Content ────────────────────────────────────────────────────────────────
func _refresh() -> void:
	_entries = LogManager.get_all()
	_log_list.clear()
	for e: LogEntry in _entries:
		_log_list.add_item(e.title)
	_count_label.text = "日志  %d 条" % _entries.size()
	if _entries.size() > 0:
		_log_list.select(0)
		_on_item_selected(0)
	else:
		_log_text.text = "[color=gray][i]尚未收集任何记忆碎片。[/i][/color]"
		_play_btn.visible = false

func _on_item_selected(idx: int) -> void:
	if idx < 0 or idx >= _entries.size():
		return
	_stop_voice()
	var e := _entries[idx]
	_log_text.text = (
		"[b]%s[/b]\n[color=gray][i]%s[/i][/color]\n\n%s" % [e.title, e.date_stamp, e.body]
	)
	# Show play button only when a voice file exists for this entry
	_play_btn.visible = not e.audio_path.is_empty() and ResourceLoader.exists(e.audio_path)
	_play_btn.text = "▶  播放"

# ── Voice playback ─────────────────────────────────────────────────────────
func _on_play_pressed() -> void:
	var idx := _log_list.get_selected_items()
	if idx.is_empty():
		return
	var e := _entries[idx[0]]
	if e.audio_path.is_empty() or not ResourceLoader.exists(e.audio_path):
		return

	if _voice_player == null:
		_voice_player = AudioStreamPlayer.new()
		_voice_player.bus = "SFX"
		_voice_player.finished.connect(_on_voice_finished)
		add_child(_voice_player)

	if _voice_player.playing:
		_stop_voice()
		return  # Toggle: second press stops playback

	_voice_player.stream = ResourceLoader.load(e.audio_path)
	_voice_player.play()
	_play_btn.text = "■  停止"

func _stop_voice() -> void:
	if _voice_player != null and _voice_player.playing:
		_voice_player.stop()
	_play_btn.text = "▶  播放"

func _on_voice_finished() -> void:
	_play_btn.text = "▶  播放"

# ── Collection notification ────────────────────────────────────────────────
func _on_log_collected(entry: LogEntry) -> void:
	_notify.text = "◆  %s" % entry.title
	_notify.visible = true
	_notify.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(_notify, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func(): _notify.visible = false)
