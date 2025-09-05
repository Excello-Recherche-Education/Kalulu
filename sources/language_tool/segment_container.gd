class_name SegmentContainer
extends HBoxContainer

signal changed()

const SEGMENT_BUILD_SCENE: PackedScene = preload("res://sources/language_tool/segment_build.tscn")
const POINT_BUTTON_SCENE: PackedScene = preload("res://sources/language_tool/segment_point_button.tscn")

@export var points_per_lines: int = 25
@export var points_per_gradient: int = 7

var gradient: Gradient
var current_segment: SegmentBuild
var current_button: SegmentPointButton
var buttons: Array[SegmentPointButton] = []

@onready var grapheme_label: Label = %GraphemeLabel
@onready var buttons_parent: Control = %ButtonsParent
@onready var segments_container: VBoxContainer = %SegmentsContainer
@onready var lines: Node2D = %Lines


func reset() -> void:
	var to_free: Array[Node] = lines.get_children()
	to_free.append_array(segments_container.get_children())
	for node: Node in to_free:
		node.queue_free()
	
	current_segment = null
	current_button = null
	
	await get_tree().process_frame


func load_segment(points: Array[Vector2]) -> void:
	_on_add_segment_button_pressed()
	current_segment.points = points
	draw_segment(current_segment)


func _process(_delta: float) -> void:
	lines.global_position = grapheme_label.global_position + grapheme_label.size / 2.0
	
	draw_all_segments()
	match_segment_with_buttons()
	
	if not is_instance_valid(current_segment):
		current_button = null
	
	if is_instance_valid(current_button):
		var ind: int = current_segment.remove_point(current_button.global_position - lines.global_position)
		current_button.global_position = get_global_mouse_position()
		current_segment.add_point_at(current_button.global_position - lines.global_position, ind)


func draw_segment(segment: SegmentBuild) -> void:
	if not is_instance_valid(segment):
		return
	
	var ind_seg: int = segments_container.get_children().find(segment)
	var line: Line2D = lines.get_child(ind_seg)
	
	line.points = Bezier.bezier_sampling(segment.points, maxi(points_per_lines, segment.points.size()))


func draw_all_segments() -> void:
	for segment: SegmentBuild in segments_container.get_children():
		draw_segment(segment)


func match_segment_with_buttons() -> void:
	var points: PackedVector2Array = []
	if is_instance_valid(current_segment):
		points = current_segment.points
	
	for index: int in range(points.size()):
		while index >= buttons.size():
			var button: SegmentPointButton = POINT_BUTTON_SCENE.instantiate()
			buttons_parent.add_child(button)
			buttons.append(button)
			button.point_down.connect(_on_button_point_down.bind(button))
			button.point_up.connect(_on_button_point_up.bind(button))
			button.minus_pressed.connect(_on_button_minus_pressed.bind(button))
		
		buttons[index].global_position = points[index] + lines.global_position
		buttons[index].set_index(index + 1)
	
	for index: int in range(buttons.size() - 1, points.size() - 1, -1):
		buttons[index].queue_free()
		buttons.remove_at(index)


func _on_button_point_down(button: SegmentPointButton) -> void:
	current_button = button
	
	changed.emit()


func _on_button_point_up(_button: SegmentPointButton) -> void:
	current_button = null
	
	changed.emit()


func _on_button_minus_pressed(button: SegmentPointButton) -> void:
	if is_instance_valid(current_segment):
		current_segment.remove_point(button.global_position - lines.global_position)
	
	buttons.erase(button)
	button.queue_free()
	
	changed.emit()


func _on_place_point_button_pressed() -> void:
	if is_instance_valid(current_segment):
		current_segment.add_point(get_global_mouse_position() - lines.global_position)
		
		changed.emit()


func _on_add_segment_button_pressed() -> void:
	# Create a new segment build instance from the scene
	var new_segment: SegmentBuild = SEGMENT_BUILD_SCENE.instantiate()
	segments_container.add_child(new_segment)

	# Connect signals for modifying and deleting the segment
	new_segment.modified.connect(_on_segment_modified.bind(new_segment))
	new_segment.deleted.connect(_on_segment_deleted.bind(new_segment))

	# Store the new segment as the currently selected one
	current_segment = new_segment

	# Create a new visual line for the segment
	var segment_line: Line2D = Line2D.new()
	segment_line.width = 25
	segment_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	segment_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	segment_line.joint_mode = Line2D.LINE_JOINT_ROUND
	lines.add_child(segment_line)

	# Compute the segment's color based on its position in the container
	var segment_index: int = segments_container.get_child_count()
	var gradient_position: float = float(segment_index % points_per_gradient) / float(points_per_gradient)
	var segment_color: Color = gradient.sample(gradient_position)

	# Apply the color to the segment and its line
	new_segment.set_color(segment_color)
	segment_line.default_color = segment_color

	# Sync segment states with any associated UI or logic
	match_segment_with_buttons()

	# Notify that something has changed (e.g., for undo, saving, etc.)
	changed.emit()


func _on_segment_modified(segment: SegmentBuild) -> void:
	current_segment = segment
	match_segment_with_buttons()
	changed.emit()


func _on_segment_deleted(segment: SegmentBuild) -> void:
	if segment == current_segment:
		var possible_segments: Array[Node] = segments_container.get_children()
		if not possible_segments.is_empty():
			current_segment = possible_segments[0] as SegmentBuild
		else:
			current_segment = null
		
		match_segment_with_buttons()
	
	var ind_seg: int = segments_container.get_children().find(segment)
	lines.get_child(ind_seg).queue_free()
	
	changed.emit()
