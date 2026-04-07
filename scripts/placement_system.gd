## Handles mirror placement in design mode via the overhead orthographic camera.
## Left-click  → place mirror (snapped to grid)
## Right-click → remove mirror
## R key       → rotate hovered / clicked mirror 45°
## Hover       → highlight mirror under cursor
extends Node

const SNAP := 2.0  # World units between grid positions

var _hovered_mirror: Node3D = null

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_mode != GameManager.Mode.DESIGN:
		return

	if event is InputEventMouseMotion:
		_update_hover(event.position)

	elif event is InputEventMouseButton and event.pressed:
		var world_pos := _screen_to_world(event.position)
		if world_pos == null:
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# If clicking an existing mirror, rotate it instead of placing
				if not GameManager.try_rotate_mirror(world_pos):
					GameManager.try_place_mirror(world_pos)
					_rebuild_mirror_nodes()
			MOUSE_BUTTON_RIGHT:
				if GameManager.try_remove_mirror(world_pos):
					_rebuild_mirror_nodes()

	elif event.is_action_pressed("rotate_mirror") and _hovered_mirror != null:
		var pos := _hovered_mirror.global_position
		GameManager.try_rotate_mirror(pos)

## Returns the snapped world XZ position hit by a ray from the design camera,
## or null if out of placement bounds.
func _screen_to_world(screen_pos: Vector2) -> Variant:
	var cam := GameManager.design_camera
	if cam == null:
		return null

	# Orthographic camera pointed straight down: ray is vertical
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir    := cam.project_ray_normal(screen_pos)

	# Intersect with Y = 0 plane
	if abs(ray_dir.y) < 0.0001:
		return null
	var t := -ray_origin.y / ray_dir.y
	var hit := ray_origin + ray_dir * t

	# Snap to grid
	return Vector3(
		round(hit.x / SNAP) * SNAP,
		0.0,
		round(hit.z / SNAP) * SNAP
	)

func _update_hover(screen_pos: Vector2) -> void:
	var cam := GameManager.design_camera
	if cam == null:
		return
	var space := cam.get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(
		cam.project_ray_origin(screen_pos),
		cam.project_ray_origin(screen_pos) + cam.project_ray_normal(screen_pos) * 100.0
	)
	params.collision_mask = 1
	var result := space.intersect_ray(params)

	var new_hover: Node3D = null
	if result and result.collider.is_in_group("mirror"):
		new_hover = result.collider

	if new_hover != _hovered_mirror:
		if _hovered_mirror and is_instance_valid(_hovered_mirror):
			_hovered_mirror.set_hovered(false)
		_hovered_mirror = new_hover
		if _hovered_mirror:
			_hovered_mirror.set_hovered(true)

## Rebuilds all 3D mirror nodes after a place/remove operation.
func _rebuild_mirror_nodes() -> void:
	var container := GameManager.mirror_container
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	var mirror_scene := preload("res://scenes/world/mirror_3d.tscn")
	for data in GameManager.placed_mirrors:
		var node: Node3D = mirror_scene.instantiate()
		node.mirror_data = data
		container.add_child(node)
	GameManager.emit_signal("beam_updated")
