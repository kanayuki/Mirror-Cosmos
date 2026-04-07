class_name LevelData
extends Resource

@export var level_name: String = ""
@export var level_index: int = 0

## Where the star beam originates in world space.
@export var beam_origin: Vector3 = Vector3(-8.0, 1.0, 0.0)
## Initial beam direction (should be unit vector, horizontal).
@export var beam_direction: Vector3 = Vector3(1.0, 0.0, 0.0)
## Position the beam must reach to solve the puzzle.
@export var target_position: Vector3 = Vector3(8.0, 1.0, 0.0)

## Maximum number of mirrors the player may place.
@export var max_mirrors: int = 2

## Valid placement bounds on the XZ plane (world units).
@export var placement_bounds: Rect2 = Rect2(-9.0, -5.0, 18.0, 10.0)

## Par mirror count for 3-star rating (place <= par to get 3 stars).
@export var par_mirrors: int = 2
