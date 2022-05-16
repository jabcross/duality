extends Panel

var nodes_by_name := {}
var edges := []
var graph_distances := {}
var intermediaries := {}
export(float, 1, 200) var base_distance : float = 100.0
export(float, 1, 200) var force_scale : float = 100.0
export(int, 0, 10) var intermediary_nodes : int = 2 setget set_intermediary_nodes

func set_intermediary_nodes(num_nodes: int):
	if not get_tree():
		return
	yield(get_tree(),"idle_frame")
	var old_value = intermediary_nodes
	intermediary_nodes = num_nodes
	if text_edit:
		clear_all_intermediaries()
		update_from_text()
	base_distance *= float(old_value + 1)
	base_distance /= num_nodes + 1

func clear_all_intermediaries():
	for inter in intermediaries.keys():
		delete_node(inter)
	intermediaries = {}

func delete_node(node: DualNode):
	nodes_by_name.erase(node.id)
	for neighbor in node.neighbors:
		graph_distances[neighbor].erase(node)
		neighbor.neighbors.erase(node)
	graph_distances.erase(node)
	node.queue_free()

onready var text_edit: TextEdit = $"../TextEdit"

func maybe_create(id: String, _match: RegExMatch) -> DualNode:
	assert(_match != null)
	if not id in nodes_by_name:
		var new_node : DualNode = preload("res://DualNode.tscn").instance()
		add_child(new_node)
		nodes_by_name[id] = new_node
		new_node.rect_position.x = rand_range(0.2,0.8)*get_rect().size.x
		new_node.rect_position.y = rand_range(0.2,0.8)*get_rect().size.y
		new_node.set_id(id)
		new_node.connect("mouse_entered",self,"on_hover_node", [new_node])
		new_node.connect("mouse_exited",self,"on_leave_node", [new_node])
	var node = nodes_by_name[id]
	node.matches[_match] = true
	return node

func is_identifier(_match: RegExMatch):
	return _match.strings[1] != ""

func is_connection(_match: RegExMatch):
	return _match.strings[2] != ""

func make_connection(id1: String, id2: String):
	if id1 in nodes_by_name and id2 in nodes_by_name:
		var names = [id1, id2]
		names.sort()
		edges[names[0]+":"+names[1]] = true

func __connect(a: DualNode, b: DualNode):
	edges.push_back([a, b])
	a.neighbors.push_back(b)
	b.neighbors.push_back(a)

func connect_nodes_with_intermediaries(a: DualNode, b: DualNode, _match: RegExMatch):
	var AtoB = b.rect_position - a.rect_position
	var curr_node = a
	for i in range(1, intermediary_nodes+1):
		var inter := maybe_create(a.id + ":" + b.id + String(i), _match)
		inter.rect_position = (a.rect_position +
			AtoB * float(i) / float(intermediary_nodes+1))
		inter.neighbors.clear()
		inter.set_link()
		__connect(curr_node, inter)
		curr_node = inter
	__connect(curr_node, b)

func update_from_text():
	var matches : Array = text_edit.tokenize()
	var connections := []
	var to_delete = nodes_by_name.keys()
	for node in nodes_by_name.values():
		node.matches = {}
	for index in matches.size():
		var Match := matches[index] as RegExMatch
		if is_identifier(Match):
			var id = Match.get_string()
			print(id)
			var node = maybe_create(id, Match)
			node.neighbors.clear()
			to_delete.erase(id)
		if (is_connection(Match) 
				and index > 0
				and is_identifier(matches[index-1])
				and index < matches.size() - 1
				and is_identifier(matches[index+1])):
			connections += [[index-1, index+1, matches[index]]]
	for id in to_delete:
		nodes_by_name[id].queue_free()
		nodes_by_name.erase(id)
	edges.clear()
	for connection in connections:
		var name1 = matches[connection[0]].get_string()
		var name2 = matches[connection[1]].get_string()
		var node1 = nodes_by_name[name1]
		var node2 = nodes_by_name[name2]
		var match_connector = connection[2]
		connect_nodes_with_intermediaries(node1, node2, match_connector)
		
	graph_distances = {}
	for node in nodes_by_name.values():
		recalculate_distances(node)
	print(graph_distances)
	print(nodes_by_name.values())
	if not edges.empty():
		update()

func __set_distance(a: DualNode, b: DualNode, value: int):
	if not a in graph_distances:
		graph_distances[a] = {}
	if not b in graph_distances:
		graph_distances[b] = {}
	if b in graph_distances[a]:
		value = min(value, graph_distances[a][b])
	if a in graph_distances[b]:
		value = min(value, graph_distances[b][a])
	graph_distances[a][b] = value
	graph_distances[b][a] = value

func recalculate_distances(from: DualNode):
	var bfs = [from]
	__set_distance(from, from, 0)
	var visited = {}
	while not bfs.empty():
		var x : DualNode = bfs.pop_front()
		visited[x] = true
		for n in x.neighbors:
			if not n in visited:
				__set_distance(from, n, graph_distances[from][x] + 1)
				bfs.push_back(n)

func get_graph_distance(a: DualNode, b: DualNode):
	if not (a in graph_distances and b in graph_distances[a]):
		return null
	if b in graph_distances[a]:
		return graph_distances[a][b]
	graph_distances[a][b] = null
	graph_distances[b][a] = null
	return null

func compare_by_degree(a: DualNode, b: DualNode):
	return a.neighbors.size() < b.neighbors.size()

func get_display_radius()->float:
	return min(rect_size.x, rect_size.y) / 2.0

func get_display_center()->Vector2:
	return rect_size/2.0

func place_3rd_point(p_a: Vector2, l_ac: float, p_b: Vector2, l_bc: float)->Vector2:
	var p0 := p_a +(p_b - p_a) * (l_ac / (l_ac + l_bc))
	var alpha = acos(p0.distance_to(p_a)/l_ac)
	return (p_b - p_a).rotated(alpha).normalized() * l_ac + p_a

func get_center_triangle(length_ab: float, length_ac: float, length_bc: float)->Array:
	var point_a = Vector2.ZERO
	var point_b = point_a + Vector2.RIGHT * length_ab
	var point_c = place_3rd_point(point_a, length_ac, point_b, length_bc)
	var points = [point_a, point_b, point_c]
	center_points(points)
	return points

func center_points(array: Array):
	var average := Vector2.ZERO
	for point in array:
		average += point
	average /= float(array.size())
	var offset = get_display_center() - average
	for index in array.size():
		array[index] += offset

func untangle():
	var nodes_to_display := nodes_by_name.values()
	for node in nodes_to_display:
		node.hide()
	nodes_to_display.sort_custom(self,"compare_by_degree")
	
	if nodes_to_display.size() >= 3:
		var node_a : DualNode = nodes_to_display[nodes_to_display.size() - 1]
		var node_b : DualNode = nodes_to_display[nodes_to_display.size() - 2]
		var node_c : DualNode = nodes_to_display[nodes_to_display.size() - 3]

func _draw():
	for edge in edges:
		draw_line(edge[0].rect_position, edge[1].rect_position, Color.red, 2.0)
		
func _process(delta: float):
	var forces = {}
	for a in nodes_by_name.values():
		forces[a] = Vector2.ZERO
		for b in nodes_by_name.values():
			if a != b:
				var node_a : DualNode = a
				var node_b : DualNode = b
				var g_dist = get_graph_distance(node_a, node_b)
				var distance = base_distance
				if g_dist != null:
					distance *= g_dist
				else:
					distance *= 5.0
				var force_offset = node_a.rect_position.distance_to(node_b.rect_position) - distance
				var force = node_a.rect_position.direction_to(node_b.rect_position) * force_offset
				if g_dist == null and force_offset > 0:
					force = Vector2.ZERO
				forces[a] += force

	var avg = Vector2.ZERO
	for node in nodes_by_name.values():
		node.rect_position += forces[node] * delta
		avg += node.rect_position
#	for node in nodes_by_name.values():
#		for edge in edges:
#			if not node in edge:
#				var middle = (edge[0].rect_position + edge[1].rect_position) / 2.0
#				var direction = middle - node.rect_position
#				var strength = force_unconnected.interpolate(direction.length() / 1000.0)
#				if strength > 0.0:
#					strength = 0.0
#				var displacement = strength * direction * delta
#				node.rect_position += displacement 
#				edge[0].rect_position -= displacement / 2.0
#				edge[1].rect_position -= displacement / 2.0
	avg /= nodes_by_name.size()
	avg -= rect_size / 2.0
	for node in nodes_by_name.values():
		node.rect_position -= avg
	
	update()

func on_hover_node(node: DualNode):
	text_edit.highlight(node)

func on_leave_node(node: DualNode):
	text_edit.unhighlight()
