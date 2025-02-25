extends MarginContainer

signal delete_pressed()
signal new_GP_asked(i: int)
signal validated()
signal GPs_updated()

const gp_list_button_scene: = preload("res://sources/language_tool/gp_list_button.tscn")
const plus_button_scene: = preload("res://sources/language_tool/plus_button.tscn")

@export var table: = "Words"
@export var table_graph_column: = "Word"
@export var sub_table: = "GPs"
@export var sub_table_graph_column: = "Grapheme"
@export var sub_table_phon_column: = "Phoneme"
@export var relational_table: = "GPsInWords"
@export var sub_table_id: = "GPID"

@onready var word_label: = %Word
@onready var graphemes_label: = %Graphemes
@onready var word_edit: = %WordEdit
@onready var tab_container: = $TabContainer
@onready var lesson_label: = %Lesson
@onready var exception_checkbox: = %ExceptionCheckBox
@onready var exception_edit_checkbox: = %ExceptionEditCheckBox
@onready var graphemes_edit_container: = %GraphemesEditContainer
@onready var add_gp_button: = %AddGPButton
@onready var remove_gp_button: = %RemoveGPButton2

var word: = "":
	set = set_word
var lesson: = 0:
	set = set_lesson
var undo_redo: UndoRedo:
	get:
		if not undo_redo:
			undo_redo = UndoRedo.new()
		return undo_redo
var id: = -1
var gp_ids: Array[int] = []:
	set = set_gp_ids
var unvalidated_gp_ids: Array[int] = []
var exception: = 0:
	set = set_exception
var sub_elements_list: Dictionary


func set_exception(p_exception: bool) -> void:
	exception = p_exception
	if exception_checkbox:
		exception_checkbox.button_pressed = bool(exception)
	if exception_edit_checkbox:
		exception_edit_checkbox.button_pressed = bool(exception)


func set_word(p_word: String) -> void:
	word = p_word
	if word_label:
		word_label.text = word
	if word_edit:
		word_edit.text = word


func set_gp_ids(p_gp_ids: Array[int]) -> void:
	gp_ids = p_gp_ids
	if graphemes_label:
		graphemes_label.text = get_gps(gp_ids)


func set_graphemes_edit(p_gp_ids: Array[int]) -> void:
	if graphemes_edit_container:
		for child in graphemes_edit_container.get_children():
			graphemes_edit_container.remove_child(child)
			child.queue_free()
		for ind_gp_id in p_gp_ids.size():
			var gp_id: = p_gp_ids[ind_gp_id]
			add_gp_list_button(gp_id, ind_gp_id)


func add_gp_list_button(gp_id: int, ind_gp_id: int) -> void:
	var gp_list_button: = gp_list_button_scene.instantiate()
	gp_list_button.set_gp_list(sub_elements_list)
	graphemes_edit_container.add_child(gp_list_button)
	graphemes_edit_container.move_child(gp_list_button, 2 * ind_gp_id)
	gp_list_button.select_id(gp_id)
	gp_list_button.gp_selected.connect(_on_gp_list_button_selected.bind(gp_list_button))
	gp_list_button.new_selected.connect(_on_gp_list_button_new_selected.bind(gp_list_button))
	var plus_button: = plus_button_scene.instantiate()
	plus_button.size = Vector2(50, 50)
	graphemes_edit_container.add_child(plus_button)
	graphemes_edit_container.move_child(plus_button, 2 * ind_gp_id + 1)
	plus_button.pressed.connect(_on_add_gp_button_pressed.bind(gp_list_button))


func _on_gp_list_button_selected(gp_id: int, element: Node) -> void:
	var ind_gp_id: = element.get_index() / 2
	unvalidated_gp_ids[ind_gp_id] = gp_id
	word_edit.text = get_graphemes(unvalidated_gp_ids)


func _on_gp_list_button_new_selected(element: Node) -> void:
	var ind_gp_id: = element.get_index() / 2
	new_GP_asked.emit(ind_gp_id)


func get_graphemes(p_gp_ids: Array[int]) -> String:
	var res: = ""
	for gp_id in p_gp_ids:
		res += sub_elements_list[gp_id].grapheme
	return res


func get_gps(p_gp_ids: Array[int]) -> String:
	var res: = ""
	for gp_id in p_gp_ids:
		res += sub_elements_list[gp_id].grapheme
		res += "-"
		res += sub_elements_list[gp_id].phoneme
		res += " "
	return res


func set_lesson(p_lesson: int) -> void:
	lesson = p_lesson
	if lesson_label:
		lesson_label.text = str(p_lesson)


func _ready() -> void:
	set_word(word)
	set_gp_ids(gp_ids)
	set_lesson(lesson)
	set_exception(exception)
	%WordEditLabel.text = table_graph_column + ": "
	%GPsEditLabel.text = sub_table + ": "


func _on_edit_button_pressed() -> void:
	edit_mode()


func edit_mode() -> void:
	set_graphemes_edit(gp_ids)
	tab_container.current_tab = 1


func _on_minus_button_pressed() -> void:
	delete_pressed.emit()


func _on_validate_button_pressed() -> void:
	undo_redo.create_action("validated")
	undo_redo.add_do_property(self, "gp_ids", unvalidated_gp_ids.duplicate())
	undo_redo.add_do_property(self, "word", word_edit.text)
	undo_redo.add_do_property(self, "exception", int(exception_edit_checkbox.button_pressed))
	undo_redo.add_undo_property(self, "gp_ids", gp_ids.duplicate())
	undo_redo.add_undo_property(self, "word", word)
	undo_redo.add_undo_property(self, "exception", int(exception_checkbox.button_pressed))
	undo_redo.commit_action()
	tab_container.current_tab = 0
	update_lesson()
	validated.emit()


func update_lesson() -> void:
	var m: = -1
	for gp_id in gp_ids:
		var i: = Database.get_min_lesson_for_gp_id(gp_id)
		if i < 0:
			m = -1
			break
		m = max(m, i)
	lesson = m


func gp_ids_from_string(p_gp_ids: String) -> Array[int]:
	var res: Array[int] = []
	var s: = p_gp_ids.split(" ")
	res.resize(s.size())
	for i in s.size():
		res[i] = int(s[i])
	return res


func set_gp_ids_from_string(p_gp_ids: String) -> void:
	gp_ids = gp_ids_from_string(p_gp_ids)
	unvalidated_gp_ids = gp_ids.duplicate()


func insert_in_database() -> void:
	if id < 0:
		Database.db.query_with_bindings("SELECT * FROM %s WHERE %s=?" % [table, table_graph_column], [word])
		if not Database.db.query_result.is_empty():
			id = Database.db.query_result[0].ID
	
	if id >= 0:
		var query: = "SELECT %s, group_concat(%s, ' ') as %ss, group_concat(%s, ' ') as %ss, group_concat(%s.ID, ' ') as %sIDs, group_concat(%s.ID, ' ') as %sIDs, %s.Exception
			FROM %s 
			INNER JOIN ( SELECT * FROM %s ORDER BY %s.Position ) %s ON %s.ID = %s.%sID 
			INNER JOIN %s ON %s.ID = %s.%s
			WHERE %s.ID = ? 
			GROUP BY %s.ID" % [table_graph_column, sub_table_graph_column, sub_table_graph_column,
				sub_table_phon_column, sub_table_phon_column,
				relational_table, relational_table, sub_table, sub_table, table,
				table,
				relational_table, relational_table, relational_table, table, relational_table, table_graph_column,
				sub_table, sub_table, relational_table, sub_table_id,
				table,
				table]
		Database.db.query_with_bindings(query, [id])
		print(query)
		if not Database.db.query_result.is_empty():
			var e = Database.db.query_result[0]
			if word != e[table_graph_column] or exception != e.Exception:
				Database.db.update_rows(table, "ID=%s" % id, {table_graph_column: word, "Exception": exception})
			if " ".join(gp_ids) != e[sub_table + "IDs"]:
				var gps_in_words_ids: Array = Array(e[relational_table + "IDs"].split(" "))
				while gps_in_words_ids.size() > gp_ids.size():
					Database.db.delete_rows(relational_table, "ID=%s" % int(gps_in_words_ids.pop_back()))
				for i in gps_in_words_ids.size():
					var gps_in_words_id: = int(gps_in_words_ids[i])
					Database.db.update_rows(relational_table, "ID=%s" % gps_in_words_id, {
						table_graph_column + "ID": id,
						sub_table_id: gp_ids[i],
						"Position": i
						})
				for i in range(gps_in_words_ids.size(), gp_ids.size()):
					Database.db.insert_row(relational_table, {
						table_graph_column + "ID": id,
						sub_table_id: gp_ids[i],
						"Position": i
						})
			return
		else:
			Database.db.query_with_bindings("SELECT * FROM %s WHERE %s=?" % [table, table_graph_column], [word])
			if not Database.db.query_result.is_empty():
				var e = Database.db.query_result[0]
				id = e.ID
				if word != e[table_graph_column] or exception != e.Exception:
					Database.db.update_rows(table, "ID=%s" % id, {table_graph_column: word, "Exception": exception})
				for i in range(gp_ids.size()):
					Database.db.insert_row(relational_table, {
						table_graph_column + "ID": id,
						sub_table_id: gp_ids[i],
						"Position": i
						})
			
	Database.db.query_with_bindings("SELECT * FROM %s WHERE %s=?" % [table, table_graph_column], [word])
	if Database.db.query_result.is_empty():
		Database.db.insert_row(table, {table_graph_column: word})
		id = Database.db.last_insert_rowid
		for i in gp_ids.size():
			Database.db.insert_row(relational_table, {
						table_graph_column + "ID": id,
						sub_table_id: gp_ids[i],
						"Position": i
					})


func _already_in_database(text: String) -> int:
	var query: = "SELECT %s.ID, %s, group_concat(%s, ' ') as %ss, group_concat(%s, ' ') as %ss, group_concat(%s.ID, ' ') as %sIDs 
	FROM %s 
	INNER JOIN ( SELECT * FROM %s ORDER BY %s.Position ) %s ON %s.ID = %s.%sID 
	INNER JOIN %s ON %s.ID = %s.%s
	WHERE %s.%s = ? 
	GROUP BY %s.ID" % [table, table_graph_column, sub_table_graph_column, sub_table_graph_column,
		sub_table_phon_column, sub_table_phon_column,
		relational_table, relational_table,
		table,
		relational_table, relational_table, relational_table, table, relational_table, table_graph_column,
		sub_table, sub_table, relational_table, sub_table_id,
		table, table_graph_column,
		table]
	Database.db.query_with_bindings(query, [text])
	if not Database.db.query_result.is_empty():
		var e = Database.db.query_result[0]
		id = e.ID
		return id
	return -1


func _add_from_additional_word_list(new_text: String) -> int:
	if new_text in Database.additional_word_list:
		var is_word: = table == "Words"
		var res: = Database._import_word_from_csv(new_text, Database.additional_word_list[new_text].GPMATCH, is_word)
		GPs_updated.emit()
		id = res[0]
		gp_ids = res[1]
		unvalidated_gp_ids = gp_ids
		return id
	return -1


func _try_to_complete_from_word(new_text: String) -> int:
	var id: = _already_in_database(new_text)
	if id >= 0:
		print("Already in DB " + new_text)
		return id
	
	id = _add_from_additional_word_list(new_text)
	if id >= 0:
		return id
	return -1


func _on_word_edit_text_submitted(new_text: String) -> void:
	if _try_to_complete_from_word(new_text) >= 0:
		_on_validate_button_pressed()
		update_lesson()


func _on_remove_gp_button_2_pressed() -> void:
	if graphemes_edit_container.get_child_count() < 2:
		return
	unvalidated_gp_ids.pop_back()
	graphemes_edit_container.get_child(graphemes_edit_container.get_child_count() - 1).queue_free()
	graphemes_edit_container.get_child(graphemes_edit_container.get_child_count() - 2).queue_free()
	word_edit.text = get_graphemes(unvalidated_gp_ids)


func _process(_delta: float) -> void:
	add_gp_button.visible = graphemes_edit_container.get_child_count() <= 0
	remove_gp_button.visible = graphemes_edit_container.get_child_count() > 0


func new_gp_asked_added(ind: int, id: int) -> void:
	unvalidated_gp_ids[ind] = id
	set_graphemes_edit(unvalidated_gp_ids)
	word_edit.text = get_graphemes(unvalidated_gp_ids)


func _on_add_gp_button_pressed(element: Node) -> void:
	var ind_gp_id: = element.get_index() / 2
	var gp_id: int = sub_elements_list.keys()[0]
	unvalidated_gp_ids.insert(ind_gp_id + 1, gp_id)
	add_gp_list_button(gp_id, ind_gp_id + 1)



func _on_empty_add_gp_button_pressed() -> void:
	var gp_id: int = sub_elements_list.keys()[0]
	unvalidated_gp_ids.append(gp_id)
	add_gp_list_button(gp_id, unvalidated_gp_ids.size() - 1)
