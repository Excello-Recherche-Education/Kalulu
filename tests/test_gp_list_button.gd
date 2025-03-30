extends "res://addons/gut/test.gd"

const GpListButton = preload("res://sources/language_tool/gp_list_button.gd")

var btn: GpListButton

func before_each():
	btn = GpListButton.new()
	add_child(btn)

func after_each():
	if is_instance_valid(btn):
		btn.queue_free()
	await get_tree().process_frame

func test_set_gp_list_add_the_items():
	var dict = {
		1: { "grapheme": "ch", "phoneme": "ʃ" },
		2: { "grapheme": "ou", "phoneme": "u" }
	}
	btn.set_gp_list(dict)
	assert_eq(btn.get_item_count(), 2)
	assert_eq(btn.get_item_text(0), "ch-ʃ")
	assert_eq(btn.get_item_text(1), "ou-u")

func test_select_id_select_the_item():
	var dict = {
		3: { "grapheme": "ai", "phoneme": "ɛ" }
	}
	btn.set_gp_list(dict)
	btn.select_id(3)
	assert_eq(btn.get_selected_id(), 3)
