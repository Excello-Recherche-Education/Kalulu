@tool
class_name FrogMinigame
extends WordsMinigame

const LILYPAD_TRACK_SCENE: PackedScene = preload("res://sources/minigames/frog/lilypad_track.tscn")

var difficulty_settings: Array[DifficultySettings] = [
	DifficultySettings.new(0.75, 100., 200.),
	DifficultySettings.new(0.66, 150., 250.),
	DifficultySettings.new(0.33, 200., 300.),
	DifficultySettings.new(0.25, 250., 350.),
	DifficultySettings.new(0.25, 300., 400.)
]

@onready var start: Control = %Start
@onready var end: Control = %End
@onready var frog_spawn_point: Control = %FrogSpawnPoint
@onready var frog_despawn_point: Control = %FrogDespawnPoint
@onready var river: River = $GameRoot/Background/River
@onready var lilypad_tracks_container: HBoxContainer = %LilypadTracksContainer
@onready var frog: Frog = %Frog


func _setup_word_progression() -> void:
	super()
	_create_tracks()
	_start_tracks()


func _start() -> void:
	super()


func _highlight() -> void:
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		if track.is_enabled:
			track.is_highlighting = true
			break


func _reset_frog() -> void:
	frog.global_position = frog_spawn_point.global_position
	frog.jump_to(start.global_position)
	await frog.jumped
	
	# Returns to the last completed track by jumping on each pad
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		if track.is_cleared:
			frog.jump_to(track.lilypads[0].global_position)
			await frog.jumped

#region Tracks management

func _free_tracks() -> void:
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		await track.reset()
	
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		track.queue_free()
		# Waits for the track to be properly freed
		await track.tree_exited


func _create_tracks() -> void:
	var current_word: Dictionary = _get_current_stimulus()
	var current_distractors: Array = _get_current_distractors()
	
	for index: int in range((current_word.GPs as Array).size()):
		var track: LilypadTrack = LILYPAD_TRACK_SCENE.instantiate()
		lilypad_tracks_container.add_child(track)
		
		track.difficulty_settings = difficulty_settings[difficulty]
		track.gp = current_word.GPs[index]
		track.distractors = current_distractors[index]
		track.distractors_queue_size = distractors_queue_size
		
		track.lilypad_in_center.connect(_on_track_lilypad_in_center.bind(track))


func _start_tracks() -> void:
	var is_first_track_enabled: bool = false
	var index: int = 0
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		if index >= current_word_progression:
			await track.reset()
			if not is_first_track_enabled:
				track.is_enabled = true
				is_first_track_enabled = true
			track.start()
		index += 1

#endregion

#region Connections

func _on_track_lilypad_in_center(lilypad: Lilypad, track: LilypadTrack) -> void:
	# Log the answer
	_log_new_response_and_score(lilypad.stimulus)
	
	# Disable the tracks
	track.stop()
	
	# Makes the frog jumps on the lilypad
	frog.jump_to(lilypad.global_position)
	await frog.jumped
	
	river.spawn_water_ring(lilypad.global_position)
	
	if lilypad.is_distractor:
		await lilypad.wrong()
		
		lilypad.disappear()
		frog.drown()
		await frog.drowned
		await audio_player.play_gp(lilypad.stimulus)
		
		current_lives -= 1
		
		_start_tracks()
		await _reset_frog()
	else:
		track.is_highlighting = false
		track.is_cleared = true
		track.is_enabled = false
		await audio_player.play_gp(lilypad.stimulus)
		current_word_progression += 1


func _on_current_word_progression_changed() -> void:
	# Enables the next track
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		if not track.is_cleared:
			track.is_enabled = true
			break


func _on_current_progression_changed() -> void:
	# Makes the frog jumps to the rock on the right
	frog.jump_to(end.global_position)
	await frog.jumped
	
	# Play the animation on each pad
	for track: LilypadTrack in lilypad_tracks_container.get_children():
		track.right()
	
	# Replay the stimulus
	await audio_player.play_word(_get_previous_stimulus().Word as String)
	
	# Makes the frog jumps out of screen
	frog.jump_to(frog_despawn_point.global_position)
	await frog.jumped
	
	# Free the tracks
	await _free_tracks()
	
	# Resets the frog position
	await _reset_frog()
	
	# Setups the next word
	super()

#endregion

class DifficultySettings:
	var stimuli_ratio: float = 0.75
	var pads_speed_disabled: float = 100.0
	var pads_speed: float = 200.0
	
	
	func _init(p_stimuli_ratio: float, p_pads_speed_disabled: float, p_pads_speed: float) -> void:
		stimuli_ratio = p_stimuli_ratio
		pads_speed_disabled = p_pads_speed_disabled
		pads_speed = p_pads_speed
