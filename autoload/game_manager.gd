## GameManager — Autoload singleton.
## Central authority for mode state, mirror data, and scene references.
extends Node

# ── Enums ──────────────────────────────────────────────────────────────────
enum Mode { DESIGN, EXPLORE }

# ── Signals ────────────────────────────────────────────────────────────────
signal mode_changed(new_mode: Mode)
signal mirror_placed(data: MirrorData)
signal mirror_removed(position: Vector3)
signal beam_updated
signal puzzle_solved

# ── State ──────────────────────────────────────────────────────────────────
var current_mode: Mode = Mode.DESIGN
var placed_mirrors: Array[MirrorData] = []
var current_level_data: LevelData = null
var is_transitioning: bool = false

# ── Scene node references (set by main.tscn after ready) ──────────────────
var design_camera: Camera3D = null
var player_node: CharacterBody3D = null
var mirror_container: Node3D = null
var star_beam: Node3D = null
var fade_overlay: ColorRect = null

# ── Level management ───────────────────────────────────────────────────────
func load_level(data: LevelData) -> void:
	current_level_data = data
	placed_mirrors.clear()
	current_mode = Mode.DESIGN
	_sync_mirrors_to_world()
	emit_signal("beam_updated")

func get_mirror_at(pos: Vector3) -> MirrorData:
	for m in placed_mirrors:
		if m.world_position.distance_to(pos) < 0.5:
			return m
	return null

# ── Mirror placement ───────────────────────────────────────────────────────
func try_place_mirror(world_pos: Vector3) -> bool:
	if current_level_data == null:
		return false
	if placed_mirrors.size() >= current_level_data.max_mirrors:
		return false
	if get_mirror_at(world_pos) != null:
		return false
	var bounds: Rect2 = current_level_data.placement_bounds
	if not bounds.has_point(Vector2(world_pos.x, world_pos.z)):
		return false

	var data := MirrorData.new()
	data.world_position = world_pos
	data.rotation_y = 0.0
	placed_mirrors.append(data)
	emit_signal("mirror_placed", data)
	emit_signal("beam_updated")
	return true

func try_remove_mirror(world_pos: Vector3) -> bool:
	var m := get_mirror_at(world_pos)
	if m == null:
		return false
	placed_mirrors.erase(m)
	emit_signal("mirror_removed", world_pos)
	emit_signal("beam_updated")
	return true

func try_rotate_mirror(world_pos: Vector3) -> bool:
	var m := get_mirror_at(world_pos)
	if m == null:
		return false
	m.rotate_next()
	emit_signal("beam_updated")
	return true

# ── Mode switching ─────────────────────────────────────────────────────────
func switch_mode() -> void:
	if is_transitioning:
		return
	if current_mode == Mode.DESIGN:
		_switch_to_explore()
	else:
		_switch_to_design()

func _switch_to_explore() -> void:
	is_transitioning = true
	await _fade_out()
	current_mode = Mode.EXPLORE
	if design_camera:
		design_camera.current = false
	if player_node:
		player_node.show()
		# Activate the camera inside the player
		var cam = player_node.get_node_or_null("Head/Camera3D")
		if cam:
			cam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("mode_changed", current_mode)
	await _fade_in()
	is_transitioning = false

func _switch_to_design() -> void:
	is_transitioning = true
	await _fade_out()
	current_mode = Mode.DESIGN
	if player_node:
		player_node.hide()
	if design_camera:
		design_camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("mode_changed", current_mode)
	await _fade_in()
	is_transitioning = false

func _fade_out() -> void:
	if fade_overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.15)
	await tween.finished

func _fade_in() -> void:
	if fade_overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.15)
	await tween.finished

# ── Internal ───────────────────────────────────────────────────────────────
## Called when a level loads or mirrors change — rebuilds 3D mirror nodes.
func _sync_mirrors_to_world() -> void:
	if mirror_container == null:
		return
	for child in mirror_container.get_children():
		child.queue_free()
	var mirror_scene := preload("res://scenes/world/mirror_3d.tscn")
	for data in placed_mirrors:
		var node: Node3D = mirror_scene.instantiate()
		node.mirror_data = data
		mirror_container.add_child(node)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mode"):
		switch_mode()
