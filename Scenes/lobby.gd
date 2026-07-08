extends Control

var steam_id: int = 0
var lobby_id: int = 0
var is_host: bool = false
var players: Dictionary = {}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	steam_id = Steam.get_steam_id()

	%ReadyButton.pressed.connect(_on_ready_pressed)
	%StartButton.pressed.connect(_on_start_pressed)
	%LeaveButton.pressed.connect(_on_leave_pressed)
	%CreateLobbyButton.pressed.connect(_on_create_lobby_pressed)
	%BackButton.pressed.connect(_on_back_pressed)

	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.join_lobby.connect(_on_join_lobby)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)

	%StatusLabel.text = "Ready to join or create lobby"
	update_player_display()

func _on_create_lobby_pressed():
	Steam.create_lobby(Steam.LOBBY_TYPE_PUBLIC, 4)
	%StatusLabel.text = "Creating lobby..."

func _on_join_lobby_pressed():
	if lobby_id > 0:
		Steam.join_lobby(lobby_id)

func _on_ready_pressed():
	if lobby_id <= 0:
		return
	var player_data = {
		"ready": not players.get(str(steam_id), {}).get("ready", false)
	}
	Steam.set_lobby_member_data(lobby_id, "ready", str(player_data.ready))
	players[str(steam_id)]["ready"] = player_data.ready
	update_player_display()

func _on_start_pressed():
	if not is_host or lobby_id <= 0:
		return

	var all_ready = true
	for player_data in players.values():
		if not player_data.get("ready", false):
			all_ready = false
			break

	if all_ready and players.size() >= 1:
		for player_id in players.keys():
			Steam.send_p2p_packet(int(player_id), "START_GAME")
		get_tree().change_scene_to_file("res://Scenes/game.tscn")
	else:
		%StatusLabel.text = "Not all players ready!"

func _on_leave_pressed():
	if lobby_id > 0:
		Steam.leave_lobby(lobby_id)
	lobby_id = 0
	is_host = false
	players.clear()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_back_pressed():
	_on_leave_pressed()

func _on_lobby_match_list(lobbies: Array):
	pass

func _on_join_lobby(result: Dictionary):
	if result["result"] == Steam.RESULT_OK:
		lobby_id = result["lobby_id"]
		is_host = result["lobby_owner"] == steam_id
		%StatusLabel.text = "Joined lobby" if not is_host else "Created lobby (Host)"
		update_player_display()
	else:
		%StatusLabel.text = "Failed to join lobby"

func _on_lobby_chat_update(lobby_id_update: int, user_changed: int, user_making_change: int, chat_state: int):
	if lobby_id_update == lobby_id:
		update_player_display()

func update_player_display():
	%PlayerListLabel.text = "Players:\n"

	if lobby_id > 0:
		var lobby_members = Steam.get_lobby_members(lobby_id)
		players.clear()

		for member_id in lobby_members:
			var member_name = Steam.get_friend_personaname(member_id)
			var member_ready = Steam.get_lobby_member_data(lobby_id, member_id, "ready") == "true"
			players[str(member_id)] = {"name": member_name, "ready": member_ready}

			var status = "[READY]" if member_ready else "[NOT READY]"
			%PlayerListLabel.text += member_name + " " + status + "\n"

	%ReadyButton.disabled = lobby_id <= 0
	%StartButton.disabled = not is_host or lobby_id <= 0
