## Handles mirror placement input in design mode.
## Translates screen clicks → snapped world positions → GameManager calls.
## Also manages the ghost placement preview and Ctrl+Z undo.
extends Node

const SNAP := 2.0  # Must match grid_overlay.gd

var _hovered_mirror: Node3D = null

# Ghost preview — shows where next mirror would land on empty valid cells.
# Added as a child of PlacementSystem (plain Node) so it survives level loads
# without being caught by MirrorSpawner's clear-children sweep.
var _ghost: MeshInstance3D = null
var _ghost_mat: StandardMaterial3D = null
var _ghost_t: float = 0.0

func _ready() -> void:
	GameManager.level_loaded.connect(_on_level_loaded)
	# Hide ghost immediately when switching to explore — don't wait for a mouse event
	GameManager.mode_changed.connect(func(_m): _hide_ghost())

func _on_level_loaded(_data: LevelData) -> void:
	if _ghost == null:
		_ghost_mat = _make_ghost_mat()
		_ghost = _make_ghost(_ghost_mat)
		add_child(_ghost)  # PlacementSystem is a plain Node; ghost renders at global_position
	_ghost.hide()

func _process(delta: float) -> void:
	if _ghost == null or not _ghost.visible:
		return
	# Slowly pulse the ghost alpha to signal "you can place here"
	_ghost_t += delta * 3.2
	_ghost_mat.albedo_color.a = 0.22 + sin(_ghost_t) * 0.10

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_mode != GameManager.Mode.DESIGN:
		_hide_ghost()
		return

	if event is InputEventMouseMotion:
		_update_hover(event.position)
		return

	if event.is_action_pressed("undo"):
		GameManager.undo_last_mirror()
		get_viewport().set_input_as_handled()
		return

	if not (event is InputEventMouseButton and event.pressed):
		return

	var world_pos := _screen_to_world(event.position)
	if world_pos == null:
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if not GameManager.try_rotate_mirror(world_pos):
				GameManager.try_place_mirror(world_pos)
		MOUSE_BUTTON_RIGHT:
			GameManager.try_remove_mirror(world_pos)

# ── Coordinate mapping ─────────────────────────────────────────────────────
## Projects screen position through the orthographic design camera onto Y=0.
func _screen_to_world(screen_pos: Vector2) -> Variant:
	var cam := GameManager.design_camera
	if cam == null:
		return null
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir    := cam.project_ray_normal(screen_pos)
	if absf(ray_dir.y) < 0.0001:
		return null
	var t   := -ray_origin.y / ray_dir.y
	var hit := ray_origin + ray_dir * t
	return Vector3(
		roundf(hit.x / SNAP) * SNAP,
		0.0,
		roundf(hit.z / SNAP) * SNAP
	)

# ── Hover highlight ────────────────────────────────────────────────────────
func _update_hover(screen_pos: Vector2) -> void:
	var cam := GameManager.design_camera
	if cam == null:
		return

	var space  := cam.get_world_3d().direct_space_state
	var origin := cam.project_ray_origin(screen_pos)
	var params := PhysicsRayQueryParameters3D.create(
		origin,
		origin + cam.project_ray_normal(screen_pos) * 100.0
	)
	var result  := space.intersect_ray(params)
	var new_hover: Node3D = null
	var collider := result.get("collider") as Node3D
	if collider and collider.is_in_group("mirror"):
		new_hover = collider

	if new_hover != _hovered_mirror:
		if _hovered_mirror and is_instance_valid(_hovered_mirror):
			_hovered_mirror.set_hovered(false)
		_hovered_mirror = new_hover
		if _hovered_mirror:
			_hovered_mirror.set_hovered(true)

	_update_ghost(screen_pos, new_hover)

# ── Ghost preview ──────────────────────────────────────────────────────────
func _update_ghost(screen_pos: Vector2, occupied_mirror: Node3D) -> void:
	if _ghost == null:
		return
	# Hovering an existing mirror → show hover highlight instead of ghost
	if occupied_mirror != null:
		_hide_ghost()
		return

	var snapped := _screen_to_world(screen_pos)
	if snapped == null:
		_hide_ghost()
		return

	var ld := GameManager.current_level_data
	if ld == null:
		_hide_ghost()
		return

	if not ld.placement_bounds.has_point(Vector2(snapped.x, snapped.z)):
		_hide_ghost()
		return
	if GameManager.get_mirror_at(snapped) != null:
		_hide_ghost()
		return
	if GameManager.placed_mirrors.size() >= ld.max_mirrors:
		_hide_ghost()
		return

	_ghost.global_position = snapped
	_ghost.show()

func _hide_ghost() -> void:
	if _ghost != null and _ghost.visible:
		_ghost.hide()

func _make_ghost_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.85, 1.0, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.7, 1.0)
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _make_ghost(mat: StandardMaterial3D) -> MeshInstance3D:
	var mi  := MeshInstance3D.new()
	var bm  := BoxMesh.new()
	bm.size = Vector3(0.1, 1.8, 1.8)  # Matches mirror_3d.tscn BoxMesh size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	return mi
