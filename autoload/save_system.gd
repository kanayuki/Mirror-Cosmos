## SaveSystem — Autoload singleton.
## Persists progress to user://save.json.
## Intentionally minimal: saves level index and collected log IDs only.
extends Node

const SAVE_PATH := "user://save.json"

## Set by main_menu.gd before loading the game scene so main.gd
## knows which level to start on without needing a query to disk.
var pending_level_index: int = 0

# ── Public API ─────────────────────────────────────────────────────────────

func save(level_index: int) -> void:
	var data := {
		"level_index": level_index,
		"collected_log_ids": _get_collected_ids(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot open %s for writing (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: cannot open %s for reading" % SAVE_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_error("SaveSystem: corrupt save file — resetting")
		delete_save()
		return {}
	return parsed as Dictionary

func load_level_index() -> int:
	var data := load_game()
	return int(data.get("level_index", 0))

func load_log_ids() -> Array:
	var data := load_game()
	var ids: Variant = data.get("collected_log_ids", [])
	return ids if ids is Array else []

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# ── Helpers ────────────────────────────────────────────────────────────────
func _get_collected_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: LogEntry in LogManager.get_all():
		ids.append(entry.log_id)
	return ids
