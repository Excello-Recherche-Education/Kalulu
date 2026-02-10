extends GutTest


func _make_layout(button_count: int) -> GardenLayout:
	var layout: GardenLayout = GardenLayout.new()
	var buttons: Array[GardenLayout.GardenLayoutLessonButton] = []
	for _index: int in range(button_count):
		buttons.append(GardenLayout.GardenLayoutLessonButton.new())
	layout.set_lesson_buttons(buttons)
	return layout


func test_compute_lessons_distribution_balances_with_capacity() -> void:
	var layouts: Array[GardenLayout] = [
		_make_layout(3),
		_make_layout(2),
		_make_layout(1),
	]
	var distribution: Array[int] = Gardens.compute_lessons_distribution(5, layouts)
	assert_eq_deep(distribution, [2, 2, 1])


func test_get_lessons_distribution_uses_layout_when_matching() -> void:
	var layouts: Array[GardenLayout] = [
		_make_layout(2),
		_make_layout(1),
	]
	var distribution: Array[int] = Gardens.get_lessons_distribution(3, layouts)
	assert_eq_deep(distribution, [2, 1])


func test_get_garden_dimensions_scales_with_image() -> void:
	var image: Image = Image.create(100, 200, false, Image.FORMAT_RGBA8)
	var dimensions: Vector2 = Gardens._get_garden_dimensions(0, image)
	assert_eq(dimensions, Vector2(Gardens.GARDEN_SIZE, 4800.0))


func test_is_position_on_garden_texture_respects_transparency() -> void:
	var image: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	var dimensions: Vector2 = Vector2(4, 4)

	assert_true(Gardens._is_position_on_garden_texture(0, Vector2(2, 2), dimensions, Vector2.ZERO, image))

	image.set_pixel(0, 0, Color(1, 1, 1, 0))
	assert_false(Gardens._is_position_on_garden_texture(0, Vector2(0, 0), dimensions, Vector2.ZERO, image))
