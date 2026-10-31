## Main scene bootstrap.
## Wires GameManager node references, builds level geometry, spawns fragments.
extends Node

const MEMORY_FRAGMENT_SCENE := preload("res://scenes/world/memory_fragment.tscn")

# Hard-coded log paths — DirAccess.open("res://...") fails in exported builds.
const LOG_PATHS: Array[String] = [
	"res://resources/logs/log_01.tres",
	"res://resources/logs/log_02.tres",
]

func _ready() -> void:
	GameManager.design_camera    = $DesignCamera as Camera3D
	GameManager.player_node      = $Player as CharacterBody3D
	GameManager.mirror_container = $GameWorld/MirrorContainer as Node3D
	GameManager.star_beam        = $GameWorld/StarBeam as Node3D
	GameManager.fade_overlay     = $UILayer/FadeOverlay as ColorRect

	GameManager.level_loaded.connect(_on_level_loaded)
	GameManager.puzzle_solved.connect(_on_puzzle_solved)

	# Restore collected logs from save before loading the level
	_restore_logs_from_save()
	GameManager.load_level_by_index(SaveSystem.pending_level_index)

func _restore_logs_from_save() -> void:
	var ids := SaveSystem.load_log_ids()
	if ids.is_empty():
		return
	for path: String in LOG_PATHS:
		var entry := ResourceLoader.load(path) as LogEntry
		if entry != null and entry.log_id in ids:
			LogManager.collect(entry)

func _on_puzzle_solved() -> void:
	# Auto-save when a puzzle is completed
	SaveSystem.save(GameManager.current_level_index)

# ── Level loading ──────────────────────────────────────────────────────────
func _on_level_loaded(data: LevelData) -> void:
	_clear_geometry()
	match data.level_index:
		0: _build_level_01(data)
		1: _build_level_02(data)
		2: _build_level_03(data)
		3: _build_level_04(data)
	_spawn_memory_fragments(data)
	($Player as CharacterBody3D).global_position = Vector3(0.0, 1.0, 0.0)

func _clear_geometry() -> void:
	var geo := $GameWorld/LevelGeometry as Node3D
	# free() not queue_free(): beam_updated fires in the same frame,
	# old nodes must be gone before raycast runs.
	for child in geo.get_children():
		child.free()
	# Also clear memory fragments from previous level
	for child in ($GameWorld/FragmentContainer as Node3D).get_children():
		child.free()

func _spawn_memory_fragments(data: LevelData) -> void:
	var container := $GameWorld/FragmentContainer as Node3D
	var pos_count  := data.memory_fragment_positions.size()
	var path_count := data.memory_fragment_log_paths.size()
	for i: int in mini(pos_count, path_count):
		var frag  := MEMORY_FRAGMENT_SCENE.instantiate() as MemoryFragment
		var entry := ResourceLoader.load(data.memory_fragment_log_paths[i]) as LogEntry
		frag.log_entry = entry
		container.add_child(frag)
		# Set global_position AFTER add_child so Godot can compute the correct
		# world transform regardless of the container's own transform.
		frag.global_position = data.memory_fragment_positions[i]

# ── Level geometry ─────────────────────────────────────────────────────────
# Level 1: open room, beam crosses corner
func _build_level_01(ld: LevelData) -> void:
	var geo := $GameWorld/LevelGeometry as Node3D
	_room(geo, Color(0.08, 0.10, 0.18), Color(0.06, 0.08, 0.15))
	_walls(geo, 11.0, 7.0, Color(0.10, 0.12, 0.22))
	_emitter(geo, ld.beam_origin)
	_target(geo, ld.target_position)

# Level 2: central pillar forces two-bounce solution
func _build_level_02(ld: LevelData) -> void:
	var geo := $GameWorld/LevelGeometry as Node3D
	_room(geo, Color(0.10, 0.08, 0.14), Color(0.08, 0.06, 0.12))
	_walls(geo, 11.0, 7.0, Color(0.12, 0.10, 0.24))
	_box(geo, Vector3(0.0, 2.0,  0.0), Vector3(2.5, 6.0, 2.5), Color(0.15, 0.12, 0.22))
	_emitter(geo, ld.beam_origin)
	_target(geo, ld.target_position)

# Level 3: two parallel pillars — beam must snake between them
func _build_level_03(ld: LevelData) -> void:
	var geo := $GameWorld/LevelGeometry as Node3D
	_room(geo, Color(0.08, 0.09, 0.16), Color(0.06, 0.07, 0.14))
	_walls(geo, 11.0, 7.0, Color(0.10, 0.11, 0.22))
	_box(geo, Vector3(-3.0, 2.0,  1.5), Vector3(1.8, 6.0, 1.8), Color(0.14, 0.11, 0.20))
	_box(geo, Vector3( 3.0, 2.0, -1.5), Vector3(1.8, 6.0, 1.8), Color(0.14, 0.11, 0.20))
	_emitter(geo, ld.beam_origin)
	_target(geo, ld.target_position)

# Level 4 (Chapter 1 boss): cross-shaped obstacle, beam starts and ends on same side
func _build_level_04(ld: LevelData) -> void:
	var geo := $GameWorld/LevelGeometry as Node3D
	_room(geo, Color(0.07, 0.08, 0.15), Color(0.05, 0.06, 0.12))
	_walls(geo, 11.0, 7.0, Color(0.09, 0.11, 0.21))
	_box(geo, Vector3( 0.0, 2.0, 0.0), Vector3(6.0, 5.0, 1.5), Color(0.13, 0.11, 0.22))
	_box(geo, Vector3( 0.0, 2.0, 0.0), Vector3(1.5, 5.0, 6.0), Color(0.13, 0.11, 0.22))
	_emitter(geo, ld.beam_origin)
	_target(geo, ld.target_position)

# ── Geometry helpers ───────────────────────────────────────────────────────
## Builds floor + ceiling for a level room.
func _room(parent: Node3D, floor_color: Color, ceiling_color: Color) -> void:
	# Floor
	_box(parent, Vector3(0.0, -0.5, 0.0), Vector3(22.0, 1.0, 14.0), floor_color)
	# Ceiling — slightly emissive to serve as ambient fill light
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ceiling_color
	mat.emission_enabled = true
	mat.emission = ceiling_color
	mat.emission_energy_multiplier = 0.35
	var ceiling := _box(parent, Vector3(0.0, 5.5, 0.0), Vector3(22.0, 0.5, 14.0), ceiling_color)
	(ceiling.get_child(0) as MeshInstance3D).set_surface_override_material(0, mat)

func _walls(parent: Node3D, hx: float, hz: float, color: Color) -> void:
	_box(parent, Vector3( 0.0,  2.0, -hz), Vector3(hx * 2.0, 6.0,  0.4),    color)
	_box(parent, Vector3( 0.0,  2.0,  hz), Vector3(hx * 2.0, 6.0,  0.4),    color)
	_box(parent, Vector3(-hx,   2.0,  0.0), Vector3(0.4,     6.0, hz * 2.0), color)
	_box(parent, Vector3( hx,   2.0,  0.0), Vector3(0.4,     6.0, hz * 2.0), color)

func _emitter(parent: Node3D, pos: Vector3) -> void:
	_box(parent, pos, Vector3(0.3, 0.3, 0.3), Color(0.3, 0.8, 1.0), true)

func _target(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var node := _box(parent, pos, Vector3(0.6, 0.6, 0.6), Color(1.0, 0.8, 0.1), true)
	node.add_to_group("target")
	return node

func _box(parent: Node3D, pos: Vector3, size: Vector3,
		color: Color, emissive: bool = false) -> StaticBody3D:
	var body   := StaticBody3D.new()
	var mesh_i := MeshInstance3D.new()
	var col    := CollisionShape3D.new()
	var mat    := StandardMaterial3D.new()
	var bm     := BoxMesh.new()
	var bs     := BoxShape3D.new()

	bm.size  = size
	bs.size  = size
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0

	mesh_i.mesh = bm
	mesh_i.set_surface_override_material(0, mat)
	col.shape = bs
	body.add_child(mesh_i)
	body.add_child(col)
	body.global_position = pos
	parent.add_child(body)
	return body
