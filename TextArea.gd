extends TextEdit

var token_re := RegEx.new()

var highlighted_node = null

func _ready():
	token_re.compile("(\\w+)|(--)")

func tokenize() -> Array:
	return token_re.search_all(text)

func _input(event: InputEvent):
	var key_event := event as InputEventKey
	if key_event and key_event.pressed and \
			key_event.scancode == KEY_ENTER and key_event.control:
		$"../GraphDisplay".update_from_text()
		get_viewport().set_input_as_handled()

func get_line_col_from_offset(offset: int)->Vector2:
	var line = 0
	while offset > 0 and line < get_line_count():
		var width = get_line(line).length()
		if width == 0:
			line += 1
			continue
		if width <= offset:
			offset -= width
			line += 1
			continue
		break
	return Vector2(offset, line)

func highlight(node: DualNode):
	highlighted_node = node
	update()
	
func unhighlight():
	highlighted_node = null
	update()

func _draw():
	if highlighted_node:
		for _match in highlighted_node.matches:
			print("Match: ", _match.get_string())
			var left := get_line_col_from_offset(_match.get_start())
			var left_rect := get_rect_at_line_column(left.y, left.x)
			var right := get_line_col_from_offset(_match.get_end() - 1)
			var right_rect := get_rect_at_line_column(right.y, right.x)
			var highlight_rect = Rect2(left_rect.position, right_rect.end - left_rect.position)	
			draw_rect(highlight_rect, Color.red, false)
