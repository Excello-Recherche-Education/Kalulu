class_name LilypadTrack
extends Control

signal lilypad_in_center(lilypad: Lilypad)

const LILYPAD_SCENE: PackedScene = preload("res://sources/minigames/frog/lilypad.tscn")

var top_to_bottom: bool = false
var is_stopped: bool = false
var is_cleared: bool = false
var is_enabled: bool = false:
	set = _set_enabled
var is_highlighting: bool = false:
	set = _set_highlighting
var difficulty_settings: FrogMinigame.DifficultySettings
var gp: Dictionary = {}:
	set(value):
		gp = value
		if gp.Type == 2:
			top_to_bottom = true
var distractors: Array[Dictionary] = []
var distractors_queue: Array[Dictionary] = []
var distractors_queue_size: int = 5
var lilypads: Array[Lilypad] = []
var lilypad_size: Vector2

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var spawn_timer: Timer = $SpawnTimer


func _process(delta: float) -> void:
	if is_stopped:
		return
	for lilypad: Lilypad in lilypads:
		if top_to_bottom:
			lilypad.position.y += _get_velocity() * delta
		else:
			lilypad.position.y -= _get_velocity() * delta


func _get_velocity() -> float:
	if is_enabled:
		return difficulty_settings.pads_speed
	return difficulty_settings.pads_speed_disabled


func reset() -> void:
	is_enabled = false
	is_stopped = true
	
	for lilypad: Lilypad in lilypads:
		lilypad.disappear()
	
	await get_tree().create_timer(0.5).timeout


func start() -> void:
	is_stopped = false


func stop() -> void:
	is_stopped = true


func right() -> void:
	for lilypad: Lilypad in lilypads:
		await lilypad.right()


func pick_distractor() -> Dictionary:
	if distractors_queue.is_empty():
		distractors_queue = distractors.duplicate()
		distractors_queue.shuffle()
		while distractors_queue.size() > distractors_queue_size:
			distractors_queue.pop_front()
	
	if distractors_queue:
		return distractors_queue.pop_front()
	
	return {}


#region Lilypads

func _spawn_lilypad() -> void:
	var lilypad: Lilypad = LILYPAD_SCENE.instantiate()
	lilypads.append(lilypad)
	add_child(lilypad)
	
	lilypad.disabled = not is_enabled
	
	if top_to_bottom:
		lilypad.global_position = global_position + Vector2(size.x / 2.0, 0.0)
	else:
		lilypad.global_position = global_position + Vector2(size.x / 2.0, size.y)
	
	lilypad_size = lilypad.button.size
	if size.x < lilypad_size.x:
		var lily_scale: float = size.x / lilypad_size.x
		lilypad.button.scale = Vector2(lily_scale, lily_scale)
		lilypad_size *= lily_scale
	
	var is_stimulus: bool = randf() < difficulty_settings.stimuli_ratio
	lilypad.is_distractor = !is_stimulus
	if is_stimulus:
		lilypad.stimulus = gp
	else:
		lilypad.stimulus = pick_distractor()
	
	if is_highlighting:
		lilypad.highlight()
	else:
		lilypad.stop_highlight()
	
	lilypad.top_to_bottom = top_to_bottom
	
	lilypad.pressed.connect(_on_lilypad_pressed.bind(lilypad))
	lilypad.disappeared.connect(_on_lilypad_disappeared.bind(lilypad))


func _despawn_lilypad(lilypad: Lilypad) -> void:
	lilypads.erase(lilypad)
	lilypad.queue_free()

#endregion

#region Setters

func _set_enabled(value: bool) -> void:
	is_enabled = value
	if not is_cleared:
		for lilypad: Lilypad in lilypads:
			lilypad.disabled = not is_enabled


func _set_highlighting(value: bool) -> void:
	is_highlighting = is_enabled and value
	for lilypad: Lilypad in lilypads:
		if is_highlighting:
			lilypad.highlight()
		else:
			lilypad.stop_highlight()

#endregion

#region Connections

func _on_lilypad_pressed(lilypad: Lilypad) -> void:
	if is_cleared or is_stopped:
		return
	audio_player.play()
	stop()
	
	for other_lilypad: Lilypad in lilypads:
		if other_lilypad != lilypad:
			other_lilypad.disappear()
	
	var center_tween: Tween = create_tween()
	center_tween.finished.connect(_on_center_tween_finished.bind(lilypad, center_tween))
	center_tween.tween_property(lilypad, "global_position", global_position + size / 2.0, 0.5)


func _on_lilypad_disappeared(lilypad: Lilypad) -> void:
	_despawn_lilypad(lilypad)


func _on_center_tween_finished(lilypad: Lilypad, center_tween: Tween) -> void:
	lilypad_in_center.emit(lilypad)
	center_tween.kill()


func _on_spawn_timer_timeout() -> void:
	if not is_stopped:
		_spawn_lilypad()
	
	# Makes sure the lilypads don't overlap
	if lilypad_size:
		spawn_timer.start(randf_range(lilypad_size.y / _get_velocity(), lilypad_size.y * 2 / _get_velocity()))
	else:
		spawn_timer.start(randf_range(0.75, 1.5))

#endregion
