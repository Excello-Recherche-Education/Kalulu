@tool
extends WordsMinigame

const BRANCH_SCENE: PackedScene = preload("res://sources/minigames/caterpillar/branch.tscn")


class DifficultySettings:
	var branches: int = 2
	var stimuli_ratio: float = 0.75
	var velocity: float = 400.
	var spawn_rate: float = 3.
	
	func _init(p_branches: int, p_stimuli_ratio: float, p_velocity: float, p_spawn_rate: float) -> void:
		branches = p_branches
		stimuli_ratio = p_stimuli_ratio
		velocity = p_velocity
		spawn_rate = p_spawn_rate


var difficulty_settings: Array[DifficultySettings] = [
	DifficultySettings.new(2, 0.75, 400., 3.),
	DifficultySettings.new(2, 0.66, 450., 2.5),
	DifficultySettings.new(3, 0.33, 500., 2.),
	DifficultySettings.new(3, 0.25, 550., 1.),
	DifficultySettings.new(4, 0.25, 600., 1.)
]


@onready var branches_zone: Control = $GameRoot/BranchesZone
@onready var caterpillar: Caterpillar = $GameRoot/Caterpillar
@onready var berry_timer: Timer = $GameRoot/BerryTimer


var branches: Array[Branch] = []
var branches_spawn_indexes: Array[int] = []

func _setup_minigame() -> void:
	super._setup_minigame()
	
	# Gets the difficulty settings
	var settings: DifficultySettings = difficulty_settings[difficulty]
	if not settings:
		return
	
	# Spawn the right amount of branches
	var branch_size: float = branches_zone.size.y / (settings.branches + 1)
	for index: int in range(settings.branches):
		var branch: Branch = BRANCH_SCENE.instantiate()
		branch.velocity = settings.velocity
		branches_zone.add_child(branch)
		branch.set_position(Vector2(0, branch_size * (index+1)))
		
		if not Engine.is_editor_hint():
			branch.branch_pressed.connect(_on_branch_pressed.bind(branch))
			branch.berry_pressed.connect(_play_berry_phoneme)
			
		branches.append(branch)
		branches_spawn_indexes.append(index)
	
		# Move the caterpillar to the right branch
		if index == int(settings.branches/2.0):
			_on_branch_pressed(branch)
	
	# Setups the timer
	berry_timer.wait_time = settings.spawn_rate
	
	# Connects the caterpillar signals
	caterpillar.berry_eaten.connect(_on_berry_eaten)


func _start() -> void:
	super()
	berry_timer.start()


func _highlight() -> void:
	for branch: Branch in branches:
		branch.is_highlighting = true


func _stop_highlight() -> void:
	for branch: Branch in branches:
		branch.is_highlighting = false

func _run() -> void:
	caterpillar.walk()
	for branch: Branch in branches:
		branch.is_running = true

func _stop() -> void:
	caterpillar.idle()
	for branch: Branch in branches:
		branch.is_running = false

func _get_difficulty_settings() -> DifficultySettings:
	return difficulty_settings[difficulty]


func _clear_berries() -> void:
	for branch: Branch in branches:
		branch.clear_berries()


func _play_berry_phoneme(gp: Dictionary) -> void:
	if gp and gp.has("Phoneme"):
		await audio_player.play_gp(gp)

#region Connections

func _on_branch_pressed(branch: Branch) -> void:
	caterpillar.move(branch.global_position.y)


func _on_berry_timer_timeout() -> void:
	# Pick a random branch to spawn a berry but not the same one twice
	var index: int = branches_spawn_indexes[randi() % (branches_spawn_indexes.size() -1)]
	branches_spawn_indexes.erase(index)
	branches_spawn_indexes.push_back(index)
	var branch: Branch = branches[index]
	
	# Define if the berry is a stimulus or a distraction
	var gp: Dictionary = {}
	var is_stimulus: bool = randf() < _get_difficulty_settings().stimuli_ratio
	if is_stimulus:
		gp = _get_gp()
	else:
		gp = _get_distractor()
	
	# Spawn the berry
	branch.spawn_berry(gp, !is_stimulus)


func _on_berry_eaten(berry: Berry) -> void:
	# Log the answer
	_log_new_response_and_score(berry.gp)
	
	# Pause the timer
	berry_timer.paused = true
	
	var gp: Dictionary = berry.gp
	
	if _is_gp_right(berry.gp):
		_clear_berries()
		_stop()
		await caterpillar.eat_berry(berry)
		await audio_player.play_gp(_get_gp())
		_run()
		current_word_progression += 1
	else:
		_stop()
		await caterpillar.spit_berry(berry)
		await audio_player.play_gp(gp)
		_run()
		current_lives -= 1
	
	# Unpause timer
	berry_timer.paused = false


func _on_current_progression_changed() -> void:
	# Stops the berries
	berry_timer.stop()
	
	# Show the word for some time and play the stimulus again
	await get_tree().create_timer(time_between_words/2).timeout
	await audio_player.play_word(_get_previous_stimulus().Word as String)
	await get_tree().create_timer(time_between_words/2).timeout
	
	# Reset the caterpillar
	await caterpillar.reset()
	
	# Play the new stimulus
	super()
	
	# Start the timer again
	berry_timer.start()

#endregion
