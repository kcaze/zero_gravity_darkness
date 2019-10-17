tool
extends Node2D

onready var rc = get_node('raycast')
var UPDATE_INTERVAL = 1000/60
var nextUpdate = 0
var triangulatedPolygon = []
var polygon = PoolVector2Array([])
var angles = []

func _ready():
	self.triangulatedPolygon = []
	set_process(true)

func _draw():
	if polygon.size() < 3:
		return
	var uvs = []
	for i in range(polygon.size()):
		uvs.append(Vector2(0,0))
	draw_colored_polygon(polygon, Color('899bb4'), PoolVector2Array(uvs), null, null, true)

func _process(delta):
	nextUpdate -= delta*1000
	if nextUpdate <= 0:
		nextUpdate = UPDATE_INTERVAL
		#get_parent().position = get_viewport().get_mouse_position()
		var offset = global_position
		var maps = get_tree().get_nodes_in_group('collision_map')
		var points = []
		var indexes = []
		var polygonPoints = []
		angles = []
		var i = 0
		for map in maps:
			var set = map.tile_set
			for pos in map.get_used_cells():
				var cell = map.get_cellv(pos)
				var occluder = set.tile_get_light_occluder(cell)
				var cell_offset = map.map_to_world(pos)
				if occluder == null:
					continue
				for p in occluder.polygon:
					polygonPoints.append(p+cell_offset)
		for borderPolygon in get_tree().get_nodes_in_group('borderPolygon'):
			for p in borderPolygon.polygon:
				polygonPoints.append(p)
		for p in polygonPoints:
			var ps = []
			for radOffset in [-0.0001, 0.0001]:
				var originalPoint = p - offset
				var point = originalPoint.rotated(radOffset).normalized()*750
				rc.cast_to = point
				rc.force_raycast_update()
				if not rc.is_colliding():
					continue
				var collisionPoint = rc.get_collision_point() - offset
				if collisionPoint.length() < originalPoint.length() - 1:
					continue
				ps.append(collisionPoint)
			if ps.size() == 2 and (ps[0] - ps[1]).length() <= 1:
				ps = [ps[0]]
			for pp in ps:
				points.append(pp)
				indexes.append(i)
				angles.append(pp.angle())
				i += 1
		indexes.sort_custom(self, "sortByAngle")
		var sortedPoints = []
		var dedupedPoints = []
		var currentPoint = null
		for idx in indexes:
			sortedPoints.append(points[idx])
		for p in sortedPoints:
			if currentPoint != null and (p-currentPoint).length() < 1:
				continue
			dedupedPoints.append(p)
			currentPoint = p
		polygon = PoolVector2Array(dedupedPoints)
		self.triangulatedPolygon = Geometry.triangulate_polygon(polygon)
		update()

func sortByAngle(a,b):
	return angles[a] < angles[b]
