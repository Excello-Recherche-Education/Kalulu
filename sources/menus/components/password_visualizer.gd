@tool
extends HBoxContainer
class_name PasswordVisualizer

const icons_textures: Dictionary = {
	"1" : preload("res://assets/menus/login/symbol01.png"),
	"2" : preload("res://assets/menus/login/symbol02.png"),
	"3" : preload("res://assets/menus/login/symbol03.png"),
	"4" : preload("res://assets/menus/login/symbol04.png"),
	"5" : preload("res://assets/menus/login/symbol05.png"),
	"6" : preload("res://assets/menus/login/symbol06.png")
}

@export var key_size: int = 200:
	set(value):
		key_size = value
		for icon: TextureRect in icons:
			icon.custom_minimum_size.x = key_size
			icon.custom_minimum_size.y = key_size
@export var password: String:
	set(value):
		password = value
		_draw_password()

@onready var icons: Array[TextureRect] = []

func _ready() -> void:
	_draw_password()
	for icon: TextureRect in icons:
		icon.custom_minimum_size.x = key_size
		icon.custom_minimum_size.y = key_size

func _draw_password() -> void:
	
	if not icons:
		icons = [%Icon1, %Icon2, %Icon3]
	
	for icon: TextureRect in icons:
		icon.texture = null
	
	if not password:
		return
	
	var i: int = 0
	for value: String in password.split(""):
		if i >= 3:
			Logger.error("PasswordVisualizer: A password cannot be more than 3 characters long")
			return
		
		if value in icons_textures:
			icons[i].texture = icons_textures[value]
		i += 1
