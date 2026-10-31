## LogManager — Autoload singleton.
## Tracks collected LogEntry resources across the whole session.
## Intentionally lightweight: no persistence to disk in Phase 2.
extends Node

signal log_collected(entry: LogEntry)
signal log_count_changed(total: int)

var _collected: Array[LogEntry] = []

# ── Public API ─────────────────────────────────────────────────────────────

func collect(entry: LogEntry) -> void:
	if entry == null or has_id(entry.log_id):
		return
	_collected.append(entry)
	log_collected.emit(entry)
	log_count_changed.emit(_collected.size())

func has_id(id: String) -> bool:
	for e: LogEntry in _collected:
		if e.log_id == id:
			return true
	return false

func get_all() -> Array[LogEntry]:
	return _collected.duplicate()

func count() -> int:
	return _collected.size()

## Call on new game / restart — clears all collected logs.
func reset() -> void:
	_collected.clear()
	log_count_changed.emit(0)
