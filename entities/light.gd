extends Area2D

onready var rc = get_node('raycast')
var UPDATE_INTERVAL = 1000/60
var nextUpdate = 0

func _ready():
	set_process(true)

func _process(delta):
	nextUpdate -= delta*1000
	if nextUpdate <= 0:
		nextUpdate = UPDATE_INTERVAL
		get_parent().position = get_viewport().get_mouse_position()
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
				var isVisible = false
				var occluderPoints = []
				for p in occluder.polygon:
					for radOffset in [0,-0.00001, 0.00001]:
						var point = (p+cell_offset - offset).rotated(radOffset)
						rc.cast_to = point
						rc.force_raycast_update()
						if rc.is_colliding():
							occluderPoints.append(rc.get_collision_point() - offset)
							if (rc.get_collision_point() - offset - point).length() < 0.1:
								isVisible = true
				if isVisible:
					for p in occluderPoints:
						points.append(p)
		points.sort_custom(self, "sortByAngle")
		var dedupedPoints = []
		var currentPoint = null
		for p in points:
			if currentPoint != null and (p-currentPoint).length() < 1:
				continue
			dedupedPoints.append(p)
			currentPoint = p
		print(dedupedPoints.size())
		points = PoolVector2Array(dedupedPoints)
		get_node('visiblePolygon').polygon = points
		get_node('collisionPolygon').polygon = points

func sortByAngle(a,b):
	return a.angle() < b.angle()
