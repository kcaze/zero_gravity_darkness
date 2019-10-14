extends KinematicBody2D

const MAX_FALL = 500
const MAX_RUN = 200
const RUN_ACCEL = 2000
const RUN_REDUCE = 750
const MAX_SWIM = 120
const SWIM_ACCEL = 500
const SWIM_FRICTION = 0.95
const SWIM_DASH_ACCEL = 500
const GRAVITY = 900
const HALF_GRAVITY_THRESHOLD = 10
const JUMP_GRACE_TIME = 0.1
const JUMP_H_BOOST = 40
const JUMP_SPEED = -305
const JUMP_INPUT_BUFFER = 0.1

var speed = Vector2(0,0)
var jumpGraceTime = 0
var inputMoveX = 0
var inputMoveY
var inputJump = 0 

func approach(curr, bound, delta):
	var s = sign(bound - curr)
	return max(bound, curr+s*abs(delta)) if s == -1 else min(bound, curr+s*abs(delta))

func _ready():
	set_process(true)

func updateInput(delta):
	inputMoveX = (-1 if Input.is_action_pressed('left') else 0) + (1 if Input.is_action_pressed('right') else 0)
	inputMoveY = (-1 if Input.is_action_pressed('up') else 0) + (1 if Input.is_action_pressed('down') else 0)
	
	if Input.is_action_just_pressed('jump'):
		inputJump = JUMP_INPUT_BUFFER
	elif not Input.is_action_pressed('jump'):
		inputJump -= delta

func _process(delta):
	updateInput(delta)
	var isInLight = inLight()

	# Regular platforming
	if isInLight:
		if is_on_floor():
			jumpGraceTime = JUMP_GRACE_TIME
		else:
			jumpGraceTime -= delta
		
		# Horizontal movement
		var maxX = MAX_RUN*inputMoveX
		if abs(speed.x) > abs(maxX) and sign(speed.x) != -inputMoveX:
			speed.x = approach(speed.x, maxX, RUN_REDUCE*delta)
		else:
			speed.x = approach(speed.x, maxX, RUN_ACCEL*delta)
		
		# Gravity
		if not is_on_floor():
			var gravityMult = 0.5 if abs(speed.y) < HALF_GRAVITY_THRESHOLD and Input.is_action_pressed('jump') else 1
			speed.y = approach(speed.y, MAX_FALL, GRAVITY*delta*gravityMult)
		else:
			speed.y = 0
		
		# Jumping
		if inputJump > 0 and jumpGraceTime > 0:
			jump()
	else:
		var maxX = MAX_SWIM*inputMoveX/SWIM_FRICTION
		var maxY = MAX_SWIM*inputMoveY/SWIM_FRICTION
		if inputMoveX != 0:
			speed.x = approach(speed.x, maxX, SWIM_ACCEL*delta)*SWIM_FRICTION
		else:
			speed.x *= SWIM_FRICTION
		if inputMoveY != 0:
			speed.y = approach(speed.y, maxY, SWIM_ACCEL*delta)*SWIM_FRICTION
		else:
			speed.y *= SWIM_FRICTION
		if inputJump > 0:
			if inputMoveX == 0 and inputMoveY == 0:
				speed.x = SWIM_DASH_ACCEL
				speed.y = 0
			else:
				speed.x = inputMoveX*SWIM_DASH_ACCEL
				speed.y = inputMoveY*SWIM_DASH_ACCEL
			inputJump = 0

	move_and_slide(speed, Vector2(0, -1))

func jump():
	jumpGraceTime = 0
	inputJump = 0
	speed.x += JUMP_H_BOOST * inputMoveX
	speed.y = JUMP_SPEED

func inLight():
	for light in get_tree().get_nodes_in_group('light'):
		var lightPoints = light.get_node('visiblePolygon').polygon
		var triangulatedPoints = Geometry.triangulate_polygon(lightPoints)
		if triangulatedPoints.size() == 0:
			continue
		for i in range(triangulatedPoints.size()/3):
			var a = lightPoints[triangulatedPoints[3*i]] + light.position
			var b = lightPoints[triangulatedPoints[3*i+1]] + light.position
			var c = lightPoints[triangulatedPoints[3*i+2]] + light.position
			if Geometry.point_is_inside_triangle(position,a,b,c):
				return true
	return false
