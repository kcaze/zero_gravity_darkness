extends Sprite

export var max_dist = 200

func _ready():
	set_process(true)

func _process(delta):
	rotation -= delta*rand_range(2.0,5.0)
