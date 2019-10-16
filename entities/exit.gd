extends Area2D

export (PackedScene) var nextLevel

func _ready():
	print(nextLevel)

func onAreaEntered(area):
	if area.is_in_group('player'):
		get_tree().change_scene_to(nextLevel)