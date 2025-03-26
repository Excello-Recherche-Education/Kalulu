extends "res://addons/gut/test.gd"

var input_folder = "res://tests/test_data/zip_unzip"
var output_folder = "res://tests/test_data/tmp/zip_unzip"
var output_zip = output_folder + "/test_data_folder_zipped.zip"

func test_zip_folder():
	var zipper = load("res://folder_zipper.gd").new()
	var error = zipper.compress(input_folder, output_zip)
	assert_true(error == OK, "Error while zipping folder: " + error_string(error))

func after_all():
	# Nettoyage
	if FileAccess.file_exists(output_folder):
		DirAccess.remove_absolute(output_folder)
