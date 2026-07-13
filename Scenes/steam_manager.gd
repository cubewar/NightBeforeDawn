extends Node

var pending_lobby_id: int = 0

func _ready():
	Steam.steamInitEx()
	print("Steam initialized")
	Steam.join_requested.connect(_on_join_requested)
	Steam.lobby_invite.connect(_on_lobby_invite)

func _process(_delta):
	Steam.run_callbacks()

# Fired when the player accepts an invite / clicks "Join Game" from the
# Steam friends list or overlay, whether the game was already running or
# just launched because of the invite.
func _on_join_requested(lobby_id: int, _friend_id: int):
	pending_lobby_id = lobby_id
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

# Fired when a friend sends an in-game invite via activateGameOverlayInviteDialog.
# Steam already shows its own toast for this, so we just remember it in case
# the player opens the lobby screen afterwards without going through the overlay.
func _on_lobby_invite(_inviter_id: int, lobby_id: int, _game_id: int):
	pending_lobby_id = lobby_id
