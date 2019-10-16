tool
extends PathFollow2D

export var speed = 1

func _ready():
	set_process(true)

func _process(delta):
	offset += speed*delta