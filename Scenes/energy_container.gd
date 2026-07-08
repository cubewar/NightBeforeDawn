extends Node3D

@export var door_path: NodePath
@export var energy_per_orb: float = 50.0

var door: Node = null
var player_in_range: Node3D = null

func _ready() -> void:
	if door_path != NodePath():
		door = get_node(door_path)
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = body

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and player_in_range == body:
		player_in_range = null

func _unhandled_input(event: InputEvent) -> void:
	if not (player_in_range and event.is_action_pressed("interact")):
		return

	var orb = player_in_range.held_item
	if orb and orb.is_in_group("EnergyOrb"):
		player_in_range.clear_held_item()
		orb.queue_free()
		if door and door.has_method("add_energy"):
			door.add_energy(energy_per_orb)
