tool
extends EditorPlugin

var editor_interface: EditorInterface
var dock_columns = []

func find_closest_ancestor_of_type(node, type):
	var ancestor = node.get_parent()
	while ancestor:
		if ancestor is type:
			return ancestor
		ancestor = ancestor.get_parent()

func _enter_tree():
	editor_interface = get_editor_interface()
	var a_dock = editor_interface.get_file_system_dock()
	var a_hsplit = find_closest_ancestor_of_type(a_dock, HSplitContainer)
	while a_hsplit.get_parent() is HSplitContainer:
		a_hsplit = a_hsplit.get_parent()
	if a_hsplit == null:
		# fail
		self.queue_free()
	var curr_hsplit = a_hsplit
	while curr_hsplit:
		var hsplit = curr_hsplit
		curr_hsplit = null
		for node in hsplit.get_children():
			if node is VSplitContainer:
				dock_columns.push_back(node)
			if node is HSplitContainer:
				curr_hsplit = node
	for column in dock_columns:
		make_collapsible(column)

func toggle_visibility(button: Button, control: Control):
	if dock_columns.find(control) < 2:
		button.get_parent().get_parent().collapsed = control.visible
	control.visible = not control.visible

func make_collapsible(dock_column: VSplitContainer):
	var cont := preload("res://addons/CollapsibleDocks/CollapseButton.tscn")\
		.instance()
	dock_column.get_parent().add_child_below_node(dock_column, cont)
	dock_column.get_parent().remove_child(dock_column)
	cont.add_child(dock_column)
	dock_column.size_flags_horizontal |= Control.SIZE_EXPAND
	for child in cont.get_children():
		if child is Button:
			child.connect("pressed", self, "toggle_visibility", [child, dock_column])
			if dock_columns.find(dock_column) < 2:
				cont.move_child(child, 1)

func remove_collapsible(dock_column: VSplitContainer):
	var cont = dock_column.get_parent()
	cont.remove_child(dock_column)
	cont.get_parent().add_child_below_node(cont, dock_column)
	cont.queue_free()
	dock_column.show()
	dock_column.size_flags_horizontal &= ~Control.SIZE_EXPAND

func _exit_tree():
	for column in dock_columns:
		remove_collapsible(column)
