extends Control

const main_menu_path := "res://sources/menus/main/main_menu.tscn"
const login_menu_path := "res://sources/menus/login/login.tscn"

@onready var teacher_steps : Array[PackedScene] = [
	preload("res://sources/menus/register/steps/teacher/method_step.tscn"),
	preload("res://sources/menus/register/steps/teacher/devices_count_step.tscn")
]
@onready var parent_steps : Array[PackedScene] = [
	preload("res://sources/menus/register/steps/parent/players_count_step.tscn")
]

@onready var account_type_step : PackedScene = preload("res://sources/menus/register/steps/account_type_step.tscn")
@onready var credential_step : PackedScene = preload("res://sources/menus/register/steps/credentials_step.tscn")
@onready var students_step : PackedScene = preload("res://sources/menus/register/steps/teacher/students_count_step.tscn")
@onready var player_step : PackedScene = preload("res://sources/menus/register/steps/parent/player_step.tscn")

var current_steps : Array[Step]

@onready var kalulu := %Kalulu
@onready var register_data := TeacherSettings.new()
@onready var progress_bar := %ProgressBar
@onready var steps := %Steps

func _ready():
	kalulu.play("Tc_Idle1")
	current_steps = [account_type_step.instantiate()]
	_go_to_step(progress_bar.value)


func _go_to_step(step_index: int):
	# Clear the steps
	for step in steps.get_children(false):
		if step is Step:
			step.back.disconnect(_on_step_back)
			step.next.disconnect(_on_step_completed)
			steps.remove_child(step)
	
	# Instantiate the step
	var next_step = current_steps[step_index]
	if not next_step.data:
		next_step.data = register_data
	steps.add_child(next_step)
	
	# Connect the step
	next_step.back.connect(_on_step_back)
	next_step.next.connect(_on_step_completed)
	
	# Handles progress bar
	progress_bar.set_value_with_tween(step_index)


func _on_step_back(_step : Step):
	if progress_bar.value == 0:
		get_tree().change_scene_to_file(main_menu_path)
	else:
		_go_to_step(progress_bar.value-1)


func _on_step_completed(step : Step):
	match step.step_name:
		"type":
			# Adds teacher or parent steps
			_remove_future_steps()
			if register_data.account_type == TeacherSettings.AccountType.Teacher:
				for scene in teacher_steps:
					current_steps.append(scene.instantiate())
			elif register_data.account_type == TeacherSettings.AccountType.Parent:
				for scene in parent_steps:
					current_steps.append(scene.instantiate())
			progress_bar.max_value = current_steps.size()
		"devices":
			# Adds students steps for teachers
			_remove_future_steps()
			for device in register_data.devices_count:
				var students_step_scene = students_step.instantiate()
				if students_step_scene is StudentsCountStep:
					students_step_scene.question = students_step_scene.question % (device + 1)
					students_step_scene.device_id = device + 1
					current_steps.append(students_step_scene)
				else:
					students_step_scene.queue_free()
			current_steps.append(credential_step.instantiate())
			progress_bar.max_value = current_steps.size()
		"players":
			# Adds students steps for parents
			_remove_future_steps()
			var student_count := 1
			for student in register_data.students[1]:
				var student_step_scene := player_step.instantiate()
				student_step_scene.question = student_step_scene.question % student_count
				student_step_scene.data = student
				current_steps.append(student_step_scene)
				student_count += 1
			current_steps.append(credential_step.instantiate())
			progress_bar.max_value = current_steps.size()
	
	if progress_bar.value == current_steps.size()-1:
		if UserDataManager.register(register_data):
			get_tree().change_scene_to_file(login_menu_path)
		else:
			print("Impossible to register")
	else:
		_go_to_step(progress_bar.value+1)


func _remove_future_steps():
	# Free memory
	for i in range(progress_bar.value + 1, current_steps.size(), 1):
		current_steps[i].queue_free()
	
	# Resize the array to remove unwanted steps
	current_steps.resize(progress_bar.value + 1)
