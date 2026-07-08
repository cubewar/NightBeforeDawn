extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	%StartButton.pressed.connect(_on_start_pressed)
	%MultiplayerButton.pressed.connect(_on_multiplayer_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_multiplayer_pressed():
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

func _on_quit_pressed():
	get_tree().quit()
