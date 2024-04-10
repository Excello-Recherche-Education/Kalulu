@tool
extends Node2D
class_name Branch

signal branch_pressed()
signal berry_pressed(gp: Dictionary)

const leaf_scene: PackedScene = preload("res://sources/minigames/caterpillar/leaf.tscn")
const berry_scene: PackedScene = preload("res://sources/minigames/caterpillar/berry.tscn")

@onready var leaves: Node2D = $Leaves
@onready var berries: Node2D = $Berries
@onready var leaf_timer: Timer = $LeafTimer

var velocity: float = 400.0


func _ready():
	if not Engine.is_editor_hint():
		leaf_timer.wait_time = randf_range(0, 2)
		leaf_timer.start()


func _process(delta):
	if Engine.is_editor_hint():
		return
	
	for leaf: Leaf in leaves.get_children():
		leaf.position.x -= velocity * delta
	for berry: Berry in berries.get_children():
		if not berry.is_eaten:
			berry.position.x -= velocity * delta


func spawn_berry(gp: Dictionary):
	var berry : Berry = berry_scene.instantiate()
	berries.add_child(berry)
	berry.gp = gp
	
	berry.pressed.connect(_on_berry_pressed)


func clear_berries() -> void:
	for berry: Berry in berries.get_children():
		berry.fall()

# ---------- CONNECTIONS ---------- # 

func _on_button_pressed():
	branch_pressed.emit()


func _on_leaf_timer_timeout():
	var leaf: Node2D = leaf_scene.instantiate()
	leaves.add_child(leaf)
	
	leaf_timer.wait_time = randf_range(2.0, 5.0)
	leaf_timer.start()


func _on_berry_pressed(gp: Dictionary):
	berry_pressed.emit(gp)