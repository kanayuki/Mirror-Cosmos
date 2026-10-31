## MemoryFragment — glowing collectible in 3D explore space.
## Collecting it registers the linked LogEntry with LogManager.
## Uses Area3D so the player only needs to walk near it, not interact manually.
class_name MemoryFragment
extends Area3D

const PULSE_SPEED   := 2.2
const PULSE_SCALE   := 0.12
const BASE_ENERGY   := 1.4
const PULSE_ENERGY  := 0.4

@export var log_entry: LogEntry = null

@onready var _mesh:  MeshInstance3D = $MeshInstance3D
@onready var _light: OmniLight3D    = $OmniLight3D

var _pulse_t: float = 0.0
var _collected: bool = false

func _ready() -> void:
	add_to_group("memory_fragment")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _collected:
		return
	_pulse_t += delta * PULSE_SPEED
	var s := 1.0 + sin(_pulse_t) * PULSE_SCALE
	_mesh.scale = Vector3(s, s, s)
	_light.light_energy = BASE_ENERGY + sin(_pulse_t) * PULSE_ENERGY

func _on_body_entered(body: Node3D) -> void:
	# Guard mode: in DESIGN the player physics body is still present at its
	# last 3D position even though the mesh is hidden — don't collect then.
	if _collected \
			or GameManager.current_mode != GameManager.Mode.EXPLORE \
			or body != GameManager.player_node:
		return
	_collected = true
	if log_entry != null:
		LogManager.collect(log_entry)
	_play_collect_fx()

func _play_collect_fx() -> void:
	set_process(false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_mesh,  "scale",        Vector3.ZERO, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_property(_light, "light_energy", 0.0,          0.45)
	tw.chain().tween_callback(queue_free)
