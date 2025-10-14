class_name CaterpillarBody
extends Node2D

var gp: Dictionary = {}:
	set(value):
		gp = value
		if gp.has("Grapheme"):
			label.text = gp.Grapheme
			resize_body()
		else:
			label.text = ""
			resize_body()
var margin: float = 1.0
var base_width: int = 10 # Minimal width of the body

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var right_FX: RightFX = $RightFX
@onready var body_left: Sprite2D = $Sprite2D_Body_Left
@onready var body_center: TextureRect = $TextureRect_Body_Center
@onready var body_right: Sprite2D = $Sprite2D_Body_Right


func _ready() -> void:
	walk()


func idle() -> void:
	animated_sprite.play("idle")


func walk() -> void:
	animated_sprite.play("walk")


func right() -> void:
	right_FX.play()
	await right_FX.finished


func resize_body() -> void:
	var letters_count: int = label.text.length()
	if letters_count <= 0:
		return
	
	label.reset_size()
	await get_tree().process_frame
	
	var start_width: float = body_center.size.x
	var text_w: float = label.size.x
	var end_width: float = max(float(base_width), text_w + float(margin) * 2.0)
	var center_h: float = float(body_center.texture.get_height())
	
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	var apply_width: Callable = func(width: float) -> void:
		body_center.size = Vector2(width, center_h)
		_update_body_layout()
	
	tween.tween_method(apply_width, start_width, end_width, 0.5)


func _update_body_layout() -> void:
	var left_width: float = float(body_left.texture.get_width())
	var center_height: float = float(body_center.texture.get_height())
	var current_center_w: float = body_center.size.x
	var label_width: float = label.size.x
	var label_height: float = label.size.y
	
	body_left.position = Vector2(0.0, 0.0)
	body_center.position = Vector2(left_width, 0.0)
	body_right.position = Vector2(left_width + current_center_w, 0.0)
	
	label.position = Vector2(
		left_width + margin + (current_center_w - 2.0 * margin) * 0.5 - label_width * 0.5,
		center_height * 0.5 - label_height * 0.5
	)



func _get_text_pixel_width() -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var label_settings: LabelSettings = label.label_settings
	var width: float = 0.0
	
	if font != null:
		width = font.get_string_size(label.text, font_size).x
	else:
		width = label.size.x
	
	if label_settings != null and label_settings.outline_size > 0:
		width += float(label_settings.outline_size) * 2.0
	
	return width
