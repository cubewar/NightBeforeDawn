extends CharacterBody3D

const PICKUP_RANGE = 4.0

var held_item: Node3D = null

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.5
		%Camera3D.rotation_degrees.x -= event.relative.y * 0.2
		%Camera3D.rotation_degrees.x = clamp(%Camera3D.rotation_degrees.x, -70.0, 70.0)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if held_item:
			drop_item()
		else:
			try_pickup()



func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	const SPEED = 5.5
	var input_direction_2D = Input.get_vector(
		"move_left", "move_right", "move_foward", "move_back"
	)
	var input_direction_3D = Vector3(
		input_direction_2D.x, 0.0, input_direction_2D.y
	)
	var direction = transform.basis * input_direction_3D

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	velocity.y -= 20.0 * delta

	move_and_slide()

func try_pickup():
	var cam: Camera3D = %Camera3D
	var space_state = get_world_3d().direct_space_state
	var from = cam.global_position
	var to = from + (-cam.global_transform.basis.z) * PICKUP_RANGE
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)

	if result and result.collider.has_method("pickup"):
		pickup_item(result.collider)

func pickup_item(item: Node3D):
	held_item = item
	item.pickup(self)

func drop_item():
	if held_item and held_item.has_method("drop"):
		held_item.drop()
	held_item = null

func clear_held_item():
	held_item = null
