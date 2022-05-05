extends Panel

var nodes_by_name := {}
var edges := []
export(Curve) var force_connected : Curve
export(Curve) var force_unconnected : Curve

export(bool) var avoid_node_edge_overlap : bool = true

func _ready():
	$"../../VBoxContainer/TextToGraph".connect("pressed",self,"update_from_text")

func maybe_create(id: String) -> DualNode:
	if not id in nodes_by_name:
		var new_node : DualNode = preload("res://DualNode.tscn").instance()
		add_child(new_node)
		nodes_by_name[id] = new_node
		new_node.rect_position.x = rand_range(0.2,0.8)*get_rect().size.x
		new_node.rect_position.y = rand_range(0.2,0.8)*get_rect().size.y
		new_node.set_id(id)
		return new_node
	return nodes_by_name[id]

func is_identifier(_match: RegExMatch):
	return _match.strings[1] != ""

func is_connection(_match: RegExMatch):
	return _match.strings[2] != ""

func make_connection(id1: String, id2: String):
	if id1 in nodes_by_name and id2 in nodes_by_name:
		var names = [id1, id2]
		names.sort()
		edges[names[0]+":"+names[1]] = true

func update_from_text():
	var matches : Array = $"../TextEdit".tokenize()
	var connections := []
	var to_delete = nodes_by_name.keys()
	for index in matches.size():
		var Match := matches[index] as RegExMatch
		if is_identifier(Match):
			var id = Match.get_string()
			print(id)
			var node = maybe_create(id)
			node.neighbors.clear()
			to_delete.erase(id)
		if (is_connection(Match) 
				and index > 0
				and is_identifier(matches[index-1])
				and index < matches.size() - 1
				and is_identifier(matches[index+1])):
			connections += [[index-1, index+1]]
	for id in to_delete:
		nodes_by_name[id].queue_free()
		nodes_by_name.erase(id)
	edges.clear()
	for connection in connections:
		var name1 = matches[connection[0]].get_string()
		var name2 = matches[connection[1]].get_string()
		var node1 = nodes_by_name[name1]
		var node2 = nodes_by_name[name2]
		edges.push_back([node1, node2])
		node1.neighbors.push_back(node2)
		node2.neighbors.push_back(node1)
	if not edges.empty():
		update()

func _draw():
	for edge in edges:
		draw_line(edge[0].rect_position, edge[1].rect_position, Color.red, 2.0)
		
func _process(delta: float):
	var avg = Vector2.ZERO
	for node1 in nodes_by_name.values():
		for node2 in nodes_by_name.values():
			if node1 != node2:
				var curve = force_connected if (node2 in node1.neighbors) else force_unconnected
				var relative_position : Vector2 = node2.rect_position - node1.rect_position
				node1.rect_position += relative_position * \
					curve.interpolate(relative_position.length() / 1000.0) 
		avg += node1.rect_position
	if avoid_node_edge_overlap:
		for node in nodes_by_name.values():
			for edge in edges:
				if not node in edge:
					var middle = (edge[0].rect_position + edge[1].rect_position) / 2.0
					var direction = middle - node.rect_position
					var strength = force_unconnected.interpolate(direction.length() / 1000.0)
					if strength > 0.0:
						strength = 0.0
					var displacement = strength * direction * delta
					node.rect_position += displacement 
					edge[0].rect_position -= displacement / 2.0
					edge[1].rect_position -= displacement / 2.0
		pass
	avg /= nodes_by_name.size()
	avg -= rect_size / 2.0
	for node in nodes_by_name.values():
		node.rect_position -= avg
	
	update()


