extends KinematicBody2D

const MAX_FALL = 180
const MAX_RUN = 120
const RUN_ACCEL = 1000
const GRAVITY = 500
const HALF_GRAVITY_THRESHOLD = 10
const JUMP_GRACE_TIME = 0.1
const JUMP_H_BOOST = 40
const JUMP_SPEED = -205
const JUMP_INPUT_BUFFER = 0.1

var speed = Vector2(0,0)
var jumpGraceTime = 0
var inputMoveX = 0
var inputJump = 0 

func approach(curr, bound, delta):
	var s = sign(bound - curr)
	return max(bound, curr+s*abs(delta)) if s == -1 else min(bound, curr+s*abs(delta))

func _ready():
	set_process(true)

func updateInput(delta):
	if Input.is_action_just_pressed('left'):
		inputMoveX = -1
	elif Input.is_action_just_released('left'):
		inputMoveX = 1 if Input.is_action_pressed('right') else 0
	if Input.is_action_just_pressed('right'):
		inputMoveX = 1
	elif Input.is_action_just_released('right'):
		inputMoveX = -1 if Input.is_action_pressed('left') else 0
	
	if Input.is_action_just_pressed('jump'):
		inputJump = JUMP_INPUT_BUFFER
	elif not Input.is_action_pressed('jump'):
		inputJump -= delta

func _process(delta):
	updateInput(delta)

	if is_on_floor():
		jumpGraceTime = JUMP_GRACE_TIME
	else:
		jumpGraceTime -= delta

	# Horizontal movement
	speed.x = approach(speed.x, MAX_RUN*inputMoveX, RUN_ACCEL*delta)

	# Gravity
	if not is_on_floor():
		var gravityMult = 0.5 if abs(speed.y) < HALF_GRAVITY_THRESHOLD and Input.is_action_pressed('jump') else 1
		speed.y = approach(speed.y, MAX_FALL, GRAVITY*delta*gravityMult)

	# Jumping
	if inputJump > 0 and jumpGraceTime > 0:
		jump()

	move_and_slide(speed, Vector2(0, -1))

func jump():
	jumpGraceTime = 0
	inputJump = 0
	speed.x += JUMP_H_BOOST * inputMoveX
	speed.y = JUMP_SPEED
