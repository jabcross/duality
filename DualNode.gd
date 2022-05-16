class_name DualNode
extends Control

var id: String = ""
var label: String = ""
var neighbors: Array = []
var matches := {}

func _ready():
	pass

func set_id(id: String):
	self.id = id
	if label == "":
		label = id.capitalize()
	$"ColorRect/Label".text = id
	$ColorRect.hint_tooltip = id

func _to_string():
	return label

func set_link():
	$ColorRect.hide()
	$Link.show()
