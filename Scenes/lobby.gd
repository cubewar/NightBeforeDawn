extends Control

var steam_id: int = 0
var lobby_id: int = 0
var is_host: bool = false
var players: Dictionary = {}
var my_ready: bool = false
var game_started: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	steam_id = Steam.getSteamID()

	%ReadyButton.pressed.connect(_on_ready_pressed)
	%StartButton.pressed.connect(_on_start_pressed)
	%LeaveButton.pressed.connect(_on_leave_pressed)
	%CreateLobbyButton.pressed.connect(_on_create_lobby_pressed)
	%InviteButton.pressed.connect(_on_invite_pressed)
	%BackButton.pressed.connect(_on_back_pressed)

	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_join_lobby)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)

	%StatusLabel.text = "Ready to join or create lobby"
	update_player_display()

	# If we got here because a Steam friend invite was accepted (either the
	# game was already running or was just launched by Steam), join it now.
	if SteamManager.pending_lobby_id > 0:
		%StatusLabel.text = "Joining invited lobby..."
		Steam.joinLobby(SteamManager.pending_lobby_id)
		SteamManager.pending_lobby_id = 0

func _on_create_lobby_pressed():
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)
	%StatusLabel.text = "Creating lobby..."

func _on_invite_pressed():
	if lobby_id > 0:
		Steam.activateGameOverlayInviteDialog(lobby_id)

func _on_ready_pressed():
	if lobby_id <= 0:
		return
	# Flip our own ready flag optimistically instead of reading it back from
	# Steam right away - GodotSteam only mirrors setLobbyMemberData locally
	# after the next run_callbacks() pass, so reading it back in the same
	# frame could still return the old value and make the button look stuck.
	my_ready = not my_ready
	Steam.setLobbyMemberData(lobby_id, "ready", str(my_ready))
	update_player_display()

func _on_start_pressed():
	if not is_host or lobby_id <= 0 or game_started:
		return

	var all_ready = true
	for player_data in players.values():
		if not player_data.get("ready", false):
			all_ready = false
			break

	if all_ready and players.size() >= 1:
		Steam.setLobbyData(lobby_id, "started", "true")
		start_networked_game()
	else:
		%StatusLabel.text = "Not all players ready!"

func start_networked_game():
	if game_started:
		return
	game_started = true

	var peer = SteamMultiplayerPeer.new()
	if is_host:
		peer.create_host(0)
	else:
		var host_steam_id = Steam.getLobbyOwner(lobby_id)
		peer.create_client(host_steam_id, 0)

	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_leave_pressed():
	if lobby_id > 0:
		Steam.leaveLobby(lobby_id)
	multiplayer.multiplayer_peer = null
	lobby_id = 0
	is_host = false
	my_ready = false
	game_started = false
	players.clear()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_back_pressed():
	_on_leave_pressed()

func _on_lobby_match_list(_lobbies: Array):
	pass

func _on_join_lobby(lobby_id_in: int, permissions: int, locked: bool, response: int):
	# In GodotSteam, a response of 1 means SUCCESS (RESULT_OK)
	if response == 1:
		lobby_id = lobby_id_in

		# Check if you are the host by asking Steam who owns this lobby ID
		var lobby_owner = Steam.getLobbyOwner(lobby_id)
		is_host = (lobby_owner == steam_id)

		if is_host:
			Steam.setLobbyJoinable(lobby_id, true)

		%StatusLabel.text = "Joined lobby" if not is_host else "Created lobby (Host)"
		update_player_display()
	else:
		%StatusLabel.text = "Failed to join lobby. Error code: " + str(response)

func _on_lobby_chat_update(lobby_id_update: int, _user_changed: int, _user_making_change: int, _chat_state: int):
	if lobby_id_update == lobby_id:
		update_player_display()

# Fires whenever lobby data OR any member's lobby data changes - this is what
# actually propagates a "ready" toggle (setLobbyMemberData) to OTHER peers,
# and is also how non-host clients learn the host set "started" = "true".
func _on_lobby_data_update(lobby_id_update: int, _member_id: int, _success: int = 1) -> void:
	if lobby_id_update != lobby_id:
		return

	update_player_display()

	if not is_host and not game_started and Steam.getLobbyData(lobby_id, "started") == "true":
		%StatusLabel.text = "Host started the game, connecting..."
		start_networked_game()

func update_player_display():
	%PlayerListLabel.text = "Players:\n"

	if lobby_id > 0:
		var member_count: int = Steam.getNumLobbyMembers(lobby_id)
		players.clear()

		for i in range(member_count):
			var member_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
			var member_name = Steam.getFriendPersonaName(member_id)
			# Trust our own optimistic flag for ourselves - see _on_ready_pressed().
			var member_ready = my_ready if member_id == steam_id else Steam.getLobbyMemberData(lobby_id, member_id, "ready") == "true"
			players[str(member_id)] = {"name": member_name, "ready": member_ready}

			var status = "[READY]" if member_ready else "[NOT READY]"
			%PlayerListLabel.text += member_name + " " + status + "\n"

	%ReadyButton.disabled = lobby_id <= 0
	%StartButton.disabled = not is_host or lobby_id <= 0
	%InviteButton.disabled = lobby_id <= 0
