@tool
extends TextureButton
class_name DeviceButton

@onready var background: TextureRect = $Background
@onready var label: Label = $Label


@export_range(1, 99) var number: int:
	set(value):
		number = value
		if label:
			label.text = str(value)

@export var background_color: Color:
	set(value):
		background_color = value
		if background:
			background.self_modulate = background_color

func _ready() -> void:
	label.text = str(number)
	background.self_modulate = background_color
