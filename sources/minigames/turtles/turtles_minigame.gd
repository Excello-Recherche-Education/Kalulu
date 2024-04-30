extends Minigame
class_name TurtlesMinigame

signal can_spawn_turtle()

const turtle_scene: PackedScene = preload("res://sources/minigames/turtles/turtle.tscn")

# Defines the maximum number of turtles visible on screen
const max_turtle_count: int = 5


class DifficultySettings:
	var velocity: float = 250.
	var spawn_rate: float = 4.
	
	func _init(p_velocity: float, p_spawn_rate: float) -> void:
		velocity = p_velocity
		spawn_rate = p_spawn_rate


var difficulty_settings: Array[DifficultySettings] = [
	DifficultySettings.new(250., 4.),
	DifficultySettings.new(300., 3.5),
	DifficultySettings.new(350., 3.),
	DifficultySettings.new(400., 2.5),
	DifficultySettings.new(450., 2.)
]


@onready var water: TextureRect = $GameRoot/Water
@onready var island: Island = $GameRoot/Island
@onready var turtles: Control = $GameRoot/Turtles
@onready var spawn_location: PathFollow2D = $GameRoot/SpawnPath/SpawnLocation
@onready var spawn_timer: Timer = $GameRoot/SpawnTimer

var settings: DifficultySettings
var turtle_count: int = 0:
	set(value):
		if turtle_count >= max_turtle_count and value < max_turtle_count:
			can_spawn_turtle.emit()
		turtle_count = value
var last_spawn_location_ratio: float

# Find and set the parameters of the minigame, like the number of lives or the victory conditions.
func _setup_minigame() -> void:
	super._setup_minigame()
	
	# Setups the current settings
	settings = difficulty_settings[difficulty]
	if not settings:
		return
	
	# Setups the timer
	spawn_timer.wait_time = settings.spawn_rate


func _start() -> void:
	super._start()
	spawn_timer.start()


func _spawn_water_ring(position: Vector2):
	print(position)
	pass


func _on_spawn_timer_timeout():
	# Checks if there are too many turtle, and wait for one to despawn
	if turtle_count >= max_turtle_count:
		await can_spawn_turtle
	
	# Spawn a turtle
	var turtle: Turtle = turtle_scene.instantiate()
	
	# Pick a position to spawn the turtle
	var position_found: bool = false
	while not position_found:
		spawn_location.progress_ratio = randf()
		
		# Check if there are other turtles near
		for other_turtle: Turtle in turtles.get_children():
			if other_turtle.position.distance_to(spawn_location.position) < 4:
				break
	
	turtle.position = spawn_location.position
	turtle.velocity = settings.velocity
	
	turtle.animation_changed.connect(_spawn_water_ring)
	turtle.tree_exited.connect(
		func() -> void:
			turtle_count -= 1
	)
	
	turtles.add_child(turtle)
	
	# Makes the turtle move toward the island
	turtle.direction = turtle.position.direction_to(island.position)
	
	# Define if the turtle is a stimulus or a distraction TODO
	
	# Increment the count
	turtle_count += 1
	
	# Restarts timer
	spawn_timer.start()
	
