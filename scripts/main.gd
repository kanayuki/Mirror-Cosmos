## Main scene bootstrap — wires GameManager node references and loads Level 1.
extends Node

func _ready() -> void:
	# Wire scene node references into GameManager
	GameManager.design_camera   = $DesignCamera
	GameManager.player_node     = $Player
	GameManager.mirror_container = $GameWorld/MirrorContainer
	GameManager.star_beam       = $GameWorld/StarBeam
	GameManager.fade_overlay    = $UILayer/FadeOverlay

	# Load Level 1
	var level_01 := _make_level_01()
	GameManager.load_level(level_01)

	# Build level 1 geometry (placeholder boxes)
	_build_level_geometry(level_01)

func _make_level_01() -> LevelData:
	var ld        := LevelData.new()
	ld.level_name  = "银影基地 — 关卡 1"
	ld.level_index = 1
	ld.beam_origin    = Vector3(-8.0, 1.0,  0.0)
	ld.beam_direction = Vector3( 1.0, 0.0,  0.0)
	ld.target_position = Vector3(8.0, 1.0,  4.0)
	ld.max_mirrors  = 2
	ld.par_mirrors  = 2
	ld.placement_bounds = Rect2(-9.0, -5.0, 18.0, 10.0)
	return ld

func _build_level_geometry(ld: LevelData) -> void:
	var world: Node3D = $GameWorld

	# Floor
	_add_box(world, Vector3(0, -0.5, 0), Vector3(22, 1, 14), Color(0.08, 0.1, 0.18))

	# Walls (N/S/E/W)
	_add_box(world, Vector3( 0,  2, -7), Vector3(22, 6, 0.5), Color(0.1, 0.12, 0.22))
	_add_box(world, Vector3( 0,  2,  7), Vector3(22, 6, 0.5), Color(0.1, 0.12, 0.22))
	_add_box(world, Vector3(-11, 2,  0), Vector3(0.5, 6, 14), Color(0.1, 0.12, 0.22))
	_add_box(world, Vector3( 11, 2,  0), Vector3(0.5, 6, 14), Color(0.1, 0.12, 0.22))

	# Beam emitter (glowing box at origin)
	_add_box(world, ld.beam_origin - Vector3(0.5, 0, 0), Vector3(0.3, 0.3, 0.3),
		Color(0.3, 0.8, 1.0), true)

	# Target (glowing box)
	var target_node := _add_box(world, ld.target_position, Vector3(0.5, 0.5, 0.5),
		Color(1.0, 0.8, 0.1), true)
	target_node.add_to_group("target")

	# Place player in the middle of the room
	$Player.global_position = Vector3(0, 1, 0)

func _add_box(parent: Node3D, pos: Vector3, size: Vector3,
		color: Color, emissive: bool = false) -> StaticBody3D:
	var body    := StaticBody3D.new()
	var mesh_i  := MeshInstance3D.new()
	var col     := CollisionShape3D.new()
	var box_m   := BoxMesh.new()
	var box_s   := BoxShape3D.new()
	var mat     := StandardMaterial3D.new()

	box_m.size = size
	box_s.size = size
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0

	mesh_i.mesh = box_m
	mesh_i.set_surface_override_material(0, mat)
	col.shape = box_s

	body.add_child(mesh_i)
	body.add_child(col)
	body.global_position = pos
	parent.add_child(body)
	return body
