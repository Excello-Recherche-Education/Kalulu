extends Control
class_name TracingManager

signal finished()

const LETTER_SEGMENT_CLASS: PackedScene = preload("res://sources/look_and_learn/letter_segment.tscn")

@export var label_settings: LabelSettings

@onready var lower_labels: HBoxContainer = %LowerLabels
@onready var upper_labels: HBoxContainer = %UpperLabels

const EXTENSION: String = ".csv"

func _process(_delta: float) -> void:
	place_segments(upper_labels.get_children())
	place_segments(lower_labels.get_children())


func place_segments(labels: Array) -> void:
	for label: Label in labels:
		for segment: LetterSegment in label.get_children():
			segment.global_position = label.global_position + label.size / 2.0 + Vector2(0.0, 72.0)


func reset() -> void:
	for child: Node in upper_labels.get_children():
		child.queue_free()
	for child: Node in lower_labels.get_children():
		child.queue_free()
	
	lower_labels.visible = false
	upper_labels.visible = false
	await get_tree().process_frame


# --- Setup ---

func setup(grapheme: String) -> void:
	await reset()
	for letter: String in grapheme:
		var tracings: Dictionary = _get_letter_tracings(letter)
		
		if tracings.upper:
			setup_tracing(letter, tracings["upper"] as Array, upper_labels, false)
			
		if tracings.lower:
			setup_tracing(letter, tracings["lower"] as Array, lower_labels, true)


func setup_tracing(letter: String, letter_tracings: Array, parent: Control, lower: bool) -> void:
	var label: Label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.label_settings = label_settings
	
	if lower:
		label.text = letter.to_lower()
	else:
		label.text = letter.to_upper()
	
	parent.add_child(label)
	
	for points: Array in letter_tracings:
		var segment: LetterSegment = LETTER_SEGMENT_CLASS.instantiate()
		label.add_child(segment)
		segment.setup(points)


func _get_letter_tracings(letter: String) -> Dictionary:
	var lower_tracing: Array = _load_tracing(_lower_path(letter))
	var upper_tracing: Array = _load_tracing(_upper_path(letter))
	
	return {"lower": lower_tracing, "upper": upper_tracing}


func _load_tracing(path: String) -> Array:
	if not FileAccess.file_exists(_real_path(path)):
		return []
	
	var segments: Array = []
	var file: FileAccess = FileAccess.open(_real_path(path), FileAccess.READ)
	var error: Error = FileAccess.get_open_error()
	if error != OK:
		Logger.error("TracingManager: Load tracing: Cannot open file %s. Error: %s" % [_real_path(path), error_string(error)])
		return segments
	if file == null:
		Logger.error("TracingManager: Load tracing: Cannot open file %s. File is null" % _real_path(path))
		return segments
	while not file.eof_reached():
		var points: Array[Vector2] = []
		var line: PackedStringArray = file.get_csv_line()
		for element: String in line:
			if element == "":
				break
			
			var elements: PackedStringArray = element.split(" ")
			points.append(Vector2(float(elements[0]), float(elements[1])))
		
		if not points.is_empty():
			segments.append(points)
	
	return segments


func _lower_path(letter: String) -> String:
	return letter + "_lower"


func _upper_path(letter: String) -> String:
	return letter + "_upper"


func _real_path(path: String) -> String:
	return Database.BASE_PATH.path_join(Database.language).path_join(Database.TRACING_DATA_FOLDER).path_join(path) + EXTENSION



# --- Start ---


func start() -> void:
	if upper_labels.get_child_count(false) > 0:
		lower_labels.visible = false
		upper_labels.visible = true
		
		await demo_labels(upper_labels)
		await start_labels(upper_labels)
	
	if lower_labels.get_child_count(false) > 0:
		lower_labels.visible = true
		upper_labels.visible = false
		
		await demo_labels(lower_labels)
		await start_labels(lower_labels)
	
	finished.emit()


func start_labels(labels_parent: Control) -> void:
	for letter: Node in labels_parent.get_children():
		for segment: LetterSegment in letter.get_children():
			segment.start()
			await segment.finished
			letter.move_child(segment, 0)


func demo_labels(labels_parent: Control) -> void:
	for letter: Node in labels_parent.get_children():
		for segment: LetterSegment in letter.get_children():
			segment.demo()
			await segment.finished
