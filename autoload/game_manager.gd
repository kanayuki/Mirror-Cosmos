## GameManager — Autoload singleton.
## Central authority for mode state, mirror data, level progression, and scene refs.
extends Node

# ── Enums ──────────────────────────────────────────────────────────────────
enum Mode { DESIGN, EXPLORE }

# ── Signals ────────────────────────────────────────────────────────────────
signal mode_changed(new_mode: Mode)
signal mirror_placed(data: MirrorData)
signal mirror_removed(position: Vector3)
signal mirror_rotated(data: MirrorData)
signal beam_updated
signal puzzle_solved
signal level_loaded(data: LevelData)

# ── Level registry — add new .tres paths here as levels are created ────────
const LEVEL_PATHS: Array[String] = [
	"res://resources/levels/level_01.tres",
	"res://resources/levels/level_02.tres",
]

# ── State ──────────────────────────────────────────────────────────────────
var current_mode: Mode = Mode.DESIGN
var placed_mirrors: Array[MirrorData] = []
var current_level_data: LevelData = null
var current_level_index: int = 0
var is_transitioning: bool = false

# ── Scene node references (assigned by main.gd on _ready) ─────────────────
var design_camera: Camera3D = null
var player_node: CharacterBody3D = null
var mirror_container: Node3D = null
var star_beam: Node3D = null
var fade_overlay: ColorRect = null

# ── Level management ───────────────────────────────────────────────────────
func load_level_by_index(index: int) -> void:
	if index < 0 or index >= LEVEL_PATHS.size():
		push_error("GameManager: level index out of range: %d" % index)
		return
	current_level_index = index
	var data := ResourceLoader.load(LEVEL_PATHS[index]) as LevelData
	if data == null:
		push_error("GameManager: failed to load level at %s" % LEVEL_PATHS[index])
		return
	load_level(data)

func load_level(data: LevelData) -> void:
	current_level_data = data
	placed_mirrors.clear()
	current_mode = Mode.DESIGN
	level_loaded.emit(data)
	beam_updated.emit()

func advance_level() -> void:
	load_level_by_index(current_level_index + 1)

func has_next_level() -> bool:
	return current_level_index + 1 < LEVEL_PATHS.size()

func get_mirror_at(pos: Vector3) -> MirrorData:
	for m: MirrorData in placed_mirrors:
		if m.world_position.distance_to(pos) < 0.6:
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
	var b: Rect2 = current_level_data.placement_bounds
	if not b.has_point(Vector2(world_pos.x, world_pos.z)):
		return false

	var data := MirrorData.new()
	data.world_position = world_pos
	data.rotation_y = 0.0
	placed_mirrors.append(data)
	mirror_placed.emit(data)
	beam_updated.emit()
	return true

func try_remove_mirror(world_pos: Vector3) -> bool:
	var m := get_mirror_at(world_pos)
	if m == null:
		return false
	placed_mirrors.erase(m)
	mirror_removed.emit(world_pos)
	beam_updated.emit()
	return true

func try_rotate_mirror(world_pos: Vector3) -> bool:
	var m := get_mirror_at(world_pos)
	if m == null:
		return false
	m.rotate_next()
	mirror_rotated.emit(m)
	beam_updated.emit()
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
		var cam := player_node.get_node_or_null("Head/Camera3D") as Camera3D
		if cam:
			cam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mode_changed.emit(current_mode)
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
	mode_changed.emit(current_mode)
	await _fade_in()
	is_transitioning = false

func _fade_out() -> void:
	if fade_overlay == null:
		return
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.15)
	await tw.finished

func _fade_in() -> void:
	if fade_overlay == null:
		return
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.15)
	await tw.finished

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mode"):
		switch_mode()
