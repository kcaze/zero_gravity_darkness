tool
extends PathFollow2D

export var speed = 1
export var intervalOffset = 0.0
export var onInterval = 1.0
export var offInterval = 0.0

var t = intervalOffset
var isOn = true

func _ready():
	t = intervalOffset
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
