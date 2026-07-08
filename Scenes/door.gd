extends Node3D
var is_closed = false
var can_interact = true
var open_y = 1.095
var closed_y = 0.103

func _ready() -> void:
	$DoorBody.position.y = open_y


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		can_interact = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		can_interact = false

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		is_closed = !is_closed
		var tween = create_tween()
		
		if is_closed:
			tween.tween_property($DoorBody, "position:y", closed_y, 0.15)
		if !is_closed:
			tween.tween_property($DoorBody, "position:y", open_y, 0.15)
