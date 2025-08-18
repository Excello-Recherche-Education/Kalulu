@tool
extends Container

@export_multiline var ref_size_text: String = ""
var ref_size: Vector2
@onready var label: Label = $Label

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_rescale()


func _ready() -> void:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	ref_size = font.get_multiline_string_size(ref_size_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)


func _rescale() -> void:
	label.pivot_offset = label.size / 2
	if ref_size.x == 0 or ref_size.y == 0:
		return
	var scale_factor: float = minf(size.x / ref_size.x, size.y / ref_size.y)
	label.scale = Vector2.ONE * scale_factor
	label.position = size / 2 - label.pivot_offset * label.scale
