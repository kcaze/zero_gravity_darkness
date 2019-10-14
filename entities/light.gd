extends Polygon2D

onready var rc = get_node('raycast')
var UPDATE_INTERVAL = 1000/60
var nextUpdate = 0

func _ready():
	set_process(true)

func _process(delta):
	nextUpdate -= delta*1000
	if nextUpdate <= 0:
		get_parent().position = get_viewport().get_mouse_position()
		nextUpdate = UPDATE_INTERVAL
		var offset = get_parent().position
		var maps = get_tree().get_nodes_in_group('collision_map')
		var points = []
		for map in maps:
			var set = map.tile_set
			for pos in map.get_used_cells():
				var cell = map.get_cellv(pos)
				var occluder = set.tile_get_light_occluder(cell)
				var cell_offset = map.map_to_world(pos)
				if occluder == null:
					continue
				for p in occluder.polygon:
					for radOffset in [0,-0.0001, 0.0001]:
						var point = p+cell_offset - offset
						point = point.rotated(radOffset).normalized()*10000
						rc.cast_to = point
						rc.force_raycast_update()
						if rc.is_colliding():
							points.append(rc.get_collision_point() - offset)
		points.sort_custom(self, "sortByAngle")
		var dedupedPoints = []
		var currentPoint = null
		for p in points:
			if currentPoint != null and (p-currentPoint).length() < 1:
				continue
			dedupedPoints.append(p)
			currentPoint = p
		points = PoolVector2Array(dedupedPoints)
		polygon = points

func sortByAngle(a,b):
	return a.angle() < b.angle()
