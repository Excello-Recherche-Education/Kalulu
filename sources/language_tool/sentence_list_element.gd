extends "res://sources/language_tool/word_list_element.gd"

const word_list_element_scene: = preload("res://sources/language_tool/word_list_element.tscn")

func update_lesson() -> void:
	var m: = -1
	for gp_id in gp_ids:
		var i: = Database.get_min_lesson_for_word_id(gp_id)
		m = max(m, i)
	lesson = m


func _add_from_additional_word_list(new_text: String) -> int:
	var punc: = "'!()[]{};:'\"\\,<>./?@#$%^&*_~"
	var new_text_clean: = new_text.to_lower()
	for char in punc:
		new_text_clean = new_text_clean.replace(char, " ")
	var word_list_element: = word_list_element_scene.instantiate()
	var all_found: = true
	var word_ids: Array[int] = []
	for word in new_text_clean.split(" "):
		var word_id: int = word_list_element._try_to_complete_from_word(word)
		word_ids.append(word_id)
		if word_id < 0:
			all_found = false
	word_list_element.free()
	if all_found:
		gp_ids = word_ids
		unvalidated_gp_ids = gp_ids
		graphemes = new_text_clean
		
		Database.db.insert_row("Sentences", {
			Sentence = new_text,
		})
		id = Database.db.last_insert_rowid
		for i in word_ids.size():
			var word_id: int = word_ids[i]
			Database.db.insert_row("WordsInSentences", {
				WordID = word_id,
				SentenceID = id,
				Position = i
			})
		return id
	return -1
