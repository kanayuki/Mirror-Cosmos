## Main scene bootstrap.
## Wires GameManager node references, builds level geometry, handles progression.
extends Node

# ── Per-level geometry builders ────────────────────────────────────────────
# Each entry maps level_index → Callable that receives the GameWorld Node3D.
# Add a new entry here when adding a new level.
const LEVEL_BUILDERS: Array[Callable] = []  # populated in _ready

func _ready() -> void:
	# Wire GameManager scene references
	GameManager.design_camera    = $DesignCamera as Camera3D
	GameManager.player_node      = $Player as CharacterBody3D
	GameManager.mirror_container = $GameWorld/MirrorContainer as Node3D
	GameManager.star_beam        = $GameWorld/StarBeam as Node3D
	GameManager.fade_overlay     = $UILayer/FadeOverlay as ColorRect

	GameManager.level_loaded.connect(_on_level_loaded)

	# Start at level 0
	GameManager.load_level_by_index(0)

# ── Level geometry ─────────────────────────────────────────────────────────
func _on_level_loaded(data: LevelData) -> void:
	_clear_geometry()
	match data.level_index:
		0: _build_level_01(data)
		1: _build_level_02(data)
	$Player.global_position = Vector3(0.0, 1.0, 0.0)

func _clear_geometry() -> void:
	var geo: Node3D = $GameWorld/LevelGeometry
	for child in geo.get_children():
		child.queue_free()

# Level 1: open room, straight-line challenge with one corner
func _build_level_01(ld: LevelData) -> void:
	var geo: Node3D = $GameWorld/LevelGeometry
	_room(geo, Vector3(0, -0.5, 0), Vector3(22, 1, 14), Color(0.08, 0.10, 0.18))
	_walls(geo, 11.0, 7.0)
	_emitter(geo, ld.beam_origin)
	_target(geo, ld.target_position)

# Level 2: central pillar forces a two-bounce solution
func _build_level_02(ld: LevelData) -> void:
	var geo: Node3D = $GameWorld/LevelGeometry
	_room(geo, Vector3(0, -0.5, 0), Vector3(22, 1, 14), Color(0.10, 0.08, 0.12))
	_walls(geo, 11.0, 7.0)
	# Central pillar — forces beam to go around
	_box(geo, Vector3(0, 2, 0), Vector3(2.5, 6, 2.5), Color(0.15, 0.12, 0.22))
	_emitter(geo, ld.beam_origin)
	_target(geo, ld.target_position)

# ── Geometry helpers ───────────────────────────────────────────────────────
func _room(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	_box(parent, pos, size, color)

func _walls(parent: Node3D, hx: float, hz: float) -> void:
	var c := Color(0.10, 0.12, 0.22)
	_box(parent, Vector3( 0,  2, -hz), Vector3(hx * 2, 6, 0.4), c)
	_box(parent, Vector3( 0,  2,  hz), Vector3(hx * 2, 6, 0.4), c)
	_box(parent, Vector3(-hx, 2,   0), Vector3(0.4, 6, hz * 2), c)
	_box(parent, Vector3( hx, 2,   0), Vector3(0.4, 6, hz * 2), c)

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
	var bm     := BoxMesh.new()
	var bs     := BoxShape3D.new()
	var mat    := StandardMaterial3D.new()

	bm.size = size
	bs.size = size
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
