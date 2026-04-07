## Star beam system — casts an iterative chain of raycasts,
## draws the path with ImmediateMesh, and detects puzzle completion.
extends Node3D

const MAX_BOUNCES   := 10
const RAY_LENGTH    := 60.0
const BEAM_COLOR    := Color(0.3, 0.9, 1.0)
const BEAM_SOLVED_COLOR := Color(1.0, 0.9, 0.2)
const EPSILON       := 0.015   # Offset from surface to avoid self-hit

@onready var beam_mesh_instance: MeshInstance3D = $BeamMesh
@onready var ray: RayCast3D = $RayCast3D

var _beam_material: StandardMaterial3D
var _solved: bool = false

func _ready() -> void:
	_beam_material = StandardMaterial3D.new()
	_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_material.albedo_color = BEAM_COLOR
	_beam_material.emission_enabled = true
	_beam_material.emission = BEAM_COLOR
	_beam_material.emission_energy_multiplier = 2.5

	GameManager.beam_updated.connect(_recalculate)

func _recalculate() -> void:
	if GameManager.current_level_data == null:
		return
	var origin    := GameManager.current_level_data.beam_origin
	var direction := GameManager.current_level_data.beam_direction.normalized()
	var points    := _cast_chain(origin, direction)
	_draw_beam(points)

func _cast_chain(origin: Vector3, direction: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = [origin]
	var pos := origin
	var dir := direction

	for _i in range(MAX_BOUNCES):
		ray.global_position = pos
		ray.target_position = dir * RAY_LENGTH
		ray.force_raycast_update()

		if not ray.is_colliding():
			points.append(pos + dir * RAY_LENGTH)
			break

		var hit_pos    := ray.get_collision_point()
		var hit_normal := ray.get_collision_normal()
		var hit_obj    := ray.get_collider()
		points.append(hit_pos)

		if hit_obj.is_in_group("target"):
			_on_target_hit()
			break

		if not hit_obj.is_in_group("mirror"):
			break  # Hit a wall — beam stops

		# Reflect direction around surface normal
		dir = (dir - 2.0 * dir.dot(hit_normal) * hit_normal).normalized()
		pos = hit_pos + dir * EPSILON

	return points

func _draw_beam(points: Array[Vector3]) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _beam_material)
	for i in range(points.size() - 1):
		# Convert from global to local (beam mesh is at origin)
		mesh.surface_add_vertex(points[i])
		mesh.surface_add_vertex(points[i + 1])
	mesh.surface_end()
	beam_mesh_instance.mesh = mesh

func _on_target_hit() -> void:
	if _solved:
		return
	_solved = true
	_beam_material.albedo_color = BEAM_SOLVED_COLOR
	_beam_material.emission = BEAM_SOLVED_COLOR
	GameManager.emit_signal("puzzle_solved")
	await get_tree().create_timer(0.5).timeout
	_solved = false  # Reset for re-entry / retry
