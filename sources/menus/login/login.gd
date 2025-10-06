extends Control

const TEACHER_PASSWORD: String = "42"
const BACK_SCENE_PATH: String = "res://sources/menus/main/main_menu.tscn"
const NEXT_SCENE_PATH: String = "res://sources/menus/brain/brain.tscn"
const TEACHER_SCENE_PATH: String = "res://sources/menus/settings/teacher_settings.tscn"
const DEVELOPER_SCENE_PATH: String = "res://sources/menus/settings/developer_settings.tscn"
const PACKAGE_LOADER_SCENE_PATH: String = "res://sources/menus/language_selection/package_downloader.tscn"
const KALULU := preload("res://sources/minigames/base/kalulu.gd")
const DEV_CLICK_THRESHOLD: int = 10 # Number of clicks needed to open Developer Settings
const DEV_CLICK_MAX_DELAY: float = 0.6 # Delay between each clicks (in seconds)

var help_speech: AudioStream
var wrong_password_speech: AudioStream
var right_password_speech: AudioStream
var dev_click_count: int = 0
var dev_last_click_time: float = 0.0

@onready var kalulu: KALULU = $Kalulu
@onready var music_player: AudioStreamPlayer = $MusicStreamPlayer
@onready var device_number_label: Label = $DeviceNumber
@onready var keyboard: CodeKeyboard = $CodeKeyboard
@onready var teacher_timer: Timer = %TeacherTimer
@onready var teacher_help_label: Label = %TeacherHelpLabel
@onready var kalulu_button: CanvasItem = %KaluluButton


func _ready() -> void:
	UserDataManager.stop_synchronization_timer()
	
	# Check if the database is connected, if not go to loader
	if not Database.is_open:
		await get_tree().process_frame
		get_tree().change_scene_to_file(PACKAGE_LOADER_SCENE_PATH)
	
	help_speech = Database.load_external_sound(Database.get_kalulu_speech_path("login_screen", "help_code"))
	wrong_password_speech = Database.load_external_sound(Database.get_kalulu_speech_path("login_screen", "feedback_wrong_password"))
	right_password_speech = Database.load_external_sound(Database.get_kalulu_speech_path("login_screen", "feedback_right_password"))
	
	device_number_label.show()
	device_number_label.text = tr("DEVICE_NUMBER").format({"number": UserDataManager.get_device_settings().device_id})
	
	await OpeningCurtain.open()
	
	kalulu_button.hide()
	await kalulu.play_kalulu_speech(help_speech)
	kalulu_button.show()
	
	music_player.play()


func _on_code_keyboard_password_entered(password: String) -> void:
	if UserDataManager.student_exists(password):
		await UserDataManager.user_database_synchronizer.synchronize()
		UserDataManager.login_student(password)
		kalulu_button.hide()
		await kalulu.play_kalulu_speech(right_password_speech)
		await OpeningCurtain.close()
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	else:
		kalulu_button.hide()
		await kalulu.play_kalulu_speech(wrong_password_speech)
		keyboard.reset_password()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(BACK_SCENE_PATH)


func _on_kalulu_button_pressed() -> void:
	kalulu_button.hide()
	await kalulu.play_kalulu_speech(help_speech)
	kalulu_button.show()


func _on_teacher_button_button_down() -> void:
	if keyboard.get_password_as_string() != TEACHER_PASSWORD:
		return
	teacher_timer.start()
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - dev_last_click_time <= DEV_CLICK_MAX_DELAY:
		dev_click_count += 1
	else:
		dev_click_count = 1  # Too slow, reset
	dev_last_click_time = now
	if dev_click_count >= DEV_CLICK_THRESHOLD:
		dev_click_count = 0
		teacher_timer.stop()
		await OpeningCurtain.close()
		get_tree().change_scene_to_file(DEVELOPER_SCENE_PATH)


func _on_teacher_button_button_up() -> void:
	teacher_help_label.show()
	teacher_timer.stop()


func _on_teacher_timer_timeout() -> void:
	teacher_help_label.hide()
	await OpeningCurtain.close()
	get_tree().change_scene_to_file(TEACHER_SCENE_PATH)
