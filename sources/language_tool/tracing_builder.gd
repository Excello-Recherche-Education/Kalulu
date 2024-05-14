extends Control

@export var gradient: Gradient

@onready var lower_container: = %Lower
@onready var upper_container: = %Upper
@onready var letter_picker: = %LetterPicker
@onready var save_ok: = %SaveOk
@onready var copy_from: = %CopyFrom

const extension: = ".csv"

var letters: Array[String] = []
var current_letter: = -1


func _ready() -> void:
	copy_from.get_popup().id_pressed.connect(_on_copy_from_id_pressed)
	
	lower_container.gradient = gradient
	upper_container.gradient = gradient
	
	_find_all_letters()
	_next_letter()


func _find_all_letters() -> void:
	letters = []
	
	var query: = "Select * FROM GPs"
	Database.db.query(query)
	var result: = Database.db.query_result
	for element in result:
		for letter in element.Grapheme:
			if not letter in letters:
				letters.append(letter)
				letter_picker.add_item(letter)
				copy_from.get_popup().add_item(letter)


func _next_letter() -> void:
	current_letter = (current_letter + 1) % letters.size()
	
	await lower_container.reset()
	await upper_container.reset()
	
	lower_container.grapheme_label.text = letters[current_letter].to_lower()
	upper_container.grapheme_label.text = letters[current_letter].to_upper()
	
	_load_segments(lower_container, lower_path(letters[current_letter]))
	_load_segments(upper_container, upper_path(letters[current_letter]))
	
	letter_picker.selected = current_letter
	save_ok.visible = true


func _load_segments(segment_container: SegmentContainer, path: String) -> void:
	if not FileAccess.file_exists(real_path(path)):
		return
	
	var file: = FileAccess.open(real_path(path), FileAccess.READ)
	while not file.eof_reached():
		var line: = file.get_csv_line()
		var points: = []
		for element in line:
			if element == "":
				break
			
			var s: = element.split(" ")
			points.append(Vector2(float(s[0]), float(s[1])))
		if not points.is_empty():
			segment_container.load_segment(points)


func _save_segments(segments: Array, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(Database.base_path.path_join(Database.language).path_join(Database.tracing_data_folder))
	var file: = FileAccess.open(real_path(path), FileAccess.WRITE)
	for segment in segments:
		var values: PackedStringArray = []
		for point in segment.points:
			values.append(str(point.x) + " " + str(point.y))
		file.store_csv_line(values)
	file.close()


func lower_path(letter: String) -> String:
	return letter + "_lower"


func upper_path(letter: String) -> String:
	return letter + "_upper"


func real_path(path: String) -> String:
	return Database.base_path.path_join(Database.language).path_join(Database.tracing_data_folder).path_join(path) + extension


func _on_save_button_pressed() -> void:
	_save_segments(lower_container.segments_container.get_children(), lower_path(letters[current_letter]))
	_save_segments(upper_container.segments_container.get_children(), upper_path(letters[current_letter]))
	
	save_ok.visible = true


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sources/language_tool/prof_tool_menu.tscn")


func _on_letter_picker_item_selected(index: int) -> void:
	current_letter = index - 1
	_next_letter()


func _on_copy_from_id_pressed(index: int) -> void:
	_load_segments(lower_container, lower_path(letters[index]))
	_load_segments(upper_container, upper_path(letters[index]))


func _on_lower_container_changed() -> void:
	save_ok.visible = false


func _on_upper_container_changed() -> void:
	save_ok.visible = false
