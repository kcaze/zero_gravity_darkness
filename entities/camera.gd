extends Camera2D

var screenshakeMagnitude = 0

func _ready():
	set_process(true)

func _process(delta):
	screenshakeMagnitude = max(0, screenshakeMagnitude - 10*delta)
	offset = Vector2(rand_range(0,screenshakeMagnitude), rand_range(0,screenshakeMagnitude))

func screenshake():
	screenshakeMagnitude = 0
