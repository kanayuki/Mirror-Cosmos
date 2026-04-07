## First-person player controller.
## Moon gravity (1.62 m/s²) is set globally in project.godot.
extends CharacterBody3D

const MOVE_SPEED    := 5.0
const JUMP_VELOCITY := 4.0   # Feels floaty on moon gravity — intentional
const MOUSE_SENS    := 0.002

@onready var head: Node3D = $Head
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Player starts hidden; game_manager shows it on mode switch
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_mode != GameManager.Mode.EXPLORE:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	if GameManager.current_mode != GameManager.Mode.EXPLORE:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement relative to look direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED)

	move_and_slide()
