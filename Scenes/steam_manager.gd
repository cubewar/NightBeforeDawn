extends Node

func _ready():
	Steam.steamInitEx()
	print("Steam initialized")

func _process(_delta):
	Steam.run_callbacks()
