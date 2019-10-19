extends KinematicBody2D

const MAX_FALL = 200
const MAX_RUN = 95
const REAL_MAX_RUN = 250
const RUN_ACCEL = 1500
const RUN_REDUCE = 1000
const MAX_SWIM = 50
const SWIM_ACCEL = 500
const SWIM_FRICTION = 0.875
const SWIM_DASH_ACCEL = 300
const GRAVITY = 900
const HALF_GRAVITY_THRESHOLD = 40
const JUMP_GRACE_TIME = 0.1
const JUMP_H_BOOST = 40
const JUMP_SPEED = -215
const JUMP_INPUT_BUFFER = 0.1
const INPUT_X_BUFFER = 0.1
const INPUT_Y_BUFFER = 0.1
const DASH_GRACE_TIME = 1.0/60*3
const WHIRLPOOL_MAX_DIST = 200
const WHIRLPOOL_DIST_POW = 1
const WHIRLPOOL_FORCE = 300
const WHIRLPOOL_RAD_OFFSET = 0.5

var speed = Vector2(0,0)
var dashGraceTime = 0
var jumpGraceTime = 0
var inputMoveX = 0
var inputMoveY = 0
var inputX = 0
var inputY = 0
var inputJump = 0 
var facing = 1

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
	
	if Input.is_action_pressed('left'):
		inputX = -INPUT_X_BUFFER
	elif Input.is_action_pressed('right'):
		inputX = INPUT_X_BUFFER
	else:
		inputX = approach(inputX, 0, delta)
	
	if Input.is_action_pressed('up'):
		inputY = -INPUT_Y_BUFFER
	elif Input.is_action_pressed('down'):
		inputY = INPUT_Y_BUFFER
	else:
		inputY = approach(inputY, 0, delta)
	

func _process(delta):
	updateInput(delta)
	var isInLight = inLight()
	#Graphical updates
	if sign(speed.x) != 0:
		facing = sign(speed.x)
	get_node('Particles2D').emitting = (not isInLight) and max(abs(speed.x),abs(speed.y)) >= MAX_SWIM/SWIM_FRICTION
	get_node('sprite').scale.x = facing
	get_node('sprite').modulate = Color(1,1,1,1) if isInLight else Color(0.5,0.5,0.5,1)
	

	# Regular platforming
	if isInLight:
		if abs(speed.x) > REAL_MAX_RUN:
			speed.x = REAL_MAX_RUN*sign(speed.x)
		if abs(speed.y) > REAL_MAX_RUN:
			speed.y = REAL_MAX_RUN*sign(speed.y)
		dashGraceTime = 0
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
		if is_on_ceiling() and speed.y < 10:
			speed.y = 0
		
		# Jumping
		if inputJump > 0 and jumpGraceTime > 0:
			jump()
	else:
		var maxX = MAX_SWIM*inputMoveX/SWIM_FRICTION
		var maxY = MAX_SWIM*inputMoveY/SWIM_FRICTION
		dashGraceTime -= delta
		if dashGraceTime > 0:
			if inputMoveX != 0 or inputMoveY != 0:
				var s = max(abs(speed.x),abs(speed.y))
				speed.x = inputMoveX*s
				speed.y = inputMoveY*s
		if inputMoveX != 0:
			speed.x = approach(speed.x, maxX, SWIM_ACCEL*delta)*SWIM_FRICTION
		else:
			speed.x *= SWIM_FRICTION
		if inputMoveY != 0:
			speed.y = approach(speed.y, maxY, SWIM_ACCEL*delta)*SWIM_FRICTION
		else:
			speed.y *= SWIM_FRICTION
		if inputJump > 0 and abs(speed.x) < MAX_SWIM/SWIM_FRICTION and abs(speed.y) < MAX_SWIM/SWIM_FRICTION:
			screenshake()
			dashGraceTime = DASH_GRACE_TIME
			if inputX == 0 and inputY == 0:
				speed.x = SWIM_DASH_ACCEL*facing
				speed.y = 0
			else:
				speed.x = sign(inputX)*SWIM_DASH_ACCEL
				speed.y = sign(inputY)*SWIM_DASH_ACCEL
			inputJump = 0
		for whirlpool in get_tree().get_nodes_in_group('whirlpool'):
			
			var direction = -((position-whirlpool.position).rotated(WHIRLPOOL_RAD_OFFSET))
			var mult = 1.0/ pow(direction.length(),WHIRLPOOL_DIST_POW) if direction.length() <= whirlpool.max_dist else 0
			speed.x += WHIRLPOOL_FORCE*mult*direction.normalized().x
			speed.y += WHIRLPOOL_FORCE*mult*direction.normalized().y
		if is_on_wall():
			speed.x /= 2
		if is_on_ceiling() or is_on_floor():
			speed.y /= 2

	move_and_slide(speed, Vector2(0, -1))

func jump():
	jumpGraceTime = 0
	inputJump = 0
	speed.x += JUMP_H_BOOST * inputMoveX
	speed.y = JUMP_SPEED

func inLight():
	for light in get_tree().get_nodes_in_group('light'):
		if not light.isOn:
			continue
		var lightPoints = light.get_node('visiblePolygon').polygon
		var triangulatedPoints = light.get_node('visiblePolygon').triangulatedPolygon
		if triangulatedPoints.size() == 0:
			continue
		for i in range(triangulatedPoints.size()/3):
			var a = lightPoints[triangulatedPoints[3*i]] + light.global_position
			var b = lightPoints[triangulatedPoints[3*i+1]] + light.global_position
			var c = lightPoints[triangulatedPoints[3*i+2]] + light.global_position
			if Geometry.point_is_inside_triangle(position,a,b,c):
				return true
	return false

func screenshake():
	get_node('../level_common/Camera2D').screenshake()

func onSpikeCollide(area):
	if area.is_in_group('whirlpool_collide'):
		if not inLight():
			die()
	else:
		die()

func die():
	get_tree().reload_current_scene()
