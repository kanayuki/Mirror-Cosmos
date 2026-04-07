## MirrorSpawner — attached to MirrorContainer.
## Single source of truth for 3D mirror node lifecycle.
## Reacts to GameManager signals; no other script instantiates mirror nodes.
extends Node3D

const MIRROR_SCENE := preload("res://scenes/world/mirror_3d.tscn")

func _ready() -> void:
	GameManager.mirror_placed.connect(_on_mirror_placed)
	GameManager.mirror_removed.connect(_on_mirror_removed)
	GameManager.mirror_rotated.connect(_on_mirror_rotated)
	GameManager.level_loaded.connect(_on_level_loaded)

# ── Signal handlers ────────────────────────────────────────────────────────
func _on_mirror_placed(data: MirrorData) -> void:
	var node: Node3D = MIRROR_SCENE.instantiate()
	node.mirror_data = data
	# Stable name for easy lookup
	node.name = _node_name(data.world_position)
	add_child(node)

func _on_mirror_removed(position: Vector3) -> void:
	var node := find_child(_node_name(position), false, false) as Node
	if node:
		node.queue_free()

func _on_mirror_rotated(data: MirrorData) -> void:
	var node := find_child(_node_name(data.world_position), false, false) as Node3D
	if node and node.has_method("_apply_data"):
		node._apply_data()

func _on_level_loaded(_data: LevelData) -> void:
	# Clear all mirror nodes when a new level starts
	for child in get_children():
		child.queue_free()

# ── Helpers ────────────────────────────────────────────────────────────────
func _node_name(pos: Vector3) -> String:
	return "M_%d_%d" % [int(pos.x), int(pos.z)]
