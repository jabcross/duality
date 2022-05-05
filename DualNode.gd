class_name DualNode
extends Control

var id: String = ""
var label: String = ""
var neighbors: Array = []

func _ready():
	pass

func set_id(id: String):
	self.id = id
	if label == "":
		label = id.capitalize()
	$"ColorRect/Label".text = id
	$ColorRect.hint_tooltip = id
