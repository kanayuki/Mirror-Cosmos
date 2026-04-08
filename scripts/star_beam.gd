## Star beam — iterative RayCast3D chain, ImmediateMesh visualisation.
## Recalculates only when beam_updated signal fires (event-driven, not per-frame).
extends Node3D

const MAX_BOUNCES      := 10
const RAY_LENGTH       := 60.0
const EPSILON          := 0.015   # Offset to avoid self-intersection after bounce
const COLOR_BEAM       := Color(0.3, 0.9, 1.0)
const COLOR_SOLVED     := Color(1.0, 0.9, 0.2)

@onready var _beam_mesh: MeshInstance3D = $BeamMesh
@onready var _ray: RayCast3D           = $RayCast3D

var _mat: StandardMaterial3D

func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = COLOR_BEAM
	_mat.emission_enabled = true
	_mat.emission = COLOR_BEAM
	_mat.emission_energy_multiplier = 2.5

	# beam_updated is always emitted after level_loaded in load_level(),
	# so one connection is sufficient — no double recalculate on level load.
	GameManager.beam_updated.connect(_recalculate)

# ── Core ───────────────────────────────────────────────────────────────────
func _recalculate() -> void:
	var ld := GameManager.current_level_data
	if ld == null:
		return
	_mat.albedo_color = COLOR_BEAM
	_mat.emission     = COLOR_BEAM

	var points := _cast_chain(ld.beam_origin, ld.beam_direction.normalized())
	_draw(points)

func _cast_chain(origin: Vector3, direction: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = [origin]
	var pos := origin
	var dir := direction

	for _i: int in range(MAX_BOUNCES):
		_ray.global_position = pos
		_ray.target_position = dir * RAY_LENGTH
		_ray.force_raycast_update()

		if not _ray.is_colliding():
			points.append(pos + dir * RAY_LENGTH)
			break

		var hit_pos    := _ray.get_collision_point()
		var hit_normal := _ray.get_collision_normal()
		var hit_obj    := _ray.get_collider() as Node
		points.append(hit_pos)

		if hit_obj.is_in_group("target"):
			_on_target_hit()
			break

		if not hit_obj.is_in_group("mirror"):
			break

		dir = (dir - 2.0 * dir.dot(hit_normal) * hit_normal).normalized()
		pos = hit_pos + dir * EPSILON

	return points

func _draw(points: Array[Vector3]) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _mat)
	for i: int in range(points.size() - 1):
		mesh.surface_add_vertex(to_local(points[i]))
		mesh.surface_add_vertex(to_local(points[i + 1]))
	mesh.surface_end()
	_beam_mesh.mesh = mesh

func _on_target_hit() -> void:
	# GameManager.is_solved guards against re-emission; set it before emit
	# so any beam_updated triggered inside puzzle_solved handlers is a no-op.
	if GameManager.is_solved:
		return
	GameManager.is_solved = true
	_mat.albedo_color = COLOR_SOLVED
	_mat.emission     = COLOR_SOLVED
	GameManager.puzzle_solved.emit()
