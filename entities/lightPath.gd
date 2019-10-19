tool
extends PathFollow2D

export var speed = 1
export var intervalOffset = 0.0
export var onInterval = 1.0
export var offInterval = 0.0
export var goBack = false

var t = intervalOffset
var internalPathOffset = 0
var isOn = true

func _ready():
	t = intervalOffset
	set_process(true)

func _process(delta):
	internalPathOffset += speed*delta
	if get_parent() is Path2D and goBack:
		var length = get_parent().curve.get_baked_length()
		var o = fmod(internalPathOffset,2*length)
		if o > length:
			offset = 2*length - o
		else:
			offset = o
	else:
		offset = internalPathOffset
	t = fmod(t+delta, onInterval+offInterval)
	if t >= onInterval -0.5 and t < onInterval and offInterval > 0:
		get_node('Sprite').modulate = Color(1,1,1,0.75)
		get_node('visiblePolygon').visible = true
		get_node('visiblePolygon').modulate = Color(0.75,0.75,0.75,1)
		isOn = true
	elif t <= onInterval:
		get_node('Sprite').modulate = Color(1,1,1,1)
		get_node('visiblePolygon').visible = true
		get_node('visiblePolygon').modulate = Color(1,1,1,1)
		isOn = true
	elif t >= onInterval+offInterval - 0.5:
		get_node('Sprite').modulate = Color(0.75,0.75,0.75,1)
		get_node('visiblePolygon').visible = true
		get_node('visiblePolygon').modulate = Color(0.25,0.25,0.25,0.25)
		isOn = false
	else:
		get_node('Sprite').modulate = Color(0.5,0.5,0.5,1)
		get_node('visiblePolygon').visible = false
		isOn = false
