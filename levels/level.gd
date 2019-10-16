extends Node2D

var t = 0

func _ready():
	set_process(true)

func _process(delta):
	t += delta/2
	get_node('background').modulate.a = pow(sin(t),2)
	get_node('background2').modulate.a = pow(cos(t),2)
