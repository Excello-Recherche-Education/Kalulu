extends MarginContainer

signal delete_pressed()

@onready var word_label: = $%Word
@onready var graphemes_label: = $%Graphemes
@onready var word_edit: = $%WordEdit
@onready var graphemes_edit: = $%GraphemesEdit
@onready var tab_container: = $TabContainer
@onready var popup_menu: = $%Popup

var word: = "":
	set = set_word
var graphemes: = "":
	set = set_graphemes
var phonemes: = "":
	set = set_phonemes
var undo_redo: UndoRedo:
	get:
		if not undo_redo:
			undo_redo = UndoRedo.new()
		return undo_redo
var prev_caret_position: int = 0
var unvalidated_graphemes: = ""
var unvalidated_phonemes: = ""


func set_word(p_word: String) -> void:
	word = p_word
	if word_label:
		word_label.text = word
	if word_edit:
		word_edit.text = word


func set_graphemes(p_graphemes: String) -> void:
	graphemes = p_graphemes
	if graphemes_label:
		_set_graphemes_label()
	if graphemes_edit:
		graphemes_edit.text = graphemes
	unvalidated_graphemes = graphemes


func _set_graphemes_label() -> void:
	var graphemes_array: = graphemes.split(" ", false)
	var phonemes_array: = phonemes.split(" ", false)
	graphemes_label.text = ""
	for i in graphemes_array.size():
		if i > 0:
			graphemes_label.text += " "
		graphemes_label.text += graphemes_array[i]
		if i < phonemes_array.size():
			graphemes_label.text += "-" + phonemes_array[i]


func set_phonemes(p_phonemes: String) -> void:
	phonemes = p_phonemes
	if graphemes_label:
		_set_graphemes_label()
	unvalidated_phonemes = phonemes


func _ready() -> void:
	set_word(word)
	set_graphemes(graphemes)


func _on_edit_button_pressed() -> void:
	edit_mode()


func edit_mode() -> void:
	tab_container.current_tab = 1


func _on_minus_button_pressed() -> void:
	delete_pressed.emit()


func _on_validate_button_pressed() -> void:
	popup_menu.clear(-1)
	undo_redo.create_action("validated")
	undo_redo.add_do_property(self, "graphemes", unvalidated_graphemes)
	undo_redo.add_do_property(self, "phonemes", unvalidated_phonemes)
	undo_redo.add_do_property(self, "word", word_edit.text)
	undo_redo.add_undo_property(self, "graphemes", graphemes)
	undo_redo.add_undo_property(self, "phonemes", phonemes)
	undo_redo.add_undo_property(self, "word", word)
	undo_redo.commit_action()
	tab_container.current_tab = 0


func _get_selected_grapheme(graphemes_array: PackedStringArray) -> int:
	var graphemes_count: = []
	graphemes_count.resize(graphemes_array.size())
	var grapheme_ind: = 0
	for i in graphemes_array.size():
		if i == 0:
			graphemes_count[i] = graphemes_array[i].length()
		else:
			graphemes_count[i] = graphemes_count[i-1] + 1 + graphemes_array[i].length()
		if graphemes_count[i] >= graphemes_edit.caret_column:
			grapheme_ind = i
			break
	return grapheme_ind


func _on_popup_gp_selected(ind: int, text: String) -> void:
	var graphemes_array: PackedStringArray = graphemes_edit.text.split(" ", false)
	var phonemes_array: PackedStringArray = phonemes.split(" ", false)
	if ind >= graphemes_array.size():
		return
	#var grapheme_ind: = _get_selected_grapheme(graphemes_array)
	var gp_array: PackedStringArray = text.split("-")
	graphemes_array[ind] = gp_array[0]
	if phonemes_array.size() <= ind:
		phonemes_array.resize(ind + 1)
	phonemes_array[ind] = gp_array[1]
	unvalidated_graphemes = " ".join(graphemes_array)
	unvalidated_phonemes = " ".join(phonemes_array)
	graphemes_edit.grab_focus()
	graphemes_edit.caret_column = prev_caret_position


func _on_graphemes_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	prev_caret_position = graphemes_edit.caret_column
	var graphemes_array: PackedStringArray = graphemes_edit.text.split(" ", false)
	if graphemes_array.is_empty():
		return
	var phonemes_array: PackedStringArray = phonemes.split(" ", false)
	var grapheme_ind: int = _get_selected_grapheme(graphemes_array)
	popup_menu.show()
	popup_menu.position = graphemes_edit.global_position + Vector2(0, graphemes_edit.size.y)
	popup_menu.size = Vector2(graphemes_edit.size.x, 0)
	popup_menu.clear(grapheme_ind)
	Database.db.query_with_bindings("Select Grapheme, Phoneme FROM GPs WHERE Grapheme=?", [graphemes_array[grapheme_ind]])
	for result in Database.db.query_result:
		var is_already_selected: bool = result.Grapheme == graphemes_array[grapheme_ind] and grapheme_ind < phonemes_array.size() and result.Phoneme == phonemes_array[grapheme_ind]
		popup_menu.add_item(result.Grapheme + "-" + result.Phoneme, is_already_selected)


func _on_graphemes_edit_focus_entered() -> void:
	popup_menu.show()


func _on_graphemes_edit_focus_exited() -> void:
	popup_menu.hide()


func _on_popup_focus_changed(p_has_focus: bool) -> void:
	popup_menu.visible = p_has_focus


func _on_graphemes_edit_text_changed(_new_text: String) -> void:
	var graphemes_array: PackedStringArray = graphemes_edit.text.split(" ", false)
	var phonemes_array: PackedStringArray = phonemes.split(" ", false)
	if graphemes_array.size() < phonemes_array.size():
		phonemes_array.remove_at(popup_menu.grapheme_ind)

