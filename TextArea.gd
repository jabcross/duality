extends TextEdit

var token_re := RegEx.new()

func _ready():
	token_re.compile("(\\w+)|(--)")

func tokenize() -> Array:
	return token_re.search_all(text)

func _gui_input(event: InputEvent):
	var key_event := event as InputEventKey
	if key_event and key_event.pressed and \
			key_event.scancode == KEY_ENTER and key_event.control:
		$"../GraphDisplay".update_from_text()
		get_viewport().set_input_as_handled()
