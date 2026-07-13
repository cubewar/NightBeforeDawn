extends Node3D

@export var player_scene: PackedScene = preload("res://Scenes/Player.tscn")
@onready var players_container = $Players

func _ready() -> void:
	# 1. We only want the Host (Peer ID 1) to handle spawning
	if not multiplayer.is_server():
		return
		
	# 2. Spawn a character for the Host immediately
	spawn_player(multiplayer.get_unique_id())
	
	# 3. Listen for any NEW clients that join the Steam lobby after the game starts
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	# Optional: Clean up player models when someone disconnects
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	# When a new friend connects via Steam, the host spawns them a character
	spawn_player(id)

func _on_peer_disconnected(id: int) -> void:
	# Find the disconnected player's node by their ID and delete it
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

func spawn_player(id: int) -> void:
	# 1. Instantiate the player scene
	var player_instance = player_scene.instantiate()
	
	# 2. CRITICAL: Name the node after the peer's unique network ID!
	# This allows Godot to automatically link inputs and authority later.
	player_instance.name = str(id)
	
	# 3. Set custom spawn coordinates here if needed (e.g., around your Hub generator)
	player_instance.position = Vector3(0, 1, 0)
	
	# 4. Add it to the watched folder. The MultiplayerSpawner takes over from here!
	players_container.add_child(player_instance)
