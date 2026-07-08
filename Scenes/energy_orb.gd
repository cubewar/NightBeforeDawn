extends RigidBody3D

var is_held: bool = false
var holder: Node3D = null
var original_parent: Node3D = null

func _ready():
	gravity_scale = 1.0
	freeze = false
	original_parent = get_parent()

func pickup(player: Node3D):
	is_held = true
	holder = player
	gravity_scale = 0.0
	freeze = true
	collision_layer = 0
	collision_mask = 0
	reparent(player)
	position = Vector3(0.5, 0.3, -0.5)

func drop():
	if not holder:
		return
	is_held = false
	var drop_pos = holder.global_position + holder.global_transform.basis.z * -1.5
	reparent(original_parent)
	global_position = drop_pos
	holder = null
	freeze = false
	gravity_scale = 1.0
	collision_layer = 1
	collision_mask = 1
