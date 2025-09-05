@tool
class_name GardenLayout
extends Resource

enum FirstOrLast {
	First,
	Neither,
	Last
}

@export var color: int = 0
@export var flowers_export: Array[Dictionary] = []:
	set = set_flowers_export
@export var lesson_buttons_export: Array[Dictionary] = []:
	set = set_lesson_buttons_export
@export var is_first_or_last: FirstOrLast = FirstOrLast.Neither

var flowers: Array[Flower] = []:
	set = set_flowers
var lesson_buttons: Array[GardenLayoutLessonButton] = []:
	set = set_lesson_buttons


func set_flowers_export(p_flowers_export: Array[Dictionary]) -> void:
	flowers_export = p_flowers_export
	flowers.clear()
	for flower_dict: Dictionary in flowers_export:
		flowers.append(Flower.from_dict(flower_dict))


func set_flowers(p_flowers: Array[Flower]) -> void:
	flowers = p_flowers
	flowers_export.clear()
	for flower: Flower in flowers:
		flowers_export.append(flower.to_dict())


func set_lesson_buttons_export(p_lesson_buttons_export: Array[Dictionary]) -> void:
	lesson_buttons_export = p_lesson_buttons_export
	lesson_buttons.clear()
	for lesson_button_dict: Dictionary in lesson_buttons_export:
		lesson_buttons.append(GardenLayoutLessonButton.from_dict(lesson_button_dict))


func set_lesson_buttons(p_lesson_buttons: Array[GardenLayoutLessonButton]) -> void:
	lesson_buttons = p_lesson_buttons
	lesson_buttons_export.clear()
	for lesson_button: GardenLayoutLessonButton in lesson_buttons:
		lesson_buttons_export.append(lesson_button.to_dict())


class Flower:
	var color: int = 0
	var type: int = 0
	var position: Vector2 = Vector2i.ZERO
	
	
	func _init(p_color: int = 0, p_type: int = 0, p_position: Vector2i = Vector2i.ZERO) -> void:
		color = p_color
		type = p_type
		position = p_position
	
	
	static func from_dict(d: Dictionary) -> Flower:
		return Flower.new(d.color as int, d.type as int, d.position as Vector2i)
	
	
	func to_dict() -> Dictionary:
		return {
			color = color,
			type = type,
			position = position,
		}


class GardenLayoutLessonButton:
	var position: Vector2i = Vector2i.ZERO
	var path_out_position: Vector2i = Vector2i.ZERO
	
	
	func _init(p_position: Vector2i = Vector2i.ZERO, p_path_out_position: Vector2i = Vector2i.ZERO) -> void:
		position = p_position
		path_out_position = p_path_out_position
	
	
	static func from_dict(d: Dictionary) -> GardenLayoutLessonButton:
		return GardenLayoutLessonButton.new(d.position as Vector2i, d.path_out_position as Vector2i)
	
	
	func to_dict() -> Dictionary:
		return {
			position = position,
			path_out_position = path_out_position
		}
