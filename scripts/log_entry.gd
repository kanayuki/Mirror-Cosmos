## LogEntry — immutable data container for a single story log.
## Stored as .tres files under resources/logs/.
class_name LogEntry
extends Resource

## Stable identifier used to deduplicate collected logs across sessions.
@export var log_id: String = ""
## Short display title shown in the log list.
@export var title: String = ""
## In-universe date shown below the title.
@export var date_stamp: String = ""
## Full log body text. Supports BBCode via RichTextLabel.
@export_multiline var body: String = ""
## Reserved for Phase 3 voice acting — leave empty until then.
@export_file("*.ogg", "*.wav") var audio_path: String = ""
