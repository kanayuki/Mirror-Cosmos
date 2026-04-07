class_name MirrorData
extends Resource

## Stores the state of a single placed mirror.
## Shared between design mode (placement) and explore mode (3D world).

enum MirrorType { BASIC }  # Phase 2: WARP, DELAY, PRISM

@export var world_position: Vector3 = Vector3.ZERO
## Rotation in degrees. Snapped to 45° increments (0/45/90/135).
@export var rotation_y: float = 0.0
@export var mirror_type: MirrorType = MirrorType.BASIC

func get_normal() -> Vector3:
	var rad = deg_to_rad(rotation_y)
	return Vector3(cos(rad), 0.0, sin(rad)).normalized()

func rotate_next() -> void:
	rotation_y = fmod(rotation_y + 45.0, 180.0)
