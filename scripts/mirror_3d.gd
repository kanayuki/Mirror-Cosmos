## A single mirror in the 3D world.
## Reads from its MirrorData resource and updates its visual + collider.
extends StaticBody3D

const MIRROR_COLOR         := Color(0.4, 0.8, 1.0, 0.85)
const MIRROR_HOVER_COLOR   := Color(0.6, 1.0, 1.0, 0.95)
const MIRROR_EMIT_ENERGY   := 0.6

var mirror_data: MirrorData = null

@onready var mesh_instance: MeshInstance3D   = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	add_to_group("mirror")
	if mirror_data:
		_apply_data()
	GameManager.beam_updated.connect(_on_beam_updated)

func _apply_data() -> void:
	global_position = mirror_data.world_position
	rotation_degrees.y = mirror_data.rotation_y

func _on_beam_updated() -> void:
	# Re-sync position/rotation if data changed (e.g. after rotate)
	if mirror_data:
		_apply_data()

## Returns the surface normal used for beam reflection.
func get_normal() -> Vector3:
	if mirror_data:
		return mirror_data.get_normal()
	return Vector3.RIGHT

## Called by PlacementSystem when the cursor hovers this mirror in design mode.
func set_hovered(hovered: bool) -> void:
	var mat := mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = MIRROR_HOVER_COLOR if hovered else MIRROR_COLOR
	mat.emission_energy_multiplier = MIRROR_EMIT_ENERGY * (1.8 if hovered else 1.0)
