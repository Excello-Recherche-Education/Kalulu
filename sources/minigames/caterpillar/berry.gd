class_name Berry
extends Area2D

signal pressed(gp: Dictionary)

const BLUE_BERRY: CompressedTexture2D = preload("/Users/kalulu/Desktop/workspace/Kalulu/assets/minigames/caterpillar/graphics/berry_bue.png")

var gp: Dictionary = {}: 
	set(value):
		gp = value
		if gp.has("Grapheme"):
			label.text = gp.Grapheme
		else:
			label.text = ""
var is_eaten: bool = false: 
	set(value):
		is_eaten = value
		if is_eaten:
			collision_shape.set_deferred("disabled", true)
var is_distractor: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = %Label
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var highlight_fx: HighlightFX = $HighlightFX
@onready var wrong_fx: WrongFX = $WrongFX
@onready var sprite_2d: Sprite2D = $Path2D/PathFollow2D/Sprite2D


func highlight() -> void:
	if not is_distractor:
		highlight_fx.play()


func wrong() -> void:
	wrong_fx.play()
	await wrong_fx.finished


func fall() -> void:
	if is_eaten:
		return
	collision_shape.set_deferred("disabled", true)
	await get_tree().create_timer(randf_range(0., 0.1)).timeout
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(path_follow, "progress_ratio", 1, 2)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_button_pressed() -> void:
	if not is_eaten and gp:
		pressed.emit(gp)
