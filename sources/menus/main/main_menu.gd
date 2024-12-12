extends Control

const Kalulu: = preload("res://sources/menus/main/kalulu.gd")
const LoginForm: = preload("res://sources/menus/main/login.gd")
const ConfirmPopup: = preload("res://sources/ui/popup.gd")

const adult_check_scene_path := "res://sources/menus/adult_check/adult_check.tscn"
const package_loader_scene_path: = "res://sources/menus/language_selection/package_downloader.tscn"

@onready var version_label : Label = $Informations/BuildVersionValue
@onready var teacher_label : Label = $Informations/TeacherValue
@onready var device_id_label : Label = $Informations/DeviceIDValue

@onready var kalulu : Kalulu = $Kalulu
@onready var play_button: Button = %PlayButton
@onready var interface_left : MarginContainer = %InterfaceLeft
@onready var keyboard_spacer: KeyboardSpacer = %KeyboardSpacer
@onready var no_internet_popup: ConfirmPopup = $NoInternetPopup


func _ready() -> void:
	version_label.text = ProjectSettings.get_setting("application/config/version")
	teacher_label.text = UserDataManager.get_device_settings().teacher
	device_id_label.text = str(UserDataManager.get_device_settings().device_id)
	OpeningCurtain.open()


func _on_main_button_pressed() -> void:
	play_button.disabled = true
	if UserDataManager.get_device_settings().teacher:
		_on_login_in()
	else:
		# Check if Internet
		if await ServerManager.check_internet_access():
			kalulu.hide()
			kalulu.stop_speech()
			keyboard_spacer.show()
			interface_left.show()
		else:
			no_internet_popup.show()
	play_button.disabled = false


func _on_back_button_pressed() -> void:
	keyboard_spacer.hide()
	kalulu.show()
	interface_left.hide()


func _on_register_pressed() -> void:
	await OpeningCurtain.close()
	get_tree().change_scene_to_file(adult_check_scene_path)


func _on_login_in() -> void:
	get_tree().change_scene_to_file(package_loader_scene_path)
