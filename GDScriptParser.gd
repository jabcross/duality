class_name GDScriptParser

var line_re := RegEx.new()

func _init():
	line_re.compile("[^\n]*\n")

func parse(text: String)->Dictionary:
	var nodes := {}
	var lines = line_re.search_all(text)
	for i in lines.size():
		nodes[String(i)] = lines[i]
	return nodes

