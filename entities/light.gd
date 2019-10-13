extends Polygon2D

onready var map = get_node('../TileMap')
onready var set = get_node('../TileMap').tile_set
onready var rc = get_node('RayCast2D')

var t = 0

func _ready():
	set_process(true)

func _process(delta):
	t += delta
	position.y += 0.5*sin(t)
	var points = []
	var castPoints = []
	for pos in map.get_used_cells():
		var cell = map.get_cellv(pos)
		var occluder = set.tile_get_light_occluder(cell)
		var cell_offset = map.map_to_world(pos)
		for p in occluder.polygon:
			castPoints.append(p+cell_offset - position)
	castPoints.sort_custom(self, "sortByAngle")
	for pos in castPoints:
		rc.cast_to = pos
		rc.force_raycast_update()
		if rc.is_colliding():
			points.append(rc.get_collision_point() - position)

	polygon = PoolVector2Array(points)

func sortByAngle(a,b):
	return atan2(a.y,a.x) < atan2(b.y,b.x)