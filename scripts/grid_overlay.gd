## GridOverlay — draws the placement grid as 3D lines in design mode.
## Attach to a MeshInstance3D node inside GameWorld.
## Grid is only visible when mode == DESIGN.
extends MeshInstance3D

const SNAP         := 2.0
const LINE_COLOR   := Color(0.2, 0.5, 0.8, 0.45)
const BOUNDS_COLOR := Color(0.4, 0.85, 1.0, 0.8)
const LINE_Y       := 0.02  # Slightly above floor to avoid z-fighting

var _mat_grid:   StandardMaterial3D
var _mat_bounds: StandardMaterial3D

func _ready() -> void:
	_mat_grid = _make_mat(LINE_COLOR)
	_mat_bounds = _make_mat(BOUNDS_COLOR)

	GameManager.level_loaded.connect(_on_level_loaded)
	GameManager.mode_changed.connect(_on_mode_changed)
	visible = true  # Starts in design mode

func _on_level_loaded(data: LevelData) -> void:
	_rebuild(data.placement_bounds)

func _on_mode_changed(mode: GameManager.Mode) -> void:
	visible = (mode == GameManager.Mode.DESIGN)

# ── Drawing ────────────────────────────────────────────────────────────────
func _rebuild(bounds: Rect2) -> void:
	var im := ImmediateMesh.new()

	# Interior grid lines
	im.surface_begin(Mesh.PRIMITIVE_LINES, _mat_grid)
	var x := snappedf(bounds.position.x, SNAP)
	while x <= bounds.end.x:
		im.surface_add_vertex(Vector3(x, LINE_Y, bounds.position.y))
		im.surface_add_vertex(Vector3(x, LINE_Y, bounds.end.y))
		x += SNAP
	var z := snappedf(bounds.position.y, SNAP)
	while z <= bounds.end.y:
		im.surface_add_vertex(Vector3(bounds.position.x, LINE_Y, z))
		im.surface_add_vertex(Vector3(bounds.end.x,      LINE_Y, z))
		z += SNAP
	im.surface_end()

	# Placement boundary outline
	im.surface_begin(Mesh.PRIMITIVE_LINES, _mat_bounds)
	var corners := [
		Vector3(bounds.position.x, LINE_Y, bounds.position.y),
		Vector3(bounds.end.x,      LINE_Y, bounds.position.y),
		Vector3(bounds.end.x,      LINE_Y, bounds.end.y),
		Vector3(bounds.position.x, LINE_Y, bounds.end.y),
	]
	for i: int in 4:
		im.surface_add_vertex(corners[i])
		im.surface_add_vertex(corners[(i + 1) % 4])
	im.surface_end()

	mesh = im

func _make_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
