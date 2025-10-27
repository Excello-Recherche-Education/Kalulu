extends Control

var lesson_container_scene: PackedScene = preload("res://sources/language_tool/lesson_container.tscn")
var gp_label_scene: PackedScene = preload("res://sources/language_tool/lesson_gp_label.tscn")
var lessons: Dictionary[int, LessonContainer] = {}

@onready var lessons_container: VBoxContainer = $%LessonsContainer
@onready var unused_gp_container: GridContainer = $%UnusedGPContainer


func _ready() -> void:
	Database.db.query("Select Grapheme, Phoneme, LessonNb, GPID FROM Lessons
		INNER JOIN GPsInLessons ON GPsInLessons.LessonID = Lessons.ID
		INNER JOIN GPs ON GPsInLessons.GPID = GPs.ID
		ORDER BY LessonNb")
	for element: Dictionary in Database.db.query_result:
		if lessons.has(element.LessonNb):
			(lessons[element.LessonNb] as LessonContainer).add_gp({grapheme = element.Grapheme, phoneme = element.Phoneme, gp_id = element.GPID})
		else:
			var lesson_container: LessonContainer = lesson_container_scene.instantiate()
			lessons_container.add_child(lesson_container)
			lesson_container.add_gp({grapheme = element.Grapheme, phoneme = element.Phoneme, gp_id = element.GPID})
			lesson_container.number = element.LessonNb
			lesson_container.lesson_dropped.connect(_on_lesson_dropped)
			lessons[element.LessonNb] = lesson_container
	
	Database.db.query("SELECT Grapheme, Phoneme, GPs.ID as GPID FROM GPs
		WHERE NOT EXISTS(SELECT 1 FROM GPsInLessons WHERE GPs.ID=GPsInLessons.GPID)")
	for element: Dictionary in Database.db.query_result:
		var gp_label: LessonGPLabel = gp_label_scene.instantiate()
		unused_gp_container.add_child(gp_label)
		gp_label.grapheme = element.Grapheme
		gp_label.phoneme = element.Phoneme
		gp_label.gp_id = element.GPID
		gp_label.gp_dropped.connect(_on_gp_dropped)
	
	unused_gp_container.set_drag_forwarding(Callable(), _can_drop_in_gp_container, _drop_data_in_gp_container)


func _on_plus_button_pressed() -> void:
	var lesson_container: LessonContainer = lesson_container_scene.instantiate()
	lessons_container.add_child(lesson_container)
	lesson_container.lesson_dropped.connect(_on_lesson_dropped)
	var max_nb: int = -1
	for element: LessonContainer in lessons.values():
		max_nb = max(max_nb, element.number)
	lesson_container.number = max_nb + 1
	lessons[max_nb + 1] = lesson_container


func _can_drop_in_gp_container(_at_position: Vector2, data: Variant) -> bool:
	@warning_ignore("unsafe_method_access")
	return data.has("gp_id")


func _drop_data_in_gp_container(_at_position: Vector2, data: Variant) -> void:
	@warning_ignore("unsafe_method_access")
	if not data.has("gp_id"):
		return
	var new_gp_label: LessonGPLabel = gp_label_scene.instantiate()
	new_gp_label.grapheme = data.grapheme
	new_gp_label.phoneme = data.phoneme
	new_gp_label.gp_id = data.gp_id
	new_gp_label.gp_dropped.connect(_drop_data_in_gp_container)
	unused_gp_container.add_child(new_gp_label)


func _on_gp_dropped(_before: bool, data: Dictionary) -> void:
	_drop_data_in_gp_container(Vector2.ZERO, data)


func _on_lesson_dropped(before: bool, number: int, dropped_number: int) -> void:
	var dropped_lesson: LessonContainer = lessons[dropped_number]
	var where_lesson: LessonContainer = lessons[number]
	var index: int = where_lesson.get_index()
	if not before:
		index += 1
	lessons_container.move_child(dropped_lesson, index)
	var children: Array[Node] = lessons_container.get_children()
	for ind: int in range(children.size()):
		var child: LessonContainer = children[ind]
		child.number = ind + 1
		lessons[child.number] = child


func _on_save_button_pressed() -> void:
	Database.db.query("DELETE FROM GPsInLessons")
	var children: Array[Node] = lessons_container.get_children()
	for index: int in range(children.size()):
		var child: LessonContainer = children[index]
		Database.db.query_with_bindings("SELECT * FROM Lessons WHERE LessonNb = ?", [index + 1])
		var lesson_id: int = -1
		if Database.db.query_result.is_empty():
			Database.db.insert_row("Lessons",
			{
				LessonNb = index + 1
			})
			lesson_id = Database.db.last_insert_rowid
		else:
			lesson_id = Database.db.query_result[0].ID
		
		for gp_id: int in child.get_gp_ids():
			Database.db.insert_row("GPsInLessons",
			{
				GPID = gp_id,
				LessonID = lesson_id,
			})
	
	Database.db.query_with_bindings("DELETE FROM Lessons WHERE LessonNb > ?", [children.size()])


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sources/language_tool/prof_tool_menu.tscn")
