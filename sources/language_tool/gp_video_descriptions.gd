extends Control

@onready var description_container: = %DescriptionsContainer

const description_line_class: = preload("res://sources/language_tool/video_gp_description.tscn")


func _on_description_line_delete(description_line: Control) -> void:
	description_line.queue_free()


func _on_plus_button_pressed() -> void:
	var description_line: = description_line_class.instantiate()
	description_line.delete.connect(_on_description_line_delete.bind(description_line))
	
	description_container.add_child(description_line)
