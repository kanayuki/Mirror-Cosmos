## Handles mirror placement input in design mode.
## Translates screen clicks → snapped world positions → GameManager calls.
## MirrorSpawner handles all 3D node creation in response.
extends Node

const SNAP := 2.0  # Must match grid_overlay.gd

var _hovered_mirror: Node3D = null

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_mode != GameManager.Mode.DESIGN:
		return

	if event is InputEventMouseMotion:
		_update_hover(event.position)
		return

	if not (event is InputEventMouseButton and event.pressed):
		return

	var world_pos := _screen_to_world(event.position)
	if world_pos == null:
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT:
			# Clicking an occupied cell rotates; empty cell places
			if not GameManager.try_rotate_mirror(world_pos):
				GameManager.try_place_mirror(world_pos)
		MOUSE_BUTTON_RIGHT:
			GameManager.try_remove_mirror(world_pos)

# ── Coordinate mapping ─────────────────────────────────────────────────────
## Projects screen position through the orthographic design camera onto Y=0.
## Returns null if outside placement bounds or camera unavailable.
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
	var result := space.intersect_ray(params)

	var new_hover: Node3D = null
	var collider := result.get("collider") as Node3D
	if collider and collider.is_in_group("mirror"):
		new_hover = collider

	if new_hover == _hovered_mirror:
		return
	if _hovered_mirror and is_instance_valid(_hovered_mirror):
		_hovered_mirror.set_hovered(false)
	_hovered_mirror = new_hover
	if _hovered_mirror:
		_hovered_mirror.set_hovered(true)
