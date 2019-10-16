tool
extends PathFollow2D

export var speed = 1
export var onInterval = 1
export var offInterval = 0

var t = 0
var isOn = true

func _ready():
	set_process(true)

func _process(delta):
	offset += speed*delta
	t = fmod(t+delta, onInterval+offInterval)
	if t <= onInterval:
		get_node('Sprite').modulate = Color(1,1,1,1)
		get_node('visiblePolygon').visible = true
		isOn = true
	else:
		get_node('Sprite').modulate = Color(0.5,0.5,0.5,1)
		get_node('visiblePolygon').visible = false
		isOn = false