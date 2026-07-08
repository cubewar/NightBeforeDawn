extends Node3D

@export var energy_max: float = 100.0
@export var energy_drain_rate: float = 5.0

var is_closed = false
var can_interact = false
var open_y = 1.095
var closed_y = 0.103
var energy_current: float

func _ready() -> void:
	$DoorBody.position.y = open_y
	energy_current = energy_max


func _process(delta: float) -> void:
	if is_closed and energy_current > 0.0:
		energy_current = max(0.0, energy_current - energy_drain_rate * delta)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		can_interact = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		can_interact = false

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		toggle()

func toggle() -> void:
	if not is_closed and energy_current <= 0.0:
		return

	is_closed = !is_closed
	var tween = create_tween()

	if is_closed:
		tween.tween_property($DoorBody, "position:y", closed_y, 0.15)
	if !is_closed:
		tween.tween_property($DoorBody, "position:y", open_y, 0.15)

func add_energy(amount: float) -> void:
	energy_current = min(energy_max, energy_current + amount)
