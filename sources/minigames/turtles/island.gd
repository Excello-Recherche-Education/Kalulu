class_name Island
extends Area2D

var stimulus: Dictionary = {}:
	set(value):
		stimulus = value
		progress = 0
var progress: int = 0:
	set(value):
		progress = value
		_update_label()

@onready var label: Label = $Label
@onready var collision: CollisionPolygon2D = $CollisionPolygon2D


func set_enabled(is_enabled: bool) -> void:
	collision.set_deferred("disabled", !is_enabled)


func _update_label() -> void:
	label.text = ""
	for index: int in range(stimulus.GPsCount):
		if progress > index or progress == stimulus.GPsCount:
			label.text += stimulus.GPs[index].Grapheme
		else:
			label.text += "_"
