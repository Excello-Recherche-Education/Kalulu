extends MarginContainer
class_name LessonContainer

var gp_label_scene: PackedScene = preload("res://sources/language_tool/lesson_gp_label.tscn")

signal lesson_dropped(before: bool, number: int, dropped_number: int)

var number: int = 0:
	set = set_number


@onready var gp_container: HBoxContainer = $%GPContainer
@onready var number_label: Label = $%NumberLabel


func set_number(p_number: int) -> void:
	number = p_number
	if number_label:
		number_label.text = str(number)


func add_gp(new_gp: Dictionary) -> void:
	var gp_label: LessonGPLabel = gp_label_scene.instantiate()
	gp_label.grapheme = new_gp.grapheme
	gp_label.phoneme = new_gp.phoneme
	gp_label.gp_id = new_gp.gp_id
	gp_container.add_child(gp_label)
	gp_label.gp_dropped.connect(_on_gp_dropped.bind(gp_label))


func _on_gp_dropped(before: bool, data: Dictionary, gp_label: Control) -> void:
	var new_gp_label: LessonGPLabel = gp_label_scene.instantiate()
	new_gp_label.grapheme = data.grapheme
	new_gp_label.phoneme = data.phoneme
	new_gp_label.gp_id = data.gp_id
	new_gp_label.gp_dropped.connect(_on_gp_dropped.bind(new_gp_label))
	gp_container.add_child(new_gp_label)
	var children: Array[Node] = gp_container.get_children()
	for index: int in range(children.size()):
		var child: Node = children[index]
		if child == gp_label:
			if before:
				gp_container.move_child(new_gp_label, index)
			else:
				gp_container.move_child(new_gp_label, index + 1)


func _can_drop_in_gp_container(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		return (data as Dictionary).has("gp_id")
	else:
		Logger.error("LessonContainer: Can not drop data (that is not of type Dictionary) in GP Container")
		return false


func _drop_data_in_gp_container(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		Logger.error("LessonContainer: Cancel drop data in GP container because data is not of type Dictionary")
		return
	if not (data as Dictionary).has("gp_id"):
		Logger.trace("LessonContainer: Cancel drop data in GP container because data has no key gp_id")
		return
	var new_gp_label: LessonGPLabel = gp_label_scene.instantiate()
	new_gp_label.grapheme = data.grapheme
	new_gp_label.phoneme = data.phoneme
	new_gp_label.gp_id = data.gp_id
	new_gp_label.gp_dropped.connect(_on_gp_dropped.bind(new_gp_label))
	gp_container.add_child(new_gp_label)
	gp_container.move_child(new_gp_label, 0)


func _ready() -> void:
	gp_container.set_drag_forwarding(Callable(), _can_drop_in_gp_container, _drop_data_in_gp_container)


func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(self.duplicate() as Control)
	return { number = number }


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		return ((data as Dictionary).has("number") and number != (data as Dictionary).number) or _can_drop_in_gp_container(at_position, data)
	else:
		Logger.error("LessonContainer: Can not drop data that is not of type Dictionary")
		return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		Logger.error("LessonContainer: drop data failed because data is not of type Dictionary")
		return
	if not (data as Dictionary).has("number") or (data as Dictionary).has("gp_id"):
		return
	if (data as Dictionary).has("number"):
		var before: bool = at_position.y < size.y
		lesson_dropped.emit(before, number, data.number)
	else:
		_drop_data_in_gp_container(at_position, data)


func get_gp_ids() -> Array[int]:
	var res: Array[int] = []
	for gp: LessonGPLabel in gp_container.get_children():
		res.append(gp.gp_id)
	return res
